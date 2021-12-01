import 'dart:io';

import '../../dcli_core.dart';
import '../util/logging.dart';

// import 'package:posix/posix.dart' as posix;

///
/// Returns true if the given [path] points to a file.
///
/// ```dart
/// isFile("~/fred.jpg");
/// ```
Future<bool> isFile(String path) async => _Is().isFile(path);

/// Returns true if the given [path] is a directory.
/// ```dart
/// isDirectory("/tmp");
///
/// ```
Future<bool> isDirectory(String path) async => _Is().isDirectory(path);

/// Returns true if the given [path] is a symlink
///
/// // ```dart
/// isLink("~/fred.jpg");
/// ```
Future<bool> isLink(String path) async => _Is().isLink(path);

/// Returns true if the given path exists.
/// It may be a file, directory or link.
///
/// If [followLinks] is true (the default) then [exists]
/// will return true if the resolved path exists.
///
/// If [followLinks] is false then [exists] will return
/// true if path exist, whether its a link or not.
///
/// ```dart
/// if (exists("/fred.txt"))
/// ```
///
/// Throws [ArgumentError] if [path] is null or an empty string.
///
/// See [isLink]
///     [isDirectory]
///     [isFile]
Future<bool> exists(String path, {bool followLinks = true}) async =>
    _Is().exists(path, followLinks: followLinks);

/// Returns the datetime the path was last modified
///
/// [path[ can be either a file or a directory.
///
/// Throws a [DCliException] with a nested
/// [FileSystemException] if the file does not
/// exist or the operation fails.
Future<DateTime> lastModified(String path) async {
  try {
    return await File(path).lastModified();
  } on FileSystemException catch (e) {
    throw DCliException.from(e, StackTraceImpl());
  }
}

/// Sets the last modified datetime on the given the path.
///
/// [path] can be either a file or a directory.
///
/// Throws a [DCliException] with a nested
/// [FileSystemException] if the file does not
/// exist or the operation fails.

Future<void> setLastModifed(String path, DateTime lastModified) async {
  try {
    await File(path).setLastModified(lastModified);
  } on FileSystemException catch (e) {
    throw DCliException.from(e, StackTraceImpl());
  }
}

/// Returns true if the passed [pathToDirectory] is an
/// empty directory.
/// For large directories this operation can be expensive.
Future<bool> isEmpty(String pathToDirectory) async =>
    _Is().isEmpty(pathToDirectory);

class _Is extends DCliFunction {
  Future<bool> isFile(String path) async {
    final fromType = await FileSystemEntity.type(path);
    return fromType == FileSystemEntityType.file;
  }

  /// true if the given path is a directory.
  Future<bool> isDirectory(String path) async {
    final fromType = await FileSystemEntity.type(path);
    return fromType == FileSystemEntityType.directory;
  }

  Future<bool> isLink(String path) async {
    final fromType = await FileSystemEntity.type(path, followLinks: false);
    return fromType == FileSystemEntityType.link;
  }

  /// checks if the given [path] exists.
  ///
  /// Throws [ArgumentError] if [path] is an empty string.
  Future<bool> exists(String path, {required bool followLinks}) async {
    if (path.isEmpty) {
      throw ArgumentError('path must not be empty.');
    }

    final _exists =
        await FileSystemEntity.type(path, followLinks: followLinks) !=
            FileSystemEntityType.notFound;

    verbose(
      () => 'exists: $_exists ${truepath(path)} followLinks: $followLinks',
    );

    return _exists;
  }

  Future<DateTime> lastModified(String path) async => File(path).lastModified();

  Future<void> setLastModifed(String path, DateTime lastModified) async {
    await File(path).setLastModified(lastModified);
  }

  /// Returns true if the passed [pathToDirectory] is an
  /// empty directory.
  /// For large directories this operation can be expensive.
  Future<bool> isEmpty(String pathToDirectory) async {
    verbose(() => 'isEmpty: ${truepath(pathToDirectory)}');

    return Directory(pathToDirectory).list(followLinks: false).isEmpty;
  }
}
