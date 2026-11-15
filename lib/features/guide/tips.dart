import 'package:flutter/widgets.dart';

import '../../ui/coach_tour.dart';

/// Ana ekran ipuçlarının hedefleri; yalnızca Ay ekranında ve alt çubukta
/// birer kez kullanılır.
abstract final class HomeTipKeys {
  static final add = GlobalKey(debugLabel: 'tip-add');
  static final habits = GlobalKey(debugLabel: 'tip-habits');
  static final nav = GlobalKey(debugLabel: 'tip-nav');
  static final settings = GlobalKey(debugLabel: 'tip-settings');
}

List<CoachStep> homeTips() => [
  const CoachStep(
    title: 'Ajandam\'a hoş geldin',
    text:
        'En çok widget ile işe yarar: ana ekranda boş bir yere basılı tut, '
        'Widget\'lar bölümünden Ajandam\'ı seç. Bugünü görür, + ile ekler, '
        'tik atarsın.',
  ),
  CoachStep(
    target: HomeTipKeys.add,
    title: 'Hızlı ekle',
    text: 'Dokun ve tek satır yaz; günü ve saati kendisi anlar.',
    example: 'yarın 15:30 dişçi',
  ),
  CoachStep(
    target: HomeTipKeys.habits,
    title: 'Alışkanlıklar',
    text:
        '+ ile alışkanlık ekle. Sekmesine dokununca takvimde hangi günler '
        'yaptığını görürsün.',
  ),
  CoachStep(
    target: HomeTipKeys.nav,
    title: 'Hafta ve Ay',
    text: 'Buradan ya da sağa sola kaydırarak geçiş yaparsın.',
  ),
  CoachStep(
    target: HomeTipKeys.settings,
    title: 'Ayarlar',
    text:
        'Renk teması, hatırlatma saatleri, widget ve ayrıntılı kullanım '
        'rehberi burada.',
  ),
];

/// Ekleme kutusunun hedefleri; her pencere kendi anahtarlarını taşır.
class QuickAddTipKeys {
  final field = GlobalKey(debugLabel: 'tip-field');
  final chips = GlobalKey(debugLabel: 'tip-chips');
  final kind = GlobalKey(debugLabel: 'tip-kind');
  final mic = GlobalKey(debugLabel: 'tip-mic');
}

List<CoachStep> quickAddTips(QuickAddTipKeys keys) => [
  CoachStep(
    target: keys.field,
    title: 'Konuşur gibi yaz',
    text:
        'Gün, saat ve tekrarı ayrıca seçmene gerek yok. Anladığı kelimeler '
        'renklenir, gerisi görevin adı olur. Küçük yazım hatalarını düzeltir.',
    example: 'her pazartesi 19:00 spor',
  ),
  CoachStep(
    target: keys.chips,
    title: 'Anladıkları',
    text:
        'Anladığı gün, saat ve tekrar burada düğme olur. Yanlışsa × ile kaldır, '
        'kelime görevin adında kalır. Dokunup elle de seçebilirsin.',
  ),
  CoachStep(
    target: keys.kind,
    title: 'Görev mi, etkinlik mi?',
    text:
        'Saat aralığı, süre ya da gün aralığı yazınca etkinlik olur. Elle '
        'değiştirmek için dokun.',
    example: 'cuma 14-16 toplantı',
  ),
  CoachStep(
    target: keys.mic,
    title: 'Sesle söyle',
    text:
        'Yazmak yerine konuş; kısa duraklamalarda dinlemeye devam eder. Daha '
        'çok örnek: Ayarlar › Kullanım rehberi.',
  ),
];
