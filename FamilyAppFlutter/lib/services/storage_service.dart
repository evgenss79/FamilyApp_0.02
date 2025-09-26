import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

/// Result of an upload operation containing both the download URL and the
/// storage path so files can be removed later.
class StorageUploadResult {
  final String downloadUrl;
  final String storagePath;
  final int bytes;
  final String? mimeType;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    this.bytes = 0,
    this.mimeType,
  });
}

/// Controller around a [UploadTask] providing download URL resolution and
/// progress tracking.
class StorageUploadTask {
  StorageUploadTask(this._task, this._ref);

  final UploadTask _task;
  final Reference _ref;

  Stream<double> get progress async* {
    await for (final TaskSnapshot snapshot in _task.snapshotEvents) {
      final int total = snapshot.totalBytes;
      if (total <= 0) {
        yield 0;
        continue;
      }
      yield snapshot.bytesTransferred / total;
    }
  }

  Future<void> cancel() => _task.cancel();

  Future<StorageUploadResult> whenComplete() async {
    final TaskSnapshot snapshot = await _task;
    final String url = await _ref.getDownloadURL();
    return StorageUploadResult(
      downloadUrl: url,
      storagePath: _ref.fullPath,
      bytes: snapshot.bytesTransferred,
      mimeType: snapshot.metadata?.contentType,
    );
  }
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
    return startGalleryUpload(
      familyId: familyId,
      file: file,
    ).whenComplete();
  }

  /// Starts a gallery upload and returns a controller that exposes progress
  /// updates. The caller must await [StorageUploadTask.whenComplete] to finish
  /// the upload and obtain the resulting URL/path pair.
  StorageUploadTask startGalleryUpload({
    required String familyId,
    required File file,
  }) {
    return _startUpload(
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

  StorageUploadTask _startUpload({
    required File file,
    required List<String> segments,
  }) {
    final Reference ref = _storage.ref().child(segments.join('/'));
    final SettableMetadata metadata = SettableMetadata(
      contentType: lookupMimeType(file.path),
    );
    final UploadTask task = ref.putFile(file, metadata);
    return StorageUploadTask(task, ref);
  }

  Future<StorageUploadResult> _uploadFile({
    required File file,
    required List<String> segments,
  }) {
    return _startUpload(file: file, segments: segments).whenComplete();
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