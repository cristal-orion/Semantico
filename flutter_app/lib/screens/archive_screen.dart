import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/pop_theme.dart';
import '../providers/auth_provider.dart';
import 'game_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Map<String, dynamic>> _archiveItems = [];
  bool _isLoading = true;

  // Start date of the game (as defined in backend)
  final DateTime _startDate = DateTime(2025, 11, 1);

  int? _userId;

  @override
  void initState() {
    super.initState();
    // Get userId before async operation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _userId = auth.user?.id;
      _loadArchive();
    });
  }

  Future<void> _loadArchive() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final List<Map<String, dynamic>> items = [];

    // Use stored userId for correct storage key
    final userKey = _userId != null ? 'user_${_userId}_' : 'guest_';

    // Iterate from today back to start date
    DateTime current = now;
    while (current.isAfter(_startDate) ||
        DateUtils.isSameDay(current, _startDate)) {
      final dateStr = DateFormat('yyyy-MM-dd').format(current);
      final key = '${userKey}guesses_$dateStr';
      final saved = prefs.getString(key);

      bool played = false;
      bool won = false;
      int attempts = 0;

      if (saved != null) {
        played = true;
        final List<dynamic> decoded = json.decode(saved);
        attempts = decoded.length;
        // Check if any guess was correct
        won = decoded.any((g) => g['correct'] == true);
      }

      // Calculate game number
      final gameNumber = current.difference(_startDate).inDays + 1;

      items.add({
        'date': dateStr,
        'gameNumber': gameNumber,
        'played': played,
        'won': won,
        'attempts': attempts,
      });

      current = current.subtract(const Duration(days: 1));
    }

    setState(() {
      _archiveItems = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ARCHIVIO', style: PopTheme.titleStyle),
        backgroundColor: PopTheme.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: PopTheme.black, width: 3)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: PopTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: PopTheme.cyan,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: PopTheme.black))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _archiveItems.length,
              itemBuilder: (context, index) {
                final item = _archiveItems[index];
                return _buildArchiveCard(context, item);
              },
            ),
    );
  }

  Widget _buildArchiveCard(BuildContext context, Map<String, dynamic> item) {
    final isWon = item['won'] as bool;
    final isPlayed = item['played'] as bool;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(date: item['date']),
          ),
        ).then((_) => _loadArchive()); // Reload when coming back
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: PopTheme.boxDecoration(
          color: isWon ? PopTheme.yellow : PopTheme.white,
        ),
        child: Row(
          children: [
            // Game Number
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PopTheme.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${item['gameNumber']}',
                style: PopTheme.titleStyle
                    .copyWith(color: PopTheme.white, fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),

            // Date & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['date'],
                    style: PopTheme.bodyStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  if (isWon)
                    Text(
                      '🏆 VINTO in ${item['attempts']} tentativi',
                      style: PopTheme.bodyStyle.copyWith(
                          fontSize: 14, color: Colors.orangeAccent.shade700),
                    )
                  else if (isPlayed)
                    Text(
                      '🤔 IN CORSO (${item['attempts']} tentativi)',
                      style: PopTheme.bodyStyle
                          .copyWith(fontSize: 14, color: Colors.grey),
                    )
                  else
                    Text(
                      '🆕 NON GIOCATO',
                      style: PopTheme.bodyStyle
                          .copyWith(fontSize: 14, color: PopTheme.cyan),
                    ),
                ],
              ),
            ),

            // Icon
            if (isWon)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 32)
            else if (isPlayed)
              const Icon(Icons.timelapse_rounded, color: Colors.grey, size: 32)
            else
              Icon(Icons.play_circle_fill_rounded,
                  color: PopTheme.black, size: 32),
          ],
        ),
      ),
    );
  }
}
