import 'package:family_app_flutter/utils/parsing.dart';

class GalleryItem {
  final String? id;
  final String? url;
  final String? storagePath;

  GalleryItem({this.id, this.url, this.storagePath});

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'storagePath': storagePath,
      };


  static GalleryItem fromDecodableMap(Map<String, dynamic> map) {
    return GalleryItem(
      id: (map['id'] ?? '').toString(),
      url: map['url'] as String?,
      storagePath: map['storagePath'] as String?,
      caption: map['caption'] as String?,
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }
}

