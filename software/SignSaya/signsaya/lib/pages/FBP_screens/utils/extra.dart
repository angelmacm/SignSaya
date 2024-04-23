import 'utils.dart'; // Importing custom utility functions

import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Importing FlutterBluePlus package

// Global maps to store stream controllers for connection and disconnection states
final Map<DeviceIdentifier, StreamControllerReemit<bool>> _cglobal = {};
final Map<DeviceIdentifier, StreamControllerReemit<bool>> _dglobal = {};

/// Extension methods for BluetoothDevice class
extension Extra on BluetoothDevice {
  // Convenience method to get connection stream controller
  StreamControllerReemit<bool> get _cstream {
    // Initializing stream controller if not already initialized
    _cglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _cglobal[remoteId]!;
  }

  // Convenience method to get disconnection stream controller
  StreamControllerReemit<bool> get _dstream {
    // Initializing stream controller if not already initialized
    _dglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _dglobal[remoteId]!;
  }

  // Getter for connection stream
  Stream<bool> get isConnecting {
    return _cstream.stream;
  }

  // Getter for disconnection stream
  Stream<bool> get isDisconnecting {
    return _dstream.stream;
  }

  // Connect to the Bluetooth device and update connection stream
  Future<void> connectAndUpdateStream() async {
    _cstream.add(true); // Indicate that connection is in progress
    try {
      await connect(mtu: null); // Perform the connection
    } finally {
      _cstream.add(false); // Indicate that connection process is complete
    }
  }

  // Disconnect from the Bluetooth device and update disconnection stream
  Future<void> disconnectAndUpdateStream({bool queue = true}) async {
    _dstream.add(true); // Indicate that disconnection is in progress
    try {
      await disconnect(queue: queue); // Perform the disconnection
    } finally {
      _dstream.add(false); // Indicate that disconnection process is complete
    }
  }
}
