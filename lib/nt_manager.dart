import 'package:nt4/nt4.dart';
import 'dart:async';

// nt_manager.dart

// nt_manager.dart
class NT4Manager {
  NT4Client? _client;
  NT4Subscription? _matchTimeSub;
  NT4Subscription? _disabledSub;
  NT4Subscription? _currentXSub;
  NT4Subscription? _currentYSub;
  NT4Subscription? _currentRotationSub;
  NT4Subscription? _targetXSub;
  NT4Subscription? _targetYSub;
  NT4Subscription? _targetRotationSub;
  
  String _serverAddress = '';
  bool _isConnected = false;
  StreamSubscription? _matchTimeStreamSub;
  StreamSubscription? _disabledStreamSub;
  StreamSubscription? _currentXStreamSub;
  StreamSubscription? _currentYStreamSub;
  StreamSubscription? _currentRotationStreamSub;
  StreamSubscription? _targetXStreamSub;
  StreamSubscription? _targetYStreamSub;
  StreamSubscription? _targetRotationStreamSub;
  
  final Function(bool) _onConnectionChanged;
  final Function(double) _onMatchTimeUpdated;
  final Function(bool)? _onRobotStateChanged;
  final Function(Map<String, double>)? _onAlignmentDataUpdated;
  
  // Robot state and alignment data
  bool _isDisabled = true;
  double _currentX = 0.0;
  double _currentY = 0.0;
  double _currentRotation = 0.0;
  double _targetX = 0.0;
  double _targetY = 0.0;
  double _targetRotation = 0.0;

  NT4Manager({
    required String initialAddress,
    required Function(bool) onConnectionChanged,
    required Function(double) onMatchTimeUpdated,
    Function(bool)? onRobotStateChanged,
    Function(Map<String, double>)? onAlignmentDataUpdated,
  }) : 
    _serverAddress = initialAddress,
    _onConnectionChanged = onConnectionChanged,
    _onMatchTimeUpdated = onMatchTimeUpdated,
    _onRobotStateChanged = onRobotStateChanged,
    _onAlignmentDataUpdated = onAlignmentDataUpdated;

  bool get isConnected => _isConnected;
  String get serverAddress => _serverAddress;
  bool get isDisabled => _isDisabled;

  Map<String, double> get alignmentData => {
    'currentX': _currentX,
    'currentY': _currentY,
    'currentRotation': _currentRotation,
    'targetX': _targetX,
    'targetY': _targetY,
    'targetRotation': _targetRotation,
  };

  void updateServerAddress(String address) {
    if (_serverAddress != address) {
      _serverAddress = address;
      
      // If currently connected, reconnect to the new address
      if (_isConnected) {
        disconnect();
        connectToServer(address);
      }
    }
  }

  void connectToServer(String address) {
    // Disconnect if already connected
    disconnect();

    _serverAddress = address;

    _client = NT4Client(
      serverBaseAddress: _serverAddress,
      onConnect: () {
        print('NT4 Client Connected to $_serverAddress');
        _isConnected = true;
        _onConnectionChanged(_isConnected);
        _subscribeToTopics();
      },
      onDisconnect: () {
        print('NT4 Client Disconnected');
        _isConnected = false;
        _onConnectionChanged(_isConnected);
        _onMatchTimeUpdated(0.0);
        if (_onRobotStateChanged != null) {
          _onRobotStateChanged(true); // Default to disabled when disconnected
        }
      },
    );
  }

  void disconnect() {
    _cancelAllSubscriptions();
    _client = null;
    _isConnected = false;
    _onConnectionChanged(_isConnected);
  }

  void _cancelAllSubscriptions() {
    _matchTimeStreamSub?.cancel();
    _disabledStreamSub?.cancel();
    _currentXStreamSub?.cancel();
    _currentYStreamSub?.cancel();
    _currentRotationStreamSub?.cancel();
    _targetXStreamSub?.cancel();
    _targetYStreamSub?.cancel();
    _targetRotationStreamSub?.cancel();
    
    _matchTimeStreamSub = null;
    _disabledStreamSub = null;
    _currentXStreamSub = null;
    _currentYStreamSub = null;
    _currentRotationStreamSub = null;
    _targetXStreamSub = null;
    _targetYStreamSub = null;
    _targetRotationStreamSub = null;
    
    _matchTimeSub = null;
    _disabledSub = null;
    _currentXSub = null;
    _currentYSub = null;
    _currentRotationSub = null;
    _targetXSub = null;
    _targetYSub = null;
    _targetRotationSub = null;
  }

