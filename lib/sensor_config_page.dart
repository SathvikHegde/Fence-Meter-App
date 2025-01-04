import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sensor.dart';
import 'sensor_reading_page.dart';

class SensorConfigPage extends StatefulWidget {
  @override
  _SensorConfigPageState createState() => _SensorConfigPageState();
}

class _SensorConfigPageState extends State<SensorConfigPage> {
  late Box<Sensor> _sensorBox;

  @override
  void initState() {
    super.initState();
    _sensorBox = Hive.box<Sensor>('sensors');
  }

  void _showAddEditSensorDialog({int? index, Sensor? sensor}) {
    final TextEditingController _nameController =
        TextEditingController(text: sensor?.name ?? '');
    final TextEditingController _phoneController = TextEditingController(
        text: sensor?.phoneNumber.replaceFirst('+91', '') ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          title: Text(
            index == null ? "Add Fence" : "Edit Fence",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Fence Name",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                maxLength: 10,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "+91 ",
                  prefixStyle: TextStyle(color: Colors.white),
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: Colors.grey),
                  counterText: "",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = _nameController.text;
                final phoneNumber = _phoneController.text;
                if (name.isNotEmpty && phoneNumber.length == 10) {
                  final fullPhoneNumber = "+91$phoneNumber";
                  if (index == null) {
                    _sensorBox
                        .add(Sensor(name: name, phoneNumber: fullPhoneNumber));
                  } else {
                    _sensorBox.putAt(index,
                        Sensor(name: name, phoneNumber: fullPhoneNumber));
                  }
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter valid details.")),
                  );
                }
              },
              child: Text(
                index == null ? "Add" : "Update",
                style: TextStyle(color: Colors.purpleAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          title: Text(
            "Delete Fence",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to delete this fence?",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("Cancel", style: TextStyle(color: Colors.purpleAccent)),
            ),
            TextButton(
              onPressed: () {
                _sensorBox.deleteAt(index);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Fences",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: _sensorBox.listenable(),
        builder: (context, Box<Sensor> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text(
                "No fences linked.\nTap the + button to add one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final sensor = box.getAt(index);
              return GestureDetector(
                onTap: () {
                  // Navigate to the Sensor Reading Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SensorReadingPage(sensor: sensor!),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.device_hub,
                          color: Colors.purpleAccent, size: 40),
                      SizedBox(height: 12),
                      Text(
                        sensor!.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Phone: ${sensor.phoneNumber}",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.purpleAccent),
                            onPressed: () => _showAddEditSensorDialog(
                                index: index, sensor: sensor),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSensorDialog(),
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
    );
  }
}
