// Import necessary packages.
import 'dart:async'; // For asynchronous operations.
import 'dart:math'; // For random number generation.
import 'package:flutter/material.dart'; // Flutter material UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Flutter Blue Plus for Bluetooth functionality.
import '../utils/snackbar.dart'; // Import Snackbar utility.

// Define a tile widget for displaying Bluetooth descriptors.
class DescriptorTile extends StatefulWidget {
  // Constructor with required parameter: descriptor.
  const DescriptorTile({Key? key, required this.descriptor}) : super(key: key);

  // Bluetooth descriptor to display in the tile.
  final BluetoothDescriptor descriptor;

  @override
  State<DescriptorTile> createState() => _DescriptorTileState();
}

// State class for the DescriptorTile widget.
class _DescriptorTileState extends State<DescriptorTile> {
  // List to hold the value of the descriptor.
  List<int> _value = [];

  // Stream subscription to monitor changes in the descriptor's value.
  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();
    // Subscribe to the last value stream of the descriptor.
    _lastValueSubscription = widget.descriptor.lastValueStream.listen((value) {
      // Update the value and refresh the UI if mounted.
      _value = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed.
    _lastValueSubscription.cancel();
    super.dispose();
  }

  // Getter method to access the descriptor.
  BluetoothDescriptor get d => widget.descriptor;

  // Method to generate a list of random bytes.
  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  // Method to handle read operation on the descriptor.
  Future<void> onReadPressed() async {
    try {
      await d.read();
      Snackbar.show(ABC.c, "Descriptor Read : Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Descriptor Read Error:", e),
          success: false);
    }
  }

  // Method to handle write operation on the descriptor.
  Future<void> onWritePressed() async {
    try {
      await d.write(_getRandomBytes());
      Snackbar.show(ABC.c, "Descriptor Write : Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Descriptor Write Error:", e),
          success: false);
    }
  }

  // Method to build and display the UUID of the descriptor.
  Widget buildUuid(BuildContext context) {
    String uuid = '0x${widget.descriptor.uuid.str.toUpperCase()}';
    return Text(uuid, style: TextStyle(fontSize: 13));
  }

  // Method to build and display the value of the descriptor.
  Widget buildValue(BuildContext context) {
    String data = _value.toString();
    return Text(data, style: TextStyle(fontSize: 13, color: Colors.grey));
  }

  // Method to build the read button.
  Widget buildReadButton(BuildContext context) {
    return TextButton(
      child: Text("Read"),
      onPressed: onReadPressed,
    );
  }

  // Method to build the write button.
  Widget buildWriteButton(BuildContext context) {
    return TextButton(
      child: Text("Write"),
      onPressed: onWritePressed,
    );
  }

  // Method to build a row containing read and write buttons.
  Widget buildButtonRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildReadButton(context),
        buildWriteButton(context),
      ],
    );
  }

  // Build method to construct the UI.
  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Tile with title, UUID, and value.
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Descriptor'), // Title indicating descriptor.
          buildUuid(context), // Display UUID of the descriptor.
          buildValue(context), // Display value of the descriptor.
        ],
      ),
      // Button row with read and write buttons.
      subtitle: buildButtonRow(context),
    );
  }
}
