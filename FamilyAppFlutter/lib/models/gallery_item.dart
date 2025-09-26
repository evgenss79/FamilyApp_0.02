import '../utils/parsing.dart';

/// Supported media types for gallery entries.
enum GalleryMediaType {
  image,
  video,
  other,
}

GalleryMediaType _mediaTypeFromString(String? value) {
  switch (value) {
    case 'image':
      return GalleryMediaType.image;
    case 'video':
      return GalleryMediaType.video;
    case 'other':
      return GalleryMediaType.other;
    default:
      return GalleryMediaType.image;
  }
}

String _mediaTypeToString(GalleryMediaType type) {
  switch (type) {
    case GalleryMediaType.image:
      return 'image';
    case GalleryMediaType.video:
      return 'video';
    case GalleryMediaType.other:
      return 'other';
  }
}

/// Photo, video or document stored in the shared family gallery.
class GalleryItem {
  static const Object _sentinel = Object();

  const GalleryItem({
    required this.id,
    this.familyId,
    this.ownerId,
    this.url,
    this.thumbnailUrl,
    this.storagePath,
    this.caption,
    this.mimeType,
    this.sizeBytes,
    this.mediaType = GalleryMediaType.image,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? familyId;
  final String? ownerId;
  final String? url;
  final String? thumbnailUrl;
  final String? storagePath;
  final String? caption;
  final String? mimeType;
  final int? sizeBytes;
  final GalleryMediaType mediaType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVideo => mediaType == GalleryMediaType.video;
  bool get isImage => mediaType == GalleryMediaType.image;

  factory GalleryItem.fromMap(Map<String, dynamic> map) {
    return GalleryItem(
      id: (map['id'] ?? '').toString(),
      familyId: map['familyId'] as String?,
      ownerId: map['ownerId'] as String?,
      url: map['url'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      storagePath: map['storagePath'] as String?,
      caption: map['caption'] as String?,
      mimeType: map['mimeType'] as String?,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt(),
      mediaType: _mediaTypeFromString(map['mediaType'] as String?),
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'familyId': familyId,
        'ownerId': ownerId,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'storagePath': storagePath,
        'caption': caption,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'mediaType': _mediaTypeToString(mediaType),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  GalleryItem copyWith({
    Object? familyId = _sentinel,
    Object? ownerId = _sentinel,
    Object? url = _sentinel,
    Object? thumbnailUrl = _sentinel,
    Object? storagePath = _sentinel,
    Object? caption = _sentinel,
    Object? mimeType = _sentinel,
    Object? sizeBytes = _sentinel,
    Object? mediaType = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return GalleryItem(
      id: id,
      familyId: familyId == _sentinel ? this.familyId : familyId as String?,
      ownerId: ownerId == _sentinel ? this.ownerId : ownerId as String?,
      url: url == _sentinel ? this.url : url as String?,
      thumbnailUrl: thumbnailUrl == _sentinel
          ? this.thumbnailUrl
          : thumbnailUrl as String?,
      storagePath: storagePath == _sentinel
          ? this.storagePath
          : storagePath as String?,
      caption: caption == _sentinel ? this.caption : caption as String?,
      mimeType: mimeType == _sentinel ? this.mimeType : mimeType as String?,
      sizeBytes: sizeBytes == _sentinel ? this.sizeBytes : sizeBytes as int?,
      mediaType: mediaType == _sentinel
          ? this.mediaType
          : mediaType as GalleryMediaType,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
