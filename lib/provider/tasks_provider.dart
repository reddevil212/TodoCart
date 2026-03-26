import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:todocart/models/task.dart';
import 'package:todocart/models/task_structure.dart';
import 'package:todocart/provider/app_preferences_provider.dart';
import 'package:todocart/services/api/api.dart';
import 'package:todocart/services/notifications/notifications.dart';

class TasksProvider with ChangeNotifier {
  static const String boxName = 'tasks_box';
  static const String tasksKey = 'tasks';

  final List<Task> _tasks = [];
  List<Task> get tasks => _tasks;
  bool _completionNotified = false;

  TasksProvider() {
    _init();
  }

  Future<void> _init() async {
    final box = await Hive.openBox(boxName);
    final stored =
        box.get(tasksKey, defaultValue: <dynamic>[]) as List<dynamic>;

    _tasks
      ..clear()
      ..addAll(
        stored.whereType<Map>().map(
          (item) => Task.fromMap(Map<dynamic, dynamic>.from(item)),
        ),
      );

    notifyListeners();

    for (final task in _tasks) {
      if (!task.isCompleted) {
        await NotificationService.instance.scheduleTaskReminder(task);
      }
    }
  }

  Future<void> _saveTasks() async {
    final box = await Hive.openBox(boxName);
    await box.put(tasksKey, _tasks.map((task) => task.toMap()).toList());
  }

  Future<void> _notifyIfAllCompleted() async {
    if (_tasks.isEmpty || _tasks.any((task) => !task.isCompleted)) {
      _completionNotified = false;
      return;
    }

    if (_completionNotified) {
      return;
    }

    final prefs = await Hive.openBox(AppPreferencesProvider.boxName);
    final enabled =
        prefs.get(
              AppPreferencesProvider.completionNotificationKey,
              defaultValue: true,
            )
            as bool;
    if (!enabled) {
      return;
    }

    _completionNotified = true;
    await NotificationService.instance.schedule(
      NotificationRequest(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Finished For Now😮‍💨',
        body: 'Congratulations! You completed all tasks.',
        kind: NotificationKind.immediate,
      ),
    );
  }

  Future<void> addTask(String title) async {
    final structured = await getSturcture(title);
    await addTaskFromStructure(structured);
  }

  Future<void> addTaskFromStructure(TaskStructure structured) async {
    Task newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch,
      title: structured.title,
      sourceText: structured.rawInput,
      dueAt: structured.dueAt,
      repeatRule: structured.repeatRule,
    );

    _tasks.add(newTask);
    notifyListeners();
    await _saveTasks();

    await NotificationService.instance.scheduleTaskReminder(newTask);
    await _notifyIfAllCompleted();
  }

  Future<void> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    await _saveTasks();

    await NotificationService.instance.cancelById(id);
    await _notifyIfAllCompleted();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) {
      return;
    }

    _tasks[index] = updatedTask;
    notifyListeners();
    await _saveTasks();

    await NotificationService.instance.cancelById(updatedTask.id);
    await NotificationService.instance.scheduleTaskReminder(updatedTask);
    await _notifyIfAllCompleted();
  }

  Future<void> toggleTask(int id) async {
    final task = tasks.where((task) => task.id == id);
    if (task.isNotEmpty) {
      task.first.isCompleted = !task.first.isCompleted;
      notifyListeners();
      await _saveTasks();
      await _notifyIfAllCompleted();
    }
  }

  Future<void> clearCompletedTasks() async {
    _tasks.removeWhere((task) => task.isCompleted);
    notifyListeners();
    await _saveTasks();
    await _notifyIfAllCompleted();
  }

  Future<void> markAllCompleted() async {
    for (final task in _tasks) {
      task.isCompleted = true;
    }
    notifyListeners();
    await _saveTasks();
    await _notifyIfAllCompleted();
  }

  Future<void> clearAllTasks() async {
    final ids = _tasks.map((task) => task.id).toList();
    _tasks.clear();
    notifyListeners();
    await _saveTasks();
    await _notifyIfAllCompleted();

    for (final id in ids) {
      await NotificationService.instance.cancelById(id);
    }
  }
}
