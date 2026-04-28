import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventapp/event/event_details.dart';
import 'package:eventapp/screen/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//store initial eventId
String? initialEventId;

//BACKGROUND HANDLER
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await showNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await setupFCM();

  //store eventId
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();

  if (initialMessage != null) {
    initialEventId = initialMessage.data['eventId'];
  }

  runApp(const ProviderScope(child: MyApp()));
}

//FCM SETUP gareko for notification ko lagi
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Permission
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Subscribe ALL participants
  await messaging.subscribeToTopic("participants");

  // LOCAL NOTIFICATION SETUP
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await localNotifications.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  // FOREGROUND MESSAGE
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    showNotification(message);
    await FirebaseFirestore.instance.collection("notifications").add({
      "title": message.notification?.title ?? "Event Update",
      "body": message.notification?.body ?? "",
      "time": FieldValue.serverTimestamp(),
      "isRead": false,
      "eventId": message.data['eventId'],
    });
  });

  // ON CLICK
  FirebaseMessaging.onMessageOpenedApp.listen((message) async {
    final eventId = message.data['eventId'];

    if (eventId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EventDetailsPage(
            eventData: data,
            eventDate: null,
            eventId: eventId,
          ),
        ),
      );
    }
  });
}

//SHOW NOTIFICATION
Future<void> showNotification(RemoteMessage message) async {
  final title =
      message.notification?.title ??
      message.data['newsTitle'] ??
      "Event Update";

  final body =
      message.notification?.body ?? message.data['newsDescription'] ?? "";

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

//APP
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    handleInitialNavigation();
  }

  //handle navigation AFTER UI loads
  Future<void> handleInitialNavigation() async {
    if (initialEventId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(initialEventId)
        .get();

    if (!doc.exists) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => EventDetailsPage(
            eventData: doc.data()!,
            eventDate: null,
            eventId: initialEventId!,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(textTheme: GoogleFonts.playfairDisplayTextTheme()),
      home: const SplashScreen(),
    );
  }
}
