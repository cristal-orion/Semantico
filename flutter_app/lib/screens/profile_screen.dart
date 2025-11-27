import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/pop_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    try {
      final stats = await ApiService().getGameStats(auth.token!);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && context.mounted) {
      try {
        await context.read<AuthProvider>().uploadAvatar(pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar aggiornato con successo!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PopTheme.cyan,
      appBar: AppBar(
        title: Text('Profilo', style: PopTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PopTheme.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          
          if (user == null) {
            return const Center(child: Text('Nessun utente loggato'));
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: PopTheme.black, width: 3),
                            color: PopTheme.grey,
                          ),
                          child: ClipOval(
                            child: user.avatarPath != null
                                ? Image.network(
                                    '${ApiService.baseUrl}${user.avatarPath}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 60,
                                      color: PopTheme.black,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: PopTheme.black,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickImage(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PopTheme.yellow,
                                shape: BoxShape.circle,
                                border: Border.all(color: PopTheme.black, width: 2),
                              ),
                              child: Icon(Icons.camera_alt, size: 20, color: PopTheme.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      user.username,
                      style: PopTheme.headingStyle.copyWith(fontSize: 24),
                    ),
                    if (user.email != null && !user.email!.contains('noemail.local'))
                      Text(
                        user.email!,
                        style: PopTheme.bodyStyle.copyWith(color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 32),
                    
                    if (user.avatarPath != null)
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await auth.deleteAvatar();
                          } catch (e) {
                            // Handle error
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Rimuovi Avatar', style: TextStyle(color: Colors.red)),
                      ),

                    const Divider(height: 32),

                    // Statistics Section
                    Text(
                      'STATISTICHE',
                      style: PopTheme.headingStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingStats)
                      const CircularProgressIndicator()
                    else if (_stats != null)
                      _buildStatsGrid()
                    else
                      Text(
                        'Nessuna partita giocata',
                        style: PopTheme.bodyStyle.copyWith(color: Colors.grey),
                      ),

                    const Divider(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          auth.logout();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PopTheme.black,
                          foregroundColor: PopTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('LOGOUT'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Partite',
                '${_stats!['total_games']}',
                Icons.gamepad,
                PopTheme.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Vinte',
                '${_stats!['games_won']}',
                Icons.emoji_events,
                PopTheme.yellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Streak',
                '${_stats!['current_streak']}',
                Icons.local_fire_department,
                PopTheme.magenta,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Media Tentativi',
                '${_stats!['average_attempts']}',
                Icons.trending_down,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PopTheme.black, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: PopTheme.headingStyle.copyWith(fontSize: 24),
          ),
          Text(
            label,
            style: PopTheme.bodyStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
