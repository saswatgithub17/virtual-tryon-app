/**
 * tryonService.js
 *
 * Calls IDM-VTON on HuggingFace using Gradio's REST API directly.
 *
 * WHY: @gradio/client's Client.connect() has a WebSocket/fetch handshake
 * incompatibility with Node.js v20+ that causes "TypeError: fetch failed"
 * even when the space is fully reachable via curl. Bypassing the SDK and
 * calling the Gradio queue REST API directly fixes this completely.
 *
 * Node.js v18+ has native fetch — no extra packages needed.
 *
 * Flow:
 *  1. Wake space ping (non-fatal)
 *  2. Upload user photo  → temp server path
 *  3. Upload dress image → temp server path
 *  4. POST /queue/join   → enqueue job
 *  5. GET  /queue/data   → SSE stream, wait for process_completed
 *  6. Download output image, save to uploads/tryon-results/
 */

const fs   = require('fs');
const path = require('path');

const SPACE      = 'https://yisol-idm-vton.hf.space';
const TIMEOUT_MS = 10 * 60 * 1000;   // 10 minutes

// ─── Upload one file to the Gradio server ─────────────────────────────────────
async function uploadFile(localPath) {
  const buf  = fs.readFileSync(localPath);
  const blob = new Blob([buf], { type: 'image/jpeg' });
  const form = new FormData();
  form.append('files', blob, path.basename(localPath));

  const res = await fetch(`${SPACE}/upload`, { method: 'POST', body: form });
  if (!res.ok) {
    throw new Error(`Upload failed (${res.status}): ${await res.text().catch(() => '')}`);
  }
  const paths = await res.json();
  if (!Array.isArray(paths) || !paths[0]) throw new Error('Upload returned no path');
  return paths[0];
}

// ─── Download an output URL to a local file ───────────────────────────────────
async function downloadImage(url, dest) {
  const fullUrl = url.startsWith('http') ? url : `${SPACE}${url}`;
  const res     = await fetch(fullUrl);
  if (!res.ok) throw new Error(`Download failed (${res.status})`);
  fs.writeFileSync(dest, Buffer.from(await res.arrayBuffer()));
}

// ─── Extract output image URL from a Gradio process_completed event ───────────
function getOutputUrl(event) {
  const d = event?.output?.data?.[0];
  if (!d) return null;
  if (typeof d === 'string') return d;
  return d.url || d.path || null;
}

// ─── Stream SSE from /queue/data until process_completed ─────────────────────
function waitForResult(sessionHash) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error('IDM-VTON timed out after 10 minutes')),
      TIMEOUT_MS
    );

    fetch(`${SPACE}/queue/data?session_hash=${sessionHash}`)
      .then(res => {
        if (!res.ok || !res.body) {
          clearTimeout(timer);
          return reject(new Error(`SSE failed: ${res.status}`));
        }

        const reader  = res.body.getReader();
        const decoder = new TextDecoder();
        let   buf     = '';

        const pump = () => {
          reader.read()
            .then(({ done, value }) => {
              if (done) {
                clearTimeout(timer);
                return reject(new Error('SSE stream ended without result'));
              }

              buf += decoder.decode(value, { stream: true });
              const lines = buf.split('\n');
              buf = lines.pop();   // save partial last line

              for (const line of lines) {
                if (!line.startsWith('data:')) continue;
                let event;
                try { event = JSON.parse(line.slice(5).trim()); }
                catch (_) { continue; }

                if (event.msg === 'process_completed') {
                  clearTimeout(timer);
                  return resolve(event);
                }
                if (event.msg === 'queue_full') {
                  clearTimeout(timer);
                  return reject(new Error('Gradio queue is full — retry shortly'));
                }
                if (event.msg === 'estimation') {
                  const pos = event.rank != null ? ` (queue pos ${event.rank})` : '';
                  console.log(`   Queued${pos}...`);
                }
                if (event.msg === 'process_starts') {
                  console.log('   AI is processing...');
                }
              }

              pump();
            })
            .catch(err => { clearTimeout(timer); reject(err); });
        };

        pump();
      })
      .catch(err => { clearTimeout(timer); reject(err); });
  });
}

