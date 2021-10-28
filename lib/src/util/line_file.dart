import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dcli_core/dcli_core.dart' as core;

import 'dcli_exception.dart';

/// Provide s collection of methods to make it easy
/// to read/write a file line by line.
class LineFile {
  /// If you instantiate FileSync you MUST call [close].
  ///
  /// We rececommend that you use [withOpenFile] in prefernce to directly
  /// calling this method.
  LineFile(String path, {FileMode fileMode = FileMode.writeOnlyAppend})
      : _fileMode = fileMode {
    _file = File(path);
  }

  final FileMode _fileMode;
  late final File _file;
  late final Future<RandomAccessFile> _raf = _open(_fileMode);

  Future<RandomAccessFile> _open(FileMode fileMode) async =>
      _file.open(mode: fileMode);

  ///
  /// Flushes the contents of the file to disk.
  Future<void> flush() async => (await _raf).flush();

  /// Returns the length of the file in bytes
  /// The file does NOT have to be open
  /// to determine its length.
  Future<int> get length async => _file.length();

  /// Close and flushes the file to disk.
  Future<void> close() async => (await _raf).close();

  /// reads every line from a file calling the passed [lineAction]
  /// for each line.
  /// if you return false from a [lineAction] call then
  /// the read returns and no more lines are read.
  Stream<String> readAll() {
    var controller = StreamController<String>();
    final inputStream = _file.openRead();
    final stackTrace = core.StackTraceImpl();
    Object? exception;

    final done = Completer<bool>();

    //late StreamSubscription<String> subscription;

    // subscription =
    utf8.decoder.bind(inputStream).transform(const LineSplitter()).listen(
          (line) async {
            controller.add(line);
            // if ((await cont) == false) {
            //   await subscription
            //       .cancel()
            //       .then((finished) => done.complete(true));
            // }
          },
          cancelOnError: true,
          //ignore: avoid_types_on_closure_parameters
          onError: (Object error) {
            exception = error;
            controller.close();
            done.complete(false);
          },
          onDone: () {
            controller.close();
            done.complete(true);
          },
        );

    // await done.future;

    if (exception != null) {
      if (exception is DCliException) {
        // not an exception, the user just doesn't want to continue.
      } else {
        throw DCliException.from(exception, stackTrace);
      }
    }
    return controller.stream;
  }

  /// Truncates the file to zero bytes and
  /// then writes the given text to the file.
  /// If [newline] is null or isn't passed then the platform
  /// end of line characters are appended as defined by
  /// [Platform().eol].
  /// Pass null or an '' to [newline] to not add a line terminator.
  Future<void> write(String line, {String? newline}) async {
    final finalline = line + (newline ?? Platform().eol);
    (await _raf)
      ..truncateSync(0)
      ..setPositionSync(0)
      ..flushSync()
      ..writeStringSync(finalline);
  }

  /// Appends the [line] to the file
  /// Appends [newline] after the line.
  /// If [newline] is null or isn't passed then the platform
  /// end of line characters are appended as defined by
  /// [Platform().eol].
  /// Pass null or an '' to [newline] to not add a line terminator.
  Future<void> append(String line, {String? newline}) async {
    final finalline = line + (newline ?? Platform().eol);

    (await _raf)
      ..setPositionSync((await _raf).lengthSync())
      ..writeStringSync(finalline);
  }

  /// Reads a single line from the file.
  /// [lineDelimiter] the end of line delimiter.
  /// May be one or two characters long.
  /// Defaults to the platform specific delimiter as
  /// defined by  [Platform().eol].
  ///
  Future<String?> read({String? lineDelimiter}) async {
    lineDelimiter ??= Platform().eol;
    final line = StringBuffer();
    int byte;
    var priorChar = '';

    var foundDelimiter = false;

    while ((byte = await (await _raf).readByte()) != -1) {
      final char = utf8.decode([byte]);

      if (_isLineDelimiter(priorChar, char, lineDelimiter)) {
        foundDelimiter = true;
        break;
      }

      line.write(char);
      priorChar = char;
    }
    final endOfFile = line.isEmpty && foundDelimiter == false;
    return endOfFile ? null : line.toString();
  }

  /// Truncates the file to zero bytes in length.
  Future<void> truncate() async => (await _raf).truncate(0);

  bool _isLineDelimiter(String priorChar, String char, String lineDelimiter) {
    if (lineDelimiter.length == 1) {
      return char == lineDelimiter;
    } else {
      return priorChar + char == lineDelimiter;
    }
  }

  Future<void> open() async {
    /// accessing raf causes the file to open.
    await _raf;
  }
}

/// Opens a File and calls [action] passing in the open [LineFile].
/// When action completes the file is closed.
/// Use this method in preference to directly callling [FileSync()]
Future<R> withOpenLineFile<R>(
  String pathToFile,
  R Function(LineFile) action, {
  FileMode fileMode = FileMode.writeOnlyAppend,
}) async {
  final file = LineFile(pathToFile, fileMode: fileMode);

  await file.open();
  R result;
  try {
    result = action(file);
  } finally {
    await file.close();
  }
  return result;
}
