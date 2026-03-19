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
const DEBUG_DIR = './uploads/tryon-debug';
let _cachedFnIndex = null;
const HF_TOKEN = process.env.HUGGINGFACE_API_KEY || process.env.HF_TOKEN;

function authHeaders() {
  if (!HF_TOKEN) return {};
  return { Authorization: `Bearer ${HF_TOKEN}` };
}

function safeStringify(value, maxLen = 500) {
  try {
    return JSON.stringify(
      value,
      (_k, v) => {
        if (typeof v === 'string' && v.length > maxLen) {
          return `${v.slice(0, 200)}...[truncated:${v.length}]...${v.slice(-50)}`;
        }
        return v;
      },
      2
    );
  } catch (_) {
    return String(value);
  }
}

function ensureDebugDir() {
  try {
    fs.mkdirSync(DEBUG_DIR, { recursive: true });
  } catch (_) {}
}

// ─── Upload one file to the Gradio server ─────────────────────────────────────
async function uploadFile(localPath) {
  const buf  = fs.readFileSync(localPath);
  const ext = path.extname(localPath).toLowerCase();
  let mime = 'image/jpeg';
  if (ext === '.png') mime = 'image/png';
  else if (ext === '.webp') mime = 'image/webp';
  else if (ext === '.jpeg') mime = 'image/jpeg';
  else if (ext === '.jpg') mime = 'image/jpeg';
  const blob = new Blob([buf], { type: mime });
  const form = new FormData();
  form.append('files', blob, path.basename(localPath));

  const res = await fetch(`${SPACE}/upload`, {
    method: 'POST',
    body: form,
    headers: authHeaders(),
  });
  if (!res.ok) {
    throw new Error(`Upload failed (${res.status}): ${await res.text().catch(() => '')}`);
  }
  const paths = await res.json();
  if (!Array.isArray(paths) || !paths[0]) throw new Error('Upload returned no path');
  return paths[0];
}

// ─── Download an output URL to a local file ───────────────────────────────────
async function downloadImage(url, dest) {
  // Support Gradio outputs that embed images as data URLs.
  if (typeof url === 'string' && url.startsWith('data:image')) {
    const m = url.match(/^data:image\/[^;]+;base64,(.*)$/);
    if (!m) throw new Error('Invalid data URL image payload');
    const base64 = m[1];
    fs.writeFileSync(dest, Buffer.from(base64, 'base64'));
    return;
  }

  const fullUrl = makeFullUrl(url);
  if (!fullUrl) throw new Error('Download failed: invalid Gradio output URL');
  const res = await fetch(fullUrl);
  if (!res.ok) throw new Error(`Download failed (${res.status})`);
  fs.writeFileSync(dest, Buffer.from(await res.arrayBuffer()));
}

function makeFullUrl(url) {
  if (typeof url !== 'string' || url.trim() === '') return null;
  if (url.startsWith('http')) return url;
  if (url.startsWith('data:image')) return url;
  // Gradio often returns internal tmp paths like "/tmp/gradio/<...>/image.jpg".
  // Those are not directly downloadable, but can be accessed via Gradio's
  // "/file=<path>" handler.
  if (url.startsWith('/tmp/')) {
    return `${SPACE}/file=${encodeURIComponent(url)}`;
  }

  // If already in "/file=..." form, it is directly downloadable.
  if (url.startsWith('/file=')) return `${SPACE}${url}`;

  // Some Gradio responses return "file=..." without a leading slash.
  if (url.startsWith('file=')) return `${SPACE}/${url}`;

  if (url.startsWith('/')) return `${SPACE}${url}`;

  return null;
}

function guessImageExtension(url) {
  if (typeof url !== 'string') return 'jpg';
  const m = url.match(/\.(png|jpe?g|webp)(?=\?|$)/i);
  if (!m) return 'jpg';
  const ext = m[1].toLowerCase();
  if (ext === 'jpeg') return 'jpg';
  return ext;
}

