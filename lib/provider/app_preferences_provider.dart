import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppPreferencesProvider with ChangeNotifier {
  static const String boxName = 'app_preferences';
  static const String showMessagesKey = 'show_messages';
  static const String speakMessagesKey = 'speak_messages';
  static const String completionNotificationKey = 'completion_notification';

  late final Box _box;
  bool _showMessages = true;
  bool _speakMessages = true;
  bool _completionNotification = true;

  bool get showMessages => _showMessages;
  bool get speakMessages => _speakMessages;
  bool get completionNotification => _completionNotification;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    _showMessages = _box.get(showMessagesKey, defaultValue: true) as bool;
    _speakMessages = _box.get(speakMessagesKey, defaultValue: true) as bool;
    _completionNotification =
        _box.get(completionNotificationKey, defaultValue: true) as bool;
    notifyListeners();
  }

  Future<void> setShowMessages(bool value) async {
    _showMessages = value;
    notifyListeners();
    await _box.put(showMessagesKey, value);
  }

  Future<void> setSpeakMessages(bool value) async {
    _speakMessages = value;
    notifyListeners();
    await _box.put(speakMessagesKey, value);
  }

  Future<void> setCompletionNotification(bool value) async {
    _completionNotification = value;
    notifyListeners();
    await _box.put(completionNotificationKey, value);
  }
}
