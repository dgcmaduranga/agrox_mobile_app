import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ===============================
// APP THEME COLORS
// ===============================
const Color kDarkGreen = Color(0xFF0B5D1E);
const Color kMainGreen = Color(0xFF1B7F35);
const Color kLightGreen = Color(0xFFEAF7EE);

// ===============================
// LANGUAGE SWITCHER
// ===============================
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
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}

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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      Provider.of<LanguageProvider>(context, listen: false).setLanguage(code);
      Navigator.pop(context);
    },
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    trailing: provider.language == code
        ? const Icon(Icons.check, color: kDarkGreen)
        : null,
    tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
  );
}

// ===============================
// HOME PAGE STATE
// ===============================
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const bool _forceDebugCoords = false;
  static const double _debugLat = 5.9485;
  static const double _debugLon = 80.5353;

  static const String _notificationPrefKey = 'agrox_notifications_enabled';
  static const int _notificationIntervalHours = 4;

  Map<String, dynamic>? weather;
  bool isLoading = true;

  List<dynamic> riskList = [];
  String riskText = 'Checking risk...';
  Color riskColor = Colors.green;
  IconData riskIcon = Icons.check_circle;

  Timer? _refreshTimer;
  Timer? _lastUpdatedTimer;
  int _bottomIndex = 0;

  DateTime? _lastUpdatedAt;

  final List<Map<String, String>> crops = [
    {
      'key': 'rice',
      'label': 'Rice',
      'asset': 'assets/images/paddy.png',
    },
    {
      'key': 'tea',
      'label': 'Tea',
      'asset': 'assets/images/tea.png',
    },
    {
      'key': 'coconut',
      'label': 'Coconut',
      'asset': 'assets/images/coconut.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadAll(showLoader: true);

    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) _loadAll(showLoader: false);
    });

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
    if (state == AppLifecycleState.resumed) {
      _loadAll(showLoader: false);
    }
  }

  String _lastUpdatedText() {
    if (_lastUpdatedAt == null) return 'Not updated yet';

    final diff = DateTime.now().difference(_lastUpdatedAt!);

    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hours ago';

    return 'Updated ${diff.inDays} days ago';
  }

  Future<void> _manualRefreshWeather() async {
    if (isLoading) return;
    await _loadAll(showLoader: true, forceNotificationCheck: true);
  }

  Future<void> _loadAll({
    bool showLoader = false,
    bool forceNotificationCheck = false,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
        riskText = 'Checking risk...';
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      });
    }

    final loc = await LocationService.getCurrentLocation();

    if (loc == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        weather = null;
        riskList = [];
        riskText = 'Location unavailable';
        riskColor = Colors.orange;
        riskIcon = Icons.location_off;
      });
      return;
    }

    double lat = _toDouble(loc['lat']) ??
        _toDouble(loc['latitude']) ??
        _debugLat;

    double lon = _toDouble(loc['lon']) ??
        _toDouble(loc['lng']) ??
        _toDouble(loc['longitude']) ??
        _debugLon;

    if (_forceDebugCoords) {
      lat = _debugLat;
      lon = _debugLon;
    }

    try {
      final weatherSvc = WeatherService();
      final w = await weatherSvc.getWeather(lat, lon);

      final String locationName = _buildAccurateLocationName(
        loc: loc,
        weatherData: w,
        lat: lat,
        lon: lon,
      );

      final double? tempVar = _toDouble(w?['temp']);
      final int? humidityVar = _toInt(w?['humidity']);

      final diseases = await fetchDiseases();

      final bool hasRain = _hasRainFromWeather(w);

      final cropKeys = crops
          .map((c) => (c['key'] ?? '').toLowerCase())
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

      if (!mounted) return;

      setState(() {
        weather = {
          ...?w,
          'temp': tempVar,
          'humidity': humidityVar,
          'hasRain': hasRain,
          'city': locationName,
          'location': locationName,
          'lat': lat,
          'lon': lon,
        };

        riskList = scored.map((d) => d.toJson()).toList();
        isLoading = false;
        _lastUpdatedAt = DateTime.now();
      });

      _calculateRiskSummary();

      await _sendAllRiskNotificationsIfNeeded(
        forceCheck: forceNotificationCheck,
      );
    } catch (e) {
      debugPrint('HomePage load error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        weather = null;
        riskList = [];
        riskText = 'Unable to fetch data';
        riskColor = Colors.orange;
        riskIcon = Icons.error_outline;
      });
    }
  }

  // ===============================
  // ACCURATE LOCATION NAME BUILDER
  // ===============================
  String _buildAccurateLocationName({
    required Map<String, dynamic> loc,
    required Map<String, dynamic>? weatherData,
    required double lat,
    required double lon,
  }) {
    final List<String?> possibleNames = [];

    possibleNames.add(_cleanLocationValue(weatherData?['location']));
    possibleNames.add(_cleanLocationValue(weatherData?['city']));
    possibleNames.add(_cleanLocationValue(weatherData?['name']));

    final raw = weatherData?['raw'];

    if (raw is Map) {
      possibleNames.add(_cleanLocationValue(raw['name']));

      final sys = raw['sys'];
      final rawName = _cleanLocationValue(raw['name']);

      if (sys is Map) {
        final country = _cleanLocationValue(sys['country']);

        if (rawName != null && country != null) {
          possibleNames.add('$rawName, $country');
        }
      }
    }

    possibleNames.add(_cleanLocationValue(loc['city']));
    possibleNames.add(_cleanLocationValue(loc['town']));
    possibleNames.add(_cleanLocationValue(loc['village']));
    possibleNames.add(_cleanLocationValue(loc['locality']));
    possibleNames.add(_cleanLocationValue(loc['subLocality']));
    possibleNames.add(_cleanLocationValue(loc['district']));
    possibleNames.add(_cleanLocationValue(loc['administrativeArea']));
    possibleNames.add(_cleanLocationValue(loc['subAdministrativeArea']));
    possibleNames.add(_cleanLocationValue(loc['address']));

    for (final name in possibleNames) {
      if (name != null && name.isNotEmpty) {
        if (name.toLowerCase() != 'nearby' &&
            name.toLowerCase() != 'unknown' &&
            name.toLowerCase() != 'null') {
          return name;
        }
      }
    }

    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }

  String? _cleanLocationValue(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;
    if (text.toLowerCase() == 'unknown') return null;

    return text;
  }

  bool _hasRainFromWeather(Map<String, dynamic>? w) {
    if (w == null) return false;

    final dynamic hasRainValue = w['hasRain'];
    if (hasRainValue == true) return true;

    if (hasRainValue is String) {
      final text = hasRainValue.toLowerCase().trim();
      if (text == 'true' || text == '1' || text == 'yes') return true;
    }

    final dynamic rainValue = w['rain'];

    if (rainValue is num && rainValue > 0) return true;

    if (rainValue is String) {
      final parsed = double.tryParse(rainValue);
      if (parsed != null && parsed > 0) return true;
    }

    final raw = w['raw'];

    if (raw is Map) {
      final rawRain = raw['rain'];

      if (rawRain is Map && rawRain.isNotEmpty) {
        final oneHour = rawRain['1h'];
        final threeHour = rawRain['3h'];

        if (_toDouble(oneHour) != null && _toDouble(oneHour)! > 0) {
          return true;
        }

        if (_toDouble(threeHour) != null && _toDouble(threeHour)! > 0) {
          return true;
        }
      }

      final weatherList = raw['weather'];

      if (weatherList is List) {
        final found = weatherList.any((it) {
          if (it is! Map) return false;

          final main = it['main']?.toString().toLowerCase() ?? '';
          final description = it['description']?.toString().toLowerCase() ?? '';

          return main.contains('rain') ||
              main.contains('drizzle') ||
              main.contains('thunder') ||
              description.contains('rain') ||
              description.contains('drizzle') ||
              description.contains('shower') ||
              description.contains('thunder');
        });

        if (found) return true;
      }
    }

    final condition = w['condition']?.toString().toLowerCase() ?? '';
    final description = w['description']?.toString().toLowerCase() ?? '';

    return condition.contains('rain') ||
        condition.contains('drizzle') ||
        condition.contains('thunder') ||
        description.contains('rain') ||
        description.contains('drizzle') ||
        description.contains('shower') ||
        description.contains('thunder');
  }

  String _displayCondition(Map<String, dynamic>? w) {
    if (w == null) return 'Unknown';

    final bool hasRain = _hasRainFromWeather(w);

    final condition = w['condition']?.toString().trim() ?? '';
    final description = w['description']?.toString().trim() ?? '';

    final conditionLower = condition.toLowerCase();
    final descriptionLower = description.toLowerCase();

    if (hasRain) {
      if (conditionLower.contains('thunder') ||
          descriptionLower.contains('thunder')) {
        return 'Thunderstorm';
      }

      if (conditionLower.contains('drizzle') ||
          descriptionLower.contains('drizzle')) {
        return 'Drizzle';
      }

      if (conditionLower.contains('shower') ||
          descriptionLower.contains('shower')) {
        return 'Showers';
      }

      return 'Rain';
    }

    if (description.isNotEmpty) return _titleCase(description);
    if (condition.isNotEmpty) return _titleCase(condition);

    return 'Unknown';
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
      debugPrint('Fetch diseases error: $e');
      return [];
    }
  }

  void _calculateRiskSummary() {
    if (riskList.isEmpty) {
      if (!mounted) return;

      setState(() {
        riskText = 'Low Risk';
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      });
      return;
    }

    int highCount = 0;
    int mediumCount = 0;

    for (final d in riskList) {
      final severity = (d['severity'] ?? '').toString().toLowerCase();

      if (severity.contains('high') || severity.contains('severe')) {
        highCount++;
      } else if (severity.contains('medium') ||
          severity.contains('moderate')) {
        mediumCount++;
      }
    }

    if (!mounted) return;

    setState(() {
      if (highCount > 0) {
        riskText = 'High disease risk';
        riskColor = Colors.red;
        riskIcon = Icons.warning;
      } else if (mediumCount > 0) {
        riskText = 'Medium risk';
        riskColor = Colors.orange;
        riskIcon = Icons.warning_amber_rounded;
      } else {
        riskText = 'Low Risk';
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
      }
    });
  }

  Future<void> _sendAllRiskNotificationsIfNeeded({
    bool forceCheck = false,
  }) async {
    try {
      if (riskList.isEmpty) return;

      final notificationsEnabled = await _notificationsEnabled();

      if (!notificationsEnabled) {
        debugPrint('Risk notification skipped: user disabled notifications');
        return;
      }

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      final topDiseases = _riskMapsToDiseases(riskList);
      final alerts = RiskService.topRisksForNotificationPerCrop(topDiseases);

      if (alerts.isEmpty) return;

      for (final disease in alerts) {
        final severity = disease.severity;

        if (!RiskService.isMediumOrHigh(severity)) continue;

        final crop = _formatCropName(disease.crop);
        final diseaseName = disease.name;
        final severityText = RiskService.displaySeverity(severity);
        final riskLevel = RiskService.displayRiskLevel(severity);

        final baseKey = '${crop}_${diseaseName}_$severityText'
            .toLowerCase()
            .replaceAll(' ', '_');

        final lastSentKey = 'agrox_last_notification_$baseKey';
        final lastSentMillis = prefs.getInt(lastSentKey) ?? 0;

        final lastSent = lastSentMillis > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastSentMillis)
            : null;

        final canSend = forceCheck ||
            lastSent == null ||
            now.difference(lastSent).inHours >= _notificationIntervalHours;

        if (!canSend) {
          debugPrint('Risk notification skipped within 4 hours: $baseKey');
          continue;
        }

        await prefs.setInt(lastSentKey, now.millisecondsSinceEpoch);

        await NotificationService.instance.showRiskNotification(
          crop: crop,
          diseaseName: diseaseName,
          riskLevel: riskLevel,
          severity: severityText,
          riskPercent: disease.percent,
        );
      }
    } catch (e) {
      debugPrint('Risk notification error: $e');
    }
  }

  Future<bool> _notificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationPrefKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  List<Disease> _riskMapsToDiseases(List<dynamic> maps) {
    return maps.map((m) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(m as Map);
      final d = Disease.fromJson(map);

      if (map['score'] != null) d.score = _toInt(map['score']) ?? 0;
      if (map['percent'] != null) d.percent = _toDouble(map['percent']) ?? 0.0;
      if (map['severity'] != null) d.severity = map['severity'].toString();

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

  String _titleCase(String value) {
    final words = value
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) return value;

    return words.map((word) {
      final w = word.trim();
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
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
    const double padding = 16.0;

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
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 86),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: mq.size.height - 20),
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
                          top: 118,
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
                              displayCondition: _displayCondition(weather),
                              hasRain: _hasRainFromWeather(weather),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 118),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: Column(
                        children: [
                          PremiumCard(
                            icon: Icons.health_and_safety_rounded,
                            title: 'Disease Detection',
                            subtitle: 'Detect crop disease from leaf images',
                            onTap: () => Navigator.pushNamed(context, '/scan'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),

                          PremiumCard(
                            icon: Icons.local_library_rounded,
                            title: 'Knowledge Hub',
                            subtitle: 'Read diseases, symptoms & treatments',
                            onTap: () =>
                                Navigator.pushNamed(context, '/knowledge'),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),

                          PremiumCard(
                            icon: Icons.smart_toy_rounded,
                            title: 'Ask AgroX AI',
                            subtitle: 'Get smart farming advice instantly',
                            onTap: () =>
                                Navigator.pushNamed(context, '/chatbot'),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TranslatedText(
                              'Best Fields',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),

                          const SizedBox(height: 7),

                          SizedBox(
                            height: 105,
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

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: SafeArea(
              top: false,
              child: FloatingBottomNav(
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
            ),
          ),
        ],
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
              Color(0xFF064E1A),
              Color(0xFF0B5D1E),
              Color(0xFF1B7F35),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: kDarkGreen.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isDark)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.18),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
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
          ],
        ),
      ),
    );
  }
}

