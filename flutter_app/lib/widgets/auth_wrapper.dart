import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../theme/pop_theme.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Trigger initial check if needed, though AuthProvider does it in constructor.
    // But we might want to ensure we show loading state.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return const HomeScreen();
        } else {
          // Pass isRoot: true to LoginScreen so it knows not to show back button
          // and not to pop on success (AuthWrapper will handle switch).
          return const LoginScreen(isRoot: true);
        }
      },
    );
  }
}
