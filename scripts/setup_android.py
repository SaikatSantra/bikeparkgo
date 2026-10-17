#!/usr/bin/env python3
import os

def setup_manifest():
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if not os.path.exists(manifest_path):
        print(f"Warning: {manifest_path} not found.")
        return

    with open(manifest_path, "r", encoding="utf-8") as f:
        content = f.read()

    permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
"""

    if "ACCESS_FINE_LOCATION" not in content:
        content = content.replace("<application", permissions + "    <application")
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Successfully added permissions to AndroidManifest.xml")

def setup_gradle():
    gradle_path = "android/app/build.gradle"
    if not os.path.exists(gradle_path):
        print(f"Warning: {gradle_path} not found.")
        return

    with open(gradle_path, "r", encoding="utf-8") as f:
        content = f.read()

    content = content.replace("minSdkVersion = flutter.minSdkVersion", "minSdkVersion = 21")
    content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 21")

    with open(gradle_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Successfully set minSdkVersion to 21 in build.gradle")

if __name__ == "__main__":
    setup_manifest()
    setup_gradle()
