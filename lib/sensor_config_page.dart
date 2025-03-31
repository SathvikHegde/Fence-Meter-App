import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemUiOverlayStyle
import 'package:hive_flutter/hive_flutter.dart';
import 'sensor.dart'; // Assuming sensor.dart defines the Sensor class
import 'sensor_reading_page.dart'; // Assuming this page exists

class SensorConfigPage extends StatefulWidget {
  @override
  _SensorConfigPageState createState() => _SensorConfigPageState();
}

class _SensorConfigPageState extends State<SensorConfigPage> {
  late Box<Sensor> _sensorBox;

  // --- Refined Color Scheme ---
  static const Color _appBackgroundColor = Color(0xFF101010);
  static const Color _cardBackgroundColor = Color(0xFF1C1C1E);
  static const Color _primaryAccentColor = Color(
      0xFFBB86FC); // Material Design dark theme purple accent (Keep for FAB/buttons)
  static const Color _textColorPrimary = Colors.white;
  static const Color _textColorSecondary = Color(0xFFB0B0B0);
  static const Color _errorColor = Color(0xFFCF6679);

  // --- GRADIENT COLORS: Adjusted to PURPLE ---
  // static const Color _gradientStartColor = Color(0xFFCE93D8); // Old: Purple 200
  // static const Color _gradientEndColor = Color(0xFFF48FB1); // Old: Pink 200
  static const Color _gradientStartColor = Color(0xFFAB47BC); // New: Purple 300
  static const Color _gradientEndColor =
      Color(0xFF7E57C2); // New: Deep Purple 300 (or try 0xFF9575CD for DP 200)

  // Use the new purple start color for highlights/icons
  static const Color _highlightColor = _gradientStartColor;
  static const Color _iconColor = _highlightColor;

