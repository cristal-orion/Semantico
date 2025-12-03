import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/shot_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'theme/pop_theme.dart';
import 'services/notification_service.dart';

import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il servizio notifiche
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Gestisce la logica smart delle notifiche (cancella se prima di mezzogiorno)
  await notificationService.onAppOpened();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ShotProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          // Sync static theme
          PopTheme.isDarkMode = gameProvider.isDarkMode;

          return MaterialApp(
            title: 'Semantico',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: PopTheme.white,
              useMaterial3: true,
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
