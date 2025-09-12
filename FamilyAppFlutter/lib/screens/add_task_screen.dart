import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  bool _hasDueDate = false;
  DateTime? _dueDateTime;
  String? _assignedMemberId;
  String _status = 'Pending';

  final List<String> _statuses = ['Pending', 'In Progress', 'Completed'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDateTime ?? now),
    );
    if (pickedTime == null) return;
    setState(() {
      _dueDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final uuid = const Uuid();
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;
    final newTask = Task(
      id: uuid.v4(),
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      endDateTime: _hasDueDate ? _dueDateTime : null,
      assignedMemberId: _assignedMemberId,
      status: _status,
      points: points,
    );

    final data = Provider.of<FamilyDataV001>(context, listen: false);
    data.addTask(newTask);

    // уведомления: только Task (без второго аргумента)
    NotificationService.sendTaskCreatedNotification(newTask);
    NotificationService.scheduleDueNotifications(newTask);

    Navigator.of(context).pop(); // закрыть экран после создания
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<FamilyDataV001>(context);
    final members = data.members;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Has due date/time'),
                value: _hasDueDate,
                onChanged: (value) {
                  setState(() {
                    _hasDueDate = value;
                    if (!value) _dueDateTime = null;
                  });
                  if (value) _pickDueDateTime();
                },
              ),
              if (_hasDueDate && _dueDateTime != null)
                ListTile(
                  title: Text(
                    'Due: '
                    '${_dueDateTime!.day.toString().padLeft(2, '0')}.'
                    '${_dueDateTime!.month.toString().padLeft(2, '0')}.'
                    '${_dueDateTime!.year} '
                    '${_dueDateTime!.hour.toString().padLeft(2, '0')}:'
                    '${_dueDateTime!.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDueDateTime,
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _assignedMemberId,
                decoration: const InputDecoration(labelText: 'Assign to'),
                items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                    ] +
                    members
                        .map((m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(m.name),
                            ))
                        .toList(),
                onChanged: (value) => setState(() => _assignedMemberId = value),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