function buildQueueData(userTmp, dressTmp, mode) {
  const fileData = (tmpPath) => ({
    path: tmpPath,
    meta: { _type: 'gradio.FileData' },
  });

  const editorData = (tmpPath) => ({
    // IDM-VTON space uses a Gradio `imageeditor` for the "Human" input.
    // For API calls we must provide an EditorData object (not a plain file path).
    background: fileData(tmpPath),
    layers: [],
    composite: null,
  });

  // Gradio spaces vary in whether file inputs expect:
  // - { path: "<tmp path>" } (object form)
  // - "<tmp path>"           (string form)
  if (mode === 'string') {
    return [
      // imageeditor does not support the raw string variant.
      userTmp,
      dressTmp,
      '', // garment description
      true, // is_checked
      true, // is_checked_crop
      30, // denoise_steps
      42, // seed
    ];
  }

  return [
    editorData(userTmp),
    fileData(dressTmp),
    '', // garment description
    true, // is_checked
    true, // is_checked_crop
    30, // denoise_steps
    42, // seed
  ];
}

function extractUrlLike(value, depth = 0) {
  // Depth cap so we don't get stuck on unexpected circular structures.
  if (depth > 10) return null;
  if (value == null) return null;

  if (typeof value === 'string') {
    const s = value.trim();
    if (s.startsWith('http')) return s;
    if (s.startsWith('data:image')) return s;
    // Gradio file URLs commonly look like "/file=...." or include "file="
    if (s.includes('/file=') || s.includes('file=')) return s;
    // Gradio may also return internal tmp paths like "/tmp/gradio/.../img.jpg".
    // We treat those as candidates; `makeFullUrl()` will convert them to
    // a downloadable "/file=<path>" URL.
    const imgExt = /\.(png|jpe?g|webp)(\?|$)/i;
    if (imgExt.test(s)) {
      if (s.includes('/tmp/') || s.startsWith('tmp/') || s.includes('gradio/')) return s;
    }
    return null;
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const found = extractUrlLike(item, depth + 1);
      if (found) return found;
    }
    return null;
  }

  if (typeof value === 'object') {
    // Direct fields first (newer Gradio payloads often use url/path).
    for (const k of ['url', 'path', 'location', 'src', 'file']) {
      if (typeof value[k] === 'string') {
        const found = extractUrlLike(value[k], depth + 1);
        if (found) return found;
      }
    }

    // Then recursively scan nested objects/arrays.
    for (const v of Object.values(value)) {
      const found = extractUrlLike(v, depth + 1);
      if (found) return found;
    }
  }

  return null;
}

// ─── Extract output image URL from a Gradio process_completed event ───────────
function getOutputUrl(event) {
  // Gradio changed its output shape a few times. Instead of trusting
  // output.data[0].url/path only, scan the whole payload for a Gradio file URL.
  return (
    extractUrlLike(event?.output?.data) ??
    extractUrlLike(event?.output) ??
    extractUrlLike(event)
  );
}

