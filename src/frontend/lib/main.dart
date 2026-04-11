import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'authentication/AuthLogInRoute.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ar_SA', null);

  // Request notification permission
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up local notifications plugin
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (_) {},
  );

  // Explicitly create the notification channel
  const channel = AndroidNotificationChannel(
    'bouh_notifications',
    'إشعارات بَوْح',
    description: 'إشعارات المواعيد والتنبيهات',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Notification tap when app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((_) {});

  // Notification tap when app was terminated
  await FirebaseMessaging.instance.getInitialMessage();

  // Foreground: show a visible local notification when an FCM message arrives
  FirebaseMessaging.onMessage.listen((message) {
    print('Foreground message: ${message.notification?.title}');
    try {
      flutterLocalNotificationsPlugin
          .show(
            message.hashCode & 0x7FFFFFFF,
            message.notification?.title ?? 'إشعار',
            message.notification?.body ?? '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'bouh_notifications',
                'إشعارات بَوْح',
                channelDescription: 'إشعارات المواعيد والتنبيهات',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                visibility: NotificationVisibility.public,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          )
          .then((_) {
            print('Local notification shown successfully');
          })
          .catchError((e) {
            print('ERROR showing local notification: $e');
          });
    } catch (e) {
      print('SYNC ERROR showing local notification: $e');
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginResolverView());
  }
}
