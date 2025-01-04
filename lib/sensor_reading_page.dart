import 'package:flutter/material.dart';
import 'sensor.dart';
import 'package:telephony/telephony.dart';

class SensorReadingPage extends StatefulWidget {
  final Sensor sensor;

  SensorReadingPage({required this.sensor});

  @override
  _SensorReadingPageState createState() => _SensorReadingPageState();
}

class _SensorReadingPageState extends State<SensorReadingPage> {
  final Telephony telephony = Telephony.instance;
  String sensorData = "No Data Available";

  @override
  void initState() {
    super.initState();
    _startListeningForSMS();
  }

  void _startListeningForSMS() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (message.address == widget.sensor.phoneNumber) {
          setState(() {
            sensorData = message.body ?? "No Data Received";
          });
        }
      },
      listenInBackground: false,
    );
  }

  Future<void> _sendUpdateRequest() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted == true) {
      try {
        await telephony.sendSms(
          to: widget.sensor.phoneNumber,
          message: "Update",
        );
        setState(() {
          sensorData = "Waiting for Data...";
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send sms: $error")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SMS permissions not granted.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sensor.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Stylized Text
              Text(
                "Fence Data",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Sensor Data Display
              Text(
                sensorData,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 36),
              // Update Button
              ElevatedButton(
                onPressed: _sendUpdateRequest,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Update Data",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
