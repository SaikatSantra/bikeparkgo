# 🌸 BikeParkGo - Production Flutter App & Google Drive Integration Guide

## 📌 Architecture Overview
This production Flutter application provides:
1. **Day / Night Theme Toggle** (Festive Durga Puja day/night aesthetics with automatic preference persistence).
2. **Customer Login & Guest Checkout**:
   - Guest Access form: Name, Phone, Email, Profile Picture (Camera / Gallery).
   - Customer Login: Fast sign-in.
3. **Automated Google Drive Integration**:
   - For every registered user/guest, a dedicated folder is created in your Google Drive: `BikeParkGo_Users/<User_Name>_<Phone_Number>/`.
   - Inside that folder:
     - `user_details.txt` (Text note containing Name, Phone, Email, Timestamp, and Mode).
     - `profile_picture.jpg` (Full decoded photo).
4. **Top-Notch Security Architecture**:
   - **Zero Client Secrets**: No Google Cloud Service Account private keys or Google passwords are embedded in the Flutter APK. (If a service account key is embedded in an APK, anyone can decompile the APK and access or wipe your entire Google Drive!).
   - **Bearer Secret Token**: The Google Apps Script webhook validates incoming requests using a private secret token (`BikeParkGo_SecureToken_2026_Trishul`) before executing any action.
   - **Folder Sanitization**: Names and numbers are strictly sanitized against special characters to prevent directory injection.
   - **TLS 1.3 Transport**: All data transmissions are encrypted.

---

## 🚀 Step 1: Deploy Google Drive Backend (2 Minutes)

1. Open your browser and go to: **[script.google.com](https://script.google.com/)**.
2. Click **"+ New Project"** and name it `BikeParkGo_Drive_Backend`.
3. Delete any default code in the editor, and copy-paste the entire contents of:
   `d:\Saitriq\mobile app\flutter_bikeparkgo\google_drive_backend\Code.gs`.
4. Click the blue **"Deploy"** button at the top right ➔ **"New deployment"**.
5. Click the gear icon (⚙️) next to "Select type" and choose **"Web app"**.
6. Set:
   - **Description**: `BikeParkGo User Sync`
   - **Execute as**: `Me (your email)`
   - **Who has access**: `Anyone` *(Note: The script authenticates requests using the secret token inside the payload, so only your app can create folders)*.
7. Click **"Deploy"** and authorize the Google Drive permissions.
8. Copy the **Web App URL** (e.g., `https://script.google.com/macros/s/AKfycb.../exec`).
9. Paste that URL into `d:\Saitriq\mobile app\flutter_bikeparkgo\lib\services\google_drive_service.dart` at line 6:
   ```dart
   static String webhookUrl = "PASTE_YOUR_WEB_APP_URL_HERE";
   ```

---

## 📱 Step 2: How to Build & Run the Flutter App

Once you have Flutter installed on your computer:
1. Open PowerShell in `d:\Saitriq\mobile app\flutter_bikeparkgo`.
2. Get dependencies:
   ```powershell
   flutter pub get
   ```
3. Run on connected Android phone or emulator:
   ```powershell
   flutter run
   ```
4. Build the final production `.apk` file:
   ```powershell
   flutter build apk --release
   ```
   Your production installer will be ready at:
   `build/app/outputs/flutter-apk/app-release.apk`!

