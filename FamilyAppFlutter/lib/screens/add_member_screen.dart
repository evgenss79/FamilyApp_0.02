import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/family_member.dart';
import '../providers/family_data.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();
  DateTime? _birthday;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _birthday == null
                          ? 'No birthday selected'
                          : 'Birthday: ${_birthday!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _birthday = date;
                        });
                      }
                    },
                    child: const Text('Select Birthday'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newMember = FamilyMember(
                      id: const Uuid().v4(),
                      name: _nameController.text,
                      relationship: _relationshipController.text,
                      birthday: _birthday,
                    );
                    Provider.of<FamilyData>(contex , listen: false)
                        .addMember(newMember);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
                    }
            ],
          ),
        ),
      ),
    );
  }
}
