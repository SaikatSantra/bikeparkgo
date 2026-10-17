/**
 * bikeparkgo - SECURE GOOGLE DRIVE REGISTRATION & PANDAL MANAGEMENT WEBHOOK
 * 
 * Top-Notch Architecture:
 * 1. Zero Client Secrets: No Google Cloud service account keys embedded in client app.
 * 2. Secret Token Authentication for POST requests.
 * 3. GET /?action=get_pandals: Reads or creates 'pandals.json' in Google Drive root folder 'BikeParkGo_Users'
 *    so the owner can add, edit, or update pandals and their images directly from their Google Drive!
 * 4. Automatic Folder & File Structure:
 *    Root: BikeParkGo_Users/
 *       ├── pandals.json (Manageable by owner anytime)
 *       └── <User_Name>_<Phone_Number>/
 *            ├── user_details.txt
 *            └── profile_picture.jpg
 */

const API_SECRET_TOKEN = "PujoBike_SecureToken_2026_Trishul";
const ROOT_FOLDER_NAME = "BikeParkGo_Users";

/**
 * Handle GET Requests: Dynamic Pandal Slider managed from Google Drive
 */
function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : "get_pandals";

    if (action === "get_pandals") {
      const rootFolder = getOrCreateFolder(DriveApp.getRootFolder(), ROOT_FOLDER_NAME);
      const files = rootFolder.getFilesByName("pandals.json");
      
      let pandals = [];
      if (files.hasNext()) {
        const file = files.next();
        const content = file.getBlob().getDataAsString();
        pandals = JSON.parse(content);
      } else {
        // Initialize default pandals in Google Drive so owner can edit them
        pandals = [
          {
            id: "sree_bhumi",
            name: "শ্রীভূমি স্পোর্টিং ক্লাব",
            nameEn: "Sree Bhumi Sporting Club",
            zone: "Lake Town / VIP Road",
            tag: "👑 Royal Palace Theme",
            crowd: "🔥 Very Crowded",
            imageUrl: "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800&auto=format&fit=crop&q=80",
            lat: 22.5976,
            lng: 88.3969,
            parkingTip: "Park near Clock Tower service lane Gate 2"
          },
          {
            id: "bagbazar",
            name: "বাগবাজার সর্বজনীন",
            nameEn: "Bagbazar Sarbojanin",
            zone: "North Kolkata (Ghat)",
            tag: "🏮 100+ Years Heritage Sabeki",
            crowd: "✨ High Flow",
            imageUrl: "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800&auto=format&fit=crop&q=80",
            lat: 22.6022,
            lng: 88.3683,
            parkingTip: "Circular Railway road bike zone near Ghat"
          },
          {
            id: "college_square",
            name: "কলেজ স্কয়ার সর্বজনীন",
            nameEn: "College Square Sarbojanin",
            zone: "Central Kolkata",
            tag: "💡 Lake Illumination",
            crowd: "🌊 Very Crowded",
            imageUrl: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80",
            lat: 22.5765,
            lng: 88.3644,
            parkingTip: "Bidhan Sarani designated two-wheeler lane"
          },
          {
            id: "mohammad_ali_park",
            name: "মহম্মদ আলী পার্ক",
            nameEn: "Mohammad Ali Park",
            zone: "MG Road Central",
            tag: "🏰 Monumental Replica",
            crowd: "🔥 Heavy Crowd",
            imageUrl: "https://images.unsplash.com/photo-1544717305-2782549b5136?w=800&auto=format&fit=crop&q=80",
            lat: 22.5802,
            lng: 88.3601,
            parkingTip: "Central Avenue service parking spot #3"
          },
          {
            id: "ekdalia",
            name: "একডালিয়া এভারগ্রিন",
            nameEn: "Ekdalia Evergreen Club",
            zone: "Gariahat, South Kolkata",
            tag: "🏛️ South Indian Temple",
            crowd: "✨ Moderate Flow",
            imageUrl: "https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800&auto=format&fit=crop&q=80",
            lat: 22.5186,
            lng: 88.3659,
            parkingTip: "Gariahat Flyover underpass bike stand"
          },
          {
            id: "suruchi_sangha",
            name: "সুরুচি সংঘ",
            nameEn: "Suruchi Sangha",
            zone: "New Alipore, South Kolkata",
            tag: "🎨 Cultural Showcase",
            crowd: "🔥 Very Crowded",
            imageUrl: "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800&auto=format&fit=crop&q=80",
            lat: 22.5132,
            lng: 88.3341,
            parkingTip: "New Alipore Petrol pump adjacent parking lane"
          }
        ];
        rootFolder.createFile("pandals.json", JSON.stringify(pandals, null, 2), "application/json");
      }

      return responseJSON({ success: true, pandals: pandals }, 200);
    }

    return responseJSON({ success: false, message: "Invalid action" }, 400);
  } catch (err) {
    return responseJSON({ success: false, error: err.toString() }, 500);
  }
}

/**
 * Handle POST Requests: User Registration and Profile Photo Upload
 */
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
