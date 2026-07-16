import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/theme_builder_screen.dart';
import 'screens/class_builder_screen.dart';
import 'screens/app_builder_screen.dart';
import 'screens/managers_screen.dart';
import 'screens/example_demos_screen.dart';
import 'screens/articles_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // URL strategy - remove # from URLs
  usePathUrlStrategy();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'ArkUI Build - Component Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Route handling
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => const HomeScreen(),
            settings: settings,
          );
        } else if (settings.name == '/theme-builder' || settings.name == '/theme-builder/') {
          return MaterialPageRoute(
            builder: (context) => const ThemeBuilderScreen(),
            settings: settings,
          );
        } else if (settings.name == '/class-builder' || settings.name == '/class-builder/') {
          return MaterialPageRoute(
            builder: (context) => const ClassBuilderScreen(),
            settings: settings,
          );
        } else if (settings.name == '/app-builder' || settings.name == '/app-builder/') {
          return MaterialPageRoute(
            builder: (context) => const AppBuilderScreen(),
            settings: settings,
          );
        } else if (settings.name == '/managers' || settings.name == '/managers/') {
          return MaterialPageRoute(
            builder: (context) => const ManagersScreen(),
            settings: settings,
          );
        } else if (settings.name == '/example-demos' || settings.name == '/example-demos/') {
          return MaterialPageRoute(
            builder: (context) => const ExampleDemosScreen(),
            settings: settings,
          );
        } else if (settings.name == '/medium' || settings.name == '/medium/') {
          return MaterialPageRoute(
            builder: (context) => const ArticlesScreen(source: ArticlesSource.medium),
            settings: settings,
          );
        } else if (settings.name == '/forum' || settings.name == '/forum/') {
          return MaterialPageRoute(
            builder: (context) => const ArticlesScreen(source: ArticlesSource.forum),
            settings: settings,
          );
        } else if (settings.name == '/admin' || settings.name == '/admin/') {
          return MaterialPageRoute(
            builder: (context) {
              return StreamBuilder<User?>(
                stream: authService.authStateChanges,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasData) {
                    return const AdminDashboardScreen();
                  } else {
                    return const AdminLoginScreen();
                  }
                },
              );
            },
            settings: settings,
          );
        }
        
        // Default route (404 - redirect to home)
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: settings,
        );
      },
    );
  }
}
