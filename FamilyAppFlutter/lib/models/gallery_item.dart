import '../utils/parsing.dart';

/// Photo or video stored in the shared family gallery.
class GalleryItem {
  static const Object _sentinel = Object();

  const GalleryItem({
    required this.id,
    this.url,
    this.storagePath,
    this.caption,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? url;
  final String? storagePath;
  final String? caption;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GalleryItem.fromMap(Map<String, dynamic> map) {
    return GalleryItem(
      id: (map['id'] ?? '').toString(),
      url: map['url'] as String?,
      storagePath: map['storagePath'] as String?,
      caption: map['caption'] as String?,
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'url': url,
        'storagePath': storagePath,
        'caption': caption,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  GalleryItem copyWith({
    Object? url = _sentinel,
    Object? storagePath = _sentinel,
    Object? caption = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return GalleryItem(
      id: id,
      url: url == _sentinel ? this.url : url as String?,
      storagePath: storagePath == _sentinel
          ? this.storagePath
          : storagePath as String?,
      caption: caption == _sentinel ? this.caption : caption as String?,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
