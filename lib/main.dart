import 'package:dogcoach/nt_manager.dart';
import 'package:dogcoach/speaker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NT4 Match Time',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.grey.shade700,
          secondary: Colors.grey.shade600,
          surface: Color(0xFF1F1F1F),
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        cardColor: Color(0xFF1F1F1F),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF333333),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: MatchTimePage(),
    );
  }
}

class MatchTimePage extends StatefulWidget {
  const MatchTimePage({super.key});

  @override
  _MatchTimePageState createState() => _MatchTimePageState();
}

class _MatchTimePageState extends State<MatchTimePage> {
  late NT4Manager _nt4Manager;
  late Speaker _speaker;
  final String _defaultServerAddress = '10.21.6.2';
  double _matchTime = 0.0;
  bool _isConnected = false;
  bool _isRobotDisabled = true;
  
  // Alignment data
  Map<String, double> _alignmentData = {
    'currentX': 0.0,
    'currentY': 0.0,
    'currentRotation': 0.0,
    'targetX': 0.0,
    'targetY': 0.0,
    'targetRotation': 0.0,
  };
  
  // Settings
  String _serverAddress = '10.21.6.2';
  bool _autoConnect = true;
  double _volume = 1.0;
  double _xTolerance = 0.0254; // 1 inch in meters
  double _yTolerance = 0.0254; // 1 inch in meters
  double _rotationTolerance = 5.0; // 5 degrees

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _speaker = Speaker();
      await _loadSettings();
      
      if (_autoConnect) {
        _nt4Manager.connectToServer(_serverAddress);
      }
    });
    
    _nt4Manager = NT4Manager(
      initialAddress: _defaultServerAddress,
      onConnectionChanged: (connected) {
        setState(() {
          _isConnected = connected;
        });
      },
      onMatchTimeUpdated: (time) {
        setState(() {
          _matchTime = time;
          // Call speaker whenever time updates
          _speaker.speakTime(time);
        });
      },
      onRobotStateChanged: (isDisabled) {
        setState(() {
          _isRobotDisabled = isDisabled;
        });
      },
      onAlignmentDataUpdated: (data) {
        setState(() {
          _alignmentData = data;
        });
      },
    );
  }

Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _serverAddress = prefs.getString('serverAddress') ?? _defaultServerAddress;
    _autoConnect = prefs.getBool('autoConnect') ?? true;
    _volume = prefs.getDouble('volume') ?? 1.0;
    
    // Load tolerance settings with defaults
    _xTolerance = prefs.getDouble('xTolerance') ?? 0.0254; // 1 inch in meters
    _yTolerance = prefs.getDouble('yTolerance') ?? 0.0254; // 1 inch in meters
    _rotationTolerance = prefs.getDouble('rotationTolerance') ?? 5.0; // 5 degrees
  });
  
  // Update the NT4Manager with the loaded server address
  _nt4Manager.updateServerAddress(_serverAddress);
  
  // Set the volume for the speaker
  _speaker.setVolume(_volume);
}

Future<void> _saveSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('serverAddress', _serverAddress);
  await prefs.setBool('autoConnect', _autoConnect);
  await prefs.setDouble('volume', _volume);
  
  // Save tolerance settings
  await prefs.setDouble('xTolerance', _xTolerance);
  await prefs.setDouble('yTolerance', _yTolerance);
  await prefs.setDouble('rotationTolerance', _rotationTolerance);
}


  @override
  void dispose() {
    _nt4Manager.dispose();
    _speaker.dispose();
    super.dispose();
  }
  
  void _toggleConnection() {
    if (_isConnected) {
      _nt4Manager.disconnect();
    } else {
      _nt4Manager.connectToServer(_serverAddress);
    }
  }
