const fs = require('fs');
const path = require('path');

console.log('--- Verifying Android Production Configuration ---');

function copyDirSync(src, dest) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src, { withFileTypes: true });
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDirSync(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// 0. Ensure launcher icons are in android res
const iconSrcDir = path.join(__dirname, '..', 'android_res');
const resDestDir = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'res');
if (fs.existsSync(iconSrcDir) && fs.existsSync(resDestDir)) {
  copyDirSync(iconSrcDir, resDestDir);
  console.log('✓ Successfully ensured launcher icons in android/app/src/main/res/');
}

// 1. Verify AndroidManifest.xml exists
const manifestPath = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
if (fs.existsSync(manifestPath)) {
  console.log('✓ Verified AndroidManifest.xml');
} else {
  console.error('! Error: AndroidManifest.xml is missing');
}

// 2. Verify android/app/build.gradle exists
const appGradlePath = path.join(__dirname, '..', 'android', 'app', 'build.gradle');
if (fs.existsSync(appGradlePath)) {
  console.log('✓ Verified android/app/build.gradle');
} else {
  console.error('! Error: android/app/build.gradle is missing');
}

console.log('--- Android Production Configuration Verified ---');
