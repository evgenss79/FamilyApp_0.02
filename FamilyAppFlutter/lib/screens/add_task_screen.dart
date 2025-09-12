isendTaskCreatedNotification
NotificationService.sendTaskCreatedNotification
mNotificationService
port 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';
import '../services/notification_service.dart';

/// A screen for creating a new task with extended fields for
/// status, points and an optional reminder date.  This form lets
/// the user enter a title and description, choose a due date,
/// assign a member, select a status, set the number of points
/// rewarded for completing the task and pick a reminder date.
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
  // Reminder date removed: automatic notifications will be scheduled instead.
  String? _assignedMemberId;
  String _status = 'Pending';

  // A list of possible task statuses.  You can extend this list as needed.
  final List<String> _statuses = ['Pending', 'In Progress', 'Completed'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  /// Opens a date picker to select a due date.  If the user
  /// cancels the dialog no changes are made.  Otherwise the
  /// chosen date is stored in [_dueDate].
  /// Opens a date and time picker to select a full due date/time.  The
  /// resulting value is stored in [_dueDateTime].
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

  // Reminder picker removed: notifications will be scheduled automatically
  // based on the due date.  The original method is left here for
  // reference but commented out.

  /// Validates the form and, if valid, creates a new [Task]
  /// instance and adds it to the [FamilyDataV001] provider.  The
  /// title is required; description, due date, assigned member,
  /// status, points and reminder date are optional.  Points
  /// entered that cannot be parsed to an integer default to zero.
  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final uuid = const Uuid();
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;
    final newTask = Task(
      id: uuid.v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      endDateTime: _hasDueDate ? _dueDateTime : null,
      assignedMemberId: _assignedMemberId,
      status: _status,
      points: points,
      // Reminder date is no longer user controlled.

    );
    final data = Provider.of<FamilyDataV001>(context, listen: false);
    data.addTask(newTask);
    // Immediately notify recipients that a new task has been created and
    // schedule due reminders if a due date exists.
    NotificationService.sendTaskCreatedNotification(newTask, data);
    NotificationService.scheduleDueNotifications(newTask, data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<FamilyDataV001>(context);
    final members = data.members;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: null,
              ),
              const SizedBox(height: 8),
              // Status selector
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              // Points field
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              // Due date toggle and picker
              SwitchListTile(
                title: const Text('Has due date/time'),
                value: _hasDueDate,
                onChanged: (value) {
                  setState(() {
                    _hasDueDate = value;
                    if (!value) {
                      _dueDateTime = null;
                    }
                  });
                  if (value) {
                    _pickDueDateTime();
                  }
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
              // Assigned member selector
              DropdownButtonFormField<String>(
                value: _assignedMemberId,
                decoration: const InputDecoration(labelText: 'Assign to'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Unassigned'),
                  ),
                  ...members.map((member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _assignedMemberId = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              // The manual reminder date picker has been removed.  Reminders
              // are scheduled automatically relative to the due date.
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
