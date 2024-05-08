import 'package:flutter/material.dart'; // Importing material package for Flutter UI components
import 'package:speech_to_text/speech_recognition_result.dart'; // Importing speech recognition result class
import 'package:speech_to_text/speech_to_text.dart'; // Importing speech to text package
import 'bluetooth_connection.dart'; // Importing Bluetooth connection class
import 'gloves_calibration.dart'; // Importing Gloves calibration class

// Importing translator package for language translation
import 'package:translator/translator.dart';

// Importing history page
import 'package:SignSaya/pages/history_page.dart';

// Importing SignSaya database configuration
import 'package:SignSaya/pages/signsaya_database_config.dart';

// Importing internationalization package for date formatting
import 'package:intl/intl.dart';

class TranslationPage extends StatefulWidget {
  // Define TranslationPage widget as a StatefulWidget
  const TranslationPage({Key? key})
      : super(key: key); // Constructor for TranslationPage widget

  @override // Indicate that the following method overrides a method in the superclass
  _TranslationPageState createState() =>
      _TranslationPageState(); // Create state for TranslationPage widget
}

// Define _TranslationPageState class as state for TranslationPage widget
class _TranslationPageState extends State<TranslationPage> {
  String? selectedLanguage; // For speech to text language selection
  SpeechToText _speechToText = SpeechToText(); // Speech to text instance
  TextEditingController _speechController =
      TextEditingController(); // Text field controller for speech to text

  TextEditingController _topTextController =
      TextEditingController(); // Text field controller for top text

  // Improved dropdown starts here
  String? selectedLanguageTop; // Selected language for top dropdown
  String? selectedLanguageBottom; // Selected language for bottom dropdown
  String translatedTextTop = ""; // Translated text for top dropdown
  String translatedTextBottom = ""; // Translated text for bottom dropdown
  // Improved dropdown ends here

  // Translator instance for language translation
  final translator = GoogleTranslator();

  // Method to translate text
  void translateText(String input, String toLanguage, String dropdown) {
    // Define a method to translate text
    translator.translate(input, to: toLanguage).then((result) {
      // Translate the input text to the specified language
      setState(() {
        // Update the UI with the translated text
        if (dropdown == 'top') {
          // Check if the translation is for the top dropdown
          translatedTextTop = result.text; // Update top dropdown translation
        } else {
          // If the translation is for the bottom dropdown
          translatedTextBottom =
              result.text; // Update bottom dropdown translation
        }
      });
    });
  }

  bool _isContainerVisible =
      false; // Initialize a boolean variable to track container visibility

// Method to toggle container visibility
  void _toggleContainerVisibility() {
    // Define a method to toggle the visibility of the container
    setState(() {
      // Update the UI state
      _isContainerVisible =
          !_isContainerVisible; // Toggle the visibility of the container
    });
  }

  @override
  void initState() {
    // Initialize the widget state
    super.initState(); // Call the superclass's initState method
    _initSpeech(); // Initialize speech to text
  }

// Speech to text functions start here
  void _initSpeech() async {
    // Initialize speech to text functionality
    _speechToText.initialize(
        onError: (error) =>
            print('Error: $error')); // Initialize speech to text
  }

  void _startListening() async {
    // Start listening for speech input
    await _speechToText.listen(
        onResult: _onSpeechResult); // Start speech recognition
  }

  void _stopListening() async {
    // Stop listening for speech input
    await _speechToText.stop(); // Stop speech recognition
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // Process speech recognition result
    setState(() {
      // Update the UI state
      _speechController.text =
          result.recognizedWords; // Set recognized speech to the text field
    });
  }

  // Speech to text functions ends here

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size screenSize = MediaQuery.of(context).size;

