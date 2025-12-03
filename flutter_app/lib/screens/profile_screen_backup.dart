import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/pop_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService().isNotificationEnabled();
    if (mounted) {
      setState(() => _notificationsEnabled = enabled);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService().setNotificationEnabled(value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? '🔔 Notifiche abilitate - Riceverai un promemoria a mezzogiorno se non hai ancora giocato!'
              : '🔕 Notifiche disabilitate',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

                    // Impostazioni Section
                    Text(
                      'IMPOSTAZIONI',
                      style: PopTheme.headingStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),

                    _buildNotificationToggle(),

                    const Divider(height: 32),

                        icon: const Icon(Icons.logout),
                        label: const Text('LOGOUT'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context, auth),
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'Elimina Account', 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
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

  Future<void> _showDeleteAccountDialog(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Account'),
        content: const Text(
          'Sei sicuro di voler eliminare il tuo account? Questa azione è irreversibile e perderai tutti i tuoi progressi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await auth.deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pop(); // Close profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account eliminato con successo')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
      }
    }
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

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PopTheme.cyan.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PopTheme.black, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: _notificationsEnabled ? PopTheme.magenta : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifica Parola del Giorno',
                  style: PopTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Promemoria a mezzogiorno se non hai giocato',
                  style: PopTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: PopTheme.magenta,
          ),
        ],
      ),
    );
  }
}
