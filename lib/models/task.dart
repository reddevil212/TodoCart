class Task {
  int id;
  String title;
  bool isCompleted = false;
  DateTime creationTime = DateTime.now();

  Task({required this.id, required this.title});
}
