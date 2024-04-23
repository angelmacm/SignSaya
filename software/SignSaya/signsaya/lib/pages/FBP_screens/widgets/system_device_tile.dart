// Import necessary packages.
import 'dart:async'; // For asynchronous operations.
import 'package:flutter/material.dart'; // Flutter material UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Flutter Blue Plus for Bluetooth functionality.

// Define a tile widget for displaying system devices.
class SystemDeviceTile extends StatefulWidget {
  // Constructor with required parameters: device, onOpen callback, onConnect callback.
  const SystemDeviceTile({
    required this.device,
    required this.onOpen,
    required this.onConnect,
    Key? key,
  }) : super(key: key);

  // Bluetooth device to display in the tile.
  final BluetoothDevice device;
  // Callback function to handle opening the device.
  final VoidCallback onOpen;
  // Callback function to handle connecting to the device.
  final VoidCallback onConnect;

  @override
  State<SystemDeviceTile> createState() => _SystemDeviceTileState();
}

// State class for the SystemDeviceTile widget.
class _SystemDeviceTileState extends State<SystemDeviceTile> {
  // Current connection state of the device.
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  // Stream subscription to monitor connection state changes.
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to connection state changes of the device.
    _connectionStateSubscription =
        widget.device.connectionState.listen((state) {
      // Update the connection state and refresh the UI if mounted.
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed.
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  // Check if the device is currently connected.
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  // Build method to construct the UI.
  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Display the platform name of the device.
      title: Text(
        widget.device.platformName,
        style: TextStyle(color: Colors.white),
      ),
      // Display the remote ID of the device.
      subtitle: Text(
        widget.device.remoteId.str,
        style: TextStyle(color: Colors.white),
      ),
      // Display a button to either open or connect to the device based on its connection state.
      trailing: ElevatedButton(
        child: isConnected ? const Text('OPEN') : const Text('CONNECT'),
        onPressed: isConnected ? widget.onOpen : widget.onConnect,
      ),
    );
  }
}
