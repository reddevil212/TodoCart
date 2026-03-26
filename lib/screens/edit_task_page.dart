import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todocart/models/repeat_rule.dart';
import 'package:todocart/models/task.dart';
import 'package:todocart/provider/tasks_provider.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late final TextEditingController _titleController;
  late RepeatKind _repeatKind;
  late int _intervalMinutes;
  late int _weekday;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task.title);
    _repeatKind = widget.task.repeatRule.kind;
    _intervalMinutes = widget.task.repeatRule.intervalMinutes ?? 30;
    _weekday = widget.task.repeatRule.weekdays.isEmpty
        ? DateTime.monday
        : widget.task.repeatRule.weekdays.first;

    final dueAt = widget.task.dueAt;
    if (dueAt != null) {
      _dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);
      _time = TimeOfDay(hour: dueAt.hour, minute: dueAt.minute);
    } else if (widget.task.repeatRule.hour != null &&
        widget.task.repeatRule.minute != null) {
      _time = TimeOfDay(
        hour: widget.task.repeatRule.hour!,
        minute: widget.task.repeatRule.minute!,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          IconButton(onPressed: _saveTask, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _buildDateTimeSection(context),
          const SizedBox(height: 16),
          DropdownButtonFormField<RepeatKind>(
            value: _repeatKind,
            decoration: const InputDecoration(
              labelText: 'Repeat',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: RepeatKind.none,
                child: Text('No repeat'),
              ),
              DropdownMenuItem(
                value: RepeatKind.interval,
                child: Text('Every N minutes'),
              ),
              DropdownMenuItem(value: RepeatKind.daily, child: Text('Daily')),
              DropdownMenuItem(value: RepeatKind.weekly, child: Text('Weekly')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _repeatKind = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildRepeatEditor(context),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveTask,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    final dateText = _dueDate == null
        ? 'No date selected'
        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
    final timeText = _time.format(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('When', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Date: $dateText')),
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                    initialDate: _dueDate ?? now,
                  );

                  if (selected != null) {
                    setState(() {
                      _dueDate = selected;
                    });
                  }
                },
                child: const Text('Pick Date'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text('Time: $timeText')),
              TextButton(
                onPressed: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );

                  if (selected != null) {
                    setState(() {
                      _time = selected;
                    });
                  }
                },
                child: const Text('Pick Time'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _dueDate = null;
                });
              },
              child: const Text('Clear Date'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatEditor(BuildContext context) {
    switch (_repeatKind) {
      case RepeatKind.none:
        return const SizedBox.shrink();
      case RepeatKind.interval:
        return TextFormField(
          initialValue: _intervalMinutes.toString(),
          decoration: const InputDecoration(
            labelText: 'Interval minutes',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed > 0) {
              _intervalMinutes = parsed;
            }
          },
        );
      case RepeatKind.daily:
        return Text(
          'Repeats daily at ${_time.format(context)}',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case RepeatKind.weekly:
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _weekday,
                decoration: const InputDecoration(
                  labelText: 'Weekday',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: DateTime.monday,
                    child: Text('Monday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.tuesday,
                    child: Text('Tuesday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.wednesday,
                    child: Text('Wednesday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.thursday,
                    child: Text('Thursday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.friday,
                    child: Text('Friday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.saturday,
                    child: Text('Saturday'),
                  ),
                  DropdownMenuItem(
                    value: DateTime.sunday,
                    child: Text('Sunday'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _weekday = value;
                  });
                },
              ),
            ),
          ],
        );
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final provider = context.read<TasksProvider>();
    final repeatRule = _buildRepeatRule();
    final dueAt = _buildDueAt(repeatRule);

    final updatedTask =
        Task(
            id: widget.task.id,
            title: title,
            sourceText: widget.task.sourceText,
            dueAt: dueAt,
            repeatRule: repeatRule,
          )
          ..isCompleted = widget.task.isCompleted
          ..creationTime = widget.task.creationTime;

    await provider.updateTask(updatedTask);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  RepeatRule _buildRepeatRule() {
    switch (_repeatKind) {
      case RepeatKind.none:
        return const RepeatRule.none();
      case RepeatKind.interval:
        return RepeatRule.interval(_intervalMinutes);
      case RepeatKind.daily:
        return RepeatRule.daily(hour: _time.hour, minute: _time.minute);
      case RepeatKind.weekly:
        return RepeatRule.weekly(
          weekdays: [_weekday],
          hour: _time.hour,
          minute: _time.minute,
        );
    }
  }

  DateTime? _buildDueAt(RepeatRule repeatRule) {
    final now = DateTime.now();

    if (_dueDate != null) {
      return DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _time.hour,
        _time.minute,
      );
    }

    switch (repeatRule.kind) {
      case RepeatKind.none:
        return null;
      case RepeatKind.interval:
        return now.add(Duration(minutes: repeatRule.intervalMinutes ?? 30));
      case RepeatKind.daily:
        final today = DateTime(
          now.year,
          now.month,
          now.day,
          repeatRule.hour ?? 9,
          repeatRule.minute ?? 0,
        );
        if (today.isAfter(now)) {
          return today;
        }
        return today.add(const Duration(days: 1));
      case RepeatKind.weekly:
        var candidate = DateTime(
          now.year,
          now.month,
          now.day,
          repeatRule.hour ?? 9,
          repeatRule.minute ?? 0,
        );
        final target = repeatRule.weekdays.isEmpty
            ? DateTime.monday
            : repeatRule.weekdays.first;

        while (candidate.weekday != target || candidate.isBefore(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
    }
  }
}
