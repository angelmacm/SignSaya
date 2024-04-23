import 'package:flutter/material.dart'; // Importing material.dart package for Flutter UI components
import 'package:flutter/services.dart'; // Importing services.dart package for accessing platform services
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Importing FlutterBluePlus package for Bluetooth functionality

// Enum representing different types
enum ABC {
  a, // Value 'a' of enum ABC
  b, // Value 'b' of enum ABC
  c, // Value 'c' of enum ABC
}

// Class for managing Snackbars
class Snackbar {
  // Global keys for managing different Snackbars
  static final snackBarKeyA = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyB = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyC = GlobalKey<ScaffoldMessengerState>();

  // Method to get the global key for a specific ABC type
  static GlobalKey<ScaffoldMessengerState> getSnackbar(ABC abc) {
    // Switch case to return the appropriate global key based on the ABC enum value
    switch (abc) {
      case ABC.a:
        return snackBarKeyA; // Return key for ABC.a
      case ABC.b:
        return snackBarKeyB; // Return key for ABC.b
      case ABC.c:
        return snackBarKeyC; // Return key for ABC.c
    }
  }

  // Method to show a Snackbar
  static show(ABC abc, String msg, {required bool success}) {
    // Constructing a Snackbar based on success status
    final snackBar = success
        ? SnackBar(
            content: Text(msg),
            backgroundColor: Colors.blue) // Snackbar for success
        : SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red); // Snackbar for failure

    // Removing any existing Snackbar and showing the new Snackbar
    getSnackbar(abc).currentState?.removeCurrentSnackBar();
    getSnackbar(abc).currentState?.showSnackBar(snackBar);
  }
}

// Method to format exceptions
String prettyException(String prefix, dynamic e) {
  if (e is FlutterBluePlusException) {
    return "$prefix ${e.description}"; // Prefixing description for FlutterBluePlusException
  } else if (e is PlatformException) {
    return "$prefix ${e.message}"; // Prefixing message for PlatformException
  }
  return prefix + e.toString(); // Prefixing default exception message
}
