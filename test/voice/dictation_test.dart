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
  late DateTime clock;
  void wait(int ms) => clock = clock.add(Duration(milliseconds: ms));

  const restart = Duration(milliseconds: 5);
  Future<void> waitRestart() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    voice = _Voice();
    text = '';
    states = [];
    errors = [];
    clock = DateTime(2026);
    dictation = Dictation(
      voice,
      onText: (t) => text = t,
      onListening: states.add,
      onError: errors.add,
      silenceLimit: const Duration(milliseconds: 200),
      restartDelay: restart,
      now: () => clock,
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

  test('duraklamadan sonra gelen uzun cümle önceki parçayı silmez', () async {
    await dictation.start('');
    voice.onText!('yarın saat dörtte', false);
    wait(300);
    voice.onText!('yarın saat dörtte toplantı', false);
    wait(2500);
    voice.onText!('müdürle ofiste konuşulacak', false);
    wait(300);
    voice.onText!('müdürle ofiste konuşulacak konular', false);
    expect(
      text,
      'yarın saat dörtte toplantı müdürle ofiste konuşulacak konular',
    );
  });

  test(
    'duraklamadan sonra aynı kelimeyle başlayan yeni cümle eklenir',
    () async {
      await dictation.start('');
      voice.onText!('saat üçte dişçi', false);
      wait(2000);
      voice.onText!('saat beşte spor salonu', false);
      expect(text, 'saat üçte dişçi saat beşte spor salonu');
    },
  );

  test('duraklamadan sonra cümle sürerse tek parça kalır', () async {
    await dictation.start('');
    voice.onText!('market alışverişi', false);
    wait(2000);
    voice.onText!('market alışverişi süt ekmek', false);
    expect(text, 'market alışverişi süt ekmek');
  });

  test('hızlı düzeltmede son kelime değişebilir', () async {
    await dictation.start('');
    voice.onText!('yarın saat üç', false);
    wait(200);
    voice.onText!('yarın saat 3 te', false);
    expect(text, 'yarın saat 3 te');
  });

  test('önceki oturumun geç sonucu ikinci kez yazılmaz', () async {
    await dictation.start('');
    voice.onText!('ilaç al', true);
    voice.onDone!();
    await waitRestart();
    voice.onText!('ilaç al', true);
    voice.onText!('akşam', false);
    expect(text, 'ilaç al akşam');
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
