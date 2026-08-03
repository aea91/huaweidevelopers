import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:arkuibuild/services/project_generator.dart';
import 'package:flutter_test/flutter_test.dart';

Archive _sampleArchive() {
  return ProjectGenerator.buildArchive(
    projectName: 'DemoApp',
    bundleId: 'com.example.demoapp',
    description: 'A demo generated app',
    primaryColor: '#6200EE',
    secondaryColor: '#03DAC6',
    tertiaryColor: '#FF6B6B',
    isDarkMode: false,
    selectedWidgets: [
      {
        'id': 'w1',
        'title': 'Fancy Card',
        'category': 'Layout',
        'code': '@Component\nexport struct FancyCard {\n  build() {\n    Text(\'hi\')\n  }\n}',
      },
    ],
    selectedManagers: [
      {
        'id': 'm1',
        'title': 'Storage Manager',
        'className': 'StorageManager',
        'exportCode': '',
        'permissions': ['ohos.permission.INTERNET'],
        'code': 'export class StorageManager {}',
      },
    ],
    models: [
      {
        'name': 'User',
        'fields': [
          {'name': 'id', 'type': 'string'},
          {'name': 'age', 'type': 'number'},
        ],
      },
    ],
    sdkVersion: '5.0.5(17)',
  );
}

Map<String, ArchiveFile> _byPath(Archive a) => {
      for (final f in a.files) f.name: f,
    };

String _content(ArchiveFile f) => utf8.decode(f.content as List<int>);

void main() {
  group('ProjectGenerator', () {
    late Archive archive;
    late Map<String, ArchiveFile> files;

    setUp(() {
      archive = _sampleArchive();
      files = _byPath(archive);
    });

    test('emits the full DevEco-style scaffold', () {
      const required = [
        'DemoApp/.gitignore',
        'DemoApp/build-profile.json5',
        'DemoApp/hvigorfile.ts',
        'DemoApp/code-linter.json5',
        'DemoApp/oh-package.json5',
        'DemoApp/hvigor/hvigor-config.json5',
        'DemoApp/AppScope/app.json5',
        'DemoApp/AppScope/resources/base/element/string.json',
        'DemoApp/AppScope/resources/base/media/layered_image.json',
        'DemoApp/AppScope/resources/base/media/background.png',
        'DemoApp/AppScope/resources/base/media/foreground.png',
        'DemoApp/entry/.gitignore',
        'DemoApp/entry/build-profile.json5',
        'DemoApp/entry/hvigorfile.ts',
        'DemoApp/entry/oh-package.json5',
        'DemoApp/entry/obfuscation-rules.txt',
        'DemoApp/entry/src/main/module.json5',
        'DemoApp/entry/src/main/ets/entryability/EntryAbility.ets',
        'DemoApp/entry/src/main/ets/entrybackupability/EntryBackupAbility.ets',
        'DemoApp/entry/src/main/ets/pages/Index.ets',
        'DemoApp/entry/src/main/ets/common/AppTheme.ets',
        'DemoApp/entry/src/main/resources/base/element/color.json',
        'DemoApp/entry/src/main/resources/base/element/float.json',
        'DemoApp/entry/src/main/resources/base/element/string.json',
        'DemoApp/entry/src/main/resources/dark/element/color.json',
        'DemoApp/entry/src/main/resources/base/media/startIcon.png',
        'DemoApp/entry/src/main/resources/base/media/background.png',
        'DemoApp/entry/src/main/resources/base/media/foreground.png',
        'DemoApp/entry/src/main/resources/base/profile/main_pages.json',
        'DemoApp/entry/src/main/resources/base/profile/backup_config.json',
      ];
      for (final path in required) {
        expect(files.containsKey(path), isTrue, reason: 'missing $path');
      }
    });

    test('places selected widgets, managers and models under entry/ets', () {
      expect(files.containsKey('DemoApp/entry/src/main/ets/widgets/FancyCard.ets'),
          isTrue);
      expect(
          files.containsKey(
              'DemoApp/entry/src/main/ets/managers/StorageManager.ets'),
          isTrue);
      expect(files.containsKey('DemoApp/entry/src/main/ets/models/User.ets'),
          isTrue);
    });

    test('all *.json / *.json5 config is parseable strict JSON', () {
      for (final entry in files.entries) {
        if (entry.key.endsWith('.json') || entry.key.endsWith('.json5')) {
          expect(() => jsonDecode(_content(entry.value)), returnsNormally,
              reason: 'invalid JSON in ${entry.key}');
        }
      }
    });

    test('media files are real (non-empty) PNGs', () {
      const pngs = [
        'DemoApp/entry/src/main/resources/base/media/startIcon.png',
        'DemoApp/entry/src/main/resources/base/media/background.png',
        'DemoApp/AppScope/resources/base/media/foreground.png',
      ];
      for (final path in pngs) {
        final bytes = files[path]!.content as List<int>;
        expect(bytes.length, greaterThan(100), reason: '$path too small');
        // PNG magic number: 89 50 4E 47
        expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47],
            reason: '$path is not a PNG');
      }
    });

    test('app.json5 references layered_image and carries the bundle id', () {
      final app = _content(files['DemoApp/AppScope/app.json5']!);
      expect(app, contains('com.example.demoapp'));
      expect(app, contains(r'$media:layered_image'));
    });

    test('module.json5 declares manager permissions with a reason', () {
      final module =
          _content(files['DemoApp/entry/src/main/module.json5']!);
      expect(module, contains('ohos.permission.INTERNET'));
      expect(module, contains(r'$string:permission_reason'));
      expect(module, contains(r'$profile:main_pages'));
    });

    test('Index page imports the theme and lists the selections', () {
      final index = _content(files['DemoApp/entry/src/main/ets/pages/Index.ets']!);
      expect(index, contains("import { AppTheme } from '../common/AppTheme'"));
      expect(index, contains('Fancy Card'));
      expect(index, contains('StorageManager'));
    });

    test('build-profile uses runtimeOS HarmonyOS and the given SDK', () {
      final bp = _content(files['DemoApp/build-profile.json5']!);
      expect(bp, contains('"runtimeOS": "HarmonyOS"'));
      expect(bp, contains('5.0.5(17)'));
    });
  });
}
