const fs = require('fs');
const path = require('path');

console.log('--- Configuring Android Project for Production Build ---');

// Helper: Copy directory contents recursively
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

// 0. Copy App Launcher Icons to android res
const iconSrcDir = path.join('android_res');
const resDestDir = path.join('android', 'app', 'src', 'main', 'res');
if (fs.existsSync(iconSrcDir) && fs.existsSync(resDestDir)) {
  copyDirSync(iconSrcDir, resDestDir);
  console.log('✓ Successfully copied launcher icons to android/app/src/main/res/');
}

// 1. AndroidManifest.xml: Inject permissions, hardware features, and clean label
const manifestPath = path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml');
if (fs.existsSync(manifestPath)) {
  let manifest = fs.readFileSync(manifestPath, 'utf8');

  // Set proper human-readable label
  manifest = manifest.replace(/android:label="[^"]*"/, 'android:label="BikeParkGo"');

  const perms = `
    <!-- PujoBike Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- Optional Hardware Features -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    <uses-feature android:name="android.hardware.location.gps" android:required="false" />
`;
  if (!manifest.includes('ACCESS_FINE_LOCATION')) {
    manifest = manifest.replace('<application', `${perms}\n    <application`);
    fs.writeFileSync(manifestPath, manifest, 'utf8');
    console.log('✓ Successfully injected permissions into AndroidManifest.xml');
  } else {
    fs.writeFileSync(manifestPath, manifest, 'utf8');
    console.log('• AndroidManifest.xml verified');
  }
} else {
  console.warn('! AndroidManifest.xml not found at:', manifestPath);
}

// 2. android/app/build.gradle: Enforce compileSdk 35, minSdk 21, targetSdk 34, and no-minify release signing
const appGradlePath = path.join('android', 'app', 'build.gradle');
if (fs.existsSync(appGradlePath)) {
  let appGradle = fs.readFileSync(appGradlePath, 'utf8');

  // Match modern DSL: compileSdk = flutter.compileSdkVersion
  appGradle = appGradle.replace(/compileSdk\s*=\s*.+/g, 'compileSdk = 35');
  appGradle = appGradle.replace(/compileSdkVersion\s+.+/g, 'compileSdkVersion 35');
  appGradle = appGradle.replace(/compileSdkVersion\s*=\s*.+/g, 'compileSdkVersion = 35');

  // Match minSdk
  appGradle = appGradle.replace(/minSdk\s*=\s*.+/g, 'minSdk = 21');
  appGradle = appGradle.replace(/minSdkVersion\s+.+/g, 'minSdkVersion 21');
  appGradle = appGradle.replace(/minSdkVersion\s*=\s*.+/g, 'minSdkVersion = 21');

  // Match targetSdk
  appGradle = appGradle.replace(/targetSdk\s*=\s*.+/g, 'targetSdk = 34');
  appGradle = appGradle.replace(/targetSdkVersion\s+.+/g, 'targetSdkVersion 34');
  appGradle = appGradle.replace(/targetSdkVersion\s*=\s*.+/g, 'targetSdkVersion = 34');

  // Disable R8 minification to prevent runtime reflection crashes on launch
  if (!appGradle.includes('minifyEnabled false')) {
    appGradle = appGradle.replace(
      /buildTypes\s*\{[\s\S]*?release\s*\{[\s\S]*?\}/,
      `signingConfigs {
        release {
            storeFile file('upload-keystore.jks')
            storePassword 'bikeparkgo123'
            keyAlias 'upload'
            keyPassword 'bikeparkgo123'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
        }
    }`
    );
  }

  fs.writeFileSync(appGradlePath, appGradle, 'utf8');
  console.log('✓ Configured android/app/build.gradle with signingConfig and minifyEnabled=false');
} else {
  console.warn('! android/app/build.gradle not found');
}

// 3. android/build.gradle: Enforce compileSdkVersion 35 and namespace across all plugin subprojects
const rootGradlePath = path.join('android', 'build.gradle');
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
    console.log('✓ Added subprojects compileSdkVersion 35 and namespace fallback to android/build.gradle');
  }
} else {
  console.warn('! android/build.gradle not found');
}

// 4. android/gradle.properties: AndroidX, Jetifier and build optimization
const propPath = path.join('android', 'gradle.properties');
let props = fs.existsSync(propPath) ? fs.readFileSync(propPath, 'utf8') : '';
if (!props.includes('android.useAndroidX')) {
  props += '\nandroid.useAndroidX=true\nandroid.enableJetifier=true\n';
}
if (!props.includes('org.gradle.jvmargs')) {
  props += '\norg.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G -XX:+HeapDumpOnOutOfMemoryError\n';
}
fs.writeFileSync(propPath, props, 'utf8');
console.log('✓ Configured android/gradle.properties');

console.log('--- Android Configuration Completed Successfully ---');
