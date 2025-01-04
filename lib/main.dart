import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sensor_config_page.dart';
import 'sensor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SensorAdapter());
  await Hive.openBox<Sensor>('sensors');
  runApp(SensorApp());
}

class SensorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1E1E1E),
      ),
      home: SensorConfigPage(),
    );
  }
}
