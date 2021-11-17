import 'package:dcli_core/src/util/line_file.dart';
import 'package:dcli_core/src/util/logging.dart';

import '../../dcli_core.dart';

///
/// Returns count [lines] from the file at [path].
///
/// ```dart
/// head('/var/log/syslog', 10).forEach((line) => print(line));
/// ```
///
/// Throws a [HeadException] exception if [path] is not a file.
///
Future<Stream<String>> head(String path, int lines) async {
  return _Head().head(path, lines);
}

class _Head extends DCliFunction {
  Future<Stream<String>> head(
    String path,
    int lines,
  ) async {
    verbose(() => 'head ${truepath(path)} lines: $lines');

    if (!await exists(path)) {
      throw HeadException('The path ${truepath(path)} does not exist.');
    }

    if (!await isFile(path)) {
      throw HeadException('The path ${truepath(path)} is not a file.');
    }

    try {
      var count = 0;
      return withOpenLineFile(path, (file) async {
        return file.readAll().take(count);

        // .listen((line) { })
        // await file.readAll((line) async {
        //   yield line;
        //   count++;
        //   if (count >= lines) {
        //     return false;
        //   }
        //   return true;
        // });
      });
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      throw HeadException(
        'An error occured reading ${truepath(path)}. Error: $e',
      );
    } finally {}
  }
}

/// Thrown if the [head] function encounters an error.
class HeadException extends DCliFunctionException {
  /// Thrown if the [head] function encounters an error.
  HeadException(String reason) : super(reason);
}
