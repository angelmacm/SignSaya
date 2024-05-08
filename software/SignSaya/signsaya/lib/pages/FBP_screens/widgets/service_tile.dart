// Import necessary packages.
import 'package:flutter/material.dart'; // Flutter material UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Flutter Blue Plus for Bluetooth functionality.
import 'characteristic_tile.dart'; // Import CharacteristicTile widget.

// Define a tile widget for displaying Bluetooth services.
class ServiceTile extends StatelessWidget {
  // Constructor with required parameters: service, characteristicTiles.
  const ServiceTile({
    Key? key,
    required this.service,
    required this.characteristicTiles,
  }) : super(key: key);


  final String matchUUID1 = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
 
  // Bluetooth service to display in the tile.
  final BluetoothService service;
  // List of characteristic tiles associated with the service.
  final List<CharacteristicTile> characteristicTiles;

  // Build method to construct the UI.
  @override
  Widget build(BuildContext context) {
    return characteristicTiles.isNotEmpty
        ? ExpansionTile(
            // Expandable tile if characteristics are present.
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Service',
                    style: TextStyle(
                        color: Colors.blue)), // Title indicating service.
                buildUuid(context), // Display the UUID of the service.
              ],
            ),
            initiallyExpanded: (service.uuid.str.toUpperCase() == matchUUID1 ) ? true : false,
            children: characteristicTiles, // List of characteristic tiles.
          )
        : ListTile(
            // Regular tile if no characteristics are present.
            title: const Text('Service'), // Title indicating service.
            subtitle: buildUuid(context), // Display the UUID of the service.
          );
  }

  // Method to build and display the UUID of the service.
  Widget buildUuid(BuildContext context) {
    String uuid =
        '0x${service.uuid.str.toUpperCase()}'; // Convert UUID to string format.
    return Text(uuid,
        style: TextStyle(
            fontSize: 13)); // Display the UUID with specified font size.
  }
}