    // Calculate positions based on screen size
    final double infoButtonTop = screenSize.height * 0.04;
    final double connectionButtonTop = screenSize.height * 0.053;
    final double dropdownContainerTop = screenSize.height * 0.253;
    final double gradientContainerTop = screenSize.height * 0.3;
    final double translationImageTop = screenSize.height * 0.87;
    final double buttonsRowTop = screenSize.height * 0.855;
    final double hiddenContainerTop = screenSize.height * 0.66;

    // String dropdownHintText = "${" " * (screenSize.width * 0.01).round()}Select Language...${" " * (screenSize.width * 0.093).round()}";

    return Scaffold(
      // Return a Scaffold widget
      body: Stack(
        // Use a Stack widget to overlay widgets
        children: [
          // Background Image
          Image.asset(
            // Display a background image
            'lib/images/backgroundTranslation.png', // Image file path
            fit: BoxFit.cover, // Cover the entire screen with the image
            width: screenSize.width, // Set the image width to the screen width
            height:
                screenSize.height, // Set the image height to the screen height
          ),
          // Calibration Button
          Positioned(
            // Position the button
            top: infoButtonTop, // Position from the top
            right: screenSize.width * 0.02, // Position from the right
            child: ElevatedButton(
              // Display an ElevatedButton widget
              onPressed: () {
                // Define button onPressed callback
                // Navigator.push(
                //   // Navigate to another screen when the button is pressed
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) =>
                //           GlovesCalibration()), // Navigate to GlovesCalibration screen
                // );
              },
              style: ElevatedButton.styleFrom(
                // Define button style
                backgroundColor:
                    const Color(0xFF011F4B), // Set button background color
                shape: const CircleBorder(), // Set button shape to circle
              ),
              child: Image.asset(
                // Display an image inside the button
                'lib/images/settingsButton.png', // Image file path
                width: 25, // Set image width
                height: 25, // Set image height
              ),
            ),
          ),

          // Connection Button
          Positioned(
            // Position the button
            top: connectionButtonTop, // Position from the top
            left: screenSize.width * 0.02, // Position from the left
            right: screenSize.width * 0.6, // Position from the right
            child: Center(
              // Center align the button
              child: SizedBox(
                // Use a SizedBox to constrain button size
                width: 150, // Set button width
                height: 30, // Set button height
                child: ElevatedButton(
                  // Display an ElevatedButton widget
                  onPressed: () {
                    // Define button onPressed callback
                    Navigator.push(
                      // Navigate to another screen when the button is pressed
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FBPMain(), // Navigate to history page
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    // Define button style
                    shape: RoundedRectangleBorder(
                      // Set button shape
                      borderRadius:
                          BorderRadius.circular(20), // Set border radius
                    ),
                  ),
                  child: const Text(
                    // Display button text
                    'Not Connected', // Text content
                    style: TextStyle(
                      // Define text style
                      fontFamily: 'Intro Rust', // Set font family
                      fontWeight: FontWeight.bold, // Set font weight
                      fontSize: 10, // Set font size
                      color: Colors.black, // Set text color
                    ),
                  ),
                ),
              ),
            ),
          ),
// Second Dropdown
          Positioned(
            // Position the dropdown
            top: screenSize.height * 0.56, // Position from the top
            left: screenSize.width * 0.05, // Position from the left
            child: Container(
              // Container to hold the dropdown
              width: screenSize.width * 0.9, // Set container width
              height: 30, // Set container height
              decoration: BoxDecoration(
                // Decorate the container
                borderRadius: BorderRadius.circular(15), // Set border radius
                color: Colors.white, // Set background color
              ),
              child: DropdownButtonHideUnderline(
                // Hide the dropdown underline
                child: DropdownButton<String>(
                  // Display a DropdownButton widget
                  isExpanded: true, // Allow the dropdown to expand horizontally
                  hint: const Text(
                    // Set default hint text
                    '  Select Language...', // Hint text content
                    style: TextStyle(
                      // Define hint text style
                      fontFamily: 'Sans', // Set font family
                      fontStyle: FontStyle.italic, // Set font style
                      fontSize: 16, // Set font size
                      color: Colors.grey, // Set text color
                    ),
                  ),
                  style: const TextStyle(
                    // Define dropdown item style
                    fontFamily: 'Sans', // Set font family
                    fontStyle: FontStyle.normal, // Set font style
                    color: Colors.black, // Set text color
                    fontSize: 16, // Set font size
                  ),
                  value:
                      selectedLanguageBottom, // Set the selected dropdown value
                  onChanged: (String? newValue) {
                    // Define dropdown onChanged callback
                    if (newValue != null) {
                      // Check if newValue is not null
                      if (newValue != selectedLanguageBottom) {
                        // Check if newValue is different from the current selected value
                        setState(() {
                          // Update the UI state
                          selectedLanguageBottom =
                              newValue; // Set the selected dropdown value
                          translateText("", newValue,
                              'bottom'); // Update bottom dropdown translation
                        });
                      }
                    }
                  },
                  items: <String>[
                    'en',
                    'fil',
                    'ja',
                    'zh-cn'
                  ] // Define dropdown items
                      .map<DropdownMenuItem<String>>((String value) {
                    // Map each item to a DropdownMenuItem widget
                    String displayText = ''; // Initialize display text
                    switch (value) {
                      // Determine display text based on value
                      case 'en':
                        displayText = 'English'; // Set display text for English
                        break;
                      case 'fil':
                        displayText =
                            'Filipino'; // Set display text for Filipino
                        break;
                      case 'ja':
                        displayText =
                            'Japanese'; // Set display text for Japanese
                        break;
                      case 'zh-cn':
                        displayText =
                            'Mandarin Chinese'; // Set display text for Mandarin Chinese
                        break;
                      default:
                        displayText = ''; // Set default display text
                    }
                    return DropdownMenuItem<String>(
                      // Return a DropdownMenuItem widget
                      value: value, // Set the value of the item
                      child: Text(
                          displayText), // Set the child widget as display text
                    );
                  }).toList(), // Convert the list of items to a list of DropdownMenuItem widgets
                ),
              ),
            ),
          ),
// First Dropdown
          Positioned(
            // Position the dropdown
            top: dropdownContainerTop, // Position from the top
            left: screenSize.width * 0.05, // Position from the left
            child: Container(
              // Container to hold the dropdown
              width: screenSize.width * 0.9, // Set container width
              height: 30, // Set container height
              decoration: BoxDecoration(
                // Decorate the container
                borderRadius: BorderRadius.circular(15), // Set border radius
                color: Colors.white, // Set background color
              ),
              child: DropdownButtonHideUnderline(
                // Hide the dropdown underline
                child: DropdownButton<String>(
                  // Display a DropdownButton widget
                  isExpanded: true, // Allow the dropdown to expand horizontally
                  hint: const Text(
                    // Set default hint text
                    '  Select Language...', // Hint text content
                    style: TextStyle(
                      // Define hint text style
                      fontFamily: 'Sans', // Set font family
                      fontStyle: FontStyle.italic, // Set font style
                      fontSize: 16, // Set font size
                      color: Colors.grey, // Set text color
                    ),
                  ),
                  style: const TextStyle(
                    // Define dropdown item style
                    fontFamily: 'Sans', // Set font family
                    fontStyle: FontStyle.normal, // Set font style
                    color: Colors.black, // Set text color
                    fontSize: 16, // Set font size
                  ),
                  value: selectedLanguageTop, // Set the selected dropdown value
                  onChanged: (String? newValue) {
                    // Define dropdown onChanged callback
                    if (newValue != null) {
                      // Check if newValue is not null
                      if (newValue != selectedLanguageTop) {
                        // Check if newValue is different from the current selected value
                        setState(() {
                          // Update the UI state
                          selectedLanguageTop =
                              newValue; // Set the selected dropdown value
                          translateText(_topTextController.text, newValue,
                              'top'); // Update top dropdown translation
                        });
                      }
                    }
                  },
                  items: <String>[
                    'en',
                    'fil',
                    'ja',
                    'zh-cn'
                  ] // Define dropdown items
                      .map<DropdownMenuItem<String>>((String value) {
                    // Map each item to a DropdownMenuItem widget
                    String displayText = ''; // Initialize display text
                    switch (value) {
                      // Determine display text based on value
                      case 'en':
                        displayText = 'English'; // Set display text for English
                        break;
                      case 'fil':
                        displayText =
                            'Filipino'; // Set display text for Filipino
                        break;
                      case 'ja':
                        displayText =
                            'Japanese'; // Set display text for Japanese
                        break;
                      case 'zh-cn':
                        displayText =
                            'Mandarin Chinese'; // Set display text for Mandarin Chinese
                        break;
                      default:
                        displayText = ''; // Set default display text
                    }
                    return DropdownMenuItem<String>(
                      // Return a DropdownMenuItem widget
                      value: value, // Set the value of the item
                      child: Text(
                          displayText), // Set the child widget as display text
                    );
                  }).toList(), // Convert the list of items to a list of DropdownMenuItem widgets
                ),
              ),
            ),
          ),
// Translation Container
          Positioned(
            // Position the container
            top: gradientContainerTop, // Position from the top
            left: screenSize.width * 0.05, // Position from the left
            right: screenSize.width * 0.05, // Position from the right
            child: Container(
              // Container to hold the translation content
              decoration: BoxDecoration(
                // Decorate the container
                gradient: const LinearGradient(
                  // Apply a linear gradient background
                  begin: Alignment.centerLeft, // Gradient start position
                  end: Alignment.centerRight, // Gradient end position
                  colors: [
                    // Define gradient colors
                    Color(0xFFCDFFD8), // Light green
                    Color(0xFF94B9FF), // Light blue
                  ],
                ),
                borderRadius: BorderRadius.circular(10), // Set border radius
                boxShadow: [
                  // Apply box shadow
                  BoxShadow(
                    // Define box shadow properties
                    color: Colors.black.withOpacity(0.3), // Shadow color
                    spreadRadius: 2, // Spread radius
                    blurRadius: 5, // Blur radius
                    offset: const Offset(0, 3), // Shadow offset
                  ),
                ],
              ),
              child: Column(
                // Column to organize translation content vertically
                mainAxisAlignment: MainAxisAlignment
                    .center, // Align content vertically at the center
                children: <Widget>[
                  // List of children widgets
                  TextField(
                    // Text field to input text for translation
                    controller:
                        _topTextController, // Set controller for text input
                    decoration: const InputDecoration(
                      // Define text field decoration
                      hintText: 'Enter text to translate', // Hint text
                      border: OutlineInputBorder(), // Border style
                    ),
                    onChanged: (text) {
                      // Define onChanged callback
                      translateText(text, selectedLanguageTop ?? '',
                          'top'); // Update top dropdown translation
                    },
                  ),
                  SizedBox(height: screenSize.height * 0.0355), // Spacer
                  const Text(
                    // Label to indicate translated text
                    'Translated Text:', // Label text
                    style:
                        TextStyle(fontWeight: FontWeight.bold), // Label style
                  ),
                  SizedBox(height: screenSize.height * 0.0355), // Spacer
                  Text(
                    // Display translated text
                    translatedTextTop, // Translated text content
                    textAlign: TextAlign.center, // Center align text
                  ),
                  SizedBox(height: screenSize.height * 0.0355), // Spacer
                ],
              ),
            ),
          ),
// Translation Image Button
          Positioned(
            // Position the translation image button
            top: translationImageTop * 1.05, // Position from the top
            left: screenSize.width * 0.05, // Position from the left
            child: ElevatedButton(
              // Display an ElevatedButton widget
              onPressed: () {
                // Define button onPressed callback
                Navigator.pop(context); // Navigate back to the previous screen
              },
              style: ElevatedButton.styleFrom(
                // Define button style
                backgroundColor:
                    const Color(0xFF011F4B), // Set background color
                shape: const CircleBorder(), // Apply circular shape to button
              ),
              child: Image.asset(
                // Display an image inside the button
                'lib/images/translationHome.png', // Image asset path
                width: 50, // Set image width
                height: 50, // Set image height
              ),
            ),
          ),
// History Button
          Positioned(
            // Position the history button
            top: translationImageTop * 1.05, // Position from the top
            left: screenSize.width * 0.68, // Position from the left
            child: ElevatedButton(
              // Display an ElevatedButton widget
              onPressed: () {
                // Define button onPressed callback
                Navigator.push(
                  // Navigate to the history page
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const HistoryPage(), // Navigate to history page
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                // Define button style
                backgroundColor:
                    const Color(0xFF011F4B), // Set background color
                shape: const CircleBorder(), // Apply circular shape to button
              ),
              child: Image.asset(
                // Display an image inside the button
                'lib/images/historyButton.png', // Image asset path
                width: 50, // Set image width
                height: 50, // Set image height
              ),
            ),
          ),
          // Gloves Placeholder Button
          Positioned(
            // Position the gloves placeholder button
            top: translationImageTop * 1.05, // Position from the top
            left: screenSize.width * 0.38, // Position from the left
            child: ElevatedButton(
              // Display an ElevatedButton widget
              onPressed:
                  _toggleContainerVisibility, // Define button onPressed callback
              style: ElevatedButton.styleFrom(
                // Define button style
                backgroundColor:
                    const Color(0xFF011F4B), // Set background color
                shape: const CircleBorder(), // Apply circular shape to button
              ),
              child: Image.asset(
                // Display an image inside the button
                'lib/images/micBttn.png', // Image asset path
                width: 45, // Set image width
                height: 45, // Set image height
              ),
            ),
          ),
          // Horizontal Divider
          Positioned(
            // Position the horizontal divider
            top: buttonsRowTop * 1.04, // Position from the top
            left: 0, // Align with the left edge
            right: 0, // Align with the right edge
            child: const Divider(
              // Display a Divider widget
              color: Colors.white, // Set divider color
              thickness: 3, // Set divider thickness
            ),
          ),
          // Animated Container for Speech to Text
          Positioned(
            // Position the animated container for speech to text
            top: hiddenContainerTop * 0.922, // Position from the top
            left: screenSize.width * 0.06, // Position from the left
            right: screenSize.width * 0.06, // Position from the right
            child: AnimatedContainer(
              // Display an AnimatedContainer widget
              duration: const Duration(
                  milliseconds: 500), // Define animation duration
              curve: Curves.easeInOut, // Apply ease-in-out animation curve
              height: _isContainerVisible
                  ? screenSize.height * 0.275
                  : 0, // Set container height based on visibility
              decoration: BoxDecoration(
                // Decorate the container
                gradient: const LinearGradient(
                  // Apply a linear gradient background
                  begin: Alignment.centerLeft, // Gradient start position
                  end: Alignment.centerRight, // Gradient end position
                  colors: [
                    // Define gradient colors
                    Color(0xFFCDFFD8), // Light green
                    Color(0xFF94B9FF), // Light blue
                  ],
                ),
                borderRadius: BorderRadius.circular(10), // Set border radius
                boxShadow: [
                  // Apply box shadow
                  BoxShadow(
                    // Define box shadow properties
                    color: Colors.black.withOpacity(0.3), // Shadow color
                    spreadRadius: 2, // Spread radius
                    blurRadius: 5, // Blur radius
                    offset: const Offset(0, 3), // Shadow offset
                  ),
                ],
              ),
              child: Stack(
                // Stack to organize speech to text content
                children: [
                  // List of children widgets
                  TextField(
                    // Text field for speech to text input
                    controller:
                        _speechController, // Set controller for text input
                    decoration: InputDecoration(
                      // Define text field decoration
                      hintText:
                          'Tap the Microphone to Start Speech to Text', // Hint text
                      hintStyle: const TextStyle(
                        // Hint text style
                        color:
                            Color.fromARGB(255, 0, 0, 0), // Set hint text color
                        fontSize: 16, // Set hint text font size
                        fontStyle: FontStyle.italic, // Set italic font style
                        fontWeight: FontWeight.w300, // Set font weight
                      ),
                      contentPadding:
                          const EdgeInsets.all(20.0), // Set content padding
                      border: InputBorder.none, // Remove border
                      suffixIcon: IconButton(
                        // Define suffix icon button
                        onPressed: _speechToText.isListening
                            ? _stopListening
                            : _startListening, // Define onPressed callback
                        icon: Icon(_speechToText.isListening
                            ? Icons.mic_off
                            : Icons
                                .mic), // Set icon based on speech listening state
                      ),
                    ),
                    maxLines: null, // Allow multiple lines of text
                    onChanged: (text) {
                      // Define onChanged callback
                      translateText(text, selectedLanguageBottom ?? '',
                          'bottom'); // Update bottom dropdown translation
                    },
                  ),
                  // Save button for conversation
                  Container(
                    // Container for save button
                    alignment:
                        Alignment.bottomLeft, // Align container to bottom left
                    child: ElevatedButton(
                      // Display an ElevatedButton widget
                      onPressed: () async {
                        // Define button onPressed callback
                        final DateFormat formatter =
                            DateFormat('MM-dd-yyyy'); // Initialize date format
                        final String formattedDate = formatter
                            .format(DateTime.now()); // Format current date
                        final translation = {
                          // Define translation data
                          'date': formattedDate, // Set date
                          'time': TimeOfDay.now().format(context), // Set time
                          'question':
                              _topTextController.text, // Set question text
                          'response':
                              _speechController.text, // Set response text
                          'translated_response':
                              translatedTextBottom // Set translated response text
                        };
                        await SignSayaDatabase().saveTranslation(
                            translation); // Save translation to database
                        ScaffoldMessenger.of(context).showSnackBar(
                          // Show snackbar
                          const SnackBar(
                            // Display a SnackBar widget
                            content: Text(
                                'Conversation Saved!'), // Set snackbar content
                          ),
                        );
                      },
                      style: ButtonStyle(
                        // Define button style
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.blue), // Set button background color
                      ),
                      child: const Text(
                        // Set button label text
                        "SAVE", // Button label
                        style: TextStyle(color: Colors.white), // Set text color
                      ),
                    ),
                  ),
                  Positioned(
                    // Position delete icon button
                    right: screenSize.width * 0.025, // Position from the right
                    top: screenSize.height * 0.225, // Position from the top
                    child: GestureDetector(
                      // GestureDetector to handle tap
                      onTap: () {
                        // Define onTap callback
                        setState(() {
                          // Update widget state
                          _speechController
                              .clear(); // Clear speech controller text
                        });
                      },
                      child: const Icon(Icons.delete, // Display delete icon
                          color: Colors.black,
                          size: 30), // Set icon color and size
                    ),
                  ),
                  Positioned(
                    // Position translated text display
                    bottom:
                        screenSize.height * 0.01, // Position from the bottom
                    left: screenSize.width * 0.06, // Position from the left
                    right: screenSize.width * 0.06, // Position from the right
                    child: Column(
                      // Column to organize translated text display
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Align children widgets horizontally
                      children: [
                        // List of children widgets
                        SizedBox(
                            height: screenSize.height * 0.0334), // Empty space
                        const Text(
                          // Display label for translated text
                          'Translated Text:', // Label text
                          style: TextStyle(
                              fontWeight: FontWeight.bold), // Set text style
                        ),
                        SizedBox(
                            height: screenSize.height * 0.0334), // Empty space
                        Text(
                          // Display translated text
                          translatedTextBottom, // Translated text
                          textAlign: TextAlign.center, // Align text to center
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
