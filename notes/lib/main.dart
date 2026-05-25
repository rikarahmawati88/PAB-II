import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/note_list_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/fcm_service.dart';

const String _savedLocaleKey = 'selected_locale';

Future<Locale?> _loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString(_savedLocaleKey);
  if (languageCode == null || languageCode.isEmpty) return null;
  return Locale(languageCode);
}

Future<void> _saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_savedLocaleKey, locale.languageCode);
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
  
  // If it's a data-only message (no notification object), we manually show it
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title'] ?? 'Notifikasi Baru';
    final body = message.data['body'] ?? 'Klik untuk melihat detail';

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // We need to re-initialize for the background isolate
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings, // Use named parameter
    );

    await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Locale? savedLocale;

  try {
    // Inisialisasi Firebase agar seluruh service Firebase dapat digunakan
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Mendaftarkan background handler untuk menangani
    // pesan FCM saat aplikasi berada di background/terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inisialisasi service FCM
    // Dijalankan async agar startup aplikasi lebih cepat
    FcmService().initialize().catchError((e) {
      // Menangkap error khusus saat proses inisialisasi FCM
      debugPrint('Error initializing FCM: $e');
    });

    savedLocale = await _loadSavedLocale();
  } catch (e) {
    // Menangkap error saat proses inisialisasi Firebase
    debugPrint('Error during Firebase initialization: $e');
  }

  runApp(MainApp(initialLocale: savedLocale));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.initialLocale});

  final Locale? initialLocale;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  Future<void> setLocale(Locale locale) async {
    await _saveLocale(locale);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) return _locale;
        if (locale == null) return supportedLocales.first;
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return supportedLocales.first;
      },
      home: NoteListScreen(onLocaleChanged: setLocale),
    );
  }
}