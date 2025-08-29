import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
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
  DateTime? _eventDate;

  @override
  Widget build(BuildContext context) {
    // Use FamilyDataV001 provider since the project uses this version of the provider.
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
              ListTile(
                title: const Text('Event Date'),
                subtitle: Text(_eventDate != null
                    ? '${_eventDate!.toLocal()}'
                    : 'Select date and time'),
                onTap: () async {
                  // Pick a date for the event.
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    // Then pick a time on that date.
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_eventDate ?? DateTime.now()),
                    );
                    if (selectedTime != null) {
                      setState(() {
                        _eventDate = DateTime(
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
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Only save if the form is valid and a date/time has been selected.
                  if (_formKey.currentState!.validate() && _eventDate != null) {
                    final uuid = Uuid();
                    final newEvent = Event(
                      id: uuid.v4(),
                      title: _titleController.text,
                      description: _descriptionController.text,
                      date: _eventDate!,
                    );
                    familyData.addEvent(newEvent);
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