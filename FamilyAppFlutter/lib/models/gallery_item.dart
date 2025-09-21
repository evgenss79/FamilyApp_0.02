import 'package:uuid/uuid.dart';

/// Represents a media item in the family gallery.
///
/// A gallery item stores the URL of the uploaded image or video along
/// with metadata such as the uploader and creation time. Further
/// enhancements might include thumbnail URLs or EXIF data.
class GalleryItem {
  final String id;
  final String url;
  final String? uploaderId;
  final DateTime createdAt;

  GalleryItem({
    String? id,
    required this.url,
    this.uploaderId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'uploaderId': uploaderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static GalleryItem fromMap(Map<String, dynamic> map) {
    return GalleryItem(
      id: map['id'] as String?,
      url: map['url'] as String,
      uploaderId: map['uploaderId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}