import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart'; // Assuming Sensor uses Hive for persistence if needed later
import 'sensor.dart';
import 'package:telephony/telephony.dart';
import 'dart:async'; // For Timer

// Use theme colors defined in the previous page or define them here again for consistency
class AppColors {
  static const Color appBackgroundColor = Color(0xFF101010);
  static const Color cardBackgroundColor = Color(0xFF1C1C1E);
  static const Color primaryAccentColor =
      Color(0xFFBB86FC); // Material Purple Accent
  static const Color textColorPrimary = Colors.white;
  static const Color textColorSecondary = Color(0xFFB0B0B0);
  static const Color errorColor = Color(0xFFCF6679);

  // Gradient colors for potential use in AppBar or highlights
  static const Color gradientStartColor = Color(0xFFAB47BC); // Purple 300
  static const Color gradientEndColor = Color(0xFF7E57C2); // Deep Purple 300
  static const Color highlightColor = gradientStartColor;
}

class SensorReadingPage extends StatefulWidget {
  final Sensor sensor;

  SensorReadingPage({required this.sensor});

  @override
  _SensorReadingPageState createState() => _SensorReadingPageState();
}

// Enum to represent the current data fetching status
enum DataStatus { idle, waiting, received, error }

class _SensorReadingPageState extends State<SensorReadingPage> {
  final Telephony telephony = Telephony.instance;

