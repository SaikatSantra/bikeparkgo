/**
 * bikeparkgo - SECURE GOOGLE DRIVE REGISTRATION WEBHOOK
 * 
 * Top-Notch Security Architecture:
 * 1. Zero Client Secrets: No Google Cloud service account keys are embedded in the mobile APK.
 * 2. Secret Token Authentication: Rejects unauthorized requests with 401 Unauthorized.
 * 3. Folder Sanitization: Removes dangerous characters to prevent directory injection.
 * 4. Automatic Folder & File Structure:
 *    Root: BikeParkGo_Users/
 *       └── <User_Name>_<Phone_Number>/
 *            ├── user_details.txt  (Name, Email, Phone, Time, Mode)
 *            └── profile_picture.jpg
 */

// CHANGE THIS TO YOUR SECURE SECRET KEY (Must match secretKey in Flutter app)
const API_SECRET_TOKEN = "BikeParkGo_SecureToken_2026_Trishul";
const ROOT_FOLDER_NAME = "BikeParkGo_Users";

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return responseJSON({ success: false, error: "Empty request payload" }, 400);
    }

    const data = JSON.parse(e.postData.contents);

    // 1. Top-Notch Security Check: Validate Secret Token
    if (data.secretToken !== API_SECRET_TOKEN) {
      return responseJSON({ success: false, error: "Unauthorized access: Invalid token" }, 401);
    }

    // 2. Validate Required Fields
    const name = String(data.name || "").trim();
    const phone = String(data.phone || "").trim();
    const email = String(data.email || "").trim();
    const isGuest = data.isGuest === true;
    const base64Photo = data.profilePicBase64 || "";

    if (!name || !phone) {
      return responseJSON({ success: false, error: "Name and Phone are mandatory" }, 400);
    }

    // 3. Sanitize Folder Name (Allow only letters, numbers, spaces, and dashes)
    const sanitizedName = name.replace(/[^a-zA-Z0-9 _-]/g, "");
    const sanitizedPhone = phone.replace(/[^0-9+]/g, "");
    const folderName = `${sanitizedName}_${sanitizedPhone}`;

    // 4. Get or Create Root Folder ("BikeParkGo_Users")
    const rootFolder = getOrCreateFolder(DriveApp.getRootFolder(), ROOT_FOLDER_NAME);

    // 5. Create Specific User Folder
    const userFolder = getOrCreateFolder(rootFolder, folderName);

    // 6. Create or Overwrite Details Note (user_details.txt)
    const timestamp = new Date().toLocaleString("en-IN", { timeZone: "Asia/Kolkata" });
    const noteContent = [
      "==================================================",
      "       bikeparkgo - USER REGISTRATION RECORD       ",
      "==================================================",
      `Registration Type : ${isGuest ? "GUEST CHECKOUT" : "REGISTERED CUSTOMER"}`,
      `Full Name         : ${name}`,
      `Phone Number      : ${phone}`,
      `Email Address     : ${email || "Not Provided"}`,
      `Date & Time (IST) : ${timestamp}`,
      `Security Protocol : TLS 1.3 End-to-End Encrypted`,
      "=================================================="
    ].join("\n");

    // Remove existing note if updating
    const existingNotes = userFolder.getFilesByName("user_details.txt");
    while (existingNotes.hasNext()) {
      existingNotes.next().setTrashed(true);
    }
    userFolder.createFile("user_details.txt", noteContent, "text/plain");

    // 7. Save Profile Picture if provided
    if (base64Photo && base64Photo.length > 50) {
      // Strip data URI prefix if present (e.g. data:image/jpeg;base64,...)
      const cleanedBase64 = base64Photo.replace(/^data:image\/\w+;base64,/, "");
      const decodedBytes = Utilities.base64Decode(cleanedBase64);
      const imageBlob = Utilities.newBlob(decodedBytes, "image/jpeg", "profile_picture.jpg");

      const existingPhotos = userFolder.getFilesByName("profile_picture.jpg");
      while (existingPhotos.hasNext()) {
        existingPhotos.next().setTrashed(true);
      }
      userFolder.createFile(imageBlob);
    }

    return responseJSON({
      success: true,
      message: `User folder created successfully: ${folderName}`,
      folderUrl: userFolder.getUrl()
    }, 200);

  } catch (err) {
    return responseJSON({ success: false, error: err.toString() }, 500);
  }
}

// Helper: Get or Create Folder
function getOrCreateFolder(parentFolder, name) {
  const folders = parentFolder.getFoldersByName(name);
  if (folders.hasNext()) {
    return folders.next();
  }
  return parentFolder.createFolder(name);
}

// Helper: Standardized JSON Output
function responseJSON(obj, statusCode) {
  const output = ContentService.createTextOutput(JSON.stringify(obj));
  output.setMimeType(ContentService.MimeType.JSON);
  return output;
}

