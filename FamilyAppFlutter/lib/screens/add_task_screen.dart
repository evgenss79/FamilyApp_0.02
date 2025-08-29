import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/family_member.dart';
import '../providers/family_data_v001.dart';

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
  DateTime? _dueDate;
  DateTime? _reminderDate;
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
  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  /// Opens a date picker to select a reminder date.  The
  /// reminder can be any date in the future relative to the
  /// current day.  If the user cancels the dialog the
  /// reminder is not changed.
  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

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
      dueDate: _hasDueDate ? _dueDate : null,
      assignedMemberId: _assignedMemberId,
      status: _status,
      points: points,
      reminderDate: _reminderDate,
    );
    final data = Provider.of<FamilyDataV001>(context, listen: false);
    data.addTask(newTask);
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
                title: const Text('Has due date'),
                value: _hasDueDate,
                onChanged: (value) {
                  setState(() {
                    _hasDueDate = value;
                    if (!value) {
                      _dueDate = null;
                    }
                  });
                  if (value) {
                    _pickDueDate();
                  }
                },
              ),
              if (_hasDueDate && _dueDate != null)
                ListTile(
                  title: Text('Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDueDate,
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
              // Reminder date picker
              ListTile(
                title: Text(_reminderDate == null
                    ? 'Set reminder date'
                    : 'Reminder: ${_reminderDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.alarm),
                onTap: _pickReminderDate,
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