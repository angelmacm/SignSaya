// Import necessary packages.
import 'dart:io'; // For platform-specific code.
import 'package:flutter/material.dart'; // Flutter material UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Flutter Blue Plus for Bluetooth functionality.
import 'utils/snackbar.dart'; // Custom snackbar utility.

// Define a screen widget to display when Bluetooth is off.
class BluetoothOffScreen extends StatelessWidget {
  // Constructor with optional parameter to receive Bluetooth adapter state.
  const BluetoothOffScreen({Key? key, this.adapterState}) : super(key: key);

  // Bluetooth adapter state received from parent widget.
  final BluetoothAdapterState? adapterState;

  // Build the Bluetooth off icon widget.
  Widget buildBluetoothOffIcon(BuildContext context) {
    return const Icon(
      Icons.bluetooth_disabled,
      size: 200.0,
      color: Colors.white54,
    );
  }

  // Build the title widget to display Bluetooth adapter state.
  Widget buildTitle(BuildContext context) {
    // Extract the Bluetooth adapter state string.
    String? state = adapterState?.toString().split(".").last;
    // Create and style the title text widget.
    return Text(
      'Bluetooth Adapter is ${state != null ? state : 'not available'}',
      style: Theme.of(context)
          .primaryTextTheme
          .titleSmall
          ?.copyWith(color: Colors.white),
    );
  }

  // Build the turn on button widget.
  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        child: const Text('TURN ON'),
        onPressed: () async {
          try {
            // Check if the platform is Android.
            if (Platform.isAndroid) {
              // Turn on Bluetooth using FlutterBluePlus.
              await FlutterBluePlus.turnOn();
            }
          } catch (e) {
            // Show an error snackbar if turning on Bluetooth fails.
            Snackbar.show(ABC.a, prettyException("Error Turning On:", e),
                success: false);
          }
        },
      ),
    );
  }

  // Build method to construct the UI.
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyA, // Use custom snackbar key.
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Set background color to transparent.
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'lib/images/backgroundTranslation.png', // Background image asset.
              fit: BoxFit.cover,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Display Bluetooth off icon.
                  buildBluetoothOffIcon(context),
                  // Display title indicating Bluetooth adapter state.
                  buildTitle(context),
                  // Display turn on button for Android devices.
                  if (Platform.isAndroid) buildTurnOnButton(context),
                ],
              ),
            ),
            Positioned(
              // Position the back button at the bottom left.
              bottom: screenSize.height *
                  0.1, // Adjust the bottom position as needed.
              left: screenSize.width * 0.38, // Center horizontally.
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to previous screen.
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF011F4B), // Button background color.
                  shape: const CircleBorder(), // Circular button shape.
                ),
                child: Image.asset(
                  'lib/images/historyBack.png', // Back button icon asset.
                  width: 50, // Set width.
                  height: 50, // Set height.
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
