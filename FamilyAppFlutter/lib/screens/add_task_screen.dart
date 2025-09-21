import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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

  // Controllers for optional task location. Latitude and longitude should be
  // provided as decimal degrees. Location name is free text.
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _locationNameController = TextEditingController();

  bool _hasDueDate = false;
  DateTime? _dueDateTime;
  String? _assignedMemberId;
  String _status = 'Pending';

  final List<String> _statuses = ['Pending', 'In Progress', 'Completed'];

  // List of reminder date/times. Users can add multiple reminders
  // for a single task. Each reminder will trigger a notification
  // separately when the time is reached. Stored as DateTime values.
  final List<DateTime> _reminders = [];

  /// Prompts the user to pick a date and time for a reminder. When both
  /// selections are made, the resulting DateTime is added to the
  /// [_reminders] list and the UI is updated.
  Future<void> _addReminder() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null) return;
    setState(() {
      _reminders.add(DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationNameController.dispose();
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
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final locationName = _locationNameController.text.trim().isEmpty
        ? null
        : _locationNameController.text.trim();
    final newTask = Task(
      id: uuid.v4(),
      title: _titleController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      endDateTime: _hasDueDate ? _dueDateTime : null,
      assignedMemberId: _assignedMemberId,
      status: _status,
      points: points,
      reminders: List<DateTime>.from(_reminders),
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    final data = Provider.of<FamilyDataV001>(context, listen: false);
    data.addTask(newTask);

    // уведомления: только Task (без второго аргумента)
    NotificationService.sendTaskCreatedNotification(newTask);
    NotificationService.scheduleDueNotifications(newTask);

    // Schedule each individual reminder (if any). This will iterate
    // through the list of reminders and schedule them via the
    // notification service. The notification service decides how to
    // handle these times (e.g. local notifications or push). If no
    // reminders are present, this loop is skipped.
    for (final reminder in _reminders) {
      NotificationService.scheduleCustomReminder(newTask, reminder);
    }

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
              // Optional location fields for geofenced reminders
              Text(
                'Location (optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 47.3769',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. 8.5417',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Location name',
                  hintText: 'e.g. Supermarket',
                ),
              ),
              const SizedBox(height: 16),
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
                    '${_dueDateTime!.day.toString().padLeft(2, '0')}. '
                    '${_dueDateTime!.month.toString().padLeft(2, '0')}. '
                    '${_dueDateTime!.year} '
                    '${_dueDateTime!.hour.toString().padLeft(2, '0')}: '
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

              const SizedBox(height: 16),
              // Section to display and add reminders
              Text(
                'Reminders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Show list of reminders with ability to remove each one
              if (_reminders.isNotEmpty)
                Column(
                  children: _reminders.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reminder = entry.value;
                    final formatted = '${reminder.day.toString().padLeft(2, '0')}. '
                        '${reminder.month.toString().padLeft(2, '0')}. '
                        '${reminder.year} '
                        '${reminder.hour.toString().padLeft(2, '0')}: '
                        '${reminder.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      key: ValueKey(reminder),
                      title: Text(formatted),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _reminders.removeAt(index);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              // Button to add a new reminder
              TextButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alert),
                label: const Text('Add Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
