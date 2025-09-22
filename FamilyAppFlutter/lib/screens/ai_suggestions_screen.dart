import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/family_data.dart';
import '../services/ai_suggestions_service.dart';

class AiSuggestionsScreen extends StatefulWidget {
  const AiSuggestionsScreen({super.key});

  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {
  final _controller = TextEditingController();
  final _service = AiSuggestionsService();

  bool _isLoading = false;
  List<String> _suggestions = [];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestions = [];
    });

    try {
      final data = context.read<FamilyData>();
      final l10n = context.loc;

      final userPrompt = _controller.text.trim();
      final promptBuffer = StringBuffer()
        ..writeln(userPrompt.isNotEmpty
            ? userPrompt
            : l10n.translate('aiSuggestionsDefaultPrompt'))
        ..writeln(l10n.translate('aiSuggestionsContextHeader'))
        ..writeln(l10n.translateWithParams('aiSuggestionsContextMembers', {
          'count': data.members.length.toString(),
        }))
        ..writeln(l10n.translateWithParams('aiSuggestionsContextTasks', {
          'count': data.tasks.length.toString(),
        }));

      final upcomingEvents = data.events.toList()
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      final nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;
      if (nextEvent != null) {
        promptBuffer.writeln(
          l10n.translateWithParams('aiSuggestionsContextNextEvent', {
            'title': nextEvent.title,
            'date': l10n.formatDate(nextEvent.startDateTime, withTime: true),
          }),
        );
      }

      final result = await _service.getSuggestions(promptBuffer.toString());
      if (!mounted) return;
      setState(() {
        _suggestions = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.loc.translateWithParams(
          'aiSuggestionsError',
          {'error': e.toString()},
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FamilyData>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('aiSuggestions')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ContextChips(
                members: data.members.length,
                tasks: data.tasks.length,
                nextEventTitle:
                    (data.events.isNotEmpty) ? data.events.first.title : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.tr('aiSuggestionsPromptHint'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _controller.clear(),
                    tooltip: context.tr('clearAction'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(context.tr('generateAction')),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_isLoading) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              Expanded(
                child: _suggestions.isEmpty && !_isLoading
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.6),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(suggestion),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextChips extends StatelessWidget {
  final int members;
  final int tasks;
  final String? nextEventTitle;

  const _ContextChips({
    required this.members,
    required this.tasks,
    this.nextEventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      Chip(
        label: Text(
          context.loc.translateWithParams('aiSuggestionsMembersChip', {
            'count': members.toString(),
          }),
        ),
        avatar: const Icon(Icons.group, size: 18),
      ),
      Chip(
        label: Text(
          context.loc.translateWithParams('aiSuggestionsTasksChip', {
            'count': tasks.toString(),
          }),
        ),
        avatar: const Icon(Icons.checklist, size: 18),
      ),
    ];

    if (nextEventTitle != null && nextEventTitle!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            context.loc.translateWithParams('aiSuggestionsNextEventChip', {
              'title': nextEventTitle!,
            }),
          ),
          avatar: const Icon(Icons.event, size: 18),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final chip in chips) ...[chip, const SizedBox(width: 8)],
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb, size: 48),
            const SizedBox(height: 8),
            Text(
              context.tr('aiSuggestionsEmptyState'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
