import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/pandal.dart';
import '../services/location_service.dart';
import '../services/pandal_service.dart';
import '../widgets/pandal_slider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;

  const HomeScreen({super.key, required this.userProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _userLocation;
  LatLng? _bikeLocation;
  String _parkedTime = 'Not Parked Yet';
  final TextEditingController _noteController = TextEditingController();

  final MapController _mapController = MapController();
  StreamSubscription? _positionSub;

  double _distanceMeters = 0.0;
  double _bearingDegrees = 0.0;
  String _gpsStatus = 'Connecting GPS...';

  List<Pandal> _pandals = [];
  Pandal? _selectedPandal;

  @override
  void initState() {
    super.initState();
    _loadSavedBikeSpot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGPS();
      _loadPandals();
    });
  }

  Future<void> _loadPandals() async {
    try {
      final list = await PandalService.getPandals();
      if (mounted) {
        setState(() {
          _pandals = list;
        });
      }
    } catch (_) {}
  }

  void _onSelectPandal(Pandal pandal) {
    setState(() {
      _selectedPandal = pandal;
    });
    try {
      _mapController.move(LatLng(pandal.latitude, pandal.longitude), 16.5);
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFB91C1C),
        content: Text('🎪 Showing ${pandal.name} on map!'),
      ),
    );
  }

  Future<void> _loadSavedBikeSpot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('bike_lat');
      final savedLng = prefs.getDouble('bike_lng');
      final savedTime = prefs.getString('bike_time');
      final savedNote = prefs.getString('bike_note');

      if (savedNote != null) _noteController.text = savedNote;
      if (savedTime != null && mounted) setState(() => _parkedTime = savedTime);

      if (savedLat != null && savedLng != null && mounted) {
        setState(() {
          _bikeLocation = LatLng(savedLat, savedLng);
        });
        _updateCalculations();
      }
    } catch (_) {}
  }

  Future<void> _initGPS() async {
    try {
      final hasPermission = await LocationService.checkAndRequestPermission();
      if (!hasPermission) {
        if (mounted) setState(() => _gpsStatus = 'Tap GPS to enable location');
        return;
      }

      // 1. Instantly get last known position without waiting for satellite lock
      final quickPos = await LocationService.getInitialPosition();
      if (quickPos != null && mounted) {
        final newPos = LatLng(quickPos.latitude, quickPos.longitude);
        setState(() {
          _userLocation = newPos;
          _gpsStatus = 'GPS Active (±${quickPos.accuracy.round()}m)';
        });
        _updateCalculations();
      }

      // 2. Start continuous streaming
      _positionSub = LocationService.getPositionStream().listen((pos) {
        if (!mounted) return;
        final newPos = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = newPos;
          _gpsStatus = 'GPS Active (±${pos.accuracy.round()}m)';
        });
        _updateCalculations();
      }, onError: (err) {
        if (mounted) setState(() => _gpsStatus = 'GPS weak signal');
      });
    } catch (e) {
      if (mounted) setState(() => _gpsStatus = 'GPS unavailable');
    }
  }

  void _updateCalculations() {
    if (_userLocation != null && _bikeLocation != null) {
      final dist = LocationService.calculateDistanceInMeters(_userLocation!, _bikeLocation!);
      final bearing = LocationService.calculateBearing(_userLocation!, _bikeLocation!);
      setState(() {
        _distanceMeters = dist;
        _bearingDegrees = bearing;
      });
    }
  }

  Future<void> _parkBikeHere() async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acquiring GPS location. Please wait a moment!')),
      );
      return;
    }

    final nowTime = TimeOfDay.now().format(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bike_lat', _userLocation!.latitude);
    await prefs.setDouble('bike_lng', _userLocation!.longitude);
    await prefs.setString('bike_time', nowTime);
    await prefs.setString('bike_note', _noteController.text.trim());

    setState(() {
      _bikeLocation = _userLocation;
      _parkedTime = nowTime;
    });

    _updateCalculations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF15803D),
          content: Text('🔒 Bike parked successfully! Safe Pujo hopping!'),
        ),
      );
    }
  }

  Future<void> _resetBikeSpot() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Bike Spot?'),
        content: const Text('Are you sure you want to clear your current parked bike location?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bike_lat');
      await prefs.remove('bike_lng');
      await prefs.remove('bike_time');
      await prefs.remove('bike_note');

      setState(() {
        _bikeLocation = null;
        _parkedTime = 'Not Parked Yet';
        _distanceMeters = 0.0;
        _bearingDegrees = 0.0;
        _noteController.clear();
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bikeparkgo_logged_in');
    await prefs.remove('bikeparkgo_user');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🔱', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BikeParkGo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Text(
                  '🌸 শুভ শারদীয়া • ${widget.userProfile.name}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFFFEF08A)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Day / Night Mode Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Day Mode (সকাল)' : 'Switch to Night Mode (রাত)',
            icon: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: const Color(0xFFFDE68A),
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          // User Avatar / Logout
          PopupMenuButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF59E0B),
              backgroundImage: widget.userProfile.localPhotoPath != null
                  ? FileImage(File(widget.userProfile.localPhotoPath!))
                  : null,
              child: widget.userProfile.localPhotoPath == null
                  ? const Icon(Icons.person, size: 18, color: Colors.black)
                  : null,
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text('📱 ${widget.userProfile.phone}'),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout / Switch User'),
                  ],
                ),
                onTap: _logout,
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              // 0. FESTIVE GREETING & MOTTO BANNER
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF450A0A), const Color(0xFF1E1B4B)]
                        : [const Color(0xFFFEF2F2), const Color(0xFFFFFBEB)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🌸', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.userProfile.name}!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB91C1C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '“Enjoy Pujo, you care for your dear ones, I care for your vehicles!”',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 1. PANDAL SLIDER CAROUSEL (MANAGED FROM GOOGLE DRIVE)
              if (_pandals.isNotEmpty) ...[
                PandalSlider(
                  pandals: _pandals,
                  onSelectPandal: _onSelectPandal,
                ),
                const SizedBox(height: 12),
              ],

              // 2. RADAR & DISTANCE CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _bikeLocation != null ? Colors.green : Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _bikeLocation != null ? 'BIKE SECURED' : 'READY TO PARK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _bikeLocation != null ? Colors.green : Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _parkedTime,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DISTANCE TO BIKE', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                _bikeLocation == null
                                    ? '-- m'
                                    : _distanceMeters < 1000
                                        ? '${_distanceMeters.round()} m'
                                        : '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              Text(
                                _gpsStatus,
                                style: const TextStyle(fontSize: 10, color: Colors.green),
                              ),
                            ],
                          ),
                          // Rotating Arrow Radar / Compass
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFB91C1C).withOpacity(0.25),
                                  const Color(0xFFB91C1C).withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: (_bearingDegrees * 3.141592653589793 / 180),
                                child: const Icon(
                                  Icons.navigation,
                                  size: 42,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. OPENSTREETMAP LEAFLET VIEW (100% FREE)
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 230,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userLocation ?? const LatLng(22.5726, 88.3639),
                          initialZoom: 15.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.bikeparkgo.bikeparkgo',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_userLocation != null)
                                Marker(
                                  point: _userLocation!,
                                  width: 20,
                                  height: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blueAccent,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              if (_bikeLocation != null)
                                Marker(
                                  point: _bikeLocation!,
                                  width: 36,
                                  height: 36,
                                  child: const Text('🏍️', style: TextStyle(fontSize: 26)),
                                ),
                              if (_selectedPandal != null)
                                Marker(
                                  point: LatLng(_selectedPandal!.latitude, _selectedPandal!.longitude),
                                  width: 38,
                                  height: 38,
                                  child: const Text('🎪', style: TextStyle(fontSize: 28)),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          heroTag: 'recenter',
                          backgroundColor: const Color(0xFFB91C1C),
                          child: const Icon(Icons.my_location, color: Colors.white),
                          onPressed: () {
                            if (_userLocation != null) {
                              _mapController.move(_userLocation!, 16.5);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. LANDMARK NOTE CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📍 Landmark Note (লক্ষণ / গেট নম্বর)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          ),
                          if (_bikeLocation != null)
                            GestureDetector(
                              onTap: _resetBikeSpot,
                              child: const Text(
                                'Clear Spot',
                                style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Near Gate 3, opposite to roll stall, electric pole #42',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. ACTION BUTTONS
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _parkBikeHere,
                  icon: const Text('🏍️', style: TextStyle(fontSize: 20)),
                  label: const Text(
                    'Park Bike Here (এখানে বাইক রাখুন)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              if (_bikeLocation != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      LocationService.launchWalkingNavigation(_bikeLocation!);
                    },
                    icon: const Icon(Icons.directions_walk, color: Color(0xFFF59E0B)),
                    label: const Text(
                      'Turn-by-Turn Walking Route (হেঁটে চলুন)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
