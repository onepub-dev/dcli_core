import 'dart:async';

import 'package:circular_buffer/circular_buffer.dart';

///
class AsyncCircularBuffer<T> {
  ///
  AsyncCircularBuffer(int capacity) : _buffer = CircularBuffer<T>(capacity);

  final Completer<bool> _notfull = Completer<bool>();
  Completer<bool> _more = Completer<bool>();

  final CircularBuffer<T> _buffer;

  ///
  int get length => _buffer.length;

  /// Take [count] elements from the buffer
  /// waiting if there are not sufficent elements
  Future<Iterable<T>> take(int count) async {
    if (count > _buffer.capacity) {
      throw Exception('Too few item');
    }
    while (count > _buffer.length) {
      _more = Completer<bool>();
      await _more.future;
    }
    return _buffer.take(count);
  }

  ///
  Future<void> add(T item) async {
    await _notfull.future;

    _buffer.add(item);
    // signal that more data is avaible to read.
    if (!_more.isCompleted) {
      _more.complete(true);
    }
  }
}

// class LimitedStreamController<T> implements Stream<T> {
//   ///
//   LimitedStreamController(this._limit, this._producer)
//   {
//     late StreamSubscription<T> sub;
//     sub = _producer.stream.listen((event) {
//       _count++;
//       _controller.add(event);
//       if (_count >= _limit)
//       {
//         sub.pause();
//       }
//     })
//     ..cancel();
//   }

// final StreamController<T> _producer ;
//   final _controller = StreamController<T>();

//   final int _limit;
//   int _count = 0;

//   // @override
//   // set onListen(void Function()? _onListen) => _controller.onListen = _onListen;

//   // @override
//   // void Function()? get onListen => _controller.onListen;

//   // @override
//   // set onPause(void Function()? _onPause) => _controller.onPause = _onPause;

//   // @override
//   // void Function()? get onPause => _controller.onPause;

//   // @override
//   // set onResume(void Function()? _onResume) => _controller.onResume = _onResume;

//   // @override
//   // void Function()? get onResume => _controller.onResume;

//   // @override
//   // set onCancel(void Function()? _onCancel) => _controller.onCancel = _onCancel;

//   // @override
//   // void Function()? get onCancel => _controller.onCancel;

//   @override
//   void add(T event) {
//     _count++;
//     _controller.add(event);
//     if (count >= limit)
//     _controller.
//   }

//   @override
//   void addError(Object error, [StackTrace? stackTrace]) {
//     _controller.addError(error, stackTrace);
//   }

//   @override
//   Future addStream(Stream<T> source, {bool? cancelOnError}) =>
//       _controller.addStream(source, cancelOnError: cancelOnError);

//   @override
//   Future close() => _controller.close();

//   @override
//   Future get done => _controller.done;

//   @override
//   bool get hasListener => _controller.hasListener;

//   @override
//   bool get isClosed => _controller.isClosed;

//   @override
//   bool get isPaused => _controller.isPaused;

//   // ignore: close_sinks
//   late final _sink = LimitedStreamSink<T>(this);

//   @override
//   StreamSink<T> get sink => _sink;

//   @override
//   Stream<T> get stream => _controller.stream;
// }

// ///
// class LimitedStreamSink<T> implements StreamSink<T> {
//   ///
//   LimitedStreamSink(this._controller);

//   final LimitedStreamController _controller;

//   @override
//   void add(T event) {
//     _controller.add(event);
//   }

//   @override
//   void addError(Object error, [StackTrace? stackTrace]) {
//     _controller.addError(error, stackTrace);
//   }

//   @override
//   Future addStream(Stream<T> stream) => _controller.addStream(stream);

//   @override
//   Future close() => _controller.close();

//   @override
//   Future get done => _controller.done;
// }

// class StreamLimiter<T> {
//   final controller = StreamController<T>();

//   // CircularBuffer buffer;
//   // Sink<T> sink;
//   void run() {
//     controller.stream.listen(buffer.add);
//   }
// }

// class StreamA<T> extends Stream<T> {
//   CircularBuffer buffer;

//   @override
//   StreamSubscription<T> listen(void Function(T event)? onData,
//       {Function? onError, void Function()? onDone, bool? cancelOnError}) {
//     buffer.isFilled;

//     //return StreamSubscription<T>()
//   }
// }

// /// [Stream] wrapper that only exposes the [Stream] interface.
// class StreamView<T> extends Stream<T> {
//   final Stream<T> _stream;

//   const StreamView(Stream<T> stream)
//       : _stream = stream,
//         super._internal();

//   @override
//   bool get isBroadcast => _stream.isBroadcast;

//   @override
//   Stream<T> asBroadcastStream(
//           {void Function(StreamSubscription<T> subscription)? onListen,
//           void Function(StreamSubscription<T> subscription)? onCancel}) =>
//       _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);

//   @override
//   StreamSubscription<T> listen(void Function(T value)? onData,
//           {Function? onError, void Function()? onDone, bool? cancelOnError}) 
// =>
//       _stream.listen(onData,
//           onError: onError, onDone: onDone, cancelOnError: cancelOnError);
// }
