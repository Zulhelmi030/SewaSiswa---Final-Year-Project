import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:finalyearproject/routes/app_routes.dart';
import 'package:finalyearproject/core/services/auth_service.dart';
import 'package:finalyearproject/core/services/push_notification_service.dart';
import 'package:finalyearproject/core/styles/app_theme.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (with try-catch to prevent crash if google-services.json is missing/invalid)
  try {
    await Firebase.initializeApp();
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  // Initialize Supabase using env variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

/// Global Supabase client accessor — use anywhere in the app:
/// `supabase.from('table').select()`
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: Builder(
        builder: (context) {
          final authService = Provider.of<AuthService>(context, listen: false);

          return MaterialApp.router(
            title: 'SewaSiswa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode
                .system, // Automatically switches based on device settings
            routerConfig: AppRoutes.createRouter(authService),
          );
        },
      ),
    );
  }
}
