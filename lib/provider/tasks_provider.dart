import 'package:flutter/material.dart';
import 'package:todocart/models/task.dart';

class TasksProvider with ChangeNotifier {
  final List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  void addTask(String title) {
    Task newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
    );
    _tasks.add(newTask);
    notifyListeners();
  }

  void deleteTask(int id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  void toggleTask(int id) {
    final task = tasks.where((task) => task.id == id);
    if (task.isNotEmpty) {
      task.first.isCompleted = !task.first.isCompleted;
      notifyListeners();
    }
  }

  void clearCompletedTasks() {
    _tasks.removeWhere((task) => task.isCompleted);
    notifyListeners();
  }
}
