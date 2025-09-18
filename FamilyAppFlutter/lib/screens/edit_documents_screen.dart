import 'package:flutter/material.dart';

class EditDocumentsScreen extends StatefulWidget {
  final List<String>? initialDocs;
  const EditDocumentsScreen({this.initialDocs, Key? key}) : super(key: key);

  @override
  State<EditDocumentsScreen> createState() => _EditDocumentsScreenState();
}

class _EditDocumentsScreenState extends State<EditDocumentsScreen> {
  late List<String> _docs;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _docs = List<String>.from(widget.initialDocs ?? []);
  }

  void _addDocument() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _docs.add(text);
      _controller.clear();
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _docs.removeAt(index);
    });
  }

  void _save() => Navigator.of(context).pop(_docs);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Documents'), actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.save)),
      ]),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _docs.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_docs[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeDocument(index),
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
                    decoration: const InputDecoration(labelText: 'New document'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addDocument,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
