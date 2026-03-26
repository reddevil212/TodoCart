import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todocart/components/add_task_bottom_sheet.dart';
import 'package:todocart/components/task_tile.dart';
import 'package:todocart/models/task.dart';
import 'package:todocart/provider/app_preferences_provider.dart';
import 'package:todocart/provider/tasks_provider.dart';
import 'package:todocart/screens/add_task_page.dart';
import 'package:todocart/screens/edit_task_page.dart';
import 'package:todocart/screens/settings_page.dart';
import 'package:todocart/services/voice/voice_command_service.dart';
import 'package:todocart/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _sortByToday = false;

  Future<void> _handleVoiceTaskWithAssistantSheet(BuildContext context) async {
    final taskProvider = context.read<TasksProvider>();
    final appPrefs = context.read<AppPreferencesProvider>();
    var started = false;

    final resultMessage = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var title = 'Listening...';
        var subtitle = 'Speak your task now';
        var loading = true;
        var success = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!started) {
              started = true;

              Future<void>(() async {
                var finalMessage = 'Could not process voice command.';

                try {
                  final voiceResult = await VoiceCommandService.instance
                      .processVoiceCommand(
                        speakFeedback: appPrefs.speakMessages,
                      );

                  setSheetState(() {
                    title = 'Processing...';
                    subtitle = 'Understanding your request';
                  });

                  if (voiceResult.structure != null) {
                    await taskProvider.addTaskFromStructure(
                      voiceResult.structure!,
                    );
                  }

                  if (!sheetContext.mounted) {
                    return;
                  }

                  finalMessage = voiceResult.message;
                  setSheetState(() {
                    loading = false;
                    success = voiceResult.success;
                    title = voiceResult.success
                        ? 'Task Ready'
                        : 'Could not process';
                    subtitle = voiceResult.message;
                  });
                } catch (_) {
                  if (!sheetContext.mounted) {
                    return;
                  }

                  finalMessage =
                      'Task created, but finishing voice flow failed. Please continue.';
                  setSheetState(() {
                    loading = false;
                    success = true;
                    title = 'Done';
                    subtitle = finalMessage;
                  });
                } finally {
                  await Future<void>.delayed(const Duration(milliseconds: 900));
                  if (!sheetContext.mounted) {
                    return;
                  }
                  Navigator.of(sheetContext).pop(finalMessage);
                }
              });

              Future<void>.delayed(const Duration(seconds: 20), () {
                if (sheetContext.mounted) {
                  Navigator.of(
                    sheetContext,
                  ).pop('Voice assistant timed out. You can try again.');
                }
              });
            }

            return _VoiceAssistantSheet(
              title: title,
              subtitle: subtitle,
              isLoading: loading,
              success: success,
            );
          },
        );
      },
    );

    if (!context.mounted || resultMessage == null) {
      return;
    }

    if (appPrefs.showMessages) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultMessage)));
    }
  }

  void _showAddOptions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.scrim.withValues(alpha: 0.35),
      builder: (context) {
        return AddTaskBottomSheet(
          onVoiceTap: () async {
            Navigator.pop(context);
            await _handleVoiceTaskWithAssistantSheet(context);
          },
          onTextTap: () {
            Navigator.pop(context);
            _openAddTaskPage(context);
          },
        );
      },
    );
  }

  Future<void> _openAddTaskPage(BuildContext context) async {
    final appPrefs = context.read<AppPreferencesProvider>();
    final resultMessage = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskPage()),
    );

    if (!context.mounted || resultMessage == null || !appPrefs.showMessages) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TasksProvider>();
    final tasks = List<Task>.from(taskProvider.tasks);
    final sortedTasks = _sortByToday ? _sortTasksByToday(tasks) : tasks;
    String user =
        'Sayan'; // for now as a placeholder, this will contain user snapshot from the cached storage.
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    double progress = tasks.isEmpty ? 0 : completedTasks / tasks.length;
    String greeting = setGreeting();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        title: Text(
          'TodoCart',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$greeting, $user ',
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Progress",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : progress,
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Your Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (tasks.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'sort_today') {
                      setState(() {
                        _sortByToday = !_sortByToday;
                      });
                    } else if (value == 'tick_all') {
                      await taskProvider.markAllCompleted();
                    } else if (value == 'clear_all') {
                      await taskProvider.clearAllTasks();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'sort_today',
                      child: Text(
                        _sortByToday
                            ? 'Disable Sort by Today'
                            : 'Sort by Today',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'tick_all',
                      child: Text('Tick All'),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear All'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(Icons.more_horiz),
                  ),
                ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: sortedTasks.length,
              itemBuilder: (context, index) {
                final task = sortedTasks[index];

                return TaskTile(
                  task: task,
                  onToggle: (value) async => taskProvider.toggleTask(task.id),
                  onDelete: () async => taskProvider.deleteTask(task.id),
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTaskPage(task: task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Task> _sortTasksByToday(List<Task> tasks) {
    final now = DateTime.now();

    tasks.sort((a, b) {
      final aDate = a.dueAt ?? a.creationTime;
      final bDate = b.dueAt ?? b.creationTime;

      final aIsToday = DateUtils.isSameDay(aDate, now);
      final bIsToday = DateUtils.isSameDay(bDate, now);

      if (aIsToday && !bIsToday) {
        return -1;
      }
      if (!aIsToday && bIsToday) {
        return 1;
      }

      return aDate.compareTo(bDate);
    });

    return tasks;
  }
}

class _VoiceAssistantSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLoading;
  final bool success;

  const _VoiceAssistantSheet({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLoading
                  ? colors.secondaryContainer
                  : success
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    success ? Icons.check_rounded : Icons.error_outline,
                    size: 34,
                    color: success ? Colors.green : Colors.red,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
