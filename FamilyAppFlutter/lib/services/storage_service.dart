import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

/// Result of an upload operation containing both the download URL and the
/// storage path so files can be removed later.
class StorageUploadResult {
  final String downloadUrl;
  final String storagePath;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });
}

/// Provides a thin wrapper around [FirebaseStorage] for uploading and
/// deleting files.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Uploads a file containing a member avatar.
  Future<StorageUploadResult> uploadMemberAvatar({
    required String familyId,
    required File file,
  }) {
    return _uploadFile(
      file: file,
      segments: ['families', familyId, 'avatars', _uniqueFileName(file.path)],
    );
  }

  /// Uploads a gallery media file.
  Future<StorageUploadResult> uploadGalleryItem({
    required String familyId,
    required File file,
  }) {
    return _uploadFile(
      file: file,
      segments: ['families', familyId, 'gallery', _uniqueFileName(file.path)],
    );
  }

  /// Uploads an attachment that belongs to a chat conversation.
  Future<StorageUploadResult> uploadChatAttachment({
    required String familyId,
    required String chatId,
    required File file,
  }) {
    return _uploadFile(
      file: file,
      segments: [
        'families',
        familyId,
        'chats',
        chatId,
        _uniqueFileName(file.path),
      ],
    );
  }

  /// Deletes a file by its storage path.
  Future<void> deleteByPath(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      // Ignore errors if the file has already been removed or never existed.
    }
  }

  /// Deletes a file using the download URL.
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