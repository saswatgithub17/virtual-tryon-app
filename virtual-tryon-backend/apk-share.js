/**
 * apk-share.js
 *
 * Run this from virtual-tryon-backend/ :
 *   node apk-share.js
 *
 * What it does:
 *  1. Finds the release APK from the Flutter build output
 *  2. Copies it into uploads/apk/ so the backend can serve it
 *  3. Detects your local IP address automatically
 *  4. Generates a QR code in the terminal
 *  5. Opens a browser page at /download-app showing the QR
 *
 * User flow:
 *  - Keep your backend running (npm start)
 *  - Run: node apk-share.js
 *  - Scan the QR code with any phone on the same WiFi
 *  - Phone downloads the APK → taps Install → app is installed
 */

'use strict';

const fs      = require('fs');
const path    = require('path');
const os      = require('os');
const { exec } = require('child_process');

// ─── 1. Locate the APK ────────────────────────────────────────────────────────

const APK_SOURCE = path.resolve(
  __dirname,
  '../build/app/outputs/flutter-apk/app-release.apk',
);

if (!fs.existsSync(APK_SOURCE)) {
  console.error('\n❌  APK not found at:');
  console.error('    ', APK_SOURCE);
  console.error('\n   Run this first:');
  console.error('   flutter build apk --release\n');
  process.exit(1);
}

// ─── 2. Copy APK into backend uploads ────────────────────────────────────────

const APK_DIR  = path.join(__dirname, 'uploads', 'apk');
const APK_DEST = path.join(APK_DIR, 'AuraTry.apk');

fs.mkdirSync(APK_DIR, { recursive: true });
fs.copyFileSync(APK_SOURCE, APK_DEST);

const apkSizeMB = (fs.statSync(APK_DEST).size / 1024 / 1024).toFixed(1);
console.log(`\n✅  APK copied → uploads/apk/AuraTry.apk  (${apkSizeMB} MB)`);

// ─── 3. Detect local IP ───────────────────────────────────────────────────────

