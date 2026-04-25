import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Firebase background message handler.
/// IMPORTANT: This must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('BACKGROUND MESSAGE: ${message.messageId}');
  debugPrint('BACKGROUND DATA: ${message.data}');
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'risk_alerts';
  static const String _channelName = 'Risk Alerts';

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: 'Notifications for crop disease risk alerts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  // =========================
  // INIT
  // =========================
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _requestPermission();

      if (!kIsWeb) {
        await _initLocalNotifications();
        await _createAndroidChannel();
      }

      _setupForegroundListener();
      _setupNotificationTapListeners();

      await _printToken();

      _initialized = true;
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  // =========================
  // PERMISSION
  // =========================
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // =========================
  // LOCAL NOTIFICATION INIT
  // =========================
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('LOCAL NOTIFICATION TAPPED: ${response.payload}');
      },
    );
  }

  // =========================
  // ANDROID CHANNEL
  // =========================
  Future<void> _createAndroidChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // =========================
  // FOREGROUND FIREBASE MESSAGE
  // =========================
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FOREGROUND MESSAGE: ${message.messageId}');
      debugPrint('FOREGROUND DATA: ${message.data}');

      final notification = message.notification;

      final title = notification?.title ??
          message.data['title']?.toString() ??
          'AgroX Risk Alert';

      final body = notification?.body ??
          message.data['body']?.toString() ??
          _buildBodyFromData(message.data);

      if (kIsWeb) {
        debugPrint('WEB FOREGROUND NOTIFICATION: $title - $body');
        return;
      }

      await _showLocalNotification(
        title: title,
        body: body,
        payload: message.data.toString(),
      );
    });
  }

  // =========================
  // NOTIFICATION TAP LISTENERS
  // =========================
  void _setupNotificationTapListeners() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('NOTIFICATION OPENED APP: ${message.messageId}');
      debugPrint('OPENED DATA: ${message.data}');
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          'APP OPENED FROM TERMINATED NOTIFICATION: ${message.messageId}',
        );
        debugPrint('INITIAL DATA: ${message.data}');
      }
    });
  }

  // =========================
  // GET FCM TOKEN
  // =========================
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM TOKEN: $token');
      return token;
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }

  // =========================
  // PRINT FCM TOKEN
  // =========================
  Future<void> _printToken() async {
    await getToken();

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM TOKEN REFRESHED: $newToken');
    });
  }

  // =========================
  // LOCAL RISK NOTIFICATION
  // =========================
  Future<void> showRiskNotification({
    required String crop,
    required String diseaseName,
    required String riskLevel,
    required String severity,
    double? riskPercent,
  }) async {
    try {
      final String risk = riskLevel.toLowerCase();
      final String sev = severity.toLowerCase();

      final bool isHigh =
          risk.contains('high') || sev.contains('high') || sev.contains('severe');

      final bool isMedium = risk.contains('medium') ||
          sev.contains('medium') ||
          sev.contains('moderate');

      if (!isHigh && !isMedium) {
        debugPrint('LOW RISK NOTIFICATION SKIPPED: $crop - $diseaseName');
        return;
      }

      final String levelText = isHigh ? 'High' : 'Medium';

      final String cropText = _formatText(crop, fallback: 'Crop');
      final String diseaseText = _formatText(diseaseName, fallback: 'Disease');

      final String title = isHigh
          ? '⚠️ High Disease Risk Alert'
          : '⚠️ Medium Disease Risk Alert';

      String percentText = '';

      if (riskPercent != null && riskPercent > 0) {
        final double displayPercent =
            riskPercent <= 1 ? riskPercent * 100 : riskPercent;

        percentText = ' (${displayPercent.toStringAsFixed(0)}%)';
      }

      final String body =
          '$cropText: $diseaseText risk is $levelText$percentText. Please check AgroX.';

      debugPrint('LOCAL RISK NOTIFICATION: $title | $body');

      if (kIsWeb) {
        debugPrint('Web local notification skipped. Use FCM web push instead.');
        return;
      }

      await _showLocalNotification(
        title: title,
        body: body,
        payload: {
          'type': 'risk_alert',
          'crop': cropText,
          'diseaseName': diseaseText,
          'riskLevel': levelText,
          'severity': levelText,
          'riskPercent': percentText,
        }.toString(),
      );
    } catch (e) {
      debugPrint('showRiskNotification error: $e');
    }
  }

  // =========================
  // SHOW MULTIPLE WEATHER RISK NOTIFICATIONS
  // =========================
  Future<void> showMultipleRiskNotifications({
    required List<Map<String, dynamic>> risks,
  }) async {
    for (final risk in risks) {
      final crop = risk['crop']?.toString() ?? 'Crop';

      final diseaseName = risk['name']?.toString() ??
          risk['disease']?.toString() ??
          risk['diseaseName']?.toString() ??
          'Disease';

      final severity = risk['severity']?.toString() ?? 'Low';

      final double? percent = risk['percent'] is num
          ? (risk['percent'] as num).toDouble()
          : double.tryParse(risk['percent']?.toString() ?? '');

      await showRiskNotification(
        crop: crop,
        diseaseName: diseaseName,
        riskLevel: severity,
        severity: severity,
        riskPercent: percent,
      );

      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  // =========================
  // SHOW LOCAL NOTIFICATION
  // =========================
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final int notificationId =
        DateTime.now().microsecondsSinceEpoch.remainder(1000000000);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notifications for crop disease risk alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // =========================
  // BUILD BODY FROM FCM DATA
  // =========================
  String _buildBodyFromData(Map<String, dynamic> data) {
    final crop = _formatText(
      data['crop']?.toString() ?? '',
      fallback: 'Crop',
    );

    final disease = _formatText(
      data['disease_name']?.toString() ??
          data['diseaseName']?.toString() ??
          data['name']?.toString() ??
          '',
      fallback: 'Disease risk',
    );

    final risk = _formatText(
      data['risk_level']?.toString() ??
          data['riskLevel']?.toString() ??
          data['severity']?.toString() ??
          '',
      fallback: 'Risk',
    );

    final percent = data['risk_percent']?.toString() ??
        data['riskPercent']?.toString() ??
        data['percent']?.toString() ??
        '';

    final percentText = percent.trim().isNotEmpty ? ' ($percent)' : '';

    return '$crop: $disease risk is $risk$percentText. Please check AgroX.';
  }

  // =========================
  // FORMAT TEXT
  // =========================
  String _formatText(String value, {required String fallback}) {
    final text = value.trim();

    if (text.isEmpty) return fallback;

    return text
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
      final w = word.trim();

      if (w.isEmpty) return w;

      if (w.toUpperCase() == w && w.length <= 6) {
        return w;
      }

      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}