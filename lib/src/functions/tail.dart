import 'dart:async';

import 'package:dcli_core/src/util/line_file.dart';
import 'package:dcli_core/src/util/logging.dart';
import 'package:dcli_core/src/util/truepath.dart';

import 'package:circular_buffer/circular_buffer.dart';

import 'dcli_function.dart';
import 'is.dart';

///
/// Returns count [lines] from the end of the file at [path].
///
/// ```dart
/// tail('/var/log/syslog', 10).forEach((line) => print(line));
/// ```
///
/// Throws a [TailException] exception if [path] is not a file.
///
Stream<String> tail(String path, int lines) => _Tail().tail(path, lines);

class _Tail extends DCliFunction {
  Stream<String> tail(
    String path,
    int lines,
  ) async* {
    verbose(() => 'tail ${truepath(path)} lines: $lines');

    if (lines < 1) {
      throw TailException('lines must be >= 1');
    }

    if (!await exists(path)) {
      throw TailException('The path ${truepath(path)} does not exist.');
    }

    if (!await isFile(path)) {
      throw TailException('The path ${truepath(path)} is not a file.');
    }

    /// circbuffer requires a min size of 2 so we
    /// add one to make certain it is always greater than one
    /// and then adjust later.
    var buffer = CircularBuffer<String>(lines + 1);
    try {
      withOpenLineFile(path, (file) async {
        late final StreamSubscription<String> sub;
        sub = file.readAll().listen((line) async {
          sub.pause();
          buffer.add(line);
          sub.resume();
        });
      });
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      throw TailException(
        'An error occured reading ${truepath(path)}. Error: $e',
      );
    }

    /// adjust the buffer by stripping extra line.
    if (buffer.isFilled && buffer.isNotEmpty) buffer.removeLast();

    // return the last [lines] which will
    // be left in the bufer.
    for (final line in buffer) {
      yield line;
    }
  }
}

/// thrown when the [tail] function encounters an exception
class TailException extends DCliFunctionException {
  /// thrown when the [tail] function encounters an exception
  TailException(String reason) : super(reason);
}
