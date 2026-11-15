import 'dart:async';

import 'voice_input.dart';

/// Parça parça dikte: Android her duraklamada oturumu kapatır, burada oturum
/// yeniden açılır ve söylenenler yazılanın sonuna eklenir. Biten parça bir daha
/// değişmez, ara sonuçlar yalnızca son parçayı günceller.
///
/// Kullanıcı durdurunca, [silenceLimit] boyunca hiç kelime gelmeyince veya
/// [maxDuration] dolunca biter.
class Dictation {
  Dictation(
    this._voice, {
    required this.onText,
    required this.onListening,
    required this.onError,
    this.silenceLimit = const Duration(seconds: 8),
    this.maxDuration = const Duration(minutes: 3),
    this.restartDelay = const Duration(milliseconds: 200),
    this.pauseGap = const Duration(milliseconds: 1200),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final VoiceInput _voice;
  final void Function(String text) onText;
  final void Function(bool listening) onListening;
  final void Function(VoiceError error) onError;
  final Duration silenceLimit;
  final Duration maxDuration;
  final Duration restartDelay;

  /// Bu kadar sessizlikten sonra gelen ara sonuç, önceki parçanın devamı
  /// değilse yeni cümledir: önceki parça yerinde kalır.
  final Duration pauseGap;
  final DateTime Function() _now;
  DateTime? _lastHeard;

  /// Biten son parça: önceki oturumun geç gelen sonucu yeni oturuma düşerse
  /// ikinci kez yazılmaz.
  String _lastPart = '';

  bool _active = false;
  int _session = 0;
  int _failures = 0;
  String _committed = '';
  String _segment = '';
  String _written = '';
  final _clock = Stopwatch();
  Timer? _silence;
  Timer? _restart;

  bool get isListening => _active;

  /// Son yazılan metin; kutudaki metin bundan farklıysa kullanıcı düzeltmiştir.
  String get written => _written;

  /// [text] kutudaki metindir, söylenenler sonuna eklenir.
  Future<void> start(String text) async {
    if (_active) return;
    _active = true;
    _failures = 0;
    _committed = text.trim();
    _segment = '';
    _lastPart = '';
    _lastHeard = null;
    _written = text;
    _clock
      ..reset()
      ..start();
    _armSilence();
    onListening(true);
    await _listen();
  }

  Future<void> stop() async {
    if (!_active) return;
    _finish();
    await _voice.stop();
  }

  /// Dinlerken kutu elle değiştirildi: sonraki parçalar bu metnin sonuna eklenir.
  void edited(String text) {
    _committed = text.trim();
    _segment = '';
    _lastPart = '';
    _lastHeard = null;
    _written = text;
  }

  void dispose() {
    if (_active) {
      _finish(notify: false);
      _voice.stop();
    }
  }

  Future<void> _listen() async {
    final session = ++_session;
    final started = await _voice.start(
      onText: (text, isFinal) => _heard(session, text, isFinal),
      onDone: () => _ended(session),
      onError: (error) => _failed(session, error),
    );
    if (!started && session == _session && _active) {
      _finish();
      onError(VoiceError.unavailable);
    }
  }

  void _heard(int session, String text, bool isFinal) {
    final words = text.trim();
    // Boş ara sonuç yazılanı silmesin.
    if (!_active || session != _session || words.isEmpty) return;
    if (_segment.isEmpty && words.toLowerCase() == _lastPart.toLowerCase()) {
      return;
    }
    _failures = 0;
    final now = _now();
    final last = _lastHeard;
    _lastHeard = now;
    // Servis duraklamadan sonra ara sonuçları baştan gönderir; önceki parça
    // kalır.
    final paused = last != null && now.difference(last) >= pauseGap;
    if (_startsOver(words, paused: paused)) _commit();
    _segment = words;
    if (isFinal) _commit();
    _armSilence();
    _written = _join(_committed, _segment);
    onText(_written);
  }

  /// Ara sonuç önceki parçanın devamı değilse yeni cümle başlamıştır.
  ///
  /// Arka arkaya gelen ara sonuçlarda servis son kelimeleri düzeltebilir; bu
  /// yüzden yalnızca kısalıp başka kelimeyle başlayan sonuç yeni sayılır.
  /// Duraklamadan sonra ise devam eden sonuç önceki parçayı aynen tekrarlar
  /// (son kelimesi düzelmiş olabilir); tekrarlamıyorsa yenidir.
  bool _startsOver(String words, {required bool paused}) {
    if (_segment.isEmpty) return false;
    final next = _words(words);
    final prev = _words(_segment);
    if (!paused) {
      return next.length < prev.length && next.first != prev.first;
    }
    final keep = prev.length > 1 ? prev.length - 1 : 1;
    if (next.length < keep) return true;
    for (var i = 0; i < keep; i++) {
      if (next[i] != prev[i]) return true;
    }
    return false;
  }

  static List<String> _words(String text) =>
      text.toLowerCase().split(RegExp(r'\s+'));

  void _ended(int session) {
    if (!_active || session != _session) return;
    _commit();
    _scheduleRestart();
  }

  void _failed(int session, VoiceError error) {
    if (!_active || session != _session) return;
    final retry =
        error == VoiceError.silence ||
        error == VoiceError.busy ||
        error == VoiceError.other;
    if (retry && ++_failures <= 5) {
      _commit();
      _scheduleRestart();
      return;
    }
    _finish();
    onError(error);
  }

  /// Bitiş bildirimi ve hata aynı oturum için art arda gelebilir; tek yeniden
  /// başlatma yapılır.
  void _scheduleRestart() {
    _restart?.cancel();
    if (_clock.elapsed > maxDuration) {
      stop();
      return;
    }
    _restart = Timer(restartDelay, () {
      if (_active) _listen();
    });
  }

  void _armSilence() {
    _silence?.cancel();
    _silence = Timer(silenceLimit, stop);
  }

  void _commit() {
    if (_segment.isNotEmpty) _lastPart = _segment;
    _committed = _join(_committed, _segment);
    _segment = '';
  }

  void _finish({bool notify = true}) {
    _commit();
    _active = false;
    _session++;
    _restart?.cancel();
    _silence?.cancel();
    _clock.stop();
    if (notify) onListening(false);
  }

  static String _join(String a, String b) =>
      a.isEmpty ? b : (b.isEmpty ? a : '$a $b');
}
