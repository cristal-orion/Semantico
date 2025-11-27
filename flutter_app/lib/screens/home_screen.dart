import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/pop_theme.dart';
import '../widgets/vector_background.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';
import 'shot_game_screen.dart';
import 'archive_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch daily info if needed, but GameScreen does it too
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VectorBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Profile / Login Button
              Positioned(
                top: 16,
                left: 16,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return FloatingActionButton(
                      heroTag: 'profile_btn',
                      mini: true,
                      backgroundColor: PopTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: PopTheme.black, width: 3),
                      ),
                      onPressed: () {
                        if (auth.isAuthenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                      child: auth.isAuthenticated && auth.user?.avatarPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.network(
                                '${ApiService.baseUrl}/${auth.user!.avatarPath}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  color: PopTheme.black,
                                ),
                              ),
                            )
                          : Icon(
                              auth.isAuthenticated ? Icons.person : Icons.login,
                              color: PopTheme.black,
                            ),
                    );
                  },
                ),
              ),

              // Theme Toggle
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: PopTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: PopTheme.black, width: 3),
                  ),
                  onPressed: () {
                    context.read<GameProvider>().toggleTheme();
                  },
                  child: Icon(
                    context.watch<GameProvider>().isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: PopTheme.black,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: PopTheme.boxDecoration(color: PopTheme.white)
                        .copyWith(boxShadow: PopTheme.shadow),
                    child: Image.asset(
                      'assets/images/SematicoLogotipo.png',
                      height: 60, // Adjust height as needed
                      fit: BoxFit.contain,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2000.ms, delay: 1000.ms)
                      .then()
                      .shake(hz: 4, curve: Curves.easeInOutCubic),

                  const SizedBox(height: 60),

                  // Play Button (Daily Word)
                  Consumer2<GameProvider, AuthProvider>(
                    builder: (context, gp, auth, _) {
                      final gameNumber = gp.dailyWordInfo?.gameNumber ?? '...';
                      return _buildMenuButton(
                        context,
                        label: 'PAROLA DEL GIORNO #$gameNumber',
                        icon: Icons.play_arrow_rounded,
                        color: PopTheme.yellow,
                        onPressed: () {
                          if (auth.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const GameScreen()),
                            );
                          } else {
                            _showAuthRequiredDialog(context);
                          }
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Shot Mode Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return _buildMenuButton(
                        context,
                        label: 'SHOT MODE',
                        icon: Icons.flash_on_rounded,
                        color: PopTheme.orange,
                        onPressed: () {
                          if (auth.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ShotGameScreen()),
                            );
                          } else {
                            _showAuthRequiredDialog(context);
                          }
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Archive Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return _buildMenuButton(
                        context,
                        label: 'ARCHIVIO',
                        icon: Icons.calendar_month_rounded,
                        color: PopTheme.cyan,
                        onPressed: () {
                          if (auth.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ArchiveScreen()),
                            ).then((_) {
                              // Ricarica la partita del giorno quando si torna dall'archivio
                              context.read<GameProvider>().initialize();
                            });
                          } else {
                            _showAuthRequiredDialog(context);
                          }
                        },
                      );
                    },
                  ),


                ],
              ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PopTheme.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PopTheme.black, width: 3),
            boxShadow: [
              BoxShadow(
                color: PopTheme.black,
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: PopTheme.yellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PopTheme.black, width: 3),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 40,
                  color: PopTheme.black,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Registrati per giocare!',
                style: PopTheme.headingStyle.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Crea un account per salvare i tuoi progressi e sfidare altri giocatori.',
                style: PopTheme.bodyStyle.copyWith(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PopTheme.black,
                    foregroundColor: PopTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'REGISTRATI',
                    style: PopTheme.bodyStyle.copyWith(
                      color: PopTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Hai gia un account? Accedi',
                  style: PopTheme.bodyStyle.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    Color? textColor,
    Color? borderColor,
    String? badge,
  }) {
    final effectiveTextColor = textColor ?? PopTheme.black;
    final effectiveBorderColor = borderColor ?? PopTheme.black;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: effectiveTextColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: PopTheme.radius,
                side: BorderSide(color: effectiveBorderColor, width: 3),
              ),
            ).copyWith(
              // Custom shadow effect via elevation hack or container?
              // Using standard elevation for now, but PopTheme uses hard shadows usually.
              // Let's stick to simple button for now, maybe wrap in Container for hard shadow later if requested.
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: PopTheme.bodyStyle
                      .copyWith(fontSize: 18, color: effectiveTextColor),
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PopTheme.magenta,
                border: Border.all(color: PopTheme.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: PopTheme.bodyStyle.copyWith(
                    fontSize: 10,
                    color: PopTheme.white,
                    fontWeight: FontWeight.bold),
              ),
            ).animate().scale(
                duration: 500.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.5, 0.5)),
          ),
      ],
    );
  }
}