void _openSettings() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String tempServerAddress = _serverAddress;
      bool tempAutoConnect = _autoConnect;
      double tempVolume = _volume;
      double tempXTolerance = _xTolerance;
      double tempYTolerance = _yTolerance;
      double tempRotationTolerance = _rotationTolerance;
      
      return AlertDialog(
        title: Text('Settings'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Address
                  Text('Server Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: tempServerAddress),
                    onChanged: (value) {
                      tempServerAddress = value;
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.computer),
                      hintText: 'Enter robot IP (e.g., 10.21.6.2)',
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Auto Connect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Auto Connect on Startup', style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: tempAutoConnect,
                        onChanged: (value) {
                          setState(() {
                            tempAutoConnect = value;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Volume Slider
                  Text('Volume', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: tempVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (value) {
                            setState(() {
                              tempVolume = value;
                            });
                          },
                        ),
                      ),
                      Icon(Icons.volume_up),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Alignment Tolerances
                  Text('Alignment Tolerances', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  
                  // X Tolerance (in inches, converted to meters)
                  Text('X Tolerance (inches)'),
                  Row(
                    children: [
                      Text('0.5"'),
                      Expanded(
                        child: Slider(
                          value: tempXTolerance * 39.37, // Convert meters to inches for display
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: '${(tempXTolerance * 39.37).toStringAsFixed(1)}"',
                          onChanged: (value) {
                            setState(() {
                              tempXTolerance = value / 39.37; // Convert inches to meters for storage
                            });
                          },
                        ),
                      ),
                      Text('5.0"'),
                    ],
                  ),
                  
                  // Y Tolerance (in inches, converted to meters)
                  Text('Y Tolerance (inches)'),
                  Row(
                    children: [
                      Text('0.5"'),
                      Expanded(
                        child: Slider(
                          value: tempYTolerance * 39.37, // Convert meters to inches for display
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: '${(tempYTolerance * 39.37).toStringAsFixed(1)}"',
                          onChanged: (value) {
                            setState(() {
                              tempYTolerance = value / 39.37; // Convert inches to meters for storage
                            });
                          },
                        ),
                      ),
                      Text('5.0"'),
                    ],
                  ),
                  
                  // Rotation Tolerance (in degrees)
                  Text('Rotation Tolerance (degrees)'),
                  Row(
                    children: [
                      Text('1°'),
                      Expanded(
                        child: Slider(
                          value: tempRotationTolerance,
                          min: 1.0,
                          max: 10.0,
                          divisions: 9,
                          label: '${tempRotationTolerance.toStringAsFixed(1)}°',
                          onChanged: (value) {
                            setState(() {
                              tempRotationTolerance = value;
                            });
                          },
                        ),
                      ),
                      Text('10°'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _serverAddress = tempServerAddress;
                _autoConnect = tempAutoConnect;
                _volume = tempVolume;
                _xTolerance = tempXTolerance;
                _yTolerance = tempYTolerance;
                _rotationTolerance = tempRotationTolerance;
              });
              
              // Update NT4Manager with new server address
              _nt4Manager.updateServerAddress(_serverAddress);
              
              // Update speaker volume
              _speaker.setVolume(_volume);
              
              // Save settings
              await _saveSettings();
              
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.settings, color: Colors.grey),
                          onPressed: _openSettings,
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? 'Connected to $_serverAddress'
                              : 'Disconnected',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _toggleConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isConnected ? const Color.fromARGB(255, 121, 26, 26) : Color(0xFF333333),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        _isConnected ? 'Disconnect' : 'Connect',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),

            // Match Time Display
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MATCH TIME',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFF121212),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _isConnected ? _matchTime.toStringAsFixed(2) : "--.-",
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'SECONDS',
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Alignment Widget
            Visibility(
              visible: _isRobotDisabled,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Auto Pose Alignment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildAlignmentDisplay(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildAlignmentDisplay() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildAlignmentInfo('X', _alignmentData['currentX']!, _alignmentData['targetX']!),
      _buildAlignmentInfo('Y', _alignmentData['currentY']!, _alignmentData['targetY']!),
      _buildAlignmentInfo('Rotation', _alignmentData['currentRotation']!, _alignmentData['targetRotation']!),
    ],
  );
}
Widget _buildAlignmentInfo(String axis, double current, double target) {
  double difference = current - target;
  
  // Use the appropriate tolerance based on the axis
  double tolerance = 0.0254; // Default 1 inch in meters
  String unit = "";
  
  if (axis == 'X') {
    tolerance = _xTolerance;
    unit = "m";
  } else if (axis == 'Y') {
    tolerance = _yTolerance;
    unit = "m";
  } else if (axis == 'Rotation') {
    tolerance = _rotationTolerance;
    unit = "°";
  }
  
  // Determine color based on whether difference is within tolerance
  Color differenceColor = difference.abs() < tolerance ? Colors.green : Colors.red;

  if (axis == 'Rotation') {
    return Column(
      children: [
        Text(axis, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
            color: Color(0xFF1A1A1A),
          ),
          child: Stack(
            children: [
              // Rotation indicator
              Center(
                child: Transform.rotate(
                  angle: current * math.pi / 180, // Convert degrees to radians
                  child: Container(
                    width: 2,
                    height: 80,
                    color: differenceColor,
                  ),
                ),
              ),
              // Target indicator
              Center(
                child: Transform.rotate(
                  angle: target * math.pi / 180,
                  child: Container(
                    width: 80,
                    height: 2,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text('Current: ${current.toStringAsFixed(2)}°'),
        Text('Target: ${target.toStringAsFixed(2)}°'),
        Text(
          'Diff: ${difference.toStringAsFixed(2)}°',
          style: TextStyle(color: differenceColor),
        ),
      ],
    );
  } else {
    // For X and Y axes
    return Column(
      children: [
        Text(axis, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
            color: Color(0xFF1A1A1A),
          ),
          child: Stack(
            children: [
              // Crosshair
              Center(
                child: Container(
                  width: 2,
                  height: 100,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              Center(
                child: Container(
                  width: 100,
                  height: 2,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
              // Target indicator
              Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
              // Current position indicator
              Positioned(
                left: 50 + (difference * 5).clamp(-45, 45),
                top: 50,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: differenceColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text('Current: ${current.toStringAsFixed(2)}$unit'),
        Text('Target: ${target.toStringAsFixed(2)}$unit'),
        Text(
          'Diff: ${difference.toStringAsFixed(2)}$unit',
          style: TextStyle(color: differenceColor),
        ),
      ],
    );
  }
}
}