// ===============================
// WEATHER CARD
// ===============================
class WeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  final bool isDark;
  final String statusText;
  final Color statusColor;
  final String lastUpdatedText;
  final VoidCallback onRefresh;
  final String displayCondition;
  final bool hasRain;

  const WeatherCard({
    this.weather,
    required this.isLoading,
    required this.isDark,
    required this.statusText,
    required this.statusColor,
    required this.lastUpdatedText,
    required this.onRefresh,
    required this.displayCondition,
    required this.hasRain,
    super.key,
  });

  String _emojiForCondition(String cond, bool rain) {
    final c = cond.toLowerCase();

    if (rain) {
      if (c.contains('thunder')) return '⛈️';
      if (c.contains('drizzle')) return '🌦️';
      return '🌧️';
    }

    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('cloud') || c.contains('overcast')) return '☁️';
    if (c.contains('clear') || c.contains('sun')) return '☀️';
    if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
      return '🌫️';
    }
    if (c.contains('snow')) return '❄️';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: kDarkGreen, size: 18),
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
                        : kDarkGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : kDarkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
                      _emojiForCondition(displayCondition, hasRain),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    TranslatedText(
                      displayCondition.isNotEmpty
                          ? displayCondition
                          : 'Unknown',
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
  final VoidCallback? onTap;
  final bool isDark;

  const PremiumCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDark = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF102014);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : kDarkGreen.withOpacity(0.07),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : kDarkGreen.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            kDarkGreen.withOpacity(0.45),
                            kDarkGreen.withOpacity(0.18),
                          ]
                        : [
                            kLightGreen,
                            Colors.white,
                          ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: kDarkGreen.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: kDarkGreen,
                      size: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      title,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TranslatedText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.7,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                        height: 1.23,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kLightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? Colors.white60 : kDarkGreen,
                ),
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
          width: 150,
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
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 10,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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