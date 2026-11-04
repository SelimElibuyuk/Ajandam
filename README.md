# Ajandam

Ana ekran widget'ından iki dokunuşta iş eklenen, Google Takvim ile çift yönlü çalışan sade bir ajanda uygulaması. İlk sürüm Android için.

Ürünün tüm gereksinimleri ve alınan kararlar üst klasördeki `Ajanda — Ürün Gereksinim Dokümanı (PRD).docx` belgesindedir.

## Durum

Faz 2 tamam: Uygulama internetsiz kullanılabilir, ana ekran widget'ı çalışır. Google Takvim (Faz 3) henüz yok.

Çalışanlar:

- Ay (açılış) ve Hafta ekranları, gün görünümü
- Doğal dille hızlı ekleme: `yarın 14:00 dişçi`, `cuma 2 saat sunum`
- Etkinlikler: `14:00-16:00 toplantı`, `saat 3-5 ders`, `5-10 kasım tatil`; hızlı eklemede Görev/Etkinlik düğmesi
- Tekrarlar: `her gün 9:00 ilaç`, `hafta içi her gün 8:30 servis`, `her salı ve perşembe 18:00-19:30 spor`, `2 haftada bir cuma`, `her ayın 5'i kira`, `her yıl 12 mart doğum günü`; bitiş için `14 mart tarihine kadar`, `mart sonuna kadar`, `4 hafta boyunca`, `1 ayın her günü`, `önümüzdeki 10 gün`, `10 kez`; başlangıç için `yarından itibaren`, `10 kasımdan başlayarak`. Tekrarlanan görev kaçırılırsa kendi gününde kalır. Düzenleme ve silmede “Yalnızca bu / Bu ve sonrakiler” sorulur
- Sesle ekleme: hızlı ekleme penceresinde ve widget'ta mikrofon düğmesi; parça parça söylenebilir, her parça sona eklenir. Mikrofona yeniden basınca, Kaydet'e basınca veya 8 saniye sessizlikte durur; kaydetmek elle yapılır
- Düzenleme, tamamlama, silme ve çöp kutusu
- Tamamlanmayan görevlerin ertesi güne taşınması
- Görev ömrü: 2 günde bir hatırlatma, 15 gün sonra silme
- Yerel hatırlatmalar: Tamamlandı, 10 dk ertele, Yarına taşı, Süreyi uzat
- Widget: 2×2, 4×2, 4×4; kutudan tamamlama, `+` ile hızlı ekleme

## Kurulum

Gerekenler: Flutter 3.47 veya üstü, Java 17+, Android SDK 36.

```bash
flutter pub get
```

Telefon USB ile bağlıyken kablosuz da çalışan sürümü kurmak için:

```bash
flutter run --release
```

Geliştirme için (debug sürüm optimize edilmemiştir, takılmalar normaldir; hız ölçümü ve günlük kullanım için release kullan):

```bash
flutter run
```

APK dosyası `build/app/outputs/flutter-apk/app-release.apk` yolunda oluşur.

Xiaomi telefonlarda Geliştirici seçeneklerinden **USB üzerinden yükle** açık olmalı. Hatırlatmaların kaçmaması için Ajandam'ın **Otomatik başlatma** izni açılmalı, pil ayarı **Kısıtlama yok** yapılmalı.

## Komutlar

Testler:

```bash
flutter test
```

Kod analizi:

```bash
flutter analyze
```

Veritabanı şeması (`lib/data/db/tables.dart`) değişince kodu yeniden üret:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Klasörler

| Klasör | İçerik |
|---|---|
| `lib/app/` | Tema, yönlendirme, alt menü |
| `lib/features/` | Ekranlar |
| `lib/domain/` | Saf Dart iş kuralları, Android'e bağımlı değil |
| `lib/data/` | drift tabloları ve depolar |
| `lib/notifications/` | Yerel bildirimler ve arka plan işi |
| `lib/widget_bridge/` | Widget'la veri ve bağlantı köprüsü |
| `lib/ui/` | Ortak bileşenler |
| `android/.../widget/` | Glance widget'ı (Kotlin) |
| `test/` | Birim ve arayüz testleri |

## Teknoloji

Flutter, Riverpod, go_router, drift (SQLite), flutter_local_notifications, workmanager. Widget Kotlin ve Jetpack Glance ile yazıldı, köprü home_widget.

Arayüz Stitch'teki Nocturne Agenda tasarımını izler. Newsreader, Inter ve JetBrains Mono yazı tipleri (SIL Open Font License) `assets/fonts` içinde gömülüdür.

Uygulama kimliği: `com.selimelibuyuk.ajandam`
