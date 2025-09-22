import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/gallery_item.dart';
import '../providers/gallery_data.dart';
import '../services/storage_service.dart';

class AddGalleryItemScreen extends StatefulWidget {
  const AddGalleryItemScreen({super.key});

  @override
  State<AddGalleryItemScreen> createState() => _AddGalleryItemScreenState();
}

class _AddGalleryItemScreenState extends State<AddGalleryItemScreen> {
  final _uuid = const Uuid();
  String? _downloadUrl;
  String? _storagePath;
  String? _fileName;
  bool _uploading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFile() async {
    final storage = context.read<StorageService>();
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() {
      _uploading = true;
    });
    final file = File(path);
    try {
      final upload = await storage.uploadGalleryItem(
        familyId: context.read<GalleryData>().familyId,
        file: file,
      );
      setState(() {
        _downloadUrl = upload.downloadUrl;
        _storagePath = upload.storagePath;
        _fileName = result.files.single.name;
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_downloadUrl == null || _storagePath == null) return;
    final item = GalleryItem(
      id: _uuid.v4(),
      url: _downloadUrl,
      storagePath: _storagePath,
    );
    await context.read<GalleryData>().addItem(item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('addGalleryItemTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _downloadUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _downloadUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.photo),
              title: Text(
                _fileName ?? context.tr('galleryNoFileSelected'),
              ),
              subtitle: _uploading
                  ? Text(context.tr('uploadingLabel'))
                  : (_downloadUrl != null
                      ? Text(context.tr('fileReadyLabel'))
                      : null),
              trailing: FilledButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.upload),
                label: Text(context.tr('selectMediaButton')),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _downloadUrl == null ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(context.tr('saveAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
