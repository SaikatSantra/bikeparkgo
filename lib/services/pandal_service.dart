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
      id: 'bagbazar',
      name: 'বাগবাজার সর্বজনীন',
      nameEn: 'Bagbazar Sarbojanin',
      zone: 'North Kolkata (Ghat)',
      tag: '🏮 100+ Years Heritage & Sabeki Pratima',
      crowd: '✨ High Flow',
      imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800&auto=format&fit=crop&q=80',
      latitude: 22.604779979383355,
      longitude: 88.36359641231952,
      parkingTip: 'Circular Railway road bike zone near Ghat',
    ),
    Pandal(
      id: 'college_square',
      name: 'কলেজ স্কয়ার সর্বজনীন',
      nameEn: 'College Square Sarbojanin',
      zone: 'Central Kolkata',
      tag: '💡 World-Famous Lake Illumination',
      crowd: '🌊 Very Crowded',
      imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5765,
      longitude: 88.3644,
      parkingTip: 'Bidhan Sarani designated two-wheeler lane',
    ),
    Pandal(
      id: 'mohammad_ali_park',
      name: 'মহম্মদ আলী পার্ক',
      nameEn: 'Mohammad Ali Park',
      zone: 'MG Road Central',
      tag: '🏰 Grand Monumental Replica',
      crowd: '🔥 Heavy Crowd',
      imageUrl: 'https://cf-img-a-in.tosshub.com/lingo/atbn/images/story/202610/6ad07c8fbd473-mohammad-ali-park-durga-puja-2026-151110993-16x9.jpg?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5802,
      longitude: 88.3601,
      parkingTip: 'Central Avenue service parking spot #3',
    ),
    Pandal(
      id: 'ekdalia',
      name: 'একডালিয়া এভারগ্রিন',
      nameEn: 'Ekdalia Evergreen Club',
      zone: 'Gariahat, South Kolkata',
      tag: '🏛️ Traditional South Indian Temple Art',
      crowd: '✨ Moderate Flow',
      imageUrl: 'https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5186,
      longitude: 88.3659,
      parkingTip: 'Gariahat Flyover underpass bike stand',
    ),
    Pandal(
      id: 'suruchi_sangha',
      name: 'সুরুচি সংঘ',
      nameEn: 'Suruchi Sangha',
      zone: 'New Alipore, South Kolkata',
      tag: '🎨 Indian State Cultural Showcase',
      crowd: '🔥 Very Crowded',
      imageUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800&auto=format&fit=crop&q=80',
      latitude: 22.5132,
      longitude: 88.3341,
      parkingTip: 'New Alipore Petrol pump adjacent parking lane',
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
