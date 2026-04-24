import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// 🔥 Firebase background message handler
/// IMPORTANT: This must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('BACKGROUND MESSAGE: ${message.messageId}');
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'risk_alert_channel',
    'Risk Alerts',
    description: 'Notifications for crop disease risk alerts',
    importance: Importance.high,
    playSound: true,
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

    await _localNotifications.initialize(initSettings);
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

      final notification = message.notification;

      final title = notification?.title ??
          message.data['title']?.toString() ??
          'AgroX Risk Alert';

      final body = notification?.body ??
          message.data['body']?.toString() ??
          'New crop disease risk alert available';

      if (kIsWeb) {
        debugPrint('WEB FOREGROUND NOTIFICATION: $title - $body');
        return;
      }

      await _showLocalNotification(
        title: title,
        body: body,
      );
    });
  }

  // =========================
  // PRINT FCM TOKEN
  // =========================
  Future<void> _printToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM TOKEN: $token');
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  // =========================
  // LOCAL RISK NOTIFICATION
  // =========================
  Future<void> showRiskNotification({
    required String crop,
    required String diseaseName,
    required String riskLevel,
    required String severity,
  }) async {
    try {
      final bool isHigh = riskLevel.toLowerCase().contains('high') ||
          severity.toLowerCase().contains('high');

      final bool isMedium = riskLevel.toLowerCase().contains('medium') ||
          severity.toLowerCase().contains('medium');

      if (!isHigh && !isMedium) return;

      final String title =
          isHigh ? '⚠️ High Disease Risk Alert' : '⚠️ Medium Disease Risk Alert';

      final String body =
          '$crop crop may be affected by $diseaseName. Risk level: $severity';

      debugPrint('LOCAL RISK NOTIFICATION: $title | $body');

      if (kIsWeb) {
        debugPrint('Web local notification skipped. Use FCM web push instead.');
        return;
      }

      await _showLocalNotification(
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('showRiskNotification error: $e');
    }
  }

  // =========================
  // SHOW LOCAL NOTIFICATION
  // =========================
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'risk_alert_channel',
          'Risk Alerts',
          channelDescription: 'Notifications for crop disease risk alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}