import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:SignSaya/pages/FBP_screens/widgets/characteristic_tile.dart';

class GlovesCalibration extends StatefulWidget {
  @override
  _GlovesCalibrationState createState() => _GlovesCalibrationState();
}

class _GlovesCalibrationState extends State<GlovesCalibration> {
  bool _isRecording = false;
  final String _fileName = "sensor_data.csv"; // Change filename if needed;
  late Directory _documentsDirectory; // Removed unnecessary `late` keyword
  late StreamSubscription<List<int>> _sensorValuesSubscription;
  late List<List<int>> _recordedSensorValues;

  @override
  void initState() {
    super.initState();
    _getDocumentsDirectory();
    _recordedSensorValues = [];
  }

  @override
  void dispose() {
    _sensorValuesSubscription.cancel();
    super.dispose();
  }

  Future<void> _getDocumentsDirectory() async {
    final permissionStatus = await Permission.storage.request();

    if (permissionStatus.isGranted) {
      final platform = Platform.operatingSystem;
      if (platform == 'android') {
        _documentsDirectory = Directory('/storage/emulated/0/Documents');
        if (!await _documentsDirectory.exists()) {
          await _documentsDirectory.create(recursive: true);
        }
        print("Documents directory: ${_documentsDirectory.path}");
      } else {
        // Handle iOS or other platforms (limited access)
        print("Platform-specific handling for documents directory needed for iOS or other platforms.");
      }
    } else {
      print("Storage permission is required to save files.");
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });

      _sensorValuesSubscription = CharacteristicTile.sensorValuesStream.listen((sensorValues) {
        if (_isRecording) {
          _recordSensorValue(sensorValues);
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _sensorValuesSubscription.cancel();
    setState(() {
      _isRecording = false;
    });

    // Save recorded sensor values to file
    if (_documentsDirectory != null) {
      final file = File('${_documentsDirectory.path}/$_fileName');
      final csvLines = _recordedSensorValues.map((values) => values.join(",")).join("\n");
      await file.writeAsString(csvLines, mode: FileMode.append);
      _recordedSensorValues.clear();
    } else {
      print("Documents directory is not set.");
    }
  }

  void _recordSensorValue(List<int> sensorValues) {
    _recordedSensorValues.add(sensorValues);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gloves Calibration'),
      ),
      body: StreamBuilder<List<int>>(
        stream: CharacteristicTile.sensorValuesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final sensorValues = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sensor Values: $sensorValues'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Exit'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: Text('Waiting for sensor values...'),
            );
          }
        },
      ),
    );
  }
}
