import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pandal.dart';
import 'google_drive_service.dart';

class PandalService {
  static const String _cacheKey = 'bikeparkgo_cached_pandals';

  /// Default curated list of famous Kolkata Durga Puja pandals
  static final List<Pandal> defaultPandals = [
    Pandal(
      id: 'bagbazar',
      name: 'বাগবাজার সর্বজনীন',
      nameEn: 'Bagbazar Sarbojanin',
      zone: 'North Kolkata (Ghat)',
      tag: '🏮 100+ Years Heritage Sabeki',
      crowd: '✨ High Flow',
      imageUrl: 'https://www.pujomap.com/photos/bagbazar-sarbojanin.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.604779979383355,
      longitude: 88.36359641231952,
      parkingTip: 'Circular Railway road bike zone near Ghat',
    ),
    Pandal(
      id: 'college_square',
      name: 'কলেজ স্কোয়ার সার্বজনীন দুর্গোৎসব',
      nameEn: 'College Square Sarbojanin Durgotsab',
      zone: 'Central Kolkata',
      tag: '💡 Spectacular Lake Lighting & Reflection',
      crowd: '🔥 Massive Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/4c9ef4b7-b5a2-4aeb-8089-844ac3c8ba10.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5760000,
      longitude: 88.3639000,
      parkingTip: 'Park near Mahatma Gandhi Road or Calcutta University parking spaces',
    ),
    Pandal(
      id: 'mohammad_ali_park',
      name: 'মহম্মদ আলী পার্ক',
      nameEn: 'Mohammad Ali Park',
      zone: 'MG Road Central',
      tag: '🏰 Monumental Replica',
      crowd: '🔥 Heavy Crowd',
      imageUrl: 'https://menafn.com/updates/pr/2026-10/15/F_7e60bimage_story.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5802,
      longitude: 88.3601,
      parkingTip: 'Central Avenue service parking spot #3',
    ),
    Pandal(
      id: 'ekdalia_evergreen',
      name: 'একডালিয়া এভারগ্রিন ক্লাব',
      nameEn: 'Ekdalia Evergreen Club',
      zone: 'South Kolkata',
      tag: '✨ Classic Traditional Lighting & Decor',
      crowd: '🔥 Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/ae185c52-7d1a-494d-b09d-ba7b95248cf9.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5181000,
      longitude: 88.3692000,
      parkingTip: 'Park near Gariahat market lanes or Ballygunge station approach',
    ),
    Pandal(
      id: 'suruchi_sangha',
      name: 'সুরুচি সংঘ',
      nameEn: 'Suruchi Sangha',
      zone: 'New Alipore, South Kolkata',
      tag: '🎨 Cultural Showcase',
      crowd: '🔥 Very Crowded',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/76c7bcf7-8588-4c25-bf02-599e3df10cb5.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5132,
      longitude: 88.3341,
      parkingTip: 'New Alipore Petrol pump adjacent parking lane',
    ),
    Pandal(
      id: 'maddox_square',
      name: 'ম্যাডকস স্কোয়ার',
      nameEn: 'Maddox Square',
      zone: 'South Kolkata',
      tag: '🎵 Adda & Open Air Pujo',
      crowd: '🔥 Massive Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/5e3e8344-0754-4327-9294-a7b6f7ac903c.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5332000,
      longitude: 88.3533000,
      parkingTip: 'Park near Ballygunge Phari or Sarat Bose Road lanes',
    ),
    Pandal(
      id: 'ahiritola_sarbojonin',
      name: 'আহিরীটোলা সার্বজনীন দুর্গোৎসব সমিতি',
      nameEn: 'Ahiritola Sarbojonin Durgotsab Samity',
      zone: 'North Kolkata',
      tag: '🏛️ Traditional & Artistic Heritage',
      crowd: '⚡ Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/4c57c507-7840-41c0-97a3-0adb6974e5f8.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5976000,
      longitude: 88.3664000,
      parkingTip: 'Park near Sovabazar Launch Ghat or Nimtala Ghat street parking',
    ),
    Pandal(
      id: 'deshapriya_park',
      name: 'দেশপ্রিয় পার্ক',
      nameEn: 'Deshapriya Park',
      zone: 'South Kolkata',
      tag: '🌟 Grand Scale Architecture',
      crowd: '🔥 Massive Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/56a49b9a-4d7a-4fca-893a-e765272a0559.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5244000,
      longitude: 88.3562000,
      parkingTip: 'Park near Rashbehari Avenue or Sarat Bose Road service lanes',
    ),
    Pandal(
      id: 'sree_bhumi',
      name: 'শ্রীভূমি স্পোর্টিং ক্লাব',
      nameEn: 'Sree Bhumi Sporting Club',
      zone: 'Lake Town / VIP Road',
      tag: '👑 Royal Palace Architecture',
      crowd: '🔥 Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/fa7f2b46-166a-49a6-a429-e1cd704584ed.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5988987,
      longitude: 88.4029328,
      parkingTip: 'Park near Clock Tower service lane Gate 2',
    ),
    Pandal(
      id: 'tala_prattoy',
      name: 'তালা প্রত্যয় দুর্গোৎসব',
      nameEn: 'Tala Prattoy Durga Puja',
      zone: 'North Kolkata',
      tag: '🎨 Avant-Garde Art & Conceptual Theme',
      crowd: '⚡ Heavy Crowd',
      imageUrl: 'https://pandalgo.in/storage/uploads/pandals/59dea174-6196-4fbf-970d-8501d07151b6.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.6074000,
      longitude: 88.3751000,
      parkingTip: 'Park near BT Road service lane or Tala Bridge approach',
    ),
  ];

  /// Fetch live pandals from Google Drive webhook, with offline fallback
  static Future<List<Pandal>> getPandals() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. First, check cached pandals for instantaneous rendering
    final cachedJson = prefs.getString(_cacheKey);
    List<Pandal> currentList = defaultPandals;
    if (cachedJson != null) {
      try {
        final List decoded = jsonDecode(cachedJson);
        if (decoded.isNotEmpty) {
          currentList = decoded.map((e) => Pandal.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    // 2. Fetch live updates from Google Drive backend in the background
    try {
      final webhookUrl = GoogleDriveService.webhookUrl;
      if (!webhookUrl.contains("YOUR_SCRIPT_ID")) {
        final uri = Uri.parse('$webhookUrl?action=get_pandals');
        final response = await http.get(uri).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['pandals'] is List) {
            final List pList = data['pandals'];
            final updatedPandals = pList.map((e) => Pandal.fromJson(e)).toList();
            if (updatedPandals.isNotEmpty) {
              await prefs.setString(_cacheKey, jsonEncode(pList));
              return updatedPandals;
            }
          }
        }
      }
    } catch (_) {
      // Graceful offline fallback to current list
    }

    return currentList;
  }
}
