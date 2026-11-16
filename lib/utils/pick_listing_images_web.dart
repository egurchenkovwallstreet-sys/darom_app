import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedListingImage {
  final Uint8List bytes;
  final String name;

  const PickedListingImage({required this.bytes, required this.name});
}

Future<List<PickedListingImage>> pickListingImages({required int maxCount}) async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp'
    ..multiple = maxCount > 1
    ..style.display = 'none';

  html.document.body?.children.add(input);

  try {
    return await _pickWithInput(input, maxCount);
  } finally {
    input.remove();
  }
}

Future<List<PickedListingImage>> _pickWithInput(
  html.FileUploadInputElement input,
  int maxCount,
) async {
  final completer = Completer<List<PickedListingImage>>();
  var done = false;

  void finish(List<PickedListingImage> value) {
    if (done) return;
    done = true;
    if (!completer.isCompleted) completer.complete(value);
  }

  void onWindowFocus(html.Event _) {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (done) return;
      if (input.files == null || input.files!.isEmpty) {
        finish([]);
      }
    });
  }

  input.onChange.listen((_) async {
    html.window.removeEventListener('focus', onWindowFocus);
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish([]);
      return;
    }
    final result = <PickedListingImage>[];
    final limit = files.length < maxCount ? files.length : maxCount;
    for (var i = 0; i < limit; i++) {
      final file = files[i];
      final bytes = await _readFileBytes(file);
      if (bytes == null || bytes.isEmpty) continue;
      var name = file.name;
      if (name.isEmpty) name = 'photo_$i.jpg';
      result.add(PickedListingImage(bytes: bytes, name: name));
    }
    finish(result);
  });

  html.window.addEventListener('focus', onWindowFocus);
  input.click();

  try {
    return await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => [],
    );
  } finally {
    html.window.removeEventListener('focus', onWindowFocus);
  }
}

Future<Uint8List?> _readFileBytes(html.File file) async {
  final reader = html.FileReader();
  final done = Completer<Uint8List?>();
  reader.onLoadEnd.listen((_) {
    final raw = reader.result;
    if (raw is ByteBuffer) {
      done.complete(Uint8List.view(raw));
    } else if (raw is List<int>) {
      done.complete(Uint8List.fromList(raw));
    } else {
      done.complete(null);
    }
  });
  reader.onError.listen((_) => done.complete(null));
  reader.readAsArrayBuffer(file);
  return done.future;
}