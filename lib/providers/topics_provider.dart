import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un canal (topic de FCM) al que el usuario se puede suscribir.
/// El `id` es exactamente el nombre del tema que se escribe en la
/// consola de Firebase al enviar la notificación.
class TopicInfo {
  const TopicInfo(this.id, this.name, this.description, this.icon);
  final String id;
  final String name;
  final String description;
  final IconData icon;
}

const kTopics = [
  TopicInfo('avisos', 'Avisos del vivero',
      'Horarios, cierres y novedades importantes', Icons.campaign_outlined),
  TopicInfo('riego', 'Recordatorios de riego',
      'Te avisamos cuándo toca regar tus plantas', Icons.water_drop_outlined),
  TopicInfo('promociones', 'Promociones',
      'Descuentos y plantas en oferta', Icons.local_offer_outlined),
  TopicInfo('talleres', 'Talleres',
      'Clases de cuidado de plantas en el vivero', Icons.school_outlined),
];

/// Suscripción del usuario a temas de interés (FCM Topics).
/// Se guarda en el dispositivo para mostrar los switches correctos.
class TopicsProvider extends ChangeNotifier {
  TopicsProvider(this._prefs) {
    final saved = _prefs.getStringList(_key);
    _firstRun = saved == null;
    _subscribed = saved?.toSet() ?? <String>{};
  }

  static const _key = 'fcm_topics';
  static const _defaultTopic = 'avisos';

  final SharedPreferences _prefs;
  final _messaging = FirebaseMessaging.instance;
  late Set<String> _subscribed;
  late bool _firstRun;
  final Set<String> _busy = {};

  bool isSubscribed(String id) => _subscribed.contains(id);
  bool isBusy(String id) => _busy.contains(id);

  /// La primera vez que se abre la app, suscribe al tema "avisos".
  Future<void> ensureDefaults() async {
    if (!_firstRun) return;
    _firstRun = false;
    await toggle(_defaultTopic, true);
  }

  /// Devuelve null si salió bien, o un mensaje de error.
  Future<String?> toggle(String id, bool subscribe) async {
    if (_busy.contains(id)) return null;
    _busy.add(id);
    notifyListeners();
    try {
      if (subscribe) {
        await _messaging.subscribeToTopic(id);
        _subscribed.add(id);
      } else {
        await _messaging.unsubscribeFromTopic(id);
        _subscribed.remove(id);
      }
      await _prefs.setStringList(_key, _subscribed.toList());
      return null;
    } catch (e) {
      debugPrint('[FCM] Error con el tema $id: $e');
      return 'No se pudo actualizar la suscripción. Revisa tu conexión.';
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }
}