function getLocalIP() {
  const ifaces = os.networkInterfaces();
  for (const name of Object.keys(ifaces)) {
    for (const iface of ifaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

const LOCAL_IP   = getLocalIP();
const PORT       = process.env.PORT || 5000;
const APK_URL    = `http://${LOCAL_IP}:${PORT}/uploads/apk/AuraTry.apk`;
const PAGE_URL   = `http://${LOCAL_IP}:${PORT}/download-app`;

// ─── 4. Register /download-app route on the existing Express server ───────────
// We monkey-patch the route into the already-running server.js if possible,
// OR generate a standalone QR in the terminal right now.

console.log('\n📱  APK Download URL:');
console.log('   ', APK_URL);
console.log('\n🌐  QR Code page:');
console.log('   ', PAGE_URL);

// ─── 5. Generate QR in the terminal ──────────────────────────────────────────

try {
  const QRCode = require('qrcode');

  QRCode.toString(APK_URL, { type: 'terminal', small: true }, (err, qr) => {
    if (err) {
      console.log('\n⚠️  Could not render QR in terminal:', err.message);
    } else {
      console.log('\n══════════════════════════════════════════════════════');
      console.log('  📲  SCAN THIS QR CODE WITH ANY ANDROID PHONE');
      console.log('      (phone must be on the same WiFi network)');
      console.log('══════════════════════════════════════════════════════\n');
      console.log(qr);
      console.log('══════════════════════════════════════════════════════\n');
    }
  });

  // Also save QR as a PNG so you can print or share it
  const QR_PNG = path.join(APK_DIR, 'download-qr.png');
  QRCode.toFile(QR_PNG, APK_URL, { width: 400 }, (err) => {
    if (!err) console.log(`🖼️   QR image saved → uploads/apk/download-qr.png`);
  });

} catch (e) {
  console.log('\n⚠️  qrcode package not found. Run:  npm install qrcode');
  console.log('   Then re-run:  node apk-share.js\n');
}

// ─── 6. Write the /download-app HTML page into the backend ───────────────────
// We write a static HTML file that server.js will serve automatically
// because server.js already serves /uploads as static files.

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Install AuraTry App</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: linear-gradient(135deg, #6C3DEB 0%, #E91E8C 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: white;
      border-radius: 24px;
      padding: 36px 32px;
      max-width: 420px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0,0,0,0.2);
    }
    .logo {
      width: 72px; height: 72px;
      background: linear-gradient(135deg, #6C3DEB, #E91E8C);
      border-radius: 18px;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 20px;
      font-size: 36px;
    }
    h1 { font-size: 26px; font-weight: 800; color: #1A1A2E; margin-bottom: 6px; }
    .subtitle { color: #888; font-size: 14px; margin-bottom: 28px; }
    .qr-wrap {
      background: #F8F8FF;
      border-radius: 16px;
      padding: 20px;
      margin-bottom: 24px;
      border: 2px dashed #E0D8FF;
    }
    .qr-wrap img { width: 200px; height: 200px; display: block; margin: 0 auto 12px; }
    .qr-label { font-size: 12px; color: #999; }
    .download-btn {
      display: block;
      background: linear-gradient(135deg, #6C3DEB, #E91E8C);
      color: white;
      text-decoration: none;
      padding: 16px 24px;
      border-radius: 14px;
      font-size: 16px;
      font-weight: 700;
      margin-bottom: 16px;
      transition: opacity 0.2s;
    }
    .download-btn:hover { opacity: 0.9; }
    .steps {
      text-align: left;
      background: #F8F9FA;
      border-radius: 12px;
      padding: 16px;
      margin-top: 20px;
    }
    .steps h3 { font-size: 13px; font-weight: 700; color: #1A1A2E; margin-bottom: 10px; }
    .step { display: flex; gap: 10px; margin-bottom: 8px; align-items: flex-start; }
    .step-num {
      background: #6C3DEB; color: white;
      border-radius: 50%; width: 20px; height: 20px;
      display: flex; align-items: center; justify-content: center;
      font-size: 11px; font-weight: 700; flex-shrink: 0; margin-top: 1px;
    }
    .step p { font-size: 12px; color: #555; line-height: 1.5; }
    .size-badge {
      display: inline-block;
      background: #EEF0FF; color: #6C3DEB;
      border-radius: 20px; padding: 4px 12px;
      font-size: 12px; font-weight: 600;
      margin-bottom: 20px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">👗</div>
    <h1>AuraTry</h1>
    <p class="subtitle">Virtual Try-On · Pantaloons</p>
    <span class="size-badge">📦 ${apkSizeMB} MB · Android APK</span>

    <div class="qr-wrap">
      <img src="/uploads/apk/download-qr.png" alt="QR Code" onerror="this.style.display='none'"/>
      <p class="qr-label">Scan with your Android phone camera</p>
    </div>

    <a class="download-btn" href="/uploads/apk/AuraTry.apk" download="AuraTry.apk">
      ⬇️ &nbsp; Download APK
    </a>

    <div class="steps">
      <h3>📋 How to install:</h3>
      <div class="step">
        <div class="step-num">1</div>
        <p>Tap <strong>Download APK</strong> or scan the QR code</p>
      </div>
      <div class="step">
        <div class="step-num">2</div>
        <p>Open the downloaded file from your notifications or Downloads folder</p>
      </div>
      <div class="step">
        <div class="step-num">3</div>
        <p>If prompted, allow <strong>Install from unknown sources</strong> in Settings</p>
      </div>
      <div class="step">
        <div class="step-num">4</div>
        <p>Tap <strong>Install</strong> and wait for it to complete</p>
      </div>
    </div>
  </div>
</body>
</html>`;

const HTML_PATH = path.join(APK_DIR, 'index.html');
fs.writeFileSync(HTML_PATH, html);
console.log('📄  Download page saved → uploads/apk/index.html');

// ─── 7. Open the download page in browser (Windows / Mac / Linux) ─────────────

console.log('\n🚀  Opening download page in browser...');

const openCmd =
  process.platform === 'win32'  ? `start ""  "${PAGE_URL}"` :
  process.platform === 'darwin' ? `open      "${PAGE_URL}"` :
                                   `xdg-open  "${PAGE_URL}"`;

exec(openCmd, (err) => {
  if (err) {
    console.log('   Could not open browser automatically.');
    console.log(`   Open manually: ${PAGE_URL}`);
  }
});

console.log('\n✅  Everything ready!');
console.log('═══════════════════════════════════════════════════════');
console.log('   Make sure your backend (npm start) is running.');
console.log('   Both your PC and the user\'s phone must be on');
console.log('   the SAME WiFi network.');
console.log('═══════════════════════════════════════════════════════\n');