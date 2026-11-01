# Ajandam

Ana ekran widget'ından iki dokunuşta iş eklenen, Google Takvim ile çift yönlü çalışan sade bir ajanda uygulaması. İlk sürüm Android için.

Ürünün tüm gereksinimleri ve alınan kararlar üst klasördeki `Ajanda — Ürün Gereksinim Dokümanı (PRD).docx` belgesindedir.

## Durum

Faz 0 kodu yazıldı: Bugün, Hafta ve Ayarlar iskeleti, tema, veritabanı şeması. Sıradaki Faz 1: yerel ajanda.

## Kurulum

Gerekenler: Flutter 3.47 veya üstü, Java 17+, Android SDK 36.

```bash
flutter doctor --android-licenses
```

```bash
flutter pub get
```

```bash
flutter run
```

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
| `lib/data/db/` | drift tabloları ve veritabanı |
| `android/` | Android projesi, widget burada yazılacak |
| `test/` | Birim ve arayüz testleri |

## Teknoloji

Flutter, Riverpod, go_router, drift (SQLite). Widget Kotlin ve Jetpack Glance ile yazılacak.

Uygulama kimliği: `com.selimelibuyuk.ajandam`
