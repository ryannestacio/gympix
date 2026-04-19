import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class VencimentoHojeNotificationService {
  VencimentoHojeNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  static String? _lastNotifiedDateKey;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      await _requestPermissions();
      _initialized = true;
    } on MissingPluginException {
      // Ignora em ambientes sem plugin (tests/web/desktop sem implementacao).
    } on PlatformException {
      // Falha local de notificacao nao deve quebrar o fluxo da tela.
    }
  }

  Future<void> notifyDueToday({required int totalAlunos, DateTime? now}) async {
    if (totalAlunos <= 0) return;
    final reference = now ?? DateTime.now();
    final dateKey = _dateKey(reference);
    if (_lastNotifiedDateKey == dateKey) return;

    try {
      await _init();
      if (!_initialized) return;
      await _plugin.show(
        dateKey.hashCode,
        'Vencimentos de hoje',
        'Hoje terá o vencimento de $totalAlunos alunos',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vencimentos_hoje',
            'Vencimentos do dia',
            channelDescription: 'Resumo diario de vencimentos dos alunos',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      _lastNotifiedDateKey = dateKey;
    } on MissingPluginException {
      // Ignora em ambientes sem plugin.
    } on PlatformException {
      // Ignora falhas em runtime para nao interromper o app.
    }
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