  // State variables for individual readings
  String fenceVoltage = "--";
  String batteryVoltage = "--";
  String fenceJoule = "--";
  String solarVoltage = "--";
  String statusMessage = "Tap 'Update Data' to fetch readings.";
  DataStatus currentStatus = DataStatus.idle;
  Timer? _waitingTimer; // Timer to handle timeout

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndListen();
  }

  @override
  void dispose() {
    _waitingTimer?.cancel(); // Cancel timer when page is disposed
    // Consider stopping the listener if appropriate, though Telephony might handle it.
    super.dispose();
  }

  Future<void> _requestPermissionsAndListen() async {
    // Request permissions first (optional here, can be done just before sending)
    // bool? permissionsGranted = await telephony.requestSmsPermissions;
    // if (permissionsGranted ?? false) {
    _startListeningForSMS();
    // } else {
    //   setState(() {
    //     currentStatus = DataStatus.error;
    //     statusMessage = "SMS permissions required to receive data.";
    //   });
    // }
  }

  void _startListeningForSMS() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        print("SMS Received: From ${message.address}, Body: ${message.body}");
        // Check if the message is from the correct sensor phone number
        if (message.address == widget.sensor.phoneNumber) {
          _waitingTimer?.cancel(); // Cancel timeout timer if message received
          _parseSensorData(message.body);
        }
      },
      listenInBackground: false, // Set to true if needed, requires more setup
    );
    print("SMS Listener Started for ${widget.sensor.phoneNumber}");
  }

  // --- Data Parsing Logic ---
  void _parseSensorData(String? data) {
    if (data == null || data.isEmpty) {
      setState(() {
        currentStatus = DataStatus.error;
        statusMessage = "Received empty data.";
        _resetReadingsToDefault();
      });
      return;
    }

    try {
      // Assuming format: "FV:8.5;FJ:1.2;BV:12.6;SV:18.1"
      // Adjust split characters (';', ':') based on your actual sensor output
      final parts = data.split(';');
      String tempFV = "--", tempBV = "--", tempFJ = "--", tempSV = "--";
      bool dataParsed = false;

      // (Rest of the parsing logic remains the same as it uses keys)
      for (String part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final key = kv[0].trim().toUpperCase();
          final value = kv[1].trim();
          dataParsed = true; // Mark that we found at least one valid pair

          switch (key) {
            case 'FV': // Fence Voltage
              tempFV = "$value kV"; // Add units
              break;
            case 'FJ': // Fence Joule << Parsing logic handles any order
              tempFJ = "$value J"; // Add units
              break;
            case 'BV': // Battery Voltage
              tempBV = "$value V"; // Add units
              break;
            case 'SV': // Solar Voltage
              tempSV = "$value V"; // Add units
              break;
            // Add more cases if your sensor sends other data
          }
        }
      }

      if (dataParsed) {
        setState(() {
          fenceVoltage = tempFV;
          batteryVoltage = tempBV;
          fenceJoule = tempFJ;
          solarVoltage = tempSV;
          currentStatus = DataStatus.received;
          statusMessage = "Data updated successfully."; // Or clear message
        });
      } else {
        // Data received but couldn't parse any known key-value pairs
        throw FormatException("Unknown data format received.");
      }
    } catch (e) {
      print("Parsing Error: $e");
      setState(() {
        currentStatus = DataStatus.error;
        statusMessage = "Error parsing data: $e";
        _resetReadingsToDefault();
      });
    }
  }

  void _resetReadingsToDefault() {
    fenceVoltage = "--";
    batteryVoltage = "--";
    fenceJoule = "--";
    solarVoltage = "--";
  }

  // --- Send SMS Request ---
  Future<void> _sendUpdateRequest() async {
    // Prevent sending if already waiting
    if (currentStatus == DataStatus.waiting) return;

    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted == true) {
      try {
        // Reset state before sending
        setState(() {
          currentStatus = DataStatus.waiting;
          statusMessage = "Requesting data from fence...";
          _resetReadingsToDefault(); // Clear old readings
        });

        // Start a timeout timer (e.g., 30 seconds)
        _waitingTimer?.cancel(); // Cancel previous timer if any
        _waitingTimer = Timer(Duration(seconds: 30), () {
          if (currentStatus == DataStatus.waiting) {
            // Only trigger if still waiting
            print("SMS Timeout Reached");
            setState(() {
              currentStatus = DataStatus.error;
              statusMessage = "No response received from fence (Timeout).";
            });
          }
        });

        await telephony.sendSms(
          to: widget.sensor.phoneNumber,
          message: "Update", // The command your sensor expects
          isMultipart: true, // Good practice
        );
        print("Update SMS sent to ${widget.sensor.phoneNumber}");
      } catch (error) {
        _waitingTimer?.cancel(); // Cancel timer on error
        print("Failed to send SMS: $error");
        setState(() {
          currentStatus = DataStatus.error;
          statusMessage = "Failed to send request: $error";
        });
        _showErrorSnackbar("Failed to send SMS: $error");
      }
    } else {
      setState(() {
        currentStatus = DataStatus.error;
        statusMessage = "SMS permissions not granted.";
      });
      _showErrorSnackbar("SMS permissions not granted.");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: TextStyle(color: AppColors.textColorPrimary)),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        margin: EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply system UI styling consistent with the theme
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.appBackgroundColor,
        appBar: AppBar(
          // Optional Gradient Title
          title: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  AppColors.gradientStartColor,
                  AppColors.gradientEndColor
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            child: Text(
              widget.sensor.name, // Display sensor name in AppBar
              style: TextStyle(
                fontSize: 26, // Adjust size
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          backgroundColor: AppColors.appBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(
              color: AppColors.textColorSecondary), // Back button color
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                // Allows grid to take available space
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the grid vertically
                  children: [
                    // --- Data Grid ---
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true, // Important inside a Column
                      physics:
                          NeverScrollableScrollPhysics(), // Disable grid scrolling
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildDataTile(
                          icon: Icons.electric_bolt, // Fence Voltage icon
                          label: "Fence Voltage",
                          value: fenceVoltage,
                          iconColor: Colors.yellowAccent, // Example color
                        ),
                        _buildDataTile(
                          icon: Icons.flash_on, // Fence Joule icon
                          label: "Fence Energy",
                          value: fenceJoule,
                          iconColor: Colors.orangeAccent, // Example color
                        ),
                        _buildDataTile(
                          icon: Icons
                              .battery_charging_full, // Battery Voltage icon
                          label: "Battery",
                          value: batteryVoltage,
                          iconColor: Colors.lightGreenAccent, // Example color
                        ),
                        _buildDataTile(
                          icon: Icons.solar_power, // Solar Panel Voltage icon
                          label: "Solar Panel",
                          value: solarVoltage,
                          iconColor: Colors.cyanAccent, // Example color
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    // --- Status Indicator ---
                    _buildStatusIndicator(),
                    SizedBox(height: 10), // Space between indicator and message
                    Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: currentStatus == DataStatus.error
                            ? AppColors.errorColor
                            : AppColors.textColorSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Update Button ---
              SizedBox(height: 20), // Space above button
              ElevatedButton.icon(
                icon: Icon(Icons.sync, size: 20),
                label: Text(
                  "Update Data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: currentStatus == DataStatus.waiting
                    ? null
                    : _sendUpdateRequest, // Disable if waiting
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, // Text/Icon color on button
                  backgroundColor:
                      AppColors.primaryAccentColor, // Button background color
                  minimumSize: Size(double.infinity, 50), // Make button wider
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // More rounded
                  ),
                  disabledBackgroundColor: AppColors.primaryAccentColor
                      .withOpacity(0.5), // Style for disabled state
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Status Indicator ---
  Widget _buildStatusIndicator() {
    if (currentStatus == DataStatus.waiting) {
      return SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.primaryAccentColor),
        ),
      );
    } else if (currentStatus == DataStatus.error) {
      return Icon(Icons.error_outline, color: AppColors.errorColor, size: 30);
    } else if (currentStatus == DataStatus.received) {
      return Icon(Icons.check_circle_outline,
          color: Colors.greenAccent, size: 30);
    }
    // Idle state - maybe show nothing or a placeholder icon
    return Icon(Icons.info_outline,
        color: AppColors.textColorSecondary, size: 30);
  }

  // --- Helper Widget for Data Tiles ---
  Widget _buildDataTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18), // Match card rounding
        // Optional: Add subtle border
        // border: Border.all(color: AppColors.textColorSecondary.withOpacity(0.1), width: 1),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center content vertically
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center content horizontally
        children: [
          Icon(icon, size: 35, color: iconColor),
          SizedBox(height: 12),
          Text(
            value, // Display the value (e.g., "8.5 kV")
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22, // Prominent value
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          Text(
            label, // Display the label (e.g., "Fence Voltage")
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColorSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
