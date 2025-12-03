import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Random _random = Random();

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastAppOpenDateKey = 'last_app_open_date';
  static const String _lastNotificationIndexKey = 'last_notification_index';
  static const int _dailyWordNotificationId = 1;

  /// Lista di messaggi per le notifiche - titoli e corpi variabili
  static const List<Map<String, String>> _notificationMessages = [
    {
      'title': '🎯 Hai giocato oggi?',
      'body':
          'La parola del giorno ti sta aspettando! Riuscirai a indovinarla?',
    },
    {
      'title': '🧠 Allena la mente!',
      'body':
          'Una nuova sfida semantica ti aspetta. Ce la farai al primo colpo?',
    },
    {
      'title': '🔥 Non spezzare la streak!',
      'body': 'La parola di oggi è pronta. Quanto sei bravo con le parole?',
    },
    {
      'title': '💡 Momento indovinello!',
      'body':
          'Riesci a trovare la parola segreta? Solo i più astuti ci riescono!',
    },
    {
      'title': '🏆 Sfida del giorno',
      'body': 'Una parola, infinite possibilità. Accetti la sfida?',
    },
    {
      'title': '🎲 Fortuna o abilità?',
      'body': 'La parola di oggi ti metterà alla prova. Sei pronto?',
    },
    {
      'title': '⚡ Quick! Parola del giorno',
      'body': 'Non far aspettare la parola segreta. Ti sta chiamando!',
    },
    {
      'title': '🌟 Brillerai oggi?',
      'body': 'Metti alla prova il tuo vocabolario con la parola del giorno!',
    },
    {
      'title': '🎮 Game time!',
      'body': 'La sfida quotidiana è servita. Quanti tentativi ti serviranno?',
    },
    {
      'title': '🤔 Pensi di farcela?',
      'body': 'La parola di oggi potrebbe sorprenderti. Provaci!',
    },
    {
      'title': '📚 Espandi il vocabolario!',
      'body': 'Oggi imparerai qualcosa di nuovo? Gioca e scoprilo!',
    },
    {
      'title': '🎪 Lo spettacolo inizia!',
      'body': 'Il palco è tuo: indovina la parola del giorno!',
    },
  ];

  bool _isInitialized = false;

  /// Inizializza il servizio notifiche
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inizializza timezone
    tz_data.initializeTimeZones();

    // Impostazioni Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Impostazioni iOS (per futuro supporto)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;

    // Richiedi permesso notifiche (Android 13+)
    await _requestPermission();
  }

  /// Richiede permesso per le notifiche (Android 13+)
  Future<bool> _requestPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Callback quando l'utente tocca la notifica
  void _onNotificationTapped(NotificationResponse response) {
    // L'app si apre automaticamente, nessuna azione aggiuntiva necessaria
  }

  /// Chiamato quando l'app viene aperta - gestisce la logica delle notifiche intelligenti
  /// Se l'utente apre l'app prima di mezzogiorno, cancella la notifica per oggi
  /// Se l'utente apre dopo mezzogiorno o non ha aperto oggi, programma per domani
  Future<void> onAppOpened() async {
    final enabled = await isNotificationEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noon = DateTime(now.year, now.month, now.day, 12, 0);

    // Salva la data di apertura odierna
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAppOpenDateKey, today.toIso8601String());

    if (now.isBefore(noon)) {
      // L'utente ha aperto l'app prima di mezzogiorno
      // Cancella la notifica di oggi (non serve più)
      await _notifications.cancel(_dailyWordNotificationId);
      print('🌅 App aperta prima di mezzogiorno - notifica di oggi cancellata');

      // Programma la notifica per domani a mezzogiorno
      await _scheduleNotificationForTomorrow();
    } else {
      // L'utente ha aperto dopo mezzogiorno
      // Programma la notifica per domani
      await _scheduleNotificationForTomorrow();
    }
  }

  /// Programma la notifica per domani a mezzogiorno (ora locale)
  Future<void> _scheduleNotificationForTomorrow() async {
    // Cancella eventuali notifiche precedenti
    await _notifications.cancel(_dailyWordNotificationId);

    // Calcola domani a mezzogiorno
    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = now.add(const Duration(days: 1));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      12, // Mezzogiorno ora locale
      0,
      0,
    );

    // Seleziona un messaggio casuale diverso dall'ultimo usato
    final message = await _getNextNotificationMessage();

    // Dettagli notifica Android
    final androidDetails = AndroidNotificationDetails(
      'daily_word_channel',
      'Parola del Giorno',
      channelDescription: 'Promemoria per giocare alla parola del giorno',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Programma notifica singola (non ricorrente)
    await _notifications.zonedSchedule(
      _dailyWordNotificationId,
      message['title']!,
      message['body']!,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('📅 Notifica programmata per: $scheduledDate');
    print('📝 Messaggio: ${message['title']}');
  }

  /// Seleziona il prossimo messaggio assicurandosi che sia diverso dall'ultimo
  Future<Map<String, String>> _getNextNotificationMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIndex = prefs.getInt(_lastNotificationIndexKey) ?? -1;

    // Genera un nuovo indice diverso dall'ultimo
    int newIndex;
    do {
      newIndex = _random.nextInt(_notificationMessages.length);
    } while (newIndex == lastIndex && _notificationMessages.length > 1);

    // Salva il nuovo indice
    await prefs.setInt(_lastNotificationIndexKey, newIndex);

    return _notificationMessages[newIndex];
  }

  /// Cancella la notifica giornaliera
  Future<void> cancelDailyWordNotification() async {
    await _notifications.cancel(_dailyWordNotificationId);
    print('🔕 Notifica giornaliera cancellata');
  }

  /// Verifica se le notifiche sono abilitate
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ??
        true; // Default: abilitate
  }

  /// Abilita/disabilita le notifiche
  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      await onAppOpened(); // Programma notifica secondo la logica smart
    } else {
      await cancelDailyWordNotification();
    }
  }

  /// Invia una notifica di test immediata
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifiche',
      channelDescription: 'Canale per testare le notifiche',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      0,
      '🧪 Test Notifica',
      'Le notifiche funzionano correttamente!',
      notificationDetails,
    );
  }
}
