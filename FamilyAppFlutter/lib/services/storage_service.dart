import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

class StorageUploadResult {
  final String downloadUrl;
  final String storagePath;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<StorageUploadResult> uploadMemberAvatar({
    required String familyId,
    required File file,
  }) {
    return _uploadFile(
      file: file,
      segments: ['families', familyId, 'avatars', _uniqueFileName(file.path)],
    );
  }

  Future<StorageUploadResult> uploadGalleryItem({
    required String familyId,
    required File file,
  }) {
    return _uploadFile(
      file: file,
      segments: ['families', familyId, 'gallery', _uniqueFileName(file.path)],
    );
  }

  Future<StorageUploadResult> uploadChatAttachment({
    required String familyId,
    required String conversationId,
    required File file,
  }) {
    return _uploadFile(
      file: file,
      segments: [
        'families',
        familyId,
        'conversations',
        conversationId,
        _uniqueFileName(file.path),
      ],
    );
  }

  Future<void> deleteByPath(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      // Ignore missing files.
    }
  }

  Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore errors for missing objects or invalid URLs.
    }
  }

  Future<StorageUploadResult> _uploadFile({
    required File file,
    required List<String> segments,
  }) async {
    final Reference ref = _storage.ref().child(segments.join('/'));
    final SettableMetadata metadata = SettableMetadata(
      contentType: lookupMimeType(file.path),
    );
    await ref.putFile(file, metadata);
    final String url = await ref.getDownloadURL();
    return StorageUploadResult(downloadUrl: url, storagePath: ref.fullPath);
  }

  String _uniqueFileName(String path) {
    final String extension = _extension(path);
    return '${_uuid.v4()}$extension';
  }

  String _extension(String path) {
    final int index = path.lastIndexOf('.');
    if (index == -1 || index == path.length - 1) {
      return '';
    }
    return path.substring(index);
  }
}
