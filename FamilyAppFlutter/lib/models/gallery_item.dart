/// Represents an item in the family photo gallery.  Each item holds
/// the identifier and the URL to the image.  Additional metadata
/// could be added such as captions or upload times.
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

  static GalleryItem fromMap(Map<String, dynamic> map) => GalleryItem(
        id: (map['id'] ?? '').toString(),
        url: map['url'] as String?,
        storagePath: map['storagePath'] as String?,
      );
}