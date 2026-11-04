import 'package:ajandam/voice/dictation.dart';
import 'package:ajandam/voice/voice_input.dart';
import 'package:flutter_test/flutter_test.dart';

class _Voice implements VoiceInput {
  VoiceText? onText;
  void Function()? onDone;
  void Function(VoiceError error)? onError;
  int starts = 0;
  bool stopped = false;
  bool available = true;

  @override
  Future<bool> start({
    required VoiceText onText,
    required void Function() onDone,
    required void Function(VoiceError error) onError,
  }) async {
    this.onText = onText;
    this.onDone = onDone;
    this.onError = onError;
    starts++;
    return available;
  }

  @override
  Future<void> stop() async => stopped = true;
}

void main() {
  late _Voice voice;
  late Dictation dictation;
  late String text;
  late List<bool> states;
  late List<VoiceError> errors;

  const restart = Duration(milliseconds: 5);
  Future<void> waitRestart() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    voice = _Voice();
    text = '';
    states = [];
    errors = [];
    dictation = Dictation(
      voice,
      onText: (t) => text = t,
      onListening: states.add,
      onError: errors.add,
      silenceLimit: const Duration(milliseconds: 200),
      restartDelay: restart,
    );
  });
  tearDown(() => dictation.dispose());

  test('ara sonuçlar son parçayı günceller, bitince parça kalır', () async {
    await dictation.start('');
    voice.onText!('yarın', false);
    voice.onText!('yarın 14', false);
    voice.onText!('yarın 14:00 dişçi', true);
    expect(text, 'yarın 14:00 dişçi');
    expect(states, [true]);
  });

  test('oturum bitince yeniden dinler, parçalar sona eklenir', () async {
    await dictation.start('market');
    voice.onText!('süt al', true);
    voice.onDone!();
    await waitRestart();

    expect(voice.starts, 2);
    expect(dictation.isListening, isTrue);
    voice.onText!('ekmek al', false);
    expect(text, 'market süt al ekmek al');
  });

  test('yeni cümlede baştan gelen ara sonuç önceki parçayı silmez', () async {
    await dictation.start('');
    voice.onText!('yarın saat dörtte toplantı', false);
    voice.onText!('raporu', false);
    expect(text, 'yarın saat dörtte toplantı raporu');
  });

  test('boş ara sonuç yazılanı silmez', () async {
    await dictation.start('');
    voice.onText!('dişçi', false);
    voice.onText!('', false);
    expect(text, 'dişçi');
  });

  test('sessizlikte yeniden dener, uzun sessizlikte durur', () async {
    await dictation.start('');
    voice.onError!(VoiceError.silence);
    await waitRestart();
    expect(voice.starts, 2);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(dictation.isListening, isFalse);
    expect(voice.stopped, isTrue);
    expect(states, [true, false]);
    expect(errors, isEmpty);
  });

  test(
    'aynı oturumun hem hatası hem bitişi tek yeniden başlatma yapar',
    () async {
      await dictation.start('');
      voice.onError!(VoiceError.silence);
      voice.onDone!();
      await waitRestart();
      expect(voice.starts, 2);
    },
  );

  test('izin hatası dinlemeyi bitirir', () async {
    await dictation.start('');
    voice.onError!(VoiceError.permission);
    expect(dictation.isListening, isFalse);
    expect(errors, [VoiceError.permission]);
  });

  test('servis yoksa hata verir', () async {
    voice.available = false;
    await dictation.start('');
    expect(dictation.isListening, isFalse);
    expect(errors, [VoiceError.unavailable]);
  });

  test('kutu elle düzeltilirse sonraki parça ona eklenir', () async {
    await dictation.start('');
    voice.onText!('dişci', true);
    dictation.edited('dişçi');
    voice.onText!('randevusu', false);
    expect(text, 'dişçi randevusu');
  });

  test('durdurulunca geç gelen sonuç yazılmaz', () async {
    await dictation.start('');
    voice.onText!('kitap', false);
    await dictation.stop();
    voice.onText!('kitap oku', true);
    voice.onDone!();
    await waitRestart();
    expect(text, 'kitap');
    expect(voice.starts, 1);
  });
}
