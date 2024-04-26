// Import necessary packages.
import 'dart:async'; // For asynchronous operations.
import 'package:flutter/material.dart'; // Flutter material UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Flutter Blue Plus for Bluetooth functionality.

// Define a tile widget for displaying scan results.
class ScanResultTile extends StatefulWidget {
  // Constructor with required parameter: result and optional parameter: onTap callback.
  const ScanResultTile({Key? key, required this.result, this.onTap})
      : super(key: key);

  // Scan result to display in the tile.
  final ScanResult result;
  // Callback function to handle tap events on the tile.
  final VoidCallback? onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

// State class for the ScanResultTile widget.
class _ScanResultTileState extends State<ScanResultTile> {
  // Current connection state of the device associated with the scan result.
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  // Stream subscription to monitor connection state changes of the device.
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to connection state changes of the device.
    _connectionStateSubscription =
        widget.result.device.connectionState.listen((state) {
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

  // Method to convert a list of bytes to a nice hexadecimal array string.
  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  // Method to convert manufacturer data to a nice string format.
  String getNiceManufacturerData(List<List<int>> data) {
    return data
        .map((val) => '${getNiceHexArray(val)}')
        .join(', ')
        .toUpperCase();
  }

  // Method to convert service data to a nice string format.
  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries
        .map((v) => '${v.key}: ${getNiceHexArray(v.value)}')
        .join(', ')
        .toUpperCase();
  }

  // Method to convert service UUIDs to a nice string format.
  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }

  // Check if the device associated with the scan result is currently connected.
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  // Method to build the title widget of the tile.
  Widget _buildTitle(BuildContext context) {
    // Check if the platform name of the device is available.
    if (widget.result.device.platformName.isNotEmpty) {
      // If available, display platform name and remote ID.
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.result.device.platformName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            widget.result.device.remoteId.str,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          )
        ],
      );
    } else {
      // If not available, only display remote ID.
      return Text(widget.result.device.remoteId.str);
    }
  }

  // Method to build the connect button widget.
  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      // Display 'OPEN' if connected, 'CONNECT' otherwise.
      // Set button style based on connection state.
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      // Enable button tap only if device is connectable.
      onPressed:
          (widget.result.advertisementData.connectable) ? widget.onTap : null,
      child: isConnected ? const Text('OPEN') : const Text('CONNECT'),
    );
  }

  // Method to build a row widget displaying advertisement data.
  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall), // Title.
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.apply(color: Colors.white), // Value.
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // Build method to construct the UI.
  @override
  Widget build(BuildContext context) {
    var adv = widget.result.advertisementData;
    return ExpansionTile(
      // Expandable tile.
      title: _buildTitle(context), // Title.
      leading: Text(widget.result.rssi.toString(), style: const TextStyle(color: Colors.white)), // RSSI.
      trailing: _buildConnectButton(context), // Connect button.
      children: <Widget>[
        if (adv.advName.isNotEmpty)
          _buildAdvRow(context, 'Name', adv.advName), // Advertisement name.
        if (adv.txPowerLevel != null)
          _buildAdvRow(context, 'Tx Power Level',
              '${adv.txPowerLevel}'), // Tx power level.
        if ((adv.appearance ?? 0) > 0)
          _buildAdvRow(context, 'Appearance',
              '0x${adv.appearance!.toRadixString(16)}'), // Appearance.
        if (adv.msd.isNotEmpty)
          _buildAdvRow(context, 'Manufacturer Data',
              getNiceManufacturerData(adv.msd)), // Manufacturer data.
        if (adv.serviceUuids.isNotEmpty)
          _buildAdvRow(context, 'Service UUIDs',
              getNiceServiceUuids(adv.serviceUuids)), // Service UUIDs.
        if (adv.serviceData.isNotEmpty)
          _buildAdvRow(context, 'Service Data',
              getNiceServiceData(adv.serviceData)), // Service data.
      ],
    );
  }
}
