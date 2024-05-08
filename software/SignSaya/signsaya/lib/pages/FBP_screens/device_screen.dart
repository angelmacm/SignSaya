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
  final List<BluetoothDevice> devices;

  // Constructor to initialize with a Bluetooth device.
  const DeviceScreen({Key? key, required this.devices}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

// State class for the DeviceScreen widget.
class _DeviceScreenState extends State<DeviceScreen> {
  int? _rssi; // Signal strength of the device.
  int? _mtuSize; // Maximum Transmission Unit size.

  final Map<BluetoothDevice, BluetoothConnectionState> _connectionStates = {};
  final Map<BluetoothDevice, bool> _isConnectingMap = {};
  final Map<BluetoothDevice, bool> _isDisconnectingMap = {};
  final Map<BluetoothDevice, List<BluetoothService>> _servicesMap = {};
  final Map<BluetoothDevice, bool> _isDiscoveringServicesMap = {};
  final Map<BluetoothDevice, int?> _rssiMap = {};
  // end of newg indicating if a disconnection is in progress.

  // Stream subscriptions to monitor various Bluetooth events.
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    for (var device in widget.devices) {
      //print("You can get the service for device ${device.remoteId}");
      _isConnectingMap[device] = false;
      _isDisconnectingMap[device] = false;
      _isDiscoveringServicesMap[device] = false;

      _connectionStateSubscription =
          device.connectionState.listen((state) async {
        setState(() {
          _connectionStates[device] = state;
          if (state == BluetoothConnectionState.connected) {
            _servicesMap[device] = []; // must rediscover services
          }
        });

        if (state == BluetoothConnectionState.connected) {
          final rssi = await device.readRssi();
          setState(() {
            _rssiMap[device] = rssi;
          });
        }
        Future.delayed(const Duration(seconds: 1), () { // connect to get service automatically
          if (mounted && !_isDiscoveringServicesMap[device]!) {
            onDiscoverServicesPressed(device);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  // Check if the device is currently connected.
  // bool get isConnected {
  //   return _connectionState == BluetoothConnectionState.connected;
  // }

  // Callback function for the connect button.
  Future onConnectPressed(BluetoothDevice device) async {
    try {
      setState(() {
        _isConnectingMap[device] = true;
      });
      await device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Connect: Success", success: true);
      //print("Connect Pasok");
      try {
        _servicesMap[device] = await device.discoverServices();
        Snackbar.show(
            ABC.c, "Discover Services: Success for ${device.remoteId.toString()}",
            success: true);
      } catch (e) {
        Snackbar.show(
            ABC.c,
            prettyException(
                "Discover Services Error for ${device.remoteId.toString()}: ", e),
            success: false);
      }
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e),
            success: false);
      }
    } finally {
      setState(() {
        _isConnectingMap[device] = false;
      });
    }
  }

  // Callback function for the cancel button.
  Future onCancelPressed(BluetoothDevice device) async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Cancel Error:", e), success: false);
    }
  }

  // Callback function for the disconnect button.
  Future onDisconnectPressed(BluetoothDevice device) async {
    try {
      setState(() {
        _isDisconnectingMap[device] = true;
      });
      await device.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Disconnect Error:", e),
          success: false);
    } finally {
      setState(() {
        _isDisconnectingMap[device] = false;
      });
    }
  }

  // Callback function for discovering services button.
  Future onDiscoverServicesPressed(BluetoothDevice device) async {
    if (mounted) {
      setState(() {
        _isDiscoveringServicesMap[device] = true;
      });
    }
    try {
      _servicesMap[device] = await device.discoverServices();
      Snackbar.show(
          ABC.c, "Discover Services: Success for ${device.remoteId.toString()}",
          success: true);
    } catch (e) {
      Snackbar.show(
          ABC.c,
          prettyException(
              "Discover Services Error for ${device.remoteId.toString()}: ", e),
          success: false);
    } finally {
      if (mounted) {
        setState(() {
          _isDiscoveringServicesMap[device] = false;
        });
      }
    }
  }

  bool isConnected(BluetoothDevice device) {
    return _connectionStates[device] == BluetoothConnectionState.connected;
  }

  Future onRequestMtuPressed(BluetoothDevice device) async {
    try {
      await device.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "Request Mtu: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Change Mtu Error:", e),
          success: false);
    }
  }

  // Build a list of service tiles to display.
  List<Widget> _buildServiceTiles(BuildContext context, BluetoothDevice d) {
    List<BluetoothService>? services = _servicesMap[d];
    if (services == null) {
      return []; // or any other default value or error handling logic
    }
    return services
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
    return const Padding(
      padding:  EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context, BluetoothDevice device) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${device.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context, BluetoothDevice device) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected(device)
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(
            ((isConnected(device) && _rssiMap[device] != null)
                ? '${_rssiMap[device]!} dBm'
                : ''),
            style: Theme.of(context).textTheme.bodyText2)
      ],
    );
  }

  // Build a widget to display the button for discovering services.
  Widget buildGetServices(BuildContext context, BluetoothDevice device) {
    return IndexedStack(
      index: (_isDiscoveringServicesMap[device]!) ? 1 : 0,
      children: <Widget>[
        TextButton(
          child: const Text("Get Services"),
          onPressed: () => onDiscoverServicesPressed(device),
        ),
        const IconButton(
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget buildMtuTile(BuildContext context, BluetoothDevice device) {
    return ListTile(
        title: const Text('MTU Size'),
        subtitle: Text('${_mtuSize ?? "Unknown"} bytes'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => onRequestMtuPressed(device),
        ));
  }

  // Build the connect/disconnect button.
  Widget buildConnectButton(BuildContext context, BluetoothDevice device) {
    return Row(children: [
      if (_isConnectingMap[device]! || _isDisconnectingMap[device]!)
        buildSpinner(context),
      TextButton(
          onPressed: _isConnectingMap[device]!
              ? () => onCancelPressed(device)
              : (isConnected(device)
                  ? () => onDisconnectPressed(device)
                  : () => onConnectPressed(device)),
          child: Text(
            _isConnectingMap[device]!
                ? "CANCEL"
                : (isConnected(device) ? "DISCONNECT" : "CONNECT"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge!
                .copyWith(color: Colors.white),
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
          title: Text(widget.devices.map((d) => d.platformName).join(', ')),
          actions: [buildConnectButton(context, widget.devices.first)],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              for (var device in widget.devices) ...[
                buildRemoteId(context, device),
                ListTile(
                  leading: buildRssiTile(context, device),
                  title: Text(
                      'Device is ${_connectionStates[device]?.toString().split('.')[1] ?? 'Unknown'}.'),
                  trailing: buildGetServices(context, device),
                ),
                buildMtuTile(context, device),
                ..._buildServiceTiles(context, device),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
