import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioService {
  final AudioPlayer _player = AudioPlayer(); // For looping drowsiness alarm
  bool _isAlarmPlaying = false;

  AudioService() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playAlarmLoop() async {
    if (_isAlarmPlaying) return;
    try {
      await _player.stop();
      // Ensure the source is set correctly. 
      // Audioplayers expects paths relative to the assets folder if using AssetSource.
      await _player.play(AssetSource('sounds/alarm_beep.mp3'));
      _isAlarmPlaying = true;
    } catch (e) {
      print("AudioService: Error playing drowsiness loop: $e");
    }
  }

  Future<void> stopAlarm() async {
    if (!_isAlarmPlaying) return;
    try {
      await _player.stop();
      _isAlarmPlaying = false;
    } catch (e) {
      print("AudioService: Error stopping drowsiness alarm: $e");
    }
  }

  Future<void> playWarningOnce() async {
    try {
      // Using a local instance for one-shot bursts to prevent state conflicts
      final burstPlayer = AudioPlayer();
      await burstPlayer.setVolume(1.0);
      // Explicitly set source then play
      await burstPlayer.setSource(AssetSource('sounds/alarm_beep.mp3'));
      await burstPlayer.resume();
      
      // Auto-dispose when finished
      burstPlayer.onPlayerComplete.listen((_) {
        burstPlayer.dispose();
      });
    } catch (e) {
      print("AudioService: Error playing speed warning burst: $e");
    }
  }

  bool get isPlaying => _isAlarmPlaying;

  Future<void> dispose() async {
    await _player.dispose();
  }
}