  void _subscribeToTopics() {
    if (_client == null) return;
    
    // Create subscription options with default parameters
    NT4SubscriptionOptions options = NT4SubscriptionOptions(
      periodicRateSeconds: 0.1, // Update every 100ms
      all: false,
      topicsOnly: false,
      prefix: false,
    );
    
    // Subscribe to match time
    _matchTimeSub = _client!.subscribe('/SmartDashboard/MatchTime', options);
    _matchTimeStreamSub = _matchTimeSub!.stream().listen((data) {
      if (data != null) {
        double matchTime = _parseNumericValue(data);
        _onMatchTimeUpdated(matchTime);
      }
    });
    
    // Subscribe to robot state
    _disabledSub = _client!.subscribe('/SmartDashboard/Disabled', options);
    _disabledStreamSub = _disabledSub!.stream().listen((data) {
      if (data != null && data is bool) {
        _isDisabled = data;
        if (_onRobotStateChanged != null) {
          _onRobotStateChanged(_isDisabled);
        }
      }
    });
    
    // Subscribe to alignment data
    _subscribeToAlignmentData();
  }
  
  void _subscribeToAlignmentData() {
    if (_client == null) return;
    
    NT4SubscriptionOptions options = NT4SubscriptionOptions(
      periodicRateSeconds: 0.1,
      all: false,
      topicsOnly: false,
      prefix: false,
    );
    
    // Current position
    _currentXSub = _client!.subscribe('/SmartDashboard/CurrentX', options);
    _currentXStreamSub = _currentXSub!.stream().listen((data) {
      if (data != null) {
        _currentX = _parseNumericValue(data);
        _updateAlignmentData();
      }
    });
    
    _currentYSub = _client!.subscribe('/SmartDashboard/CurrentY', options);
    _currentYStreamSub = _currentYSub!.stream().listen((data) {
      if (data != null) {
        _currentY = _parseNumericValue(data);
        _updateAlignmentData();
      }
    });
    
    _currentRotationSub = _client!.subscribe('/SmartDashboard/CurrentRotation', options);
    _currentRotationStreamSub = _currentRotationSub!.stream().listen((data) {
      if (data != null) {
        _currentRotation = _parseNumericValue(data);
        _updateAlignmentData();
      }
    });
    
    // Target position
    _targetXSub = _client!.subscribe('/SmartDashboard/TargetX', options);
    _targetXStreamSub = _targetXSub!.stream().listen((data) {
      if (data != null) {
        _targetX = _parseNumericValue(data);
        _updateAlignmentData();
      }
    });
    
    _targetYSub = _client!.subscribe('/SmartDashboard/TargetY', options);
    _targetYStreamSub = _targetYSub!.stream().listen((data) {
      if (data != null) {
        _targetY = _parseNumericValue(data);
        _updateAlignmentData();
      }
    });
    
    _targetRotationSub = _client!.subscribe('/SmartDashboard/TargetRotation', options);
    _targetRotationStreamSub = _targetRotationSub!.stream().listen((data) {
      if (data != null) {
        _targetRotation = _parseNumericValue(data);
        _updateAlignmentData();
      }
    });
  }
  
  void _updateAlignmentData() {
    if (_onAlignmentDataUpdated != null) {
      _onAlignmentDataUpdated(alignmentData);
    }
  }
  
  double _parseNumericValue(dynamic data) {
    if (data is double) {
      return data;
    } else if (data is int) {
      return data.toDouble();
    } else if (data is String) {
      return double.tryParse(data) ?? 0.0;
    } else if (data is num) {
      return data.toDouble();
    }
    return 0.0;
  }

  void dispose() {
    disconnect();
  }
}
