import 'package:hive/hive.dart';

part 'sensor.g.dart';

@HiveType(typeId: 0)
class Sensor {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String phoneNumber;

  Sensor({required this.name, required this.phoneNumber});
}
