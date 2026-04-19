import 'dart:async';
import 'dart:convert';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/weather_service.dart';
import '../../services/location_service.dart';
import '../../services/risk_service.dart';
import '../../models/disease_model.dart';
import '../../services/theme_provider.dart';
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';
import '../../widgests/floating_bottom_nav.dart';
import 'notification_page.dart';
// NOTE: TranslatedText (existing app widget) is used for translations on this page.

// NOTE: Translations are provided at runtime by TranslationService.
// UI source strings MUST be plain English. Use `TText` to render translated text.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Debug coords (optional)
  static const bool _forceDebugCoords = false;
  static const double _debugLat = 5.9485;
  static const double _debugLon = 80.5353;

  Map<String, dynamic>? weather;
  bool isLoading = true;

  List<dynamic> riskList = [];
  String riskText = "Checking risk...";
  Color riskColor = Colors.green;
  IconData riskIcon = Icons.check_circle;

  Timer? _refreshTimer;
  int _bottomIndex = 0;
  int _selectedFeature = -1;
  bool _isFabPressed = false;
  String? _selectedCrop;

  // Crops list
  final List<Map<String, String>> crops = [
    {'key': 'coconut', 'label': 'Coconut', 'asset': 'assets/images/coconut.png'},
    {'key': 'tea', 'label': 'Tea', 'asset': 'assets/images/tea.png'},
    {'key': 'rice', 'label': 'Rice', 'asset': 'assets/images/paddy.png'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (mounted) _loadAll();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      isLoading = true;
      riskText = "Checking risk...";
      riskColor = Colors.green;
      riskIcon = Icons.check_circle;
    });

    final loc = await LocationService.getCurrentLocation();
    if (loc == null) {
      setState(() {
        isLoading = false;
        weather = null;
        riskList = [];
        riskText = "Location unavailable";
      });
      return;
    }
    double lat = loc['lat'] as double;
    double lon = loc['lon'] as double;

    if (_forceDebugCoords) {
      // ignore: avoid_print
      print('HomePage: DEBUG forcing coords to $_debugLat,$_debugLon');
      lat = _debugLat;
      lon = _debugLon;
    }

    try {
      final weatherSvc = WeatherService();
      // ignore: avoid_print
      print('HomePage: fetching weather for lat=$lat, lon=$lon');
      final w = await weatherSvc.getWeather(lat, lon);

      // prefer LocationService city if available
      final cityName = (loc['city'] as String?) ?? '';

      final dynamic rawTemp = w?['temp'];
      final double? tempVar = rawTemp is num ? (rawTemp as num).toDouble() : (rawTemp is String ? double.tryParse(rawTemp) : null);
      final int? humidityVar = (w != null && w['humidity'] != null) ? (w['humidity'] is num ? (w['humidity'] as num).toInt() : int.tryParse(w['humidity'].toString()) ?? null) : null;

      final diseases = await fetchDiseases();

      final bool hasRain = (w != null && (w['raw'] != null) && ((w['raw']['rain'] != null) || (w['raw']['weather'] != null && (w['raw']['weather'] as List).any((it) => (it['main']?.toString().toLowerCase() ?? '').contains('rain')))));

      final cropKeys = crops.map((c) => (c['key'] ?? '').toString().toLowerCase()).where((s) => s.isNotEmpty).toList();
      final scored = RiskService.selectTopPerCrop(diseases, tempVar, humidityVar, hasRain, cropOrder: cropKeys, limit: 3);

      setState(() {
        weather = {
          ...?w,
          'temp': tempVar,
          'humidity': humidityVar,
          'city': (cityName.isNotEmpty) ? cityName : (w != null && (w['city']?.toString().isNotEmpty ?? false) ? w['city'] : 'Nearby'),
        };
        riskList = scored.map((d) => d.toJson()).toList();
        isLoading = false;
      });

      _calculateRiskSummary();
    } catch (e) {
      setState(() {
        isLoading = false;
        weather = null;
        riskList = [];
        riskText = "Unable to fetch data";
      });
    }
  }

  Future<List<Disease>> fetchDiseases() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/diseases');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List) {
          return data.map((e) => Disease.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void _calculateRiskSummary() {
    if (riskList.isEmpty) {
      setState(() {
        riskText = "Low Risk";
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      });
      return;
    }

    int highCount = 0;
    for (var d in riskList) {
      final severity = (d['severity'] ?? '').toString().toLowerCase();
      if (severity.contains('high') || severity.contains('severe')) highCount++;
    }

    setState(() {
      if (highCount >= 3 || riskList.length >= 5) {
        riskText = "High disease risk";
        riskColor = Colors.red;
        riskIcon = Icons.warning;
      } else if (highCount > 0) {
        riskText = "Medium disease risk";
        riskColor = Colors.orange;
        riskIcon = Icons.warning_amber_rounded;
      } else {
        riskText = "Low Risk";
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      }
    });
  }

  bool get _showRiskDot {
    try {
      return riskList.isNotEmpty && (riskList.take(3).any((d) => (d['score'] ?? 0) > 0));
    } catch (_) {
      return false;
    }
  }

  void _showRiskModal() {
    final topMaps = (riskList.isNotEmpty) ? riskList.take(3).toList() : [];
    final topDiseases = topMaps.map((m) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(m as Map);
      final d = Disease.fromJson(map);
      if (map['score'] != null) d.score = (map['score'] is num) ? (map['score'] as num).toInt() : int.tryParse(map['score'].toString()) ?? 0;
      if (map['percent'] != null) d.percent = (map['percent'] is num) ? (map['percent'] as num).toDouble() : double.tryParse(map['percent']?.toString() ?? '') ?? 0.0;
      if (map['severity'] != null) d.severity = map['severity'].toString();
      return d;
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => NotificationPage(diseases: topDiseases)),
    );
  }

  String _formatDate(DateTime dt) {
    final weekday = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][dt.weekday % 7];
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$weekday, $day/$month/$year';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isDark = theme.isDark;
    final mq = MediaQuery.of(context);
    final double padding = 16.0;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: mq.size.height - 40),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header with floating weather card (full-width)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: HeaderWidget(
                          greeting: _greeting(),
                          userName: user?.displayName ?? 'User',
                          date: _formatDate(DateTime.now()),
                          showRiskDot: _showRiskDot,
                          onBellTap: _showRiskModal,
                          isDark: isDark,
                          avatarInitial: (user?.email?.isNotEmpty == true) ? user!.email![0].toUpperCase() : 'U',
                        ),
                      ),

                      Positioned(
                        top: 120,
                        left: padding,
                        right: padding,
                        child: Transform.translate(
                          offset: const Offset(0, -20),
                          child: WeatherCard(
                            weather: weather,
                            isLoading: isLoading,
                            isDark: isDark,
                            statusText: riskText,
                            statusColor: riskColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      children: [
                        PremiumCard(
                          icon: Icons.camera_alt,
                          title: 'Disease Detection',
                          subtitle: 'Capture or upload leaf image',
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, '/scan'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        PremiumCard(
                          icon: Icons.menu_book,
                          title: 'Knowledge Hub',
                          subtitle: 'Learn diseases & treatments',
                          color: Colors.orange,
                          onTap: () => Navigator.pushNamed(context, '/knowledge'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        PremiumCard(
                          icon: Icons.smart_toy,
                          title: 'Ask AgroX AI',
                          subtitle: 'Instant farming advice',
                          color: Colors.blue,
                          onTap: () => Navigator.pushNamed(context, '/chatbot'),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TranslatedText('Best Fields', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                            TextButton(onPressed: () {}, child: TranslatedText('See All', style: TextStyle(color: Colors.green.shade700))),
                          ],
                        ),

                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: crops.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final c = crops[i];
                              return CropCard(label: c['label']!, asset: c['asset']!, isDark: isDark);
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: FloatingBottomNav(
        activeIndex: _bottomIndex,
        isDark: isDark,
        showCenterButton: true,
        onTap: (i) {
          if (i == 0) {
            setState(() => _bottomIndex = 0);
          } else if (i == 1) {
            setState(() => _bottomIndex = 1);
            Navigator.pushNamed(context, '/profile');
          }
        },
        onCenterTap: () => Navigator.pushNamed(context, '/scan'),
      ),
    );
  }
}


/// Header widget with green gradient curved background, greeting, date, avatar and bell.
class CustomHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeaderWidget extends StatelessWidget {
  final String greeting;
  final String userName;
  final String date;
  final bool showRiskDot;
  final VoidCallback onBellTap;
  final bool isDark;
  final String avatarInitial;

  const HeaderWidget({
    required this.greeting,
    required this.userName,
    required this.date,
    required this.showRiskDot,
    required this.onBellTap,
    required this.isDark,
    required this.avatarInitial,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const height = 150.0;
    return ClipPath(
      clipper: CustomHeaderClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
          image: const DecorationImage(
            image: AssetImage('assets/images/home.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            // dark overlay + slight blur to improve readability
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.32), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // greeting (English source) + capitalize username
                      Builder(builder: (ctx) {
                        String name = userName.trim();
                        if (name.isNotEmpty) {
                          final parts = name.split(' ');
                          name = parts.map((p) => p.isEmpty ? p : (p[0].toUpperCase() + p.substring(1))).join(' ');
                        }
                        // Use TranslatedText for the greeting phrase and append the name as plain text
                        return Row(children: [
                          TranslatedText('${greeting}, ', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('${name.isNotEmpty ? name : 'User'} 👋', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ]);
                      }),
                      const SizedBox(height: 6),
                      Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onBellTap,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                                if (showRiskDot)
                                  Positioned(top: -4, right: -4, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)]))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Text(avatarInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big weather card
class WeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  final bool isDark;
  final String statusText;
  final Color statusColor;

  const WeatherCard({this.weather, required this.isLoading, required this.isDark, required this.statusText, required this.statusColor, super.key});

  @override
  Widget build(BuildContext context) {
    final double? tempNum = (weather != null && weather!['temp'] != null)
      ? (weather!['temp'] is num
        ? (weather!['temp'] as num).toDouble()
        : double.tryParse(weather!['temp'].toString()))
      : null;
    final String temp = tempNum != null ? '${tempNum.toStringAsFixed(1)}°C' : '--';
    final cond = weather != null ? (weather!['condition'] ?? '') : '--';
    final int? humidityNum = (weather != null && weather!['humidity'] != null)
      ? (weather!['humidity'] is num
        ? (weather!['humidity'] as num).toInt()
        : int.tryParse(weather!['humidity'].toString()))
      : null;
    final String humidity = humidityNum != null ? '${humidityNum}%' : '--';
    final city = weather != null ? (weather!['city'] ?? '') : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: isLoading
          ? SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.green.shade700)))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(city, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                ]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12))),
              ]),
              const SizedBox(height: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(temp, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 12),
                  Flexible(child: Text(cond, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[800]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.water_drop, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  TranslatedText('Humidity', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 12)),
                const SizedBox(width: 6),
                Text(humidity, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 12)),
                ]),
              ])
            ]),
    );
  }
}

/// Feature card used in the feature row
class PremiumCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isDark;

  const PremiumCard({required this.icon, required this.title, required this.subtitle, required this.color, this.onTap, this.isDark = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 0),
          constraints: const BoxConstraints(minHeight: 85),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TranslatedText(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                TranslatedText(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white54 : Colors.grey),
          ]),
        ),
      ),
    );
  }
}

/// Crop card for Best Fields
class CropCard extends StatelessWidget {
  final String label;
  final String asset;
  final bool isDark;

  const CropCard({required this.label, required this.asset, required this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(asset, fit: BoxFit.cover),
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.28), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
            Positioned(left: 12, bottom: 12, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
        ),
      ),
    );
  }
}

/// Bottom navigation bar with center FAB
// Bottom nav replaced by FloatingBottomNav in this file.