// ─── One try-on: upload → queue → stream → download ──────────────────────────
async function runOneTryOn(userPhotoPath, dressImagePath) {
  console.log(`   Uploading user photo...`);
  const userTmp  = await uploadFile(userPhotoPath);

  console.log(`   Uploading dress image...`);
  const dressTmp = await uploadFile(dressImagePath);

  const sessionHash = Math.random().toString(36).substring(2);

  console.log('   Joining Gradio queue...');
  const joinRes = await fetch(`${SPACE}/queue/join`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({
      fn_index:     0,
      data: [
        { path: userTmp  },   // human photo
        { path: dressTmp },   // garment image
        '',                   // garment description
        true,                 // is_checked
        true,                 // is_checked_crop
        30,                   // denoise_steps
        42,                   // seed
      ],
      session_hash: sessionHash,
    }),
  });

  if (!joinRes.ok) {
    throw new Error(`Queue join failed (${joinRes.status}): ${await joinRes.text().catch(() => '')}`);
  }

  console.log('   Waiting for AI result (1-3 minutes)...');
  const event     = await waitForResult(sessionHash);
  const outputUrl = getOutputUrl(event);
  if (!outputUrl) throw new Error('No output URL in Gradio response');
  return outputUrl;
}

// ─── Wake space (non-fatal) ────────────────────────────────────────────────────
async function wakeSpace() {
  try {
    console.log('   Waking IDM-VTON space...');
    await fetch(`${SPACE}/`, { signal: AbortSignal.timeout(30_000) });
    console.log('   Space is awake.');
  } catch (e) {
    console.log(`   Wake ping skipped: ${e.message}`);
  }
}

// ─── Exported: process multiple dresses sequentially ─────────────────────────
/**
 * @param {string}   userPhotoPath    local path to user's photo
 * @param {string[]} dressImagePaths  array of local dress image paths
 * @returns {Promise<string[]>}       relative URLs of saved result images
 */
exports.processMultipleTryOns = async function (userPhotoPath, dressImagePaths) {
  const outDir = './uploads/tryon-results';
  fs.mkdirSync(outDir, { recursive: true });

  await wakeSpace();

  const results = [];

  for (let i = 0; i < dressImagePaths.length; i++) {
    const dressPath = dressImagePaths[i];
    const stamp     = Date.now();
    const outFile   = `tryon-${stamp}-${i}.jpg`;
    const outPath   = path.join(outDir, outFile);
    const relPath   = `/uploads/tryon-results/${outFile}`;

    console.log(`\n[${i + 1}/${dressImagePaths.length}] Processing dress...`);

    let success = false;

    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        console.log(`   Attempt ${attempt}/3`);
        const outputUrl = await runOneTryOn(userPhotoPath, dressPath);
        console.log('   Downloading result...');
        await downloadImage(outputUrl, outPath);
        console.log(`   ✅ Saved → ${relPath}`);
        results.push(relPath);
        success = true;
        break;
      } catch (err) {
        console.error(`   ❌ Attempt ${attempt} failed: ${err.message}`);
        if (attempt < 3) {
          console.log('   Retrying in 5 s...');
          await new Promise(r => setTimeout(r, 5000));
        }
      }
    }

    if (!success) {
      // Fallback: use the dress image itself as a preview
      const fbFile = `tryon-fallback-${stamp}-${i}.jpg`;
      const fbPath = path.join(outDir, fbFile);
      const fbRel  = `/uploads/tryon-results/${fbFile}`;
      try {
        fs.copyFileSync(dressPath, fbPath);
        console.log(`   ⚠️  Used dress image as fallback → ${fbRel}`);
        results.push(fbRel);
      } catch (_) {
        results.push('');
      }
    }

    // Pause between dresses
    if (i < dressImagePaths.length - 1) {
      await new Promise(r => setTimeout(r, 3000));
    }
  }

  return results;
};