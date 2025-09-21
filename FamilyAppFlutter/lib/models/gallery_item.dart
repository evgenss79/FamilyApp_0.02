/// Represents an item in the family photo gallery.  Each item holds
/// the identifier and the URL to the image.  Additional metadata
/// could be added such as captions or upload times.
class GalleryItem {
  final String? id;
  final String? url;

  GalleryItem({this.id, this.url});
}