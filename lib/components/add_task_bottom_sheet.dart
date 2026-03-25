import 'package:flutter/material.dart';

class AddTaskBottomSheet extends StatelessWidget {
  final VoidCallback onTextTap;
  final VoidCallback onVoiceTap;

  const AddTaskBottomSheet({
    super.key,
    required this.onTextTap,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.2,
      maxChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                "Create Task",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //
                  GestureDetector(
                    onTap: onVoiceTap,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: colors.secondaryContainer,
                          foregroundColor: colors.onSecondaryContainer,
                          child: const Icon(Icons.mic, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Voice",
                          style: TextStyle(color: colors.onSurface),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: onTextTap,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                          child: const Icon(Icons.keyboard, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text("Text", style: TextStyle(color: colors.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
