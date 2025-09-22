import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';

/// Screen for adding a new event.  Users may specify a title,
/// description, date range and participants.
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _participantIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    setState(() {
      _startDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? initial.hour,
        time?.minute ?? initial.minute,
      );
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = _startDate!.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final start = _startDate ?? now;
    final initial = _endDate ?? start.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: start,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    setState(() {
      _endDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? initial.hour,
        time?.minute ?? initial.minute,
      );
    });
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final start = _startDate ?? DateTime.now();
    final end = (_endDate == null || _endDate!.isBefore(start))
        ? start.add(const Duration(hours: 1))
        : _endDate!;

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description.isEmpty ? null : description,
      startDateTime: start,
      endDateTime: end,
      participantIds: _participantIds.toList(),
    );

    context.read<FamilyData>().addEvent(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<FamilyData>().members;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickStartDate,
                        child: Text(
                          _startDate == null
                              ? 'Select start'
                              : 'Start: ${_formatDate(_startDate!)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickEndDate,
                        child: Text(
                          _endDate == null
                              ? 'Select end'
                              : 'End: ${_formatDate(_endDate!)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Participants', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  const Text('Add family members to assign participants.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final FamilyMember member in members)
                        FilterChip(
                          label: Text(member.name ?? 'Unnamed'),
                          selected: _participantIds.contains(member.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _participantIds.add(member.id);
                              } else {
                                _participantIds.remove(member.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy HH:mm').format(date);
}
