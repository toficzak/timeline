import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'timeline_repository.dart';

/// The storage boundary used by repositories to manage entry photos.
abstract interface class PhotoStore {
  Future<String> importPhoto(File source);

  Future<File> resolvePhoto(String relativePath);

  Future<void> deletePhoto(String relativePath);
}

/// Stores imported photos below [root] and exposes only paths relative to it.
class LocalPhotoStore implements PhotoStore {
  LocalPhotoStore(this.root);

  /// Creates the production store below the app-controlled support directory.
  static Future<LocalPhotoStore> create() async {
    final Directory supportDirectory = await getApplicationSupportDirectory();
    return LocalPhotoStore(Directory(p.join(supportDirectory.path, 'photos')));
  }

  final Directory root;
  int _sequence = 0;

  @override
  Future<String> importPhoto(File source) async {
    final Directory directory = Directory(p.join(root.path, 'entries'));
    await directory.create(recursive: true);
    final String extension = p.extension(source.path);
    final String name =
        '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}$extension';
    final String relativePath = p.join('entries', name);
    final String destinationPath = _absolutePath(relativePath);
    try {
      await source.copy(destinationPath);
    } catch (_) {
      final File destination = File(destinationPath);
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
    return relativePath;
  }

  @override
  Future<File> resolvePhoto(String relativePath) async {
    final String absolutePath = _absolutePath(relativePath);
    final File file = File(absolutePath);
    if (await file.exists()) {
      final String rootPath = await root.resolveSymbolicLinks();
      final String filePath = await file.resolveSymbolicLinks();
      if (filePath != rootPath && !p.isWithin(rootPath, filePath)) {
        throw InvalidPhotoPathFailure(relativePath);
      }
    }
    return file;
  }

  @override
  Future<void> deletePhoto(String relativePath) async {
    final File file = File(_absolutePath(relativePath));
    if (await file.exists()) {
      final String rootPath = await root.resolveSymbolicLinks();
      final String filePath = await file.resolveSymbolicLinks();
      if (filePath != rootPath && !p.isWithin(rootPath, filePath)) {
        throw InvalidPhotoPathFailure(relativePath);
      }
      await file.delete();
    }
  }

  String _absolutePath(String relativePath) {
    if (p.isAbsolute(relativePath)) {
      throw InvalidPhotoPathFailure(relativePath);
    }
    final String rootPath = p.normalize(p.absolute(root.path));
    final String candidate = p.normalize(p.join(rootPath, relativePath));
    if (candidate != rootPath && !p.isWithin(rootPath, candidate)) {
      throw InvalidPhotoPathFailure(relativePath);
    }
    return candidate;
  }
}
