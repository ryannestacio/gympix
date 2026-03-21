import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CobrancaNotificationService {
  CobrancaNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } on MissingPluginException {
      // Ambiente sem plugin disponível (tests/web/desktop sem implementação).
    } on PlatformException {
      // Falha de inicialização local de notificações não deve quebrar o fluxo.
    }
  }

  Future<void> notify({
    required String idempotencyKey,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await init();
      if (!_initialized) return;
      await _plugin.show(
        idempotencyKey.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cobranca_automatica',
            'Cobranca automatica',
            channelDescription: 'Lembretes da regua automatica de cobranca',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } on MissingPluginException {
      // Ignora em ambientes sem plugin.
    } on PlatformException {
      // Ignora falhas em runtime para não interromper a régua.
    }
  }
}
