import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/family_member.dart';
import '../providers/family_data.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _hasDueDate = false;
  DateTime? _dueDate;
  String? _assignedMemberId;

  @override
  Widget build(BuildContext context) {
    final familyData = Provider.of<FamilyData>(context);
    final members = familyData.members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              SwitchListTile(
                title: const Text('Has due date'),
                value: _hasDueDate,
                onChanged: (bool value) {
                  setState(() {
                    _hasDueDate = value;
                    if (!value) {
                      _dueDate = null;
                    }
                  });
                },
              ),
              if (_hasDueDate)
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(_dueDate != null
                      ? '${_dueDate!.toLocal()}'
                      : 'Select date'),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      final selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            _dueDate ?? DateTime.now()),
                      );
                      if (selectedTime != null) {
                        setState(() {
                          _dueDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              DropdownButtonFormField<String>(
                value: _assignedMemberId,
                decoration:
                    const InputDecoration(labelText: 'Assign to Member'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Unassigned'),
                  ),
                  ...members.map((member) {
                    return DropdownMenuItem<String>(
                      value: member.id,
                      child: Text(member.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _assignedMemberId = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final uuid = Uuid();
                    final newTask = Task(
                      id: uuid.v4(),
                      title: _titleController.text,
                      description: _descriptionController.text,
                      dueDate: _dueDate,
                      assignedMemberId: _assignedMemberId,
                    );
                    familyData.addTask(newTask);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
