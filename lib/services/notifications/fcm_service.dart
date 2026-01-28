import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentToken;
  String? _accessToken;
  DateTime? _tokenExpiry;

  static const String _projectId = 'testfirbase-1f25a';

  static const Map<String, dynamic> _serviceAccount = {
    "type": "service_account",
    "project_id": "testfirbase-1f25a",
    "private_key_id": "688274c43c0b0842c3fa949e15cad3a57912a540",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC2CEJcEFI/QA9E\nroK+yZv9YAx9yJMgODJQCDry+0zD0rVUCTyAWcJonR0PgKgWDwRjUoGGMrYK6KUs\njizwvHqVEky25q+8+25EGSDwKjjD0XNSnFUx0wITpEw3OiCsv6IT2cdm7dgDIeRb\nIeX1FvVJW/WrEC99/GQV1VoXnbXzCSh3mnX1CWbjf68ISpHqQFJL5t+RPXi1E14K\nsrOl4NSfdJtEcwRj09rY7yW39tfelM8MSDpg6e5NENJHL+FDda2ACrf8OhMFHA8i\nFd5uett+qYxNEARovOJY0ETB1lb5TPrIZlpUoall+cQB+EU3Mmcg82/MeQ/u9WU5\nIFTES9iTAgMBAAECggEABL/ma1yJqNjVDSe4hZ3hEhVlfgqzvA17UpdEYn6oHBvt\nW0n6aCbvaadf0L28pQazSJwogQXlthcn6Ce1iHqCgE0/7y3JvBabY+976ohPftyC\nM8+ccXZeAYEx8+byX0+IvRfbmhXuovZJbQ9PXrvAnq9lk5cShikFu4Qbm64jxzmU\nl0cdOktDrXp53Fl1jaNa0LHkd9tHol/EDnHI1Es4VeVDNR1Rw0OCvKXM0z6pM+/u\nCpG3V5D68Jx4Nw2ZHG/BF/XGYIOxmXScJU5n2qCzevtYDiD2+hg0ppYE2uB9JO05\n1vDTkI/9p4rmIn8BA8n17xcmUjBjZDrFbvqiCaSpIQKBgQD1RvTCvzAlpXfmBzx6\nSHNhq9XJ3WOjiy4VfKBsMdM6FWLln2ll2RkrNB03GrLrNdt4Eyo3Lx9Ez9PJ+EXi\nLcoq9Nxc6yT3bao3irFbL66rDrZ5jtPm8Zp8AOe3sWme4ghY/kyTuuEUX8PHflh2\n9O8C82VKI/TULRTCJ46+hLtomQKBgQC9/X3NWRshZKHIlMTACdxxESPGGH39CaYK\n2Az/lPs+wFLRImnmUHO5gDYEBAqrTAj8xkDCB4aeeNXo8Oz3S29l17OLh1dC8Tzn\nxbgs2+hRa6JgEjfB/DJ05W55Kyu+Kqy2uTvVXQmbYb/EA+cjxdwictt7/SUVCk/F\nPUX7aMdqCwKBgQDJfDxcLkoS4taXc6JOoW2G8m1wohjTo+V7aSEvP87Qi/jtwAII\n1EpEn07QkXIgneFnxfaL1n3NPRwxcW2W2x6UIwlSmyeGyeNmNNx0l7rYcgGb4aRY\ntme9LdErqOWmyu8oi93EDWQQJIrjOfrZ3WLp/Z9bRCY+lbnTtEMiZk69IQKBgQC7\njhh39KQk1gwkUEDe950n/WycbadKehDxmZFTagaRTxkync9/byKfGKO6WScTLY+d\nwjVBll5d6Rn6yISWKGEDX+o+LtCFJFMk1vpXRoxUfHYiczmaBdblsWzarzSSmdxA\n0iHwItWOD/RYlCXFGdmUJGDqSOAnojNXmoKQi0J5OwKBgFpACOlgk+kz4SSJPudF\nudNhDrSCcKTp/w71EWA9bmTK9QQ3zv/U2ZT0O3b1SlCaQpo/EICZTc0zeYLTifkg\nIWttBJgg1sHio3cvNACurDreuKpGmhsxangFRvpOcZcgXXuNW3kXKnJOM2uku5RH\nMUpquRhb0c+KREP8Xbm+cViF\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@testfirbase-1f25a.iam.gserviceaccount.com",
    "client_id": "116767582032532903793",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
  };

  Future<void> initialize() async {
    try {
      await _requestPermission();

      await _initializeLocalNotifications();

      await _getAndSaveToken();

      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('FCMService initialized successfully');
    } catch (e) {
      debugPrint('FCMService initialization error: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'wissal_messages',
        'Messages',
        description: 'Notifications for new messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<String?> _getAndSaveToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      if (_currentToken != null) {
        await _saveTokenToDatabase(_currentToken!);
      }
      return _currentToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    _currentToken = token;
    await _saveTokenToDatabase(token);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'other';

      await _supabase.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      debugPrint('FCM token saved to database');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<String?> _getAccessToken() async {
    try {
      if (_accessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken;
      }

      final accountCredentials =
          ServiceAccountCredentials.fromJson(_serviceAccount);

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(accountCredentials, scopes);

      _accessToken = client.credentials.accessToken.data;
      _tokenExpiry = client.credentials.accessToken.expiry;

      client.close();
      return _accessToken;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  Future<bool> sendNotificationToUser({
    required String receiverUserId,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      final tokens = await _getUserFCMTokens(receiverUserId);
      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for user: $receiverUserId');
        return false;
      }

      bool anySent = false;
      for (final token in tokens) {
        final success = await _sendToToken(
          token: token,
          title: title,
          body: body,
          data: data,
          imageUrl: imageUrl,
        );
        if (success) anySent = true;
      }

      return anySent;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    for (final odId in userIds) {
      await sendNotificationToUser(
        receiverUserId: odId,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
      );
    }
  }

  Future<List<String>> _getUserFCMTokens(String odId) async {
    try {
      final response = await _supabase
          .from('fcm_tokens')
          .select('token')
          .eq('user_id', odId)
          .eq('is_active', true);

      return (response as List).map((e) => e['token'] as String).toList();
    } catch (e) {
      debugPrint('Error getting FCM tokens: $e');
      return [];
    }
  }

  Future<bool> _sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('Failed to get access token');
        return false;
      }

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

      final message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
            if (imageUrl != null) 'image': imageUrl,
          },
          if (data != null) 'data': data,
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'wissal_messages',
              'sound': 'default',
              'default_vibrate_timings': true,
              'default_light_settings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
        return true;
      } else {
        debugPrint('Failed to send notification: ${response.body}');
        // If token is invalid, mark it as inactive
        if (response.statusCode == 404 ||
            response.body.contains('UNREGISTERED')) {
          await _markTokenInactive(token);
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error sending to token: $e');
      return false;
    }
  }

  Future<void> _markTokenInactive(String token) async {
    try {
      await _supabase
          .from('fcm_tokens')
          .update({'is_active': false}).eq('token', token);
    } catch (e) {
      debugPrint('Error marking token inactive: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        data: message.data,
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wissal_messages',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateToScreen(data);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _navigateToScreen(message.data);
  }

  void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'];
    final targetId = data['target_id'];

    debugPrint('Navigate to: $type - $targetId');
  }

  Future<void> deleteToken() async {
    try {
      if (_currentToken != null) {
        await _supabase.from('fcm_tokens').delete().eq('token', _currentToken!);
      }
      await _firebaseMessaging.deleteToken();
      _currentToken = null;
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  String? get currentToken => _currentToken;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}
