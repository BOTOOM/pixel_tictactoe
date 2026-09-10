import 'package:audioplayers/audioplayers.dart';

/// Chiptune SFX + looping BGM. Every play call is wrapped so audio failures
/// (headless tests, web autoplay policy) never crash the game.
class GameAudio {
  final AudioPlayer _bgm = AudioPlayer();
  final List<AudioPlayer> _sfx = [
    for (var i = 0; i < 3; i++) AudioPlayer(),
  ];
  int _nextSfx = 0;
  bool _bgmStarted = false;

  bool muted = false;

  static const double _bgmVolume = 0.18;

  Future<void> startBgm() async {
    if (_bgmStarted) return;
    _bgmStarted = true;
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(muted ? 0 : _bgmVolume);
      await _bgm.play(AssetSource('sounds/bgm.wav'));
    } catch (_) {
      _bgmStarted = false;
    }
  }

  Future<void> _play(String name, double volume) async {
    if (muted) return;
    try {
      final p = _sfx[_nextSfx];
      _nextSfx = (_nextSfx + 1) % _sfx.length;
      await p.setReleaseMode(ReleaseMode.release);
      await p.setVolume(volume);
      await p.play(AssetSource('sounds/$name.wav'));
    } catch (_) {}
  }

  Future<void> placeX() => _play('place_x', 0.7);
  Future<void> placeO() => _play('place_o', 0.7);
  Future<void> win() => _play('win', 0.9);
  Future<void> draw() => _play('draw', 0.9);

  void setMuted(bool m) {
    muted = m;
    try {
      _bgm.setVolume(m ? 0 : _bgmVolume);
    } catch (_) {}
  }

  void dispose() {
    try {
      _bgm.dispose();
      for (final p in _sfx) {
        p.dispose();
      }
    } catch (_) {}
  }
}
