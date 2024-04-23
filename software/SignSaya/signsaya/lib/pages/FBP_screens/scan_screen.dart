import 'dart:async'; // Importing the async library for working with asynchronous operations.

import 'package:flutter/material.dart'; // Importing material.dart for building UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Importing flutter_blue_plus.dart for Bluetooth functionalities.

import 'device_screen.dart'; // Importing the device_screen.dart file.
import 'utils/snackbar.dart'; // Importing the snackbar.dart file for showing snackbars.
import 'widgets/system_device_tile.dart'; // Importing the system_device_tile.dart file for the system device tile widget.
import 'widgets/scan_result_tile.dart'; // Importing the scan_result_tile.dart file for the scan result tile widget.
import 'utils/extra.dart'; // Importing the extra.dart file for additional utilities.

class ScanScreen extends StatefulWidget {
  // Declaring the ScanScreen StatefulWidget.
  const ScanScreen({Key? key})
      : super(key: key); // Constructor for the ScanScreen widget.

  @override
  State<ScanScreen> createState() =>
      _ScanScreenState(); // Creating the state for the ScanScreen widget.
}

class _ScanScreenState extends State<ScanScreen> {
  // Defining the state class for the ScanScreen widget.
  List<BluetoothDevice> _systemDevices = []; // List to store system devices.
  List<ScanResult> _scanResults = []; // List to store scan results.
  bool _isScanning =
      false; // Boolean flag indicating whether scanning is in progress.
  late StreamSubscription<List<ScanResult>>
      _scanResultsSubscription; // Subscription for scan results stream.
  late StreamSubscription<bool>
      _isScanningSubscription; // Subscription for scanning status stream.

  @override
  void initState() {
    // Initializing the state.
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Listening to scan results stream.
      _scanResults = results; // Updating scan results list.
      if (mounted) {
        // Checking if widget is mounted before calling setState.
        setState(() {}); // Updating UI.
      }
    }, onError: (e) {
      // Handling errors from scan results stream.
      Snackbar.show(ABC.b, prettyException("Scan Error:", e),
          success: false); // Showing error message.
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      // Listening to scanning status stream.
      _isScanning = state; // Updating scanning status.
      if (mounted) {
        // Checking if widget is mounted before calling setState.
        setState(() {}); // Updating UI.
      }
    });
  }

  @override
  void dispose() {
    // Disposing the subscriptions when the widget is disposed.
    _scanResultsSubscription.cancel(); // Canceling scan results subscription.
    _isScanningSubscription.cancel(); // Canceling scanning status subscription.
    super.dispose();
  }

  Future onScanPressed() async {
    // Method to handle scan button press.
    try {
      _systemDevices =
          await FlutterBluePlus.systemDevices; // Getting system devices.
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e),
          success: false); // Showing error message.
    }
    try {
      await FlutterBluePlus.startScan(
          timeout:
              const Duration(seconds: 15)); // Starting scan with a timeout.
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false); // Showing error message.
    }
    if (mounted) {
      // Checking if widget is mounted before calling setState.
      setState(() {}); // Updating UI.
    }
  }

  Future onStopPressed() async {
    // Method to handle stop button press.
    try {
      FlutterBluePlus.stopScan(); // Stopping the scan.
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
          success: false); // Showing error message.
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    // Method to handle connect button press.
    device.connectAndUpdateStream().catchError((e) {
      // Connecting to the device and handling errors.
      Snackbar.show(ABC.c, prettyException("Connect Error:", e),
          success: false); // Showing error message.
    });
    MaterialPageRoute route = MaterialPageRoute(
        // Creating a new route for device screen.
        builder: (context) => DeviceScreen(device: device),
        settings: RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context).push(route); // Pushing the device screen route.
  }

  Future onRefresh() {
    // Method to handle refresh action.
    if (_isScanning == false) {
      // Checking if scanning is not in progress.
      FlutterBluePlus.startScan(
          timeout:
              const Duration(seconds: 15)); // Starting scan with a timeout.
    }
    if (mounted) {
      // Checking if widget is mounted before calling setState.
      setState(() {}); // Updating UI.
    }
    return Future.delayed(
        Duration(milliseconds: 500)); // Returning a delayed future.
  }

  Widget buildScanButton(BuildContext context) {
    // Method to build the scan button widget.
    if (FlutterBluePlus.isScanningNow) {
      // Checking if scanning is in progress.
      return FloatingActionButton(
        // Returning a FloatingActionButton to stop scanning.
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      // If scanning is not in progress.
      return FloatingActionButton(
          // Returning a FloatingActionButton to start scanning.
          child: const Text("SCAN"),
          onPressed: onScanPressed);
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    // Method to build system device tiles.
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            // Creating a SystemDeviceTile for each system device.
            device: d,
            onOpen: () => Navigator.of(context).push(
              // Pushing the device screen route.
              MaterialPageRoute(
                builder: (context) => DeviceScreen(device: d),
                settings: RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () =>
                onConnectPressed(d), // Handling connect button press.
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    // Method to build scan result tiles.
    return _scanResults
        .map(
          (r) => ScanResultTile(
            // Creating a ScanResultTile for each scan result.
            result: r,
            onTap: () =>
                onConnectPressed(r.device), // Handling connect button press.
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Building the UI for the ScanScreen widget.
    return ScaffoldMessenger(
      // Using ScaffoldMessenger to show snackbars.
      key: Snackbar.snackBarKeyB, // Setting the key for the scaffold messenger.
      child: Stack(
        // Using a stack to overlay components.
        children: [
          Image.asset(
            // Adding a background image to the stack.
            'lib/images/backgroundTranslation.png',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Scaffold(
            // Main scaffold for the screen.
            backgroundColor:
                Colors.transparent, // Setting background color to transparent.
            body: RefreshIndicator(
              // Adding a refresh indicator to the body.
              onRefresh: onRefresh, // Handling refresh action.
              child: Padding(
                // Adding padding to the body content.
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.22,
                  left: 16.0,
                ),
                child: ListView(
                  // Adding a ListView to display content.
                  children: <Widget>[
                    ..._buildSystemDeviceTiles(
                        context), // Adding system device tiles.
                    ..._buildScanResultTiles(
                        context), // Adding scan result tiles.
                  ],
                ),
              ),
            ),
            floatingActionButton:
                buildScanButton(context), // Adding a floating action button.
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat, // Setting FAB position.
            bottomNavigationBar: Padding(
              // Adding padding to the bottom navigation bar.
              padding: const EdgeInsets.only(
                left: 16.0,
                bottom: 16.0,
              ),
              child: GestureDetector(
                // Adding a gesture detector to the bottom navigation bar.
                onTap: () {
                  Navigator.pop(context); // Handling tap on the back button.
                },
                child: Image.asset(
                  // Adding an image for the back button.
                  'lib/images/historyBack.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
