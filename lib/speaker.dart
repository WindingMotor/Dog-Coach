import 'dart:io' show Directory, File;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class Speaker {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastSpokenSecond = -1;
  bool _isInitialized = false;
  late Directory _audioDirectory;
  double _volume = 1.0;
  final double _boostFactor = 1.8; // Control the amplification

  Speaker() {
    _initAudio();
  }
  
  Future<void> _initAudio() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _audioDirectory = Directory('${appDir.path}/coach_audio');
      
      // Check if directory exists
      if (await _audioDirectory.exists()) {
        _isInitialized = true;
        print("Audio directory found: ${_audioDirectory.path}");
        
        // Set initial volume
        await _audioPlayer.setVolume(_volume);
      } else {
        print("Audio directory not found: ${_audioDirectory.path}");
      }
    } catch (e) {
      print("Audio initialization error: $e");
    }
  }
  
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _audioPlayer.setVolume(volume);
    print("Volume set to: $_volume");
  }
  
  Future<void> speakTime(double matchTime) async {
    if (!_isInitialized) return;
    
    // Convert to int to get the whole second
    int currentSecond = matchTime.floor();
    
    // Only speak if this is a new second
    if (currentSecond != _lastSpokenSecond) {
      _lastSpokenSecond = currentSecond;
      
      String? fileName;
      
      // Handle specific time points
      if(currentSecond == 120) {
        fileName = "120.wav"; // 2 minutes
      } else if (currentSecond == 60) {
        fileName = "60.wav"; // 1 minute
      } else if (currentSecond == 30) {
        fileName = "30.wav"; // 30 seconds
      } else if (currentSecond == 15) {
        fileName = "endgame.wav"; // Play endgame at 15 seconds
      } else if (currentSecond >= 1 && currentSecond <= 14) {
        // Regular countdown from 14 to 1
        fileName = "$currentSecond.wav";
      } else {
        return; // Don't play anything for other times
      }
      
    final audioFile = File('${_audioDirectory.path}/$fileName');
    
    if (await audioFile.exists()) {
      print("Playing boosted audio for $currentSecond seconds: ${audioFile.path}");
      await _playBoostedAudio(audioFile.path);
    } else {
      print("Audio file not found: ${audioFile.path}");
    }
    }
}

Future<void> _playBoostedAudio(String filePath) async {
  final player = AudioPlayer();
  await player.setFilePath(filePath);
  await player.setVolume(_volume * _boostFactor);
  await player.play();
}

  
  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
  }
}
