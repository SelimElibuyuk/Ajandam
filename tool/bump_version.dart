// Sürümü artırır ve uygulamadaki sürüm sabitini yeniler.
//
//   dart run tool/bump_version.dart patch   # hata düzeltmesi: 0.2.0 → 0.2.1
//   dart run tool/bump_version.dart minor   # yeni özellik:     0.2.1 → 0.3.0
//   dart run tool/bump_version.dart major   # büyük değişiklik: 0.3.0 → 1.0.0
//   dart run tool/bump_version.dart build   # yalnızca yapı numarası
//
// Her çağrıda yapı numarası (+N, Android versionCode) bir artar.
import 'dart:io';

void main(List<String> args) {
  final kind = args.isEmpty ? 'patch' : args.first;
  if (!{'patch', 'minor', 'major', 'build'}.contains(kind)) {
    stderr.writeln(
      'Kullanım: dart run tool/bump_version.dart '
      '[patch|minor|major|build]',
    );
    exit(64);
  }

  final pubspec = File('pubspec.yaml');
  final text = pubspec.readAsStringSync();
  final line = RegExp(
    r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
    multiLine: true,
  );
  final m = line.firstMatch(text);
  if (m == null) {
    stderr.writeln('pubspec.yaml içinde "version: X.Y.Z+N" bulunamadı.');
    exit(1);
  }
  var major = int.parse(m[1]!);
  var minor = int.parse(m[2]!);
  var patch = int.parse(m[3]!);
  final build = int.parse(m[4]!) + 1;
  switch (kind) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
    case 'minor':
      minor++;
      patch = 0;
    case 'patch':
      patch++;
  }
  final name = '$major.$minor.$patch';

  pubspec.writeAsStringSync(
    text.replaceRange(m.start, m.end, 'version: $name+$build'),
  );
  File('lib/app/version.dart').writeAsStringSync(versionFile(name, build));
  stdout.writeln('${m[1]}.${m[2]}.${m[3]}+${m[4]} → $name+$build');
}

String versionFile(String name, int build) =>
    '''
// tool/bump_version.dart üretir; elle değiştirme.

/// Kullanıcının gördüğü sürüm (pubspec.yaml ile aynı).
const appVersion = '$name';

/// Android versionCode.
const appBuild = $build;
''';
