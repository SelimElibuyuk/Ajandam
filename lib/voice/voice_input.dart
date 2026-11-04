import 'package:speech_to_text/speech_to_text.dart';

typedef VoiceText = void Function(String text, bool isFinal);

enum VoiceError { silence, busy, network, permission, unavailable, other }

/// Tek bir dinleme oturumu. Arayüz eklentiye doğrudan bağlanmaz ki testlerde
/// değiştirilebilsin; sürekli dikteyi [Dictation] yapar.
abstract class VoiceInput {
  /// Dinlemeye başlar. Mikrofon izni yoksa veya tanıma servisi bulunmazsa
  /// false döner. Oturum kendiliğinden bitince [onDone], hata olursa
  /// [onError] çağrılır.
  Future<bool> start({
    required VoiceText onText,
    required void Function() onDone,
    required void Function(VoiceError error) onError,
  });

  Future<void> stop();
}

/// Android'in ses tanıma servisi, Türkçe.
class SpeechVoiceInput implements VoiceInput {
  final _speech = SpeechToText();
  bool _ready = false;
  bool _active = false;
  void Function()? _onDone;
  void Function(VoiceError error)? _onError;

  @override
  Future<bool> start({
    required VoiceText onText,
    required void Function() onDone,
    required void Function(VoiceError error) onError,
  }) async {
    // İlk çağrıda mikrofon izni istenir.
    _ready =
        _ready ||
        await _speech.initialize(
          onStatus: (status) {
            // Önceki oturumun geç gelen “bitti” bildirimi yeni oturumu
            // bitirmesin diye yalnızca dinlemeye geçmiş oturum bildirilir.
            if (status == SpeechToText.listeningStatus) {
              _active = true;
            } else if (_active) {
              _active = false;
              _onDone?.call();
            }
          },
          onError: (error) => _onError?.call(_kind(error.errorMsg)),
        );
    if (!_ready) return false;
    if (_speech.isListening) await _speech.cancel();
    _active = false;
    _onDone = onDone;
    _onError = onError;
    try {
      await _speech.listen(
        onResult: (r) => onText(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: 'tr_TR',
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(minutes: 1),
        ),
      );
    } on ListenFailedException {
      return false;
    }
    return true;
  }

  @override
  Future<void> stop() async {
    _onDone = null;
    _onError = null;
    await _speech.stop();
  }

  static VoiceError _kind(String code) => switch (code) {
    'error_no_match' || 'error_speech_timeout' => VoiceError.silence,
    'error_busy' || 'error_client' => VoiceError.busy,
    'error_network' ||
    'error_network_timeout' ||
    'error_server' ||
    'error_server_disconnected' ||
    'error_too_many_requests' => VoiceError.network,
    'error_permission' => VoiceError.permission,
    'error_language_not_supported' ||
    'error_language_unavailable' => VoiceError.unavailable,
    _ => VoiceError.other,
  };
}
