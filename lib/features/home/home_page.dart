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
import '../../services/notification_service.dart';
import '../../models/disease_model.dart';
import '../../services/theme_provider.dart';
import '../../services/language_provider.dart';
import '../../widgests/translated_text.dart';
import '../../widgests/floating_bottom_nav.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Language selector circular button
Widget _buildLanguageSwitcher(BuildContext context, bool isDark) {
  final lang = Provider.of<LanguageProvider>(context);
  final display = lang.language.toUpperCase();

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(42),
      onTap: () => _showLanguageSelector(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Text(
          display,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}

// Language selector bottom sheet
void _showLanguageSelector(BuildContext context) {
  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 48,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              _languageOption(context, 'English', 'en'),
              _languageOption(context, 'සිංහල', 'si'),
              _languageOption(context, 'தமிழ்', 'ta'),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

Widget _languageOption(BuildContext context, String label, String code) {
  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
  final provider = Provider.of<LanguageProvider>(context);

  return ListTile(
    title: Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
    onTap: () {
      final providerWrite =
          Provider.of<LanguageProvider>(context, listen: false);
      providerWrite.setLanguage(code);
      Navigator.pop(context);
    },
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    trailing: provider.language == code
        ? const Icon(Icons.check, color: Colors.green)
        : null,
    tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
  );
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
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
  Timer? _lastUpdatedTimer;
  int _bottomIndex = 0;

  DateTime? _lastUpdatedAt;

  // Avoid duplicate notifications for same crop/disease/severity in same day
  final Set<String> _sentNotificationKeys = {};

  final List<Map<String, String>> crops = [
    {
      'key': 'coconut',
      'label': 'Coconut',
      'asset': 'assets/images/coconut.png',
    },
    {
      'key': 'tea',
      'label': 'Tea',
      'asset': 'assets/images/tea.png',
    },
    {
      'key': 'rice',
      'label': 'Rice',
      'asset': 'assets/images/paddy.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();

    // Weather and risk auto refresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) _loadAll();
    });

    // Last updated text refresh
    _lastUpdatedTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _lastUpdatedTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadAll();
  }

  String _lastUpdatedText() {
    if (_lastUpdatedAt == null) {
      return 'Not updated yet';
    }

    final diff = DateTime.now().difference(_lastUpdatedAt!);

    if (diff.inSeconds < 60) {
      return 'Updated just now';
    }

    if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes} mins ago';
    }

    if (diff.inHours < 24) {
      return 'Updated ${diff.inHours} hours ago';
    }

    return 'Updated ${diff.inDays} days ago';
  }

  Future<void> _manualRefreshWeather() async {
    if (isLoading) return;
    await _loadAll();
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
      print('HomePage: DEBUG forcing coords to $_debugLat,$_debugLon');
      lat = _debugLat;
      lon = _debugLon;
    }

    try {
      final weatherSvc = WeatherService();

      print('HomePage: fetching weather for lat=$lat, lon=$lon');
      final w = await weatherSvc.getWeather(lat, lon);

      final cityName = (loc['city'] as String?) ?? '';

      final dynamic rawTemp = w?['temp'];
      final double? tempVar = rawTemp is num
          ? rawTemp.toDouble()
          : rawTemp is String
              ? double.tryParse(rawTemp)
              : null;

      final int? humidityVar = w != null && w['humidity'] != null
          ? w['humidity'] is num
              ? (w['humidity'] as num).toInt()
              : int.tryParse(w['humidity'].toString())
          : null;

      final diseases = await fetchDiseases();

      final bool hasRain = _hasRainFromWeather(w);

      final cropKeys = crops
          .map((c) => (c['key'] ?? '').toString().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      final scored = RiskService.selectTopPerCrop(
        diseases,
        tempVar,
        humidityVar,
        hasRain,
        cropOrder: cropKeys,
        limit: 3,
      );

      setState(() {
        weather = {
          ...?w,
          'temp': tempVar,
          'humidity': humidityVar,
          'city': cityName.isNotEmpty
              ? cityName
              : w != null && (w['city']?.toString().isNotEmpty ?? false)
                  ? w['city']
                  : 'Nearby',
        };

        riskList = scored.map((d) => d.toJson()).toList();
        isLoading = false;
        _lastUpdatedAt = DateTime.now();
      });

      _calculateRiskSummary();
      await _sendAllRiskNotificationsIfNeeded();
    } catch (e) {
      print('HomePage load error: $e');

      setState(() {
        isLoading = false;
        weather = null;
        riskList = [];
        riskText = "Unable to fetch data";
      });
    }
  }

  bool _hasRainFromWeather(Map<String, dynamic>? w) {
    if (w == null) return false;

    final dynamic rainValue = w['rain'];

    if (rainValue is num && rainValue > 0) return true;

    final raw = w['raw'];

    if (raw is Map) {
      if (raw['rain'] != null) return true;

      final weatherList = raw['weather'];

      if (weatherList is List) {
        return weatherList.any((it) {
          if (it is! Map) return false;

          final main = it['main']?.toString().toLowerCase() ?? '';
          final description = it['description']?.toString().toLowerCase() ?? '';

          return main.contains('rain') ||
              main.contains('drizzle') ||
              main.contains('thunder') ||
              description.contains('rain') ||
              description.contains('drizzle') ||
              description.contains('shower');
        });
      }
    }

    final condition = w['condition']?.toString().toLowerCase() ?? '';
    final description = w['description']?.toString().toLowerCase() ?? '';

    return condition.contains('rain') ||
        condition.contains('drizzle') ||
        condition.contains('thunder') ||
        description.contains('rain') ||
        description.contains('drizzle') ||
        description.contains('shower');
  }

  Future<List<Disease>> fetchDiseases() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/diseases');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        if (data is List) {
          return data
              .map((e) => Disease.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Fetch diseases error: $e');
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
    int mediumCount = 0;

    for (var d in riskList) {
      final severity = (d['severity'] ?? '').toString().toLowerCase();

      if (severity.contains('high') || severity.contains('severe')) {
        highCount++;
      } else if (severity.contains('medium') ||
          severity.contains('moderate')) {
        mediumCount++;
      }
    }

    String newRiskText;
    Color newRiskColor;
    IconData newRiskIcon;

    if (highCount > 0) {
      newRiskText = "High disease risk";
      newRiskColor = Colors.red;
      newRiskIcon = Icons.warning;
    } else if (mediumCount > 0) {
      newRiskText = "Medium disease risk";
      newRiskColor = Colors.orange;
      newRiskIcon = Icons.warning_amber_rounded;
    } else {
      newRiskText = "Low Risk";
      newRiskColor = Colors.green;
      newRiskIcon = Icons.check_circle;
    }

    setState(() {
      riskText = newRiskText;
      riskColor = newRiskColor;
      riskIcon = newRiskIcon;
    });
  }

  Future<void> _sendAllRiskNotificationsIfNeeded() async {
    try {
      if (riskList.isEmpty) return;

      final topDiseases = _riskMapsToDiseases(riskList);
      final alerts = RiskService.topRisksForNotificationPerCrop(topDiseases);

      if (alerts.isEmpty) return;

      for (final disease in alerts) {
        final severity = disease.severity;
        final riskLevel = RiskService.displayRiskLevel(severity);

        final key =
            '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-${disease.crop}-${disease.name}-${severity}';

        if (_sentNotificationKeys.contains(key)) {
          continue;
        }

        _sentNotificationKeys.add(key);

        await NotificationService.instance.showRiskNotification(
          crop: _formatCropName(disease.crop),
          diseaseName: disease.name,
          riskLevel: riskLevel,
          severity: RiskService.displaySeverity(severity),
        );
      }
    } catch (e) {
      print('Risk notification error: $e');
    }
  }

  List<Disease> _riskMapsToDiseases(List<dynamic> maps) {
    return maps.map((m) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(m as Map);
      final d = Disease.fromJson(map);

      if (map['score'] != null) {
        d.score = map['score'] is num
            ? (map['score'] as num).toInt()
            : int.tryParse(map['score'].toString()) ?? 0;
      }

      if (map['percent'] != null) {
        d.percent = map['percent'] is num
            ? (map['percent'] as num).toDouble()
            : double.tryParse(map['percent']?.toString() ?? '') ?? 0.0;
      }

      if (map['severity'] != null) {
        d.severity = map['severity'].toString();
      }

      return d;
    }).toList();
  }

  String _formatCropName(String crop) {
    final c = crop.toLowerCase().trim();

    if (c == 'rice' || c == 'paddy') return 'Rice';
    if (c == 'tea') return 'Tea';
    if (c == 'coconut') return 'Coconut';

    if (crop.trim().isEmpty) return 'Crop';

    return crop[0].toUpperCase() + crop.substring(1);
  }

  bool get _showRiskDot {
    try {
      return riskList.isNotEmpty &&
          riskList.take(3).any((d) {
            final severity = (d['severity'] ?? '').toString().toLowerCase();

            return severity.contains('high') ||
                severity.contains('severe') ||
                severity.contains('medium') ||
                severity.contains('moderate');
          });
    } catch (_) {
      return false;
    }
  }

  void _showRiskModal() {
    final topMaps = riskList.isNotEmpty ? riskList.take(3).toList() : [];

    final topDiseases = _riskMapsToDiseases(topMaps);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => NotificationPage(diseases: topDiseases),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final weekday = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ][dt.weekday % 7];

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
    final isDark = theme.isDark;
    final mq = MediaQuery.of(context);
    final double padding = 16.0;

    final String userName = user?.displayName ?? user?.email ?? '';
    final String avatarInitial =
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    final String greetingStr = _greeting();
    final String dateStr = _formatDate(DateTime.now());

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: mq.size.height - 40),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      HeaderWidget(
                        greeting: greetingStr,
                        userName: userName,
                        date: dateStr,
                        showRiskDot: _showRiskDot,
                        onBellTap: _showRiskModal,
                        isDark: isDark,
                        avatarInitial: avatarInitial,
                      ),
                      Positioned(
                        top: 120,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: WeatherCard(
                            weather: weather,
                            isLoading: isLoading,
                            isDark: isDark,
                            statusText: riskText,
                            statusColor: riskColor,
                            lastUpdatedText: _lastUpdatedText(),
                            onRefresh: _manualRefreshWeather,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 130),

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
                          onTap: () =>
                              Navigator.pushNamed(context, '/knowledge'),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 12),

                        PremiumCard(
                          icon: Icons.smart_toy,
                          title: 'Ask AgroX AI',
                          subtitle: 'Instant farming advice',
                          color: Colors.blue,
                          onTap: () =>
                              Navigator.pushNamed(context, '/chatbot'),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TranslatedText(
                              'Best Fields',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: TranslatedText(
                                'See All',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: crops.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final c = crops[i];

                              return CropCard(
                                label: c['label']!,
                                asset: c['asset']!,
                                isDark: isDark,
                              );
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

// ===============================
// HEADER CLIPPER
// ===============================
class CustomHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    path.lineTo(0, size.height - 5);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + 95,
      size.width,
      size.height - 5,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ===============================
// HEADER WIDGET
// ===============================
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
    const height = 185.0;

    return ClipPath(
      clipper: CustomHeaderClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 76, 175, 80),
              Color.fromARGB(255, 102, 187, 106),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isDark)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.22),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (ctx) {
                              String name = userName.trim();

                              if (name.isNotEmpty) {
                                final parts = name.split(' ');
                                name = parts
                                    .map(
                                      (p) => p.isEmpty
                                          ? p
                                          : p[0].toUpperCase() + p.substring(1),
                                    )
                                    .join(' ');
                              }

                              return Row(
                                children: [
                                  TranslatedText(
                                    '$greeting, ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${name.isNotEmpty ? name : 'User'} 👋',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 6),

                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onBellTap,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                                size: 26,
                              ),

                              if (showRiskDot)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        _buildLanguageSwitcher(context, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// WEATHER CARD WITHOUT SUNRISE / SUNSET
// ===============================
class WeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  final bool isDark;
  final String statusText;
  final Color statusColor;
  final String lastUpdatedText;
  final VoidCallback onRefresh;

  const WeatherCard({
    this.weather,
    required this.isLoading,
    required this.isDark,
    required this.statusText,
    required this.statusColor,
    required this.lastUpdatedText,
    required this.onRefresh,
    super.key,
  });

  String _emojiForCondition(String? cond) {
    if (cond == null) return '🌤';

    final c = cond.toLowerCase();

    if (c.contains('rain') || c.contains('drizzle')) return '🌧';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('clear') || c.contains('sun')) return '☀️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('thunder') || c.contains('storm')) return '🌩';

    return '🌤';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.94,
        height: 165,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: CircularProgressIndicator(color: Colors.green.shade700),
        ),
      );
    }

    final loc = weather != null
        ? (weather!['location'] ?? weather!['city'] ?? 'Nearby')
        : 'Nearby';

    final double tempNum = weather != null && weather!['temp'] != null
        ? weather!['temp'] is num
            ? (weather!['temp'] as num).toDouble()
            : double.tryParse(weather!['temp'].toString()) ?? 0.0
        : 0.0;

    final int humidity = weather != null && weather!['humidity'] != null
        ? weather!['humidity'] is num
            ? (weather!['humidity'] as num).toInt()
            : int.tryParse(weather!['humidity'].toString()) ?? 0
        : 0;

    final int pressure = weather != null && weather!['pressure'] != null
        ? weather!['pressure'] is num
            ? (weather!['pressure'] as num).toInt()
            : int.tryParse(weather!['pressure'].toString()) ?? 0
        : 0;

    final double wind = weather != null && weather!['wind_speed'] != null
        ? weather!['wind_speed'] is num
            ? (weather!['wind_speed'] as num).toDouble()
            : double.tryParse(weather!['wind_speed'].toString()) ?? 0.0
        : 0.0;

    final String condition = weather != null
        ? (weather!['condition']?.toString() ??
            weather!['description']?.toString() ??
            '')
        : '';

    final tempStr = '${tempNum.toStringAsFixed(1)}°C';

    return Container(
      width: MediaQuery.of(context).size.width * 0.94,
      height: 165,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location + Risk + Refresh
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.toString(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.green.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Temperature + Condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tempStr,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _emojiForCondition(condition),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      condition.isNotEmpty ? condition : 'Unknown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Humidity / Pressure / Wind
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeatherStat(
                label: 'Humidity',
                value: '$humidity%',
                isDark: isDark,
              ),
              _WeatherStat(
                label: 'Pressure',
                value: '$pressure hPa',
                isDark: isDark,
                alignCenter: true,
              ),
              _WeatherStat(
                label: 'Wind',
                value: '${wind.toStringAsFixed(1)} m/s',
                isDark: isDark,
                alignRight: true,
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 4),
              Text(
                lastUpdatedText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool alignCenter;
  final bool alignRight;

  const _WeatherStat({
    required this.label,
    required this.value,
    required this.isDark,
    this.alignCenter = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    CrossAxisAlignment align = CrossAxisAlignment.start;

    if (alignCenter) align = CrossAxisAlignment.center;
    if (alignRight) align = CrossAxisAlignment.end;

    return Column(
      crossAxisAlignment: align,
      children: [
        TranslatedText(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}

// ===============================
// PREMIUM FEATURE CARD
// ===============================
class PremiumCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isDark;

  const PremiumCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.isDark = false,
    super.key,
  });

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
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TranslatedText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================
// CROP CARD
// ===============================
class CropCard extends StatelessWidget {
  final String label;
  final String asset;
  final bool isDark;

  const CropCard({
    required this.label,
    required this.asset,
    required this.isDark,
    super.key,
  });

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
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(asset, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.28),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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