// ─── Stream SSE from /queue/data until process_completed ─────────────────────
function waitForResult(sessionHash) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error('IDM-VTON timed out after 10 minutes')),
      TIMEOUT_MS
    );

    fetch(
      `${SPACE}/queue/data?session_hash=${encodeURIComponent(sessionHash)}`,
      { headers: authHeaders() }
    )
      .then(res => {
        if (!res.ok || !res.body) {
          clearTimeout(timer);
          return reject(new Error(`SSE failed: ${res.status}`));
        }

        const reader  = res.body.getReader();
        const decoder = new TextDecoder();
        let   buf     = '';
        // SSE events can be split across multiple `data:` lines.
        // We must accumulate all `data:` lines until a blank line, then parse as one JSON blob.
        let   dataParts = [];

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
                const trimmed = line.trimEnd();

                // Blank line = end of SSE event
                if (trimmed === '') {
                  if (dataParts.length === 0) continue;
                  const payload = dataParts.join('\n').trim();
                  dataParts = [];

                  let event;
                  try { event = JSON.parse(payload); }
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
                  // Note: we only handle JSON events where msg exists.
                  continue;
                }

                if (trimmed.startsWith('data:')) {
                  dataParts.push(trimmed.slice(5).trim());
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

  const fnIndex = await resolveFnIndex();

  // Try two input encodings because the space may expect different types
  // for file components.
  const modesToTry = ['object'];
  let lastErr = null;

  for (const mode of modesToTry) {
    const sessionHash = Math.random().toString(36).substring(2);

    console.log(`   Joining Gradio queue... (mode=${mode})`);
    const joinRes = await fetch(`${SPACE}/queue/join`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders(),
      },
      body: JSON.stringify({
        fn_index: fnIndex,
        data: buildQueueData(userTmp, dressTmp, mode),
        session_hash: sessionHash,
      }),
    });

    if (!joinRes.ok) {
      lastErr = new Error(
        `Queue join failed (${joinRes.status}) mode=${mode}: ${await joinRes.text().catch(() => '')}`
      );
      continue;
    }

    // Some Gradio versions return the final session hash in the response body.
    let joinJson = null;
    let joinText = '';
    try {
      joinText = await joinRes.text();
      try { joinJson = JSON.parse(joinText); } catch (_) {}
    } catch (_) {}

    const effectiveSessionHash =
      joinJson?.session_hash ||
      joinJson?.sessionHash ||
      joinJson?.hash ||
      sessionHash;

    if (!effectiveSessionHash) {
      lastErr = new Error(`Queue join did not return session_hash. mode=${mode}`);
      continue;
    }

    console.log('   Waiting for AI result (1-3 minutes)...');
    const event = await waitForResult(effectiveSessionHash);
    const outputUrl = getOutputUrl(event);

    if (outputUrl) return outputUrl;

    const debugErr = event?.output?.error ?? event?.error;
    // Dump payload for inspection.
    ensureDebugDir();
    const stamp = Date.now();
    const debugPath = path.join(
      DEBUG_DIR,
      `gradio-process-completed-${stamp}-fn${fnIndex}-mode-${mode}.json`
    );

    fs.writeFileSync(
      debugPath,
      safeStringify(
        {
          msg: event?.msg,
          success: event?.success,
          error: event?.error,
          output: event?.output,
          outputKeys: event?.output ? Object.keys(event.output) : null,
          fnIndex,
          mode,
        },
        1200
      ),
      'utf8'
    );

    const outPreview = safeStringify(event?.output, 800).slice(0, 1200);
    if (debugErr != null && debugErr !== '') {
      // Gradio often returns a useful error string in output.error.
      lastErr = new Error(
        `Gradio try-on failed: ${String(debugErr)}. fnIndex=${fnIndex} mode=${mode}. debug: ${debugPath}`
      );
    } else {
      lastErr = new Error(
        `No output URL in Gradio response. fnIndex=${fnIndex} mode=${mode} output preview: ${outPreview}. debug: ${debugPath}`
      );
    }

    // If we hit a typical signature/type issue (AttributeError), retry the other mode.
    if (String(debugErr || '').includes('AttributeError')) continue;
    break;
  }

  throw lastErr ?? new Error('IDM-VTON try-on failed with unknown error');
}

async function resolveFnIndex() {
  if (_cachedFnIndex != null) return _cachedFnIndex;

  // Default (older implementation)
  let fallback = 0;

  try {
    const res = await fetch(`${SPACE}/config`);
    if (!res.ok) throw new Error(`config fetch failed (${res.status})`);
    const cfg = await res.json();

    const deps = Array.isArray(cfg?.dependencies) ? cfg.dependencies : [];
    if (deps.length === 0) throw new Error('config.dependencies missing');

    // Heuristic: pick dependency whose number of inputs matches what we send (7).
    // This is more reliable than relying on dependency ordering.
    const candidates = deps
      .map((d, idx) => ({ d, idx }))
      .filter(({ d }) => Array.isArray(d.inputs) && d.inputs.length === 7)
      .filter(({ d }) => Array.isArray(d.outputs) && d.outputs.length >= 1);

    if (candidates.length > 0) {
      _cachedFnIndex = candidates[0].idx;
      console.log(`   ✅ Resolved Gradio fn_index=${_cachedFnIndex} (inputs=7)`);
      return _cachedFnIndex;
    }

    // If heuristic fails, save config shape for debugging.
    ensureDebugDir();
    const debugPath = path.join(DEBUG_DIR, `gradio-config-fallback-${Date.now()}.json`);
    fs.writeFileSync(debugPath, safeStringify(cfg, 2500), 'utf8');
  } catch (e) {
    console.log(`   ⚠️  resolveFnIndex fallback: ${e.message}`);
  }

  _cachedFnIndex = fallback;
  console.log(`   ℹ️  Using fallback fn_index=${_cachedFnIndex}`);
  return _cachedFnIndex;
}

