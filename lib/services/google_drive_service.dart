import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

class GoogleDriveService {
  // Replace this with your deployed Google Apps Script Web App URL
  // https://script.google.com/macros/s/AKfycbwKjRAMN0Vla9x_ljpDVOx2wQGoraSZSScoe5Fuu7UU91hzoDZnJrEmyMw7NCupAr4V/exec
  static String webhookUrl = "https://script.google.com/macros/s/AKfycbwKjRAMN0Vla9x_ljpDVOx2wQGoraSZSScoe5Fuu7UU91hzoDZnJrEmyMw7NCupAr4V/exec";
  
  // Must match API_SECRET_TOKEN in Code.gs
  static const String secretToken = "Bikeparkgo_SecureToken_2026_Trishul";

  /// Top-notch secure sync to Google Drive
  /// Creates: BikeParkGo_Users/<User_Name>_<Phone>/
  ///   ├── user_details.txt
  ///   └── profile_picture.jpg
  static Future<Map<String, dynamic>> syncUserToGoogleDrive(UserProfile profile) async {
    try {
      if (webhookUrl.contains("YOUR_SCRIPT_ID")) {
        // Mock fallback if user hasn't deployed the script yet
        return {
          'success': true,
          'message': 'Local profile saved. Deploy Google Apps Script to enable live Google Drive sync.',
        };
      }

      final payload = {
        'secretToken': secretToken,
        'name': profile.name,
        'phone': profile.phone,
        'email': profile.email,
        'isGuest': profile.isGuest,
        'profilePicBase64': profile.profilePicBase64 ?? '',
      };

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 302) {
        final resData = jsonDecode(response.body);
        return {
          'success': resData['success'] == true,
          'message': resData['message'] ?? 'Successfully synced to Google Drive!',
          'folderUrl': resData['folderUrl'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': 'Server returned code ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Sync notice: ${e.toString()}',
      };
    }
  }
}

