import '../models/gallery_item.dart';
import 'base_firestore_repository.dart';

class GalleryRepository extends BaseFirestoreRepository<GalleryItem> {
  GalleryRepository()
      : super(
          collectionName: 'gallery',
          fromMap: GalleryItem.fromMap,
          toMap: (GalleryItem item) => item.toMap(),
          idSelector: (GalleryItem item) => item.id,
          sorter: (GalleryItem a, GalleryItem b) =>
              (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)),
        );
}

