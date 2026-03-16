import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/cosmic_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/kundali_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/book_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kundali_generator_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/book_library_screen.dart';
import 'screens/kundali_dashboard_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const JyotishAIApp());
}

class JyotishAIApp extends StatelessWidget {
  const JyotishAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KundaliProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: MaterialApp(
        title: 'Jyotish AI',
        debugShowCheckedModeBanner: false,
        theme: CosmicTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/kundali/generate': (context) => const KundaliGeneratorScreen(),
          '/ai/chat': (context) => const AIChatScreen(),
          '/books': (context) => const BookLibraryScreen(),
          '/kundali/dashboard': (context) => const KundaliDashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
