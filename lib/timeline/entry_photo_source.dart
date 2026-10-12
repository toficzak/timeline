import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Provides the media inputs accepted by a timeline entry.
///
/// Implementations keep platform media APIs outside entry forms, allowing
/// tests to provide deterministic files without invoking platform channels.
abstract interface class EntryPhotoSource {
  Future<File?> pickFromGallery();

  Future<File> captureFromCamera();
}

/// Uses the device gallery and the deterministic mock camera input.
class ImagePickerEntryPhotoSource implements EntryPhotoSource {
  ImagePickerEntryPhotoSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> pickFromGallery() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    return selected == null ? null : File(selected.path);
  }

  @override
  Future<File> captureFromCamera() async {
    final File placeholder = File(
      p.join(Directory.systemTemp.path, 'timelines-camera-placeholder.png'),
    );
    await placeholder.writeAsBytes(base64Decode(_blankPngBase64));
    return placeholder;
  }
}

// A deterministic one-pixel transparent PNG. It is only a temporary input;
// LocalPhotoStore copies it to durable application storage when saved.
const String _blankPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
