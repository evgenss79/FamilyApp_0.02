import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

      // Базовый промпт из поля ввода
      final userPrompt = _controller.text.trim();

      // Лёгкий контекст из текущих данных приложения
      final membersCount = data.members.length;
      final tasksCount = data.tasks.length;

      // Вытащим ближайшее событие (если есть)
      final upcomingEvents = data.events.toList()
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      final nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

      final contextualPrompt = StringBuffer()
        ..writeln(userPrompt.isNotEmpty
            ? userPrompt
            : 'Сгенерируй полезные семейные подсказки на сегодня.')
        ..writeln('Контекст:')
        ..writeln('- членов семьи: $membersCount')
        ..writeln('- активных задач: $tasksCount');

      if (nextEvent != null) {
        contextualPrompt.writeln(
            "- ближайшее событие: ${nextEvent.title} (${_fmtDate(nextEvent.startDateTime)})");
      }

      // Вызов сервиса (у вас он может быть stub — это нормально)
      final result = await _service.getSuggestions(contextualPrompt.toString());

      if (!mounted) return;

      setState(() {
        _suggestions = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка генерации: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FamilyData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Suggestions'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Короткая справка по контексту
              _ContextChips(
                members: data.members.length,
                tasks: data.tasks.length,
                nextEventTitle:
                    (data.events.isNotEmpty) ? data.events.first.title : null,
              ),
              const SizedBox(height: 12),

              // Поле ввода промпта
              TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Что подсказать семье? (например: идеи на выходные)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _controller.clear(),
                    tooltip: 'Очистить',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Кнопка генерации
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Сгенерировать'),
                ),
              ),
              const SizedBox(height: 12),

              // Ошибка (если есть)
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Индикатор загрузки
              if (_isLoading) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],

              // Список подсказок
              Expanded(
                child: _suggestions.isEmpty && !_isLoading
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
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
                            child: Text(s),
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
        label: Text('Члены семьи: $members'),
        avatar: const Icon(Icons.group, size: 18),
      ),
      Chip(
        label: Text('Задач: $tasks'),
        avatar: const Icon(Icons.checklist, size: 18),
      ),
    ];

    if (nextEventTitle != null && nextEventTitle!.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('Ближайшее: $nextEventTitle'),
          avatar: const Icon(Icons.event, size: 18),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final c in chips) ...[c, const SizedBox(width: 8)],
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb, size: 48),
            SizedBox(height: 8),
            Text('Пока нет подсказок — введите запрос и нажмите «Сгенерировать».'),
          ],
        ),
      ),
    );
  }
}