  @override
  void initState() {
    super.initState();
    _sensorBox = Hive.box<Sensor>('sensors');

    // Set status bar style for dark theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.light, // Icons light
      statusBarBrightness: Brightness.dark, // For iOS
    ));
  }

  // --- Dialogs (Add/Edit, Delete - Themed) ---
  // (Keep the dialog code largely the same, ensure theme colors are used correctly)
  // --- Dialog for Adding/Editing Sensor (Themed) ---
  void _showAddEditSensorDialog({int? index, Sensor? sensor}) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController =
        TextEditingController(text: sensor?.name ?? '');
    final TextEditingController _phoneController = TextEditingController(
        text: sensor?.phoneNumber.replaceFirst('+91', '') ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          title: Text(
            index == null ? "Add Fence" : "Edit Fence",
            style: TextStyle(
                color: _textColorPrimary, fontWeight: FontWeight.w600),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration("Fence Name"),
                  style: TextStyle(color: _textColorPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a fence name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  maxLength: 10,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration("Phone Number").copyWith(
                    prefixText: "+91 ",
                    prefixStyle:
                        TextStyle(color: _textColorPrimary, fontSize: 16),
                    counterText: "",
                  ),
                  style: TextStyle(color: _textColorPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (value.length != 10 || int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                    color: _textColorSecondary, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text.trim();
                  final phoneNumber = _phoneController.text;
                  final fullPhoneNumber = "+91$phoneNumber";
                  final newSensor =
                      Sensor(name: name, phoneNumber: fullPhoneNumber);

                  if (index == null) {
                    _sensorBox.add(newSensor);
                  } else {
                    final key = _sensorBox.keyAt(index);
                    _sensorBox.put(key, newSensor);
                  }
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(
                  backgroundColor: _primaryAccentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
              child: Text(
                index == null ? "Add" : "Update",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.only(left: 20, right: 20, bottom: 16),
        );
      },
    );
  }

  // --- Helper for Themed InputDecoration ---
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textColorSecondary.withOpacity(0.8)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _textColorSecondary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: _highlightColor, width: 1.5), // Use purple highlight color
        borderRadius: BorderRadius.circular(10.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _errorColor),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _errorColor, width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      contentPadding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
    );
  }

  // --- Dialog for Deleting Sensor (Themed) ---
  void _confirmDelete(int index) {
    final sensor = _sensorBox.getAt(index);
    if (sensor == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          title: Text(
            "Delete Fence",
            style: TextStyle(
                color: _textColorPrimary, fontWeight: FontWeight.w600),
          ),
          content: Text(
            "Delete '${sensor.name}'?\nThis action cannot be undone.",
            style: TextStyle(color: _textColorSecondary, height: 1.4),
            textAlign: TextAlign.center, // Center align text in confirmation
          ),
          actionsAlignment: MainAxisAlignment.center, // Center align buttons
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: TextStyle(
                      color: _textColorSecondary, fontWeight: FontWeight.w500)),
            ),
            SizedBox(width: 10), // Space between buttons
            TextButton(
              onPressed: () {
                final String deletedName = sensor.name;
                _sensorBox.deleteAt(index);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("'$deletedName' deleted.",
                        style: TextStyle(color: _textColorPrimary)),
                    backgroundColor: _cardBackgroundColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    margin: EdgeInsets.all(15),
                  ),
                );
              },
              style: TextButton.styleFrom(
                  backgroundColor: _errorColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
              child: Text("Delete",
                  style: TextStyle(
                      color: _textColorPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
          actionsPadding: EdgeInsets.only(
              left: 20, right: 20, bottom: 16, top: 10), // Added top padding
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _appBackgroundColor,
        appBar: AppBar(
          title: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                // Use NEW PURPLE gradient colors
                colors: [_gradientStartColor, _gradientEndColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            child: Text(
              "Fences",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          backgroundColor: _appBackgroundColor,
          elevation: 0,
          centerTitle: false,
        ),
        body: ValueListenableBuilder(
          valueListenable: _sensorBox.listenable(),
          builder: (context, Box<Sensor> box, _) {
            if (box.isEmpty) {
              // --- Themed Empty State ---
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fence_outlined,
                        size: 80,
                        color: _textColorSecondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 25),
                      Text(
                        "No Fences Linked",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _textColorPrimary.withOpacity(0.9),
                            fontSize: 22,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Tap the '+' button below to add your first fence.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _textColorSecondary,
                            fontSize: 16,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }

            // --- Grid View with Refined Themed Cards ---
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.82,
              ),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final sensor = box.getAt(index);
                if (sensor == null) return SizedBox.shrink();
                return _buildFenceCard(context, index, sensor);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditSensorDialog(),
          backgroundColor: _primaryAccentColor,
          foregroundColor: Colors.black,
          tooltip: "Add Fence",
          elevation: 6.0,
          child: Icon(Icons.add, size: 30),
        ),
      ),
    );
  }

  // --- Helper Widget for Building Refined Themed Fence Card (CENTER ALIGNED) ---
  Widget _buildFenceCard(BuildContext context, int index, Sensor sensor) {
    return Card(
      elevation: 0,
      color: _cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SensorReadingPage(sensor: sensor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            // *** ALIGNMENT CHANGE: Center align the main content ***
            crossAxisAlignment:
                CrossAxisAlignment.center, // Changed from start to center
            children: [
              // Top Section: Icon and Info (will now be centered)
              Icon(Icons.fence,
                  color: _iconColor, size: 38), // Use purple icon color
              SizedBox(height: 15),
              Text(
                sensor.name,
                textAlign: TextAlign
                    .center, // Ensure text itself is centered if it wraps
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColorPrimary.withOpacity(0.95),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              Text(
                sensor.phoneNumber,
                textAlign: TextAlign.center, // Ensure text itself is centered
                style: TextStyle(color: _textColorSecondary, fontSize: 12),
              ),
              Spacer(), // Pushes buttons to the bottom
              // Bottom Section: Subtle Action Buttons
              // Keep buttons right-aligned at the bottom unless specified otherwise
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Keep buttons center-aligned
                children: [
                  _buildCardIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: "Edit ${sensor.name}",
                    color: _highlightColor
                        .withOpacity(0.6), // Use purple highlight
                    onPressed: () =>
                        _showAddEditSensorDialog(index: index, sensor: sensor),
                  ),
                  SizedBox(width: 8),
                  _buildCardIconButton(
                    icon: Icons.delete_outline,
                    tooltip: "Delete ${sensor.name}",
                    color: _errorColor.withOpacity(0.6),
                    onPressed: () => _confirmDelete(index),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper for *More Subtle* icon buttons within cards ---
  Widget _buildCardIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 18,
      color: color,
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.all(4),
      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
      splashRadius: 18,
      visualDensity: VisualDensity.compact,
    );
  }
}
