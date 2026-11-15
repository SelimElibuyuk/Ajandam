import 'dart:io';

import 'package:ajandam/app/version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uygulamadaki sürüm pubspec.yaml ile aynı', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(
      r'^version:\s*(\S+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(appVersion, m[1], reason: 'dart run tool/bump_version.dart');
    expect(appBuild, int.parse(m[2]!));
  });
}
