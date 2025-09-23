class GalleryItem {
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

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'url': url,
        'storagePath': storagePath,
        'caption': caption,
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static GalleryItem fromDecodableMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return GalleryItem(
      id: (map['id'] ?? '').toString(),
      url: map['url'] as String?,
      storagePath: map['storagePath'] as String?,
      caption: map['caption'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }
}
