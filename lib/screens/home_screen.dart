import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/location_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSavedBikeSpot();
    _initGPS();
  }

  Future<void> _loadSavedBikeSpot() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble('bike_lat');
    final savedLng = prefs.getDouble('bike_lng');
    final savedTime = prefs.getString('bike_time');
    final savedNote = prefs.getString('bike_note');

    if (savedNote != null) _noteController.text = savedNote;
    if (savedTime != null) setState(() => _parkedTime = savedTime);

    if (savedLat != null && savedLng != null) {
      setState(() {
        _bikeLocation = LatLng(savedLat, savedLng);
      });
      _updateCalculations();
    }
  }

  Future<void> _initGPS() async {
    final hasPermission = await LocationService.checkAndRequestPermission();
    if (!hasPermission) {
      setState(() => _gpsStatus = 'Location permission denied');
      return;
    }

    _positionSub = LocationService.getPositionStream().listen((pos) {
      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = newPos;
        _gpsStatus = 'GPS Active (±${pos.accuracy.round()}m)';
      });
      _updateCalculations();
    });
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
        const SnackBar(content: Text('Acquiring GPS location. Please wait 3 seconds!')),
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
          content: Text('🎉 বাইকের লোকেশন সেভ হয়েছে! (Bike parking saved!)'),
        ),
      );
    }
  }

  Future<void> _resetBikeSpot() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Parking Spot?'),
        content: const Text('Are you sure you want to clear your saved bike location?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
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
        _noteController.clear();
        _distanceMeters = 0.0;
        _bearingDegrees = 0.0;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bikeparkgo_user');
    await prefs.setBool('bikeparkgo_logged_in', false);

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
            const Text('🔱 ', style: TextStyle(fontSize: 22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BikeParkGo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Text(
                  'User: ${widget.userProfile.name} (${widget.userProfile.isGuest ? "Guest" : "Member"})',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // 1. RADAR & DISTANCE CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
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
                              Text(_gpsStatus, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          // Rotating Directional Compass Needle
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFB91C1C).withOpacity(0.12),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: _bearingDegrees * (3.1415926535 / 180),
                                child: const Text('🏹', style: TextStyle(fontSize: 32)),
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

              // 2. 100% FREE OPENSTREETMAP VIEW
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _userLocation ?? const LatLng(22.5726, 88.3639), // Kolkata default
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.bikeparkgo.app',
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

              // 3. LANDMARK NOTE CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
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

              // 4. ACTION BUTTONS
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _bikeLocation == null
                      ? null
                      : () => LocationService.launchWalkingNavigation(_bikeLocation!),
                  icon: const Icon(Icons.directions_walk, color: Color(0xFFF59E0B)),
                  label: const Text(
                    'Free Turn-by-Turn Voice Navigation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

