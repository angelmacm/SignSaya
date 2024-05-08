// Import necessary packages.
import 'dart:async'; // For asynchronous operations.
import 'dart:math'; // For random number generation.
import 'package:flutter/material.dart'; // Flutter material UI components.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Flutter Blue Plus for Bluetooth functionality.
//import 'package:SignSaya/pages/gloves_calibration.dart'; // Import GlovesCalibration page.
import '../utils/snackbar.dart'; // Import Snackbar utility.
import 'descriptor_tile.dart'; // Import DescriptorTile widget.
import 'package:SignSaya/pages/translation_page.dart';

// Define a tile widget for displaying Bluetooth characteristics.
class CharacteristicTile extends StatefulWidget {
  // Constructor with required parameters: characteristic and descriptorTiles.
  
  // Bluetooth characteristic to display in the tile.
  final BluetoothCharacteristic characteristic;
  // List of descriptor tiles associated with the characteristic.
  final List<DescriptorTile> descriptorTiles;
  
  const CharacteristicTile({
    Key? key,
    required this.characteristic,
    required this.descriptorTiles,
  }) : super(key: key);


  // Static stream controller for sensor values.
  // static StreamController<List<int>> _sensorValuesController =
  //     StreamController<List<int>>.broadcast(); commented

  // Getter method to access the sensor values stream.
  // static Stream<List<int>> get sensorValuesStream =>
  //     _sensorValuesController.stream;  commented

  @override
  State<CharacteristicTile> createState() => _CharacteristicTileState();
}

// State class for the CharacteristicTile widget.
class _CharacteristicTileState extends State<CharacteristicTile> {
  // List to hold the value of the characteristic.
  List<int> _value = [];

  // Stream subscription to monitor changes in the characteristic's value.
  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();
    // Subscribe to the last value stream of the characteristic.
    _lastValueSubscription =
        widget.characteristic.lastValueStream.listen((value) {
      // Update the value and refresh the UI if mounted.
      _value = value;
      if (mounted) {
        setState(() {});
        // Add the value to the sensor values stream.
        //CharacteristicTile._sensorValuesController.add(_value); commented
        print(value); // Log the value.
      }
    });
    Future.delayed(const Duration(seconds: 1), () {
      //print("Now Subscribed!");
      onSubscribePressed(context);
    });
  }

  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed.
    _lastValueSubscription.cancel();
    super.dispose();
  }

  // Getter method to access the characteristic.
  BluetoothCharacteristic get c => widget.characteristic;

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

  // Method to handle read operation on the characteristic.
  Future<void> onReadPressed() async {
    try {
      await c.read();
      Snackbar.show(ABC.c, "Read: Success", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Read Error:", e), success: false);
    }
  }

  // Method to handle write operation on the characteristic.
  Future<void> onWritePressed() async {
    try {
      await c.write(
        _getRandomBytes(),
        withoutResponse: c.properties.writeWithoutResponse,
      );
      Snackbar.show(ABC.c, "Write: Success", success: true);
      // Read the characteristic if it supports reading.
      if (c.properties.read) {
        await c.read();
      }
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Write Error:", e), success: false);
    }
  }

  // Method to handle subscribe/unsubscribe operation on the characteristic.
  Future<void> onSubscribePressed(BuildContext context) async {
    try {
      String op = c.isNotifying == false ? "Subscribe" : "Unsubscribe";
      await c.setNotifyValue(!c.isNotifying);
      Snackbar.show(ABC.c, "$op: Success", success: true);
      // Read the characteristic if it supports reading.
      if (c.properties.read) {
        await c.read();
      }
      if (mounted) {
        setState(() {});
      }
      // Navigate to GlovesCalibration page.
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => GlovesCalibration()),
      // );
      Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  const TranslationPage()),
    );

    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Subscribe Error:", e),
          success: false);
    }
  }

  // Method to build and display the UUID of the characteristic.
  Widget buildUuid(BuildContext context) {
    String uuid = '0x${widget.characteristic.uuid.str.toUpperCase()}';
    return Text(uuid, style: const TextStyle(fontSize: 13));
  }

  // Method to build and display the value of the characteristic.
  Widget buildValue(BuildContext context) {
    String data = _value.toString();
    return Text(data, style: const TextStyle(fontSize: 13, color: Colors.black));
  }

  // Method to build the read button.
  Widget buildReadButton(BuildContext context) {
    return TextButton(
      child: const Text("Read"),
      onPressed: () async {
        await onReadPressed();
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // Method to build the write button.
  Widget buildWriteButton(BuildContext context) {
    bool withoutResp = widget.characteristic.properties.writeWithoutResponse;
    return TextButton(
      child: Text(withoutResp ? "WriteNoResp" : "Write"),
      onPressed: () async {
        await onWritePressed();
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // Method to build the subscribe/unsubscribe button.
  Widget buildSubscribeButton(BuildContext context) {
    bool isNotifying = widget.characteristic.isNotifying;
    return TextButton(
      child: Text(isNotifying ? "Unsubscribe" : "Subscribe"),
      onPressed: () async {
        await onSubscribePressed(context);
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // Method to build a row containing buttons based on characteristic properties.
  Widget buildButtonRow(BuildContext context) {
    bool read = widget.characteristic.properties.read;
    bool write = widget.characteristic.properties.write;
    bool notify = widget.characteristic.properties.notify;
    bool indicate = widget.characteristic.properties.indicate;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (read) buildReadButton(context),
        if (write) buildWriteButton(context),
        if (notify || indicate) buildSubscribeButton(context),
      ],
    );
  }

  // Build method to construct the UI.
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      // Expansion tile with title, UUID, value, and buttons.
      title: ListTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Characteristic'), // Title indicating characteristic.
            buildUuid(context), // Display UUID of the characteristic.
            buildValue(context), // Display value of the characteristic.
          ],
        ),
        subtitle: buildButtonRow(context), // Button row.
        contentPadding: const EdgeInsets.all(0.0),
      ),
      children: widget.descriptorTiles, // Descriptor tiles.
    );
  }
}
