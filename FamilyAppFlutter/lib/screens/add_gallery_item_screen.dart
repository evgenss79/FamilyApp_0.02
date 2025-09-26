import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/gallery_item.dart';
import '../providers/auth_provider.dart';
import '../providers/gallery_data.dart';
import '../services/storage_service.dart';

class AddGalleryItemScreen extends StatefulWidget {
  const AddGalleryItemScreen({super.key});

  @override
  State<AddGalleryItemScreen> createState() => _AddGalleryItemScreenState();
}

class _AddGalleryItemScreenState extends State<AddGalleryItemScreen> {
  final Uuid _uuid = const Uuid();
  final TextEditingController _captionController = TextEditingController();

  StorageUploadTask? _uploadTask;
  StreamSubscription<double>? _progressSubscription;
  StorageUploadResult? _uploadResult;
  File? _selectedFile;
  String? _fileName;
  double _progress = 0;
  bool _uploading = false;
  String? _error;
  String? _mimeType;

  @override
  void dispose() {
    _progressSubscription?.cancel();
    unawaited(_uploadTask?.cancel());
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.media);
    if (result == null || result.files.isEmpty) {
      return;
    }
    final PlatformFile file = result.files.single;
    final String? path = file.path;
    if (path == null) {
      return;
    }

    final File selected = File(path);
    final String? mime = lookupMimeType(path);
    if (!mounted) return;

    setState(() {
      _selectedFile = selected;
      _fileName = file.name;
      _mimeType = mime;
      _uploadResult = null;
      _progress = 0;
      _error = null;
    });

    await _startUpload(selected);
  }

  Future<void> _startUpload(File file) async {
    final StorageService storage = context.read<StorageService>();
    final GalleryData gallery = context.read<GalleryData>();

    _progressSubscription?.cancel();
    unawaited(_uploadTask?.cancel());

    final StorageUploadTask task = storage.startGalleryUpload(
      familyId: gallery.familyId,
      file: file,
    );

    setState(() {
      _uploadTask = task;
      _uploading = true;
      _progress = 0;
      _error = null;
      _uploadResult = null;
    });

    _progressSubscription = task.progress.listen(
      (double value) {
        if (!mounted) return;
        setState(() {
          _progress = value.clamp(0, 1);
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _error = error.toString();
          _uploading = false;
          _uploadTask = null;
        });
      },
    );

    try {
      final StorageUploadResult result = await task.whenComplete();
      if (!mounted) return;
      setState(() {
        _uploadTask = null;
        _uploadResult = result;
        _uploading = false;
        _progress = 1;
        _mimeType = result.mimeType ?? _mimeType;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _uploading = false;
        _uploadTask = null;
      });
    }
  }

  Future<void> _retryUpload() async {
    final File? file = _selectedFile;
    if (file == null) {
      return;
    }
    await _startUpload(file);
  }

  Future<void> _save() async {
    final StorageUploadResult? result = _uploadResult;
    if (result == null) {
      return;
    }
    final GalleryData gallery = context.read<GalleryData>();
    final AuthProvider auth = context.read<AuthProvider>();
    final DateTime now = DateTime.now().toUtc();
    final String? caption = _captionController.text.trim().isEmpty
        ? null
        : _captionController.text.trim();
    final String? mime = _mimeType;
    final GalleryMediaType mediaType = _mediaTypeFromMime(mime);

    final GalleryItem item = GalleryItem(
      id: _uuid.v4(),
      familyId: gallery.familyId,
      ownerId: auth.currentMember?.id,
      url: result.downloadUrl,
      storagePath: result.storagePath,
      mimeType: mime,
      sizeBytes: result.bytes > 0 ? result.bytes : null,
      mediaType: mediaType,
      caption: caption,
      createdAt: now,
      updatedAt: now,
    );
    await gallery.addItem(item);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _uploadResult != null && _error == null;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('addGalleryItemTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _GalleryUploadPreview(
              fileName: _fileName,
              downloadUrl: _uploadResult?.downloadUrl,
              selectedFile: _selectedFile,
              mimeType: _mimeType,
              onPick: _uploading ? null : _pickFile,
            ),
            if (_uploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.trParams('galleryUploadProgressLabel', {
                    'progress': (_progress * 100)
                        .clamp(0, 100)
                        .toStringAsFixed(0),
                  }),
                ),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('galleryUploadFailed'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _retryUpload,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('galleryRetryUpload')),
                ),
              ),
            ] else if (ready) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(context.tr('fileReadyLabel')),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: context.tr('galleryCaptionLabel'),
                hintText: context.tr('galleryCaptionHint'),
              ),
              maxLength: 120,
            ),
            const SizedBox(height: 8),
            if (_uploadResult?.bytes != null && _uploadResult!.bytes > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.trParams('galleryFileSizeLabel', {
                    'size': _formatBytes(_uploadResult!.bytes),
                  }),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ready && !_uploading ? _save : null,
                icon: const Icon(Icons.save),
                label: Text(context.tr('saveAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  GalleryMediaType _mediaTypeFromMime(String? mime) {
    if (mime == null) {
      return GalleryMediaType.image;
    }
    if (mime.startsWith('video/')) {
      return GalleryMediaType.video;
    }
    if (mime.startsWith('image/')) {
      return GalleryMediaType.image;
    }
    return GalleryMediaType.other;
  }

  String _formatBytes(int value) {
    if (value <= 0) {
      return '0 B';
    }
    const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    double size = value.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final bool useDecimals = unitIndex > 0 && size < 100;
    final String formatted = useDecimals
        ? size.toStringAsFixed(1)
        : size.toStringAsFixed(0);
    return '$formatted ${units[unitIndex]}';
  }
}

class _GalleryUploadPreview extends StatelessWidget {
  const _GalleryUploadPreview({
    required this.fileName,
    required this.downloadUrl,
    required this.selectedFile,
    required this.mimeType,
    required this.onPick,
  });

  final String? fileName;
  final String? downloadUrl;
  final File? selectedFile;
  final String? mimeType;
  final Future<void> Function()? onPick;

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (downloadUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          downloadUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    } else if (selectedFile != null &&
        (mimeType?.startsWith('image/') ?? false)) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          selectedFile!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    } else {
      preview = CircleAvatar(
        radius: 36,
        child: Icon(
          mimeType?.startsWith('video/') ?? false ? Icons.videocam : Icons.photo,
          size: 28,
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: preview,
      title: Text(fileName ?? context.tr('galleryNoFileSelected')),
      subtitle: downloadUrl != null
          ? Text(context.tr('fileReadyLabel'))
          : (onPick == null
              ? Text(context.tr('uploadingLabel'))
              : null),
      trailing: FilledButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.upload),
        label: Text(context.tr('selectMediaButton')),
      ),
    );
  }
}
