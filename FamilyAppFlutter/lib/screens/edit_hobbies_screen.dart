import 'package:flutter/material.dart';

class EditHobbiesScreen extends StatefulWidget {
  final List<String>? initialHobbies;
  const EditHobbiesScreen({this.initialHobbies, Key? key}) : super(key: key);

  @override
  State<EditHobbiesScreen> createState() => _EditHobbiesScreenState();
}

class _EditHobbiesScreenState extends State<EditHobbiesScreen> {
  late List<String> _hobbies;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hobbies = List<String>.from(widget.initialHobbies ?? []);
  }

  void _addHobby() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _hobbies.add(text);
      _controller.clear();
    });
  }

  void _removeHobby(int index) {
    setState(() {
      _hobbies.removeAt(index);
    });
  }

  void _save() => Navigator.of(context).pop(_hobbies);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Hobbies'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.save)),
      ]),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _hobbies.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_hobbies[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeHobby(index),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'New hobby'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addHobby,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
