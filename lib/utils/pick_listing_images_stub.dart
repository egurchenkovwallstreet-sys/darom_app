import 'dart:typed_data';

class PickedListingImage {
  final Uint8List bytes;
  final String name;

  const PickedListingImage({required this.bytes, required this.name});
}

Future<List<PickedListingImage>> pickListingImages({required int maxCount}) {
  throw UnsupportedError('pickListingImages only supported on web here; use image_picker on mobile');
}