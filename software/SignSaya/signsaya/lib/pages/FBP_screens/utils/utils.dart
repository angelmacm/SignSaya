import 'dart:async'; // Importing dart:async package for asynchronous programming

// Stream controller with re-emitting latest value
class StreamControllerReemit<T> {
  T? _latestValue; // Latest value of the stream
  final StreamController<T> _controller =
      StreamController<T>.broadcast(); // Stream controller

  // Constructor with optional initial value
  StreamControllerReemit({T? initialValue}) : _latestValue = initialValue;

  // Getter for the stream
  Stream<T> get stream {
    // Return a new stream with initial value if latestValue is not null
    return _latestValue != null
        ? _controller.stream.newStreamWithInitialValue(_latestValue!)
        : _controller.stream; // Otherwise, return the stream
  }

  // Getter for the latest value
  T? get value => _latestValue;

  // Method to add a new value to the stream
  void add(T newValue) {
    _latestValue = newValue; // Update the latest value
    _controller.add(newValue); // Add the new value to the stream
  }

  // Method to close the stream controller
  Future<void> close() {
    return _controller.close(); // Close the stream controller
  }
}

// Extension for creating a new stream with initial value
extension _StreamNewStreamWithInitialValue<T> on Stream<T> {
  // Method to create a new stream with initial value
  Stream<T> newStreamWithInitialValue(T initialValue) {
    return transform(_NewStreamWithInitialValueTransformer(
        initialValue)); // Transform the stream
  }
}

// Stream transformer for creating a new stream with initial value
class _NewStreamWithInitialValueTransformer<T>
    extends StreamTransformerBase<T, T> {
  // Initial value to push to the new stream
  final T initialValue;
  late StreamController<T> controller; // Controller for the new stream
  late StreamSubscription<T>
      subscription; // Subscription to the original stream
  var listenerCount = 0; // New stream listener count

  // Constructor
  _NewStreamWithInitialValueTransformer(this.initialValue);

  // Method to bind the transformer to a stream
  @override
  Stream<T> bind(Stream<T> stream) {
    // Bind the transformer to the stream based on broadcast status
    if (stream.isBroadcast) {
      return _bind(stream, broadcast: true);
    } else {
      return _bind(stream);
    }
  }

  // Method to bind the transformer to a stream
  Stream<T> _bind(Stream<T> stream, {bool broadcast = false}) {
    // Original Stream Subscription Callbacks

    // Callback for when the original stream emits data
    void onData(T data) {
      controller.add(data); // Forward data to the new stream
    }

    // Callback for when the original stream is done
    void onDone() {
      controller.close(); // Close the new stream
    }

    // Callback for when the original stream has an error
    void onError(Object error) {
      controller.addError(error); // Forward error to the new stream
    }

    // Callback for when a client listens to the new stream
    void onListen() {
      // Emit the initial value to the new stream
      controller.add(initialValue);

      // Listen to the original stream if needed
      if (listenerCount == 0) {
        subscription = stream.listen(
          onData,
          onError: onError,
          onDone: onDone,
        );
      }

      listenerCount++; // Increment new stream listener count
    }

    // New Stream Controller Callbacks
    //A callback is like a special instruction that tells a program what to do when something specific happens, such as receiving data or finishing a task.
    // Callback for pausing the new stream (Single Subscription Only)
    void onPause() {
      subscription.pause(); // Pause the original stream
    }

    // Callback for resuming the new stream (Single Subscription Only)
    void onResume() {
      subscription.resume(); // Resume the original stream
    }

    // Callback for canceling the new stream subscription
    void onCancel() {
      listenerCount--; // Decrement new stream listener count

      // When there are no more listeners, cancel the subscription and close the controller
      if (listenerCount == 0) {
        subscription.cancel();
        controller.close();
      }
    }

    // Return New Stream

    // Create a new stream controller based on broadcast status
    if (broadcast) {
      controller = StreamController<T>.broadcast(
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<T>(
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel,
      );
    }

    return controller.stream; // Return the new stream
  }
}
