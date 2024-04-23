// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Importing necessary packages and files
import 'dart:async'; // Library for asynchronous programming
import 'package:flutter/material.dart'; // Material Design UI components for Flutter
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // FlutterBluePlus for Bluetooth functionalities

import 'FBP_screens/bluetooth_off_screen.dart'; // Importing custom screen for Bluetooth off state
import 'FBP_screens/scan_screen.dart'; // Importing custom screen for Bluetooth scan

// Defining the FBPMain widget
class FBPMain extends StatefulWidget {
  const FBPMain({Key? key}) : super(key: key);

  @override
  State<FBPMain> createState() => _FBPMainState();
}

// State class for FBPMain widget
class _FBPMainState extends State<FBPMain> {
  // Initializing BluetoothAdapterState with unknown state
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  // Declaring subscription for Bluetooth adapter state changes
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  // Initialization when the stateful widget is created
  @override
  void initState() {
    super.initState();
    // Listening to Bluetooth adapter state changes
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      // Checking if the widget is still mounted before updating the state
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Cleanup when the stateful widget is removed from the widget tree
  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  // Building the UI for the FBPMain widget
  @override
  Widget build(BuildContext context) {
    // Determining which screen to display based on Bluetooth adapter state
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const ScanScreen() // Display ScanScreen if Bluetooth is on
        : BluetoothOffScreen(
            adapterState:
                _adapterState); // Display BluetoothOffScreen if Bluetooth is off

    return Scaffold(
      // Body of the scaffold contains the determined screen
      body: screen,
    );
  }
}

// Main function to run the Flutter application
void main() {
  // Setting verbose log level for FlutterBluePlus package
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  // Running the MaterialApp with FBPMain as the home screen
  runApp(const MaterialApp(
    home: FBPMain(),
  ));
}

//
// This observer listens for Bluetooth Off and dismisses the DeviceScreen
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    // Checking if the pushed route is the DeviceScreen
    if (route.settings.name == '/DeviceScreen') {
      // Start listening to Bluetooth state changes when a new route is pushed
      _adapterStateSubscription ??=
          FlutterBluePlus.adapterState.listen((state) {
        // If Bluetooth state becomes off, pop the current route
        if (state != BluetoothAdapterState.on) {
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when the route is popped
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}
