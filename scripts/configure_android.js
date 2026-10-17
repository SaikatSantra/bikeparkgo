const fs = require('fs');
const path = require('path');

console.log('--- Configuring Android for Production Build ---');

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

// 1. Add subprojects fallback rule to android/build.gradle
const rootGradlePath = path.join(__dirname, '..', 'android', 'build.gradle');
if (fs.existsSync(rootGradlePath)) {
  let rootGradle = fs.readFileSync(rootGradlePath, 'utf8');
  const subprojectRule = `
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) {
                    namespace project.group
                }
                compileSdkVersion 35
                defaultConfig {
                    minSdkVersion 21
                    targetSdkVersion 34
                }
            }
        }
    }
}
`;
  if (!rootGradle.includes('subprojects {')) {
    rootGradle += '\n' + subprojectRule;
    fs.writeFileSync(rootGradlePath, rootGradle, 'utf8');
    console.log('✓ Added subprojects fallback to android/build.gradle');
  }
}

// 2. Verify AndroidManifest.xml exists
const manifestPath = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
if (fs.existsSync(manifestPath)) {
  console.log('✓ Verified AndroidManifest.xml');
}

// 3. Verify android/app/build.gradle exists
const appGradlePath = path.join(__dirname, '..', 'android', 'app', 'build.gradle');
if (fs.existsSync(appGradlePath)) {
  console.log('✓ Verified android/app/build.gradle');
}

console.log('--- Android Production Configuration Complete ---');
