import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/weather_service.dart';
import '../../widgests/translated_text.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/geocoding_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  Timer? _carouselTimer;

  int _currentIndex = 0;
  int _bottomIndex = 0;
  bool _forward = true;

  int _selectedIndex = -1;
  bool _isFabPressed = false;

  // === Risk alert state ===
  List allDiseases = [];
  String riskText = "Checking risk...";
  Color riskColor = Colors.orange;
  IconData riskIcon = Icons.warning_amber_rounded;

  /// 🔥 WEATHER DATA
  Map<String, dynamic>? weather;
  bool isLoading = true;

  // No API keys in the Flutter app. Weather comes from backend.

  final List<String> images = [
    "assets/images/paddy.png",
    "assets/images/tea.png",
    "assets/images/coconut.png",
  ];

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  void initState() {
    super.initState();

    // Observe app lifecycle to refresh location when app resumes
    WidgetsBinding.instance.addObserver(this);

    // Load location, weather and risk data (force fresh GPS)
    loadData();

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      setState(() {
        if (_forward) {
          if (_currentIndex < images.length - 1) {
            _currentIndex++;
          } else {
            _forward = false;
            _currentIndex--;
          }
        } else {
          if (_currentIndex > 0) {
            _currentIndex--;
          } else {
            _forward = true;
            _currentIndex++;
          }
        }
      });

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      // Recalculate risk for the currently visible crop
      calculateRisk();
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App returned to foreground — refresh location and weather
      loadData();
    }
  }

  ///////////////////////////////////////////////////////////////
  /// 🔥 GET LOCATION + WEATHER
  ///////////////////////////////////////////////////////////////

  // Orchestrator: get coords, fetch weather, reverse geocode place name
  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      riskText = "Checking risk...";
    });

    // 1) Get fresh coordinates from device GPS (do NOT use hardcoded or cached values)
    final coords = await getLocation();
    if (coords == null) {
      // Could not obtain fresh location — show error instead of using fallback coordinates
      setState(() {
        isLoading = false;
        weather = null;
        allDiseases = [];
        riskText = "Unable to fetch data";
      });
      return;
    }

    final double lat = coords['lat']!.toDouble();
    final double lon = coords['lon']!.toDouble();

    // 2) Fetch weather via WeatherService and risk via backend
    try {
      final weatherService = WeatherService();
      final w = await weatherService.getWeather(lat, lon);
      final r = await fetchRisk(lat, lon);

      if (w == null) {
        // API failed
        setState(() {
          isLoading = false;
          weather = null;
          allDiseases = r ?? [];
          riskText = "Unable to fetch data";
        });
        return;
      }

      // Debug: print full parsed response from WeatherService
      // ignore: avoid_print
      print('WeatherService returned: $w');

      // Extract values (support both data['main']['temp'] and data['temp'])
      final dynamic rawTemp = w['temp'];
      final double? tempVar = rawTemp is num ? (rawTemp as num).toDouble() : (rawTemp is String ? double.tryParse(rawTemp) : null);
      final int? humidityVar = w['humidity'] is int ? (w['humidity'] as int) : (w['humidity'] is num ? (w['humidity'] as num).toInt() : null);
      final String? condVar = (w['condition'] != null) ? w['condition'].toString() : null;

      // Print temp before UI update for debugging
      // ignore: avoid_print
      print('Parsed temp before UI update: $tempVar');

      // Use backend-provided city if present; show 'Detecting...' while reverse geocoding
      final String apiCity = (w['city'] != null && w['city'].toString().isNotEmpty) ? w['city'].toString() : 'Detecting...';

      // Update UI immediately with weather data returned from backend
      setState(() {
        weather = {
          ...?w,
          'temp': tempVar,
          'humidity': humidityVar,
          'condition': condVar ?? '',
          'city': apiCity,
        };
        allDiseases = r ?? [];
        isLoading = false;
      });

      // Run reverse geocoding asynchronously (do not block UI). Prefer Google Geocoding API.
      _reverseGeocodeAndUpdate(lat, lon, apiCity: apiCity);

      calculateRisk();
    } catch (e) {
      // General failure
      // ignore: avoid_print
      print('Weather load failed: $e');
      setState(() {
        isLoading = false;
        weather = null;
        allDiseases = [];
        riskText = "Unable to fetch data";
      });
    }
  }

  // Returns {'lat': .., 'lon': ..} or null if unavailable.
  // Public wrapper named `getLocation` per requirements.
  Future<Map<String, double>?> getLocation() async {
    return await getLocationCoordinates();
  }

  /// Reverse geocode coordinates to a readable city/locality and update UI.
  /// Keeps a safe fallback and never throws to the UI.
  Future<void> _reverseGeocodeAndUpdate(double lat, double lon, {String? apiCity}) async {
    try {
      final name = await GeocodingService.getBestLocationName(lat, lon);
      final chosen = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Unknown Location';

      if (!mounted) return;
      setState(() {
        weather = {
          ...?weather,
          'city': chosen,
        };
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          weather = {
            ...?weather,
            'city': 'Unknown Location',
          };
        });
      }
      // ignore: avoid_print
      print('Reverse geocoding (Nominatim) failed: $e');
    }
  }

  Future<Map<String, double>?> getLocationCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled on the device.
        print('Location services disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        print('Location permission denied by user.');
        return null;
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied.');
        return null;
      }

      // IMPORTANT: force fresh GPS location with highest practical accuracy
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );

      return {'lat': pos.latitude, 'lon': pos.longitude};
    } catch (e) {
      print('getLocationCoordinates failed: $e');
      // Do NOT use last known position or cached coordinates per requirements.
      return null;
    }
  }

  // Weather API calls are handled in services/weather_service.dart

  // Load diseases JSON from assets
  Future<void> loadDiseases() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/risk');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          allDiseases = (data is List) ? data : [];
        });
      } else {
        print('Failed to load diseases from backend: ${resp.statusCode}');
        setState(() {
          allDiseases = [];
        });
      }
    } catch (e) {
      // Networking or parsing error: fallback to empty list and log
      print('Failed to load diseases from backend: $e');
      setState(() {
        allDiseases = [];
      });
    }
  }

  Future<List<dynamic>?> fetchRisk(double lat, double lon) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/risk?lat=$lat&lon=$lon');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return (data is List) ? data : [];
      }
      return [];
    } catch (e) {
      print('fetchRisk error: $e');
      return [];
    }
  }

  // Evaluate all diseases against current weather and build a risk alert
  void calculateRisk() {
    if (weather == null || allDiseases.isEmpty) return;

    // Cast once to a non-null map to avoid repeated null checks.
    final Map<String, dynamic> w = weather as Map<String, dynamic>;

    final double tempVal = (w['temp'] is int)
        ? (w['temp'] as int).toDouble()
        : (w['temp'] as double? ?? 0.0);
    final int humidityVal = (w['humidity'] as int?) ?? 0;
    final double rainVal = (w['rain'] is int)
        ? (w['rain'] as int).toDouble()
        : (w['rain'] as double? ?? 0.0);

    final String selectedCrop = images.isNotEmpty
        ? images[_currentIndex].split('/').last.split('.').first.toLowerCase()
        : '';

    int bestScore = -1;
    String bestDisease = '';

    for (var d in allDiseases) {
      final risk = d['riskConditions'];
      if (risk == null) continue;

      // Crop-based filtering: check `crop` or `crops` fields if present
      final cropField = d['crop'];
      final cropsField = d['crops'];
      if (cropField != null) {
        if (cropField.toString().toLowerCase() != selectedCrop) continue;
      } else if (cropsField != null && cropsField is List) {
        final lower = cropsField.map((e) => e.toString().toLowerCase()).toList();
        if (!lower.contains(selectedCrop)) continue;
      }

      final int minT = (risk['minTemp'] as num?)?.toInt() ?? -999;
      final int maxT = (risk['maxTemp'] as num?)?.toInt() ?? 999;
      final int minH = (risk['minHumidity'] as num?)?.toInt() ?? 0;
      final bool needRain = (risk['rainRequired'] == true);

      final bool tempOk = tempVal >= minT && tempVal <= maxT;
      final bool humidityOk = humidityVal >= minH;
      final bool rainOk = !needRain || rainVal > 0;

      int score = 0;
      if (tempOk) score++;
      if (humidityOk) score++;
      if (rainOk) score++;

      if (score > bestScore) {
        bestScore = score;
        bestDisease = d['name'] ?? 'Unknown';
      }
    }

    setState(() {
      if (bestScore <= 0) {
        // No meaningful match
        riskText = "Low Risk";
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      } else if (bestScore == 1) {
        // Barely matching
        riskText = "Low Risk for $bestDisease";
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      } else if (bestScore == 2) {
        // Partial match
        riskText = "Medium Risk for $bestDisease";
        riskColor = const Color.fromARGB(255, 232, 120, 46);
        riskIcon = Icons.warning_amber_rounded;
      } else {
        // Full match
        riskText = "High Risk for $bestDisease";
        riskColor = Colors.red;
        riskIcon = Icons.warning;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color.fromARGB(255, 248, 247, 247),

      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() => _isFabPressed = true),
        onTapUp: (_) {
          setState(() => _isFabPressed = false);
          Navigator.pushNamed(context, '/scan');
        },
        onTapCancel: () => setState(() => _isFabPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 62,
          width: 62,
          transform: _isFabPressed
              ? (Matrix4.identity()..scale(0.9))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isDark
            ? const Color(0xFF1E1E1E)
            :Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _isFabPressed
                  ? Colors.green.shade800
                  : Colors.green.shade300,
              width: _isFabPressed ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            size: 26,
            color: _isFabPressed
                ? Colors.green.shade900
                : Colors.green.shade700,
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 12),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TranslatedText(
                        getGreeting(),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ", ${user?.displayName ?? "User"} 👋",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none,
                            color: isDark ? Colors.white : Colors.black),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          height: 8,
                          width: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              /// 🔥 WEATHER UPDATED
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (weather == null)
                    ? const Center(child: TranslatedText('Unable to fetch data'))
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _WeatherItem(
                          icon: Icons.location_on,
                          textWidget: Text('${weather?['city'] ?? 'Detecting...'}'),
                        ),
                        _WeatherItem(
                          icon: Icons.thermostat,
                          text: weather?['temp'] != null ? '${(weather!['temp'] as num).toStringAsFixed(1)}°C' : '--',
                        ),
                        _WeatherItem(
                          icon: Icons.water_drop,
                          text: weather?['humidity'] != null ? '${weather!['humidity']}%': '--',
                        ),
                        _WeatherItem(
                          icon: Icons.cloud,
                          textWidget: Text('${weather?['condition'] ?? ''}'),
                        ),
                      ],
                      ),
              ),

              const SizedBox(height: 14),

              /// RISK ALERT
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(riskIcon, color: riskColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TranslatedText(
                        riskText,
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// CAROUSEL (same)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.asset(
                            images[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: TranslatedText(
                          'AI-powered detection\nfor Paddy, Tea & Coconut',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 10 : 6,
                    height: _currentIndex == index ? 10 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.green
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 22),

              _menuCard(0, Icons.camera_alt, Colors.green,
                  const TranslatedText('Scan Leaf'), const TranslatedText('Upload or Capture image'), () {
                Navigator.pushNamed(context, '/scan');
              }),
              _menuCard(1, Icons.menu_book, Colors.orange,
                  const TranslatedText('Knowledge Hub'), const TranslatedText('Learn diseases & treatments'), () {
                Navigator.pushNamed(context, '/knowledge');
              }),

              _menuCard(2, Icons.smart_toy, Colors.blue,
                  const TranslatedText('Ask AgroX AI'), const TranslatedText('Instant farming advice'), () {
                Navigator.pushNamed(context, '/chatbot');
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, "Home", 0),
              const SizedBox(width: 40),
              _navItem(Icons.person, "Profile", 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _bottomIndex == index;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _bottomIndex = index);

        if (index == 1) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isSelected
                  ? Colors.green
                  : (isDark ? Colors.grey : Colors.grey)),
          const SizedBox(height: 2),
            TranslatedText(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.green : Colors.grey),
            ),
        ],
      ),
    );
  }

    Widget _menuCard(int index, IconData icon, Color color, Widget title,
      Widget subtitle, VoidCallback onTap) {
    final isSelected = _selectedIndex == index;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        transform: isSelected
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade700
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black),
                      child: title),
                    const SizedBox(height: 4),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey : Colors.grey),
                      child: subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final IconData icon;
  final String? text;
  final Widget? textWidget;

  const _WeatherItem({required this.icon, this.text, this.textWidget});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final child = textWidget ?? Text(text ?? '',
        style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black));

    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 5),
        child,
      ],
    );
  }
}