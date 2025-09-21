import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/family_data.dart';

/// A stateful widget that presents a form for creating a new family event.
/// The event is saved into the [FamilyDataV001] provider once the form is
/// submitted and a date/time is selected.
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime ?? now),
    );
    if (pickedTime == null) return;
    setState(() {
      _startDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      // If end is null or before start, set end equal to start by default.
      if (_endDateTime == null || _endDateTime!.isBefore(_startDateTime!)) {
        _endDateTime = _startDateTime;
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    final now = DateTime.now();
    final initial = _endDateTime ?? _startDateTime ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDateTime ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;
    final end = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      _endDateTime = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyData = Provider.of<FamilyDataV001>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
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
              const SizedBox(height: 8),
              // Start date/time picker
              ListTile(
                title: const Text('Start'),
                subtitle: Text(_startDateTime != null
                    ? '${_startDateTime!.day.toString().padLeft(2, '0')}.'
                        '${_startDateTime!.month.toString().padLeft(2, '0')}.'
                        '${_startDateTime!.year} '
                        '${_startDateTime!.hour.toString().padLeft(2, '0')}:'
                        '${_startDateTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select start date and time'),
                onTap: _pickStartDateTime,
              ),
              // End date/time picker
              ListTile(
                title: const Text('End'),
                subtitle: Text(_endDateTime != null
                    ? '${_endDateTime!.day.toString().padLeft(2, '0')}.'
                        '${_endDateTime!.month.toString().padLeft(2, '0')}.'
                        '${_endDateTime!.year} '
                        '${_endDateTime!.hour.toString().padLeft(2, '0')}:'
                        '${_endDateTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select end date and time'),
                onTap: _pickEndDateTime,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_startDateTime == null || _endDateTime == null) return;
                  if (_endDateTime!.isBefore(_startDateTime!)) {
                    // Show error if end is before start.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('End time must be after start time.')),
                    );
                    return;
                  }
                  final uuid = Uuid();
                  final newEvent = Event(
                    id: uuid.v4(),
                    title: _titleController.text,
                    description: _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : null,
                    startDateTime: _startDateTime!,
                    endDateTime: _endDateTime!,
                  );
                  familyData.addEvent(newEvent);
                  Navigator.of(context).pop();
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
