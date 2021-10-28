import 'dart:io';

import 'package:dcli_core/src/util/logging.dart';
import 'package:path/path.dart';

import '../../dcli_core.dart';

///
/// Copies the file [from] to the path [to].
///
/// ```dart
/// copy("/tmp/fred.text", "/tmp/fred2.text", overwrite=true);
/// ```
///
/// [to] may be a directory in which case the [from] filename is
/// used to construct the [to] files full path.
///
/// The [to] file must not exists unless [overwrite] is set to true.
///
/// The default for [overwrite] is false.
///
/// If an error occurs a [CopyException] is thrown.
Future<void> copy(String from, String to, {bool overwrite = false}) async =>
    await _Copy().copy(from, to, overwrite: overwrite);

class _Copy extends DCliFunction {
  Future<void> copy(String from, String to, {bool overwrite = false}) async {
    var finalto = to;
    if (await isDirectory(finalto)) {
      finalto = join(finalto, basename(from));
    }

    verbose(() => 'copy ${truepath(from)} -> ${truepath(finalto)}');

    if (overwrite == false && await exists(finalto)) {
      throw CopyException(
        'The target file ${truepath(finalto)} already exists.',
      );
    }

    try {
      await File(from).copy(finalto);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      /// lets try and improve the message.
      /// We do these checks only on failure
      /// so in the most common case (everything is correct)
      /// we don't waste cycles on unnecessary work.
      if (!await exists(from)) {
        throw CopyException('The from file ${truepath(from)} does not exists.');
      }
      if (!await exists(dirname(to))) {
        throw CopyException(
          'The to directory ${truepath(dirname(to))} does not exists.',
        );
      }

      throw CopyException(
        'An error occured copying ${truepath(from)} to ${truepath(finalto)}. '
        'Error: $e',
      );
    }
  }
}

/// Throw when the [copy] function encounters an error.
class CopyException extends DCliFunctionException {
  /// Throw when the [copy] function encounters an error.
  CopyException(String reason) : super(reason);
}