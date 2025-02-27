// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub/src/validator.dart';
import 'package:pub/src/validator/language_version.dart';
import 'package:test/test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator validator() => LanguageVersionValidator();

Future<void> setup(
    {required String sdkConstraint, String? libraryLanguageVersion}) async {
  await d.validPackage.create();
  await d.dir(appPath, [
    d.pubspec({
      'name': 'test_pkg',
      'version': '1.0.0',
      'environment': {'sdk': sdkConstraint},
    }),
    d.dir('lib', [
      if (libraryLanguageVersion != null)
        d.file('library.dart', '// @dart = $libraryLanguageVersion\n'),
    ])
  ]).create();
  await pubGet(environment: {'_PUB_TEST_SDK_VERSION': '2.7.0'});
}

void main() {
  group('should consider a package valid if it', () {
    test('has no library-level language version annotations', () async {
      await setup(sdkConstraint: '>=2.4.0 <3.0.0');
      await expectValidation(validator);
    });

    test('opts in to older language versions', () async {
      await setup(
          sdkConstraint: '>=2.4.0 <3.0.0', libraryLanguageVersion: '2.0');
      await d.dir(appPath, []).create();
      await expectValidation(validator);
    });
    test('opts in to same language versions', () async {
      await setup(
          sdkConstraint: '>=2.4.0 <3.0.0', libraryLanguageVersion: '2.4');
      await d.dir(appPath, []).create();
      await expectValidation(validator);
    });

    test('opts in to older language version, with non-range constraint',
        () async {
      await setup(sdkConstraint: '2.7.0', libraryLanguageVersion: '2.3');
      await d.dir(appPath, []).create();
      await expectValidation(validator);
    });
  });

  group('should error if it', () {
    test('opts in to a newer version.', () async {
      await setup(
          sdkConstraint: '>=2.4.1 <3.0.0', libraryLanguageVersion: '2.5');
      await expectValidation(validator, errors: isNotEmpty);
    });
    test('opts in to a newer version, with non-range constraint.', () async {
      await setup(sdkConstraint: '2.7.0', libraryLanguageVersion: '2.8');
      await expectValidation(validator, errors: isNotEmpty);
    });
  });
}
