const fs = require('fs');
const path = require('path');

console.log('--- Configuring Android Project for Production Build ---');

// 1. AndroidManifest.xml: Inject permissions
const manifestPath = path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml');
if (fs.existsSync(manifestPath)) {
  let manifest = fs.readFileSync(manifestPath, 'utf8');
  const perms = `
    <!-- PujoBike Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.VIBRATE" />
`;
  if (!manifest.includes('ACCESS_FINE_LOCATION')) {
    manifest = manifest.replace('<application', `${perms}\n    <application`);
    fs.writeFileSync(manifestPath, manifest, 'utf8');
    console.log('✓ Successfully injected permissions into AndroidManifest.xml');
  } else {
    console.log('• AndroidManifest.xml already contains permissions');
  }
} else {
  console.warn('! AndroidManifest.xml not found at:', manifestPath);
}

// 2. android/app/build.gradle: Enforce compileSdk 35, minSdk 21, targetSdk 35
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
  appGradle = appGradle.replace(/targetSdk\s*=\s*.+/g, 'targetSdk = 35');
  appGradle = appGradle.replace(/targetSdkVersion\s+.+/g, 'targetSdkVersion 35');
  appGradle = appGradle.replace(/targetSdkVersion\s*=\s*.+/g, 'targetSdkVersion = 35');

  fs.writeFileSync(appGradlePath, appGradle, 'utf8');
  console.log('✓ Configured android/app/build.gradle (compileSdk=35, minSdk=21, targetSdk=35)');
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
                    targetSdkVersion 35
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
