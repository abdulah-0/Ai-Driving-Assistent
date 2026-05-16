import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playAlarmLoop() async {
    if (_isPlaying) return;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(AssetSource('sounds/alarm_beep.mp3'));
    await _player.setVolume(1.0);
    await _player.resume();
    _isPlaying = true;
  }

  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    await _player.stop();
    _isPlaying = false;
  }

  bool get isPlaying => _isPlaying;

  Future<void> dispose() async {
    await _player.dispose();
  }
}
