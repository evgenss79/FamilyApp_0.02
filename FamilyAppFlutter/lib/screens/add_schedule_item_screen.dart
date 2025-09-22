import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../models/schedule_item.dart';
import '../providers/family_data.dart';
import '../providers/schedule_data.dart';

class AddScheduleItemScreen extends StatefulWidget {
  const AddScheduleItemScreen({super.key});

  @override
  State<AddScheduleItemScreen> createState() => _AddScheduleItemScreenState();
}

class _AddScheduleItemScreenState extends State<AddScheduleItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dateTime;
  Duration? _duration;
  String? _memberId;

  final List<Duration> _durationOptions = const [
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 3),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _dateTime ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted) return;
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    setState(() {
      _dateTime = DateTime(
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
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();
    final dateTime = _dateTime ?? DateTime.now();

    final item = ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dateTime: dateTime,
      duration: _duration,
      location: location.isEmpty ? null : location,
      notes: notes.isEmpty ? null : notes,
      memberId: _memberId,
    );

    context.read<ScheduleData>().addItem(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<FamilyData>().members;
    return Scaffold(
      appBar: AppBar(title: const Text('Add schedule item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date & time'),
                  subtitle: Text(
                    _dateTime == null
                        ? 'Not set'
                        : DateFormat('dd.MM.yyyy HH:mm').format(_dateTime!),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: _pickDateTime,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Duration?>(
                  initialValue: _duration,
                  decoration: const InputDecoration(labelText: 'Duration'),
                  items: [
                    const DropdownMenuItem<Duration?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ..._durationOptions.map(
                      (duration) => DropdownMenuItem<Duration?>(
                        value: duration,
                        child: Text('${duration.inMinutes} minutes'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _duration = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _memberId,
                  decoration: const InputDecoration(labelText: 'Assign to member'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No member'),
                    ),
                    ...members.map(
                      (FamilyMember member) => DropdownMenuItem<String?>(
                        value: member.id,
                        child: Text(member.name ?? 'Unnamed'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _memberId = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