// ─── Wake space (non-fatal) ────────────────────────────────────────────────────
async function wakeSpace() {
  try {
    console.log('   Waking IDM-VTON space...');
    await fetch(`${SPACE}/`, {
      signal: AbortSignal.timeout(30_000),
      headers: authHeaders(),
    });
    console.log('   Space is awake.');
  } catch (e) {
    console.log(`   Wake ping skipped: ${e.message}`);
  }
}

// ─── Exported: process multiple dresses sequentially ─────────────────────────
/**
 * @param {string}   userPhotoPath     local path to user's photo
 * @param {string[]} dressImagePaths  array of local dress image paths
 * @returns {Promise<Array<{success: boolean, resultUrl: string|null, method: string, error?: string}>>}
 */
exports.processMultipleTryOns = async function (userPhotoPath, dressImagePaths) {
  const outDir = './uploads/tryon-results';
  fs.mkdirSync(outDir, { recursive: true });

  await wakeSpace();

  const results = [];

  for (let i = 0; i < dressImagePaths.length; i++) {
    const dressPath = dressImagePaths[i];
    const stamp     = Date.now();
    const outBase   = `tryon-${stamp}-${i}`;

    console.log(`\n[${i + 1}/${dressImagePaths.length}] Processing dress...`);

    let success = false;
    let lastAttemptErr = null;
    let lastOutputUrl = null;

    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        console.log(`   Attempt ${attempt}/3`);
        const outputUrl = await runOneTryOn(userPhotoPath, dressPath);
        lastOutputUrl = outputUrl;

        const ext = guessImageExtension(outputUrl);
        const outFile = `${outBase}.${ext}`;
        const outPath = path.join(outDir, outFile);
        const relPath = `/uploads/tryon-results/${outFile}`;
        console.log(
          `   Output URL hint: ${String(outputUrl).slice(0, 120)} (saving .${ext})`
        );

        console.log('   Downloading result...');
        await downloadImage(outputUrl, outPath);
        console.log(`   ✅ Saved → ${relPath}`);
        results.push({
          success: true,
          resultUrl: relPath,
          method: 'IDM-VTON AI',
        });
        success = true;
        break;
      } catch (err) {
        lastAttemptErr = err;
        console.error(`   ❌ Attempt ${attempt} failed: ${err.message}`);
        if (attempt < 3) {
          console.log('   Retrying in 5 s...');
          await new Promise(r => setTimeout(r, 5000));
        }
      }
    }

    if (!success) {
      const outHint = lastOutputUrl ? `; outputUrl=${String(lastOutputUrl).slice(0, 120)}` : '';
      const finalErrMsg = lastAttemptErr?.message
        ? `Try-on failed: ${lastAttemptErr.message}${outHint}`
        : `Try-on failed${outHint}`;

      // Fallback: use the dress image itself as a preview
      const fbFile = `tryon-fallback-${stamp}-${i}.jpg`;
      const fbPath = path.join(outDir, fbFile);
      const fbRel  = `/uploads/tryon-results/${fbFile}`;
      try {
        fs.copyFileSync(dressPath, fbPath);
        console.log(`   ⚠️  Used dress image as fallback → ${fbRel}`);
        results.push({
          // Do NOT mark this as a successful try-on.
          // Returning the dress image in the UI makes it look like try-on worked.
          success: false,
          resultUrl: null,
          method: 'Fallback',
          error: finalErrMsg,
        });
      } catch (_) {
        results.push({
          success: false,
          resultUrl: null,
          method: 'Fallback',
          error: `Failed to save fallback image${lastAttemptErr?.message ? `; last error=${lastAttemptErr.message}` : ''}`,
        });
      }
    }

    // Pause between dresses
    if (i < dressImagePaths.length - 1) {
      await new Promise(r => setTimeout(r, 3000));
    }
  }

  return results;
};