import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'widgets/service_tile.dart';
import 'widgets/characteristic_tile.dart';
import 'widgets/descriptor_tile.dart';
import 'utils/snackbar.dart';
import 'utils/extra.dart';

// Define a screen widget to display details of a Bluetooth device.
class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  // Constructor to initialize with a Bluetooth device.
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

// State class for the DeviceScreen widget.
class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi; // Signal strength of the device.
  int? _mtuSize; // Maximum Transmission Unit size.
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected; // Connection state.
  List<BluetoothService> _services =
      []; // List of services provided by the device.
  bool _isDiscoveringServices =
      false; // Flag indicating if services are being discovered.
  bool _isConnecting = false; // Flag indicating if a connection is in progress.
  bool _isDisconnecting =
      false; // Flag indicating if a disconnection is in progress.

  // Stream subscriptions to monitor various Bluetooth events.
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to Bluetooth connection state changes.
    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      _connectionState = state;
      // If connected, clear the services list to rediscover services.
      if (state == BluetoothConnectionState.connected) {
        _services = [];
      }
      // If connected and RSSI (Received Signal Strength Indicator) is not available, read it.
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      // Update the UI.
      if (mounted) {
        setState(() {});
      }
    });

    // Subscribe to MTU (Maximum Transmission Unit) changes.
    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    // Subscribe to connection status changes.
    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    // Subscribe to disconnection status changes.
    _isDisconnectingSubscription =
        widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions when the widget is disposed.
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    super.dispose();
  }

  // Check if the device is currently connected.
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  // Callback function for the connect button.
  Future onConnectPressed() async {
    try {
      // Attempt to connect to the device and update the connection stream.
      await widget.device.connectAndUpdateStream();
      // Show a success message.
      Snackbar.show(ABC.c, "Connect: Success", success: true);
    } catch (e) {
      // Handle connection errors.
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // Ignore connections canceled by the user.
      } else {
        // Show an error message.
        Snackbar.show(ABC.c, prettyException("Connect Error:", e),
            success: false);
      }
    }
  }

  // Callback function for the cancel button.
  Future onCancelPressed() async {
    try {
      // Attempt to cancel the connection and update the connection stream.
      await widget.device.disconnectAndUpdateStream(queue: false);
      // Show a success message.
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      // Show an error message if cancellation fails.
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  // Callback function for the disconnect button.
  Future onDisconnectPressed() async {
    try {
      // Attempt to disconnect from the device and update the connection stream.
      await widget.device.disconnectAndUpdateStream();
      // Show a success message.
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      // Show an error message if disconnection fails.
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
    }
  }

  // Callback function for discovering services button.
  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      // Discover services provided by the device.
      _services = await widget.device.discoverServices();
      // Show a success message.
      Snackbar.show(ABC.c, "Discover Services: Success", success: true);
    } catch (e) {
      // Show an error message if service discovery fails.
      Snackbar.show(ABC.c, prettyException("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  // Callback function for requesting MTU change.
  Future onRequestMtuPressed() async {
    try {
      // Request a change in MTU size.
      await widget.device.requestMtu(223, predelay: 0);
      // Show a success message.
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e) {
      // Show an error message if MTU change fails.
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e),
          success: false);
    }
  }

  // Build a list of service tiles to display.
  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map((c) => _buildCharacteristicTile(c))
                .toList(),
          ),
        )
        .toList();
  }

  // Build a characteristic tile for a given characteristic.
  CharacteristicTile _buildCharacteristicTile(BluetoothCharacteristic c) {
    return CharacteristicTile(
      characteristic: c,
      descriptorTiles:
          c.descriptors.map((d) => DescriptorTile(descriptor: d)).toList(),
    );
  }

  // Build a spinner widget.
  Widget buildSpinner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  // Build a widget to display the remote ID of the device.
  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.device.remoteId}'),
    );
  }

  // Build a widget to display the RSSI information.
  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Show a Bluetooth icon indicating connection status.
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        // Show the RSSI value if available.
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  // Build a widget to display the button for discovering services.
  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        // Button to initiate service discovery.
        TextButton(
          child: const Text("Get Services"),
          onPressed: onDiscoverServicesPressed,
        ),
        // Loading indicator while discovering services.
        const IconButton(
          icon: SizedBox(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
            width: 18.0,
            height: 18.0,
          ),
          onPressed: null,
        )
      ],
    );
  }

  // Build a widget to display the MTU information and option to change MTU.
  Widget buildMtuTile(BuildContext context) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('$_mtuSize bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onRequestMtuPressed,
        ));
  }

  // Build the connect/disconnect button.
  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      // Display spinner if connecting or disconnecting.
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      // Button to connect, disconnect, or cancel.
      TextButton(
          onPressed: _isConnecting
              ? onCancelPressed
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          child: Text(
            _isConnecting ? "CANCEL" : (isConnected ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: Colors.white),
          ))
    ]);
  }

  // Build the UI for the device screen.
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyC,
      child: Scaffold(
        appBar: AppBar(
          // Display the platform name of the device in the app bar.
          title: Text(widget.device.platformName),
          actions: [buildConnectButton(context)],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Display the remote ID of the device.
              buildRemoteId(context),
              // Display RSSI and connection status.
              ListTile(
                leading: buildRssiTile(context),
                title: Text(
                    'Device is ${_connectionState.toString().split('.')[1]}.'),
                trailing: buildGetServices(context),
              ),
              // Display MTU size and option to change MTU.
              buildMtuTile(context),
              // Display service tiles.
              ..._buildServiceTiles(context, widget.device),
            ],
          ),
        ),
      ),
    );
  }
}
