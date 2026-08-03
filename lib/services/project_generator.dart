import 'dart:convert';
import 'package:archive/archive.dart';

import 'project_template_assets.dart';
import 'project_download_stub.dart'
    if (dart.library.html) 'project_download_web.dart';

/// Generates a complete, runnable HarmonyOS (Stage model) project as a .zip,
/// mirroring the structure DevEco Studio creates for a default project so it
/// opens and builds without manual fixing.
///
/// Layout (single `entry` module):
///   `<project>/`
///     `AppScope/`                app.json5 + app resources (icon media)
///     `entry/`                   the HAP module
///       `src/main/ets/`          entryability, pages, theme, managers, models, widgets
///       `src/main/resources/`    element / media / profile resources
///     build-profile.json5, hvigorfile.ts, oh-package.json5, code-linter.json5
///     hvigor/hvigor-config.json5
class ProjectGenerator {
  static const String _defaultSdkVersion = '5.0.5(17)';

  static Future<void> generateAndDownload({
    required String projectName,
    required String bundleId,
    required String description,
    required String primaryColor,
    required String secondaryColor,
    required String tertiaryColor,
    required bool isDarkMode,
    required List<Map<String, dynamic>> selectedWidgets,
    required List<Map<String, dynamic>> selectedManagers,
    required List<Map<String, dynamic>> models,
    String? sdkVersion,
  }) async {
    final archive = buildArchive(
      projectName: projectName,
      bundleId: bundleId,
      description: description,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      isDarkMode: isDarkMode,
      selectedWidgets: selectedWidgets,
      selectedManagers: selectedManagers,
      models: models,
      sdkVersion: sdkVersion,
    );

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      downloadZip(zipData, '$projectName.zip');
    }
  }

  /// Builds the in-memory project [Archive]. Pure (no browser APIs) so it can
  /// be unit-tested off-web.
  static Archive buildArchive({
    required String projectName,
    required String bundleId,
    required String description,
    required String primaryColor,
    required String secondaryColor,
    required String tertiaryColor,
    required bool isDarkMode,
    required List<Map<String, dynamic>> selectedWidgets,
    required List<Map<String, dynamic>> selectedManagers,
    required List<Map<String, dynamic>> models,
    String? sdkVersion,
  }) {
    final archive = Archive();
    final resolvedSdkVersion = (sdkVersion == null || sdkVersion.trim().isEmpty)
        ? _defaultSdkVersion
        : sdkVersion.trim();
    final modelVersion = _modelVersion(resolvedSdkVersion);

    _addProjectFiles(
      archive,
      projectName: projectName,
      bundleId: bundleId,
      description: description,
      sdkVersion: resolvedSdkVersion,
      modelVersion: modelVersion,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      tertiaryColor: tertiaryColor,
      isDarkMode: isDarkMode,
      widgets: selectedWidgets,
      managers: selectedManagers,
      models: models,
    );
    return archive;
  }

  static void _addProjectFiles(
    Archive archive, {
    required String projectName,
    required String bundleId,
    required String description,
    required String sdkVersion,
    required String modelVersion,
    required String primaryColor,
    required String secondaryColor,
    required String tertiaryColor,
    required bool isDarkMode,
    required List<Map<String, dynamic>> widgets,
    required List<Map<String, dynamic>> managers,
    required List<Map<String, dynamic>> models,
  }) {
    final p = projectName;

    // ---- Project root ------------------------------------------------------
    _text(archive, '$p/.gitignore', _rootGitignore());
    _text(archive, '$p/build-profile.json5', _appBuildProfile(sdkVersion));
    _text(archive, '$p/hvigorfile.ts', _appHvigorfile());
    _text(archive, '$p/code-linter.json5', _codeLinter());
    _text(archive, '$p/oh-package.json5', _appOhPackage(modelVersion));
    _text(archive, '$p/local.properties', _localProperties());
    _text(archive, '$p/hvigor/hvigor-config.json5', _hvigorConfig(modelVersion));
    _text(archive, '$p/README.md',
        _readme(projectName, description, widgets, managers, models));

    // ---- AppScope ----------------------------------------------------------
    _text(archive, '$p/AppScope/app.json5', _appJson(bundleId));
    _text(archive, '$p/AppScope/resources/base/element/string.json',
        _appScopeString(projectName));
    _text(archive, '$p/AppScope/resources/base/media/layered_image.json',
        _layeredImage());
    _binary(archive, '$p/AppScope/resources/base/media/background.png',
        kBackgroundPngBase64);
    _binary(archive, '$p/AppScope/resources/base/media/foreground.png',
        kForegroundPngBase64);

    // ---- entry module config ----------------------------------------------
    _text(archive, '$p/entry/.gitignore', _entryGitignore());
    _text(archive, '$p/entry/build-profile.json5', _entryBuildProfile());
    _text(archive, '$p/entry/hvigorfile.ts', _entryHvigorfile());
    _text(archive, '$p/entry/obfuscation-rules.txt', _obfuscationRules());
    _text(archive, '$p/entry/oh-package.json5', _entryOhPackage());
    _text(archive, '$p/entry/src/main/module.json5', _moduleJson(managers));

    // ---- entry sources -----------------------------------------------------
    _text(archive, '$p/entry/src/main/ets/entryability/EntryAbility.ets',
        _entryAbility());
    _text(
        archive,
        '$p/entry/src/main/ets/entrybackupability/EntryBackupAbility.ets',
        _entryBackupAbility());
    _text(archive, '$p/entry/src/main/ets/common/AppTheme.ets',
        _theme(primaryColor, secondaryColor, tertiaryColor, isDarkMode));
    _text(archive, '$p/entry/src/main/ets/pages/Index.ets',
        _indexPage(projectName, description, widgets, managers, models));

    for (final m in managers) {
      final className = _sanitize((m['className'] ?? 'Manager').toString());
      final code = (m['code'] ?? '').toString().trim();
      if (code.isEmpty) continue;
      _text(archive, '$p/entry/src/main/ets/managers/$className.ets', '$code\n');
    }
    for (final model in models) {
      final name = _sanitize((model['name'] ?? 'Model').toString());
      _text(archive, '$p/entry/src/main/ets/models/$name.ets',
          _modelCode(model, name));
    }
    for (final w in widgets) {
      final name = _widgetFileName(w);
      final code = (w['code'] ?? '').toString().trim();
      _text(archive, '$p/entry/src/main/ets/widgets/$name.ets',
          code.isEmpty ? _emptyWidget(name) : '$code\n');
    }

    // ---- entry resources ---------------------------------------------------
    _text(archive, '$p/entry/src/main/resources/base/element/color.json',
        _entryColorLight());
    _text(archive, '$p/entry/src/main/resources/base/element/float.json',
        _entryFloat());
    _text(archive, '$p/entry/src/main/resources/base/element/string.json',
        _entryString(projectName, managers));
    _text(archive, '$p/entry/src/main/resources/dark/element/color.json',
        _entryColorDark());
    _text(archive, '$p/entry/src/main/resources/base/media/layered_image.json',
        _layeredImage());
    _binary(archive, '$p/entry/src/main/resources/base/media/background.png',
        kBackgroundPngBase64);
    _binary(archive, '$p/entry/src/main/resources/base/media/foreground.png',
        kForegroundPngBase64);
    _binary(archive, '$p/entry/src/main/resources/base/media/startIcon.png',
        kStartIconPngBase64);
    _text(archive, '$p/entry/src/main/resources/base/profile/main_pages.json',
        _mainPages());
    _text(archive, '$p/entry/src/main/resources/base/profile/backup_config.json',
        _backupConfig());
  }

  // ==========================================================================
  // Archive helpers
  // ==========================================================================

  static void _text(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static void _binary(Archive archive, String path, String base64Data) {
    final bytes = base64.decode(base64Data);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  // ==========================================================================
  // Naming / version helpers
  // ==========================================================================

  /// Extracts the model version prefix (e.g. `6.0.1` from `6.0.1(21)`).
  static String _modelVersion(String sdkVersion) {
    final idx = sdkVersion.indexOf('(');
    final prefix = (idx > 0 ? sdkVersion.substring(0, idx) : sdkVersion).trim();
    return prefix.isEmpty ? '5.0.5' : prefix;
  }

  /// Sanitizes a name into a valid ArkTS file/identifier fragment.
  static String _sanitize(String raw) {
    var s = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    if (s.isEmpty) s = 'Item';
    if (RegExp(r'^[0-9]').hasMatch(s)) s = 'W$s';
    return s;
  }

  static String _widgetFileName(Map<String, dynamic> w) {
    final title = (w['title'] ?? '').toString();
    final fromTitle = _sanitize(title);
    if (fromTitle != 'Item') return fromTitle;
    return _sanitize((w['id'] ?? 'Widget').toString());
  }

  static String _esc(String s) => s.replaceAll('\\', r'\\').replaceAll("'", r"\'");

  // ==========================================================================
  // Project-root files
  // ==========================================================================

  static String _rootGitignore() => '''/node_modules
/oh_modules
/local.properties
/.idea
**/build
/.hvigor
.cxx
/.clangd
/.clang-format
/.clang-tidy
**/.test
/.appanalyzer
''';

  static String _appBuildProfile(String sdkVersion) => '''{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "targetSdkVersion": "$sdkVersion",
        "compatibleSdkVersion": "$sdkVersion",
        "runtimeOS": "HarmonyOS",
        "buildOption": {
          "strictMode": {
            "caseSensitiveCheck": true,
            "useNormalizedOHMUrl": true
          }
        }
      }
    ],
    "buildModeSet": [
      {
        "name": "debug"
      },
      {
        "name": "release"
      }
    ]
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    }
  ]
}
''';

  static String _appHvigorfile() => '''import { appTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
}
''';

  static String _codeLinter() => '''{
  "files": [
    "**/*.ets"
  ],
  "ignore": [
    "**/src/ohosTest/**/*",
    "**/src/test/**/*",
    "**/src/mock/**/*",
    "**/node_modules/**/*",
    "**/oh_modules/**/*",
    "**/build/**/*",
    "**/.preview/**/*"
  ],
  "ruleSet": [
    "plugin:@performance/recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
  }
}
''';

  static String _appOhPackage(String modelVersion) => '''{
  "modelVersion": "$modelVersion",
  "description": "Generated by ArkUI Build",
  "dependencies": {
  },
  "devDependencies": {
  }
}
''';

  static String _localProperties() => '''# This file is automatically generated by DevEco Studio.
# Do not modify this file -- YOUR CHANGES WILL BE ERASED!
''';

  static String _hvigorConfig(String modelVersion) => '''{
  "modelVersion": "$modelVersion",
  "dependencies": {
  },
  "execution": {
  },
  "logging": {
  },
  "debugging": {
  },
  "nodeOptions": {
  }
}
''';

  // ==========================================================================
  // AppScope
  // ==========================================================================

  static String _appJson(String bundleId) => '''{
  "app": {
    "bundleName": "$bundleId",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "\$media:layered_image",
    "label": "\$string:app_name"
  }
}
''';

  static String _appScopeString(String projectName) => '''{
  "string": [
    {
      "name": "app_name",
      "value": "${_esc(projectName)}"
    }
  ]
}
''';

  static String _layeredImage() => '''{
  "layered-image": {
    "background": "\$media:background",
    "foreground": "\$media:foreground"
  }
}
''';

  // ==========================================================================
  // entry module config
  // ==========================================================================

  static String _entryGitignore() => '''/node_modules
/oh_modules
/.preview
/build
/.cxx
/.test
''';

  static String _entryBuildProfile() => '''{
  "apiType": "stageMode",
  "buildOption": {
  },
  "buildOptionSet": [
    {
      "name": "release",
      "arkOptions": {
        "obfuscation": {
          "ruleOptions": {
            "enable": false,
            "files": [
              "./obfuscation-rules.txt"
            ]
          }
        }
      }
    }
  ],
  "targets": [
    {
      "name": "default"
    }
  ]
}
''';

  static String _entryHvigorfile() => '''import { hapTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: hapTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
}
''';

  static String _obfuscationRules() => '''# Define project specific obfuscation rules here.
-enable-property-obfuscation
-enable-toplevel-obfuscation
-enable-filename-obfuscation
-enable-export-obfuscation
''';

  static String _entryOhPackage() => '''{
  "name": "entry",
  "version": "1.0.0",
  "description": "Please describe the basic information.",
  "main": "",
  "author": "",
  "license": "",
  "dependencies": {}
}
''';

  static String _moduleJson(List<Map<String, dynamic>> managers) {
    final permissions = _collectPermissions(managers);
    final permBlock = permissions.isEmpty
        ? ''
        : ''',
    "requestPermissions": [
${permissions.map((perm) => '''      {
        "name": "$perm",
        "reason": "\$string:permission_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }''').join(',\n')}
    ]''';

    return '''{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "\$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "\$profile:main_pages"$permBlock,
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "\$string:EntryAbility_desc",
        "icon": "\$media:layered_image",
        "label": "\$string:EntryAbility_label",
        "startWindowIcon": "\$media:startIcon",
        "startWindowBackground": "\$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "ohos.want.action.home"
            ]
          }
        ]
      }
    ],
    "extensionAbilities": [
      {
        "name": "EntryBackupAbility",
        "srcEntry": "./ets/entrybackupability/EntryBackupAbility.ets",
        "type": "backup",
        "exported": false,
        "metadata": [
          {
            "name": "ohos.extension.backup",
            "resource": "\$profile:backup_config"
          }
        ]
      }
    ]
  }
}
''';
  }

  static Set<String> _collectPermissions(List<Map<String, dynamic>> managers) {
    final map = <String, String>{};
    for (final m in managers) {
      final raw = m['permissions'];
      if (raw is List) {
        for (final p in raw) {
          final value = p.toString().trim();
          if (value.isNotEmpty) {
            map.putIfAbsent(value.toUpperCase(), () => value);
          }
        }
      }
    }
    return map.values.toSet();
  }

  // ==========================================================================
  // entry sources
  // ==========================================================================

  static String _entryAbility() => '''import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
''';

  static String _entryBackupAbility() => '''import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    hilog.info(DOMAIN, 'testTag', 'onBackup ok');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, 'testTag', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}
''';

  static String _theme(
      String primary, String secondary, String tertiary, bool isDark) {
    return '''/**
 * App theme generated by ArkUI Build.
 */
export class AppTheme {
  static readonly PRIMARY: string = '$primary';
  static readonly SECONDARY: string = '$secondary';
  static readonly TERTIARY: string = '$tertiary';

  static readonly BACKGROUND: string = '${isDark ? '#121212' : '#FAFAFA'}';
  static readonly SURFACE: string = '${isDark ? '#1E1E1E' : '#FFFFFF'}';
  static readonly TEXT_PRIMARY: string = '${isDark ? '#FFFFFF' : '#212121'}';
  static readonly TEXT_SECONDARY: string = '${isDark ? '#B3B3B3' : '#757575'}';
}
''';
  }

  static String _modelCode(Map<String, dynamic> model, String name) {
    final fields = model['fields'];
    final buffer = StringBuffer();
    buffer.writeln('/**');
    buffer.writeln(' * $name data model generated by ArkUI Build.');
    buffer.writeln(' */');
    buffer.writeln('export class $name {');
    if (fields is List && fields.isNotEmpty) {
      for (final f in fields) {
        if (f is Map) {
          final fname = _sanitize((f['name'] ?? 'field').toString());
          final ftype = (f['type'] ?? 'string').toString();
          buffer.writeln('  $fname: $ftype${_defaultForType(ftype)};');
        }
      }
    } else {
      buffer.writeln('  id: string = \'\';');
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  static String _defaultForType(String type) {
    switch (type.toLowerCase()) {
      case 'number':
        return ' = 0';
      case 'boolean':
        return ' = false';
      case 'string':
        return " = ''";
      default:
        return '';
    }
  }

  static String _emptyWidget(String name) => '''@Component
export struct $name {
  build() {
    Column() {
      Text('$name')
        .fontSize(16)
    }
  }
}
''';

  static String _indexPage(
    String projectName,
    String description,
    List<Map<String, dynamic>> widgets,
    List<Map<String, dynamic>> managers,
    List<Map<String, dynamic>> models,
  ) {
    String rows(String title, List<String> items, String emptyLabel) {
      final safeItems = items.map(_esc).toList();
      final listExpr = safeItems.isEmpty
          ? "['$emptyLabel']"
          : '[${safeItems.map((i) => "'$i'").join(', ')}]';
      return '''
        Text('$title')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.PRIMARY)
          .margin({ top: 16, bottom: 8 })
        ForEach($listExpr, (item: string) => {
          Row() {
            Text('•')
              .fontSize(14)
              .fontColor(AppTheme.SECONDARY)
              .margin({ right: 8 })
            Text(item)
              .fontSize(14)
              .fontColor(AppTheme.TEXT_PRIMARY)
          }
          .width('100%')
          .padding({ top: 6, bottom: 6, left: 12, right: 12 })
          .backgroundColor(AppTheme.SURFACE)
          .borderRadius(8)
          .margin({ bottom: 6 })
        }, (item: string) => item)''';
    }

    final widgetItems =
        widgets.map((w) => (w['title'] ?? 'Widget').toString()).toList();
    final managerItems =
        managers.map((m) => (m['className'] ?? 'Manager').toString()).toList();
    final modelItems =
        models.map((m) => (m['name'] ?? 'Model').toString()).toList();

    return '''import { AppTheme } from '../common/AppTheme';

@Entry
@Component
struct Index {
  @State message: string = 'Welcome to ${_esc(projectName)}';

  build() {
    Scroll() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .margin({ top: 24, bottom: 8 })

        Text('${_esc(description.isEmpty ? 'Generated by ArkUI Build' : description)}')
          .fontSize(14)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .margin({ bottom: 8 })

${rows('Widgets (${widgets.length})', widgetItems, 'No widgets selected')}

${rows('Managers (${managers.length})', managerItems, 'No managers selected')}

${rows('Models (${models.length})', modelItems, 'No models selected')}
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BACKGROUND)
  }
}
''';
  }

  // ==========================================================================
  // entry resources
  // ==========================================================================

  static String _entryColorLight() => '''{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    }
  ]
}
''';

  static String _entryColorDark() => '''{
  "color": [
    {
      "name": "start_window_background",
      "value": "#000000"
    }
  ]
}
''';

  static String _entryFloat() => '''{
  "float": [
    {
      "name": "page_text_font_size",
      "value": "50fp"
    }
  ]
}
''';

  static String _entryString(
      String projectName, List<Map<String, dynamic>> managers) {
    final needsPermission = _collectPermissions(managers).isNotEmpty;
    final permissionEntry = needsPermission
        ? ''',
    {
      "name": "permission_reason",
      "value": "This app needs the permission to provide its features."
    }'''
        : '';
    return '''{
  "string": [
    {
      "name": "module_desc",
      "value": "module description"
    },
    {
      "name": "EntryAbility_desc",
      "value": "description"
    },
    {
      "name": "EntryAbility_label",
      "value": "${_esc(projectName)}"
    }$permissionEntry
  ]
}
''';
  }

  static String _mainPages() => '''{
  "src": [
    "pages/Index"
  ]
}
''';

  static String _backupConfig() => '''{
  "allowToBackupRestore": true
}
''';

  // ==========================================================================
  // README
  // ==========================================================================

  static String _readme(
    String projectName,
    String description,
    List<Map<String, dynamic>> widgets,
    List<Map<String, dynamic>> managers,
    List<Map<String, dynamic>> models,
  ) {
    return '''# $projectName

$description

Generated by **ArkUI Build**. This is a complete HarmonyOS (Stage model)
project — open the folder in DevEco Studio, let it sync (ohpm), then Run.

## Structure

```
$projectName/
├── AppScope/                 # app-level config + icon
├── entry/                    # the HAP module
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/  # UIAbility entry point
│       │   ├── pages/         # Index page
│       │   ├── common/        # AppTheme
│       │   ├── managers/      # ${managers.length} manager(s)
│       │   ├── models/        # ${models.length} model(s)
│       │   └── widgets/       # ${widgets.length} widget component(s)
│       └── resources/         # element / media / profile
├── build-profile.json5
├── hvigorfile.ts
├── oh-package.json5
└── hvigor/hvigor-config.json5
```

## Included from the catalog

- Widgets: ${widgets.isEmpty ? '(none)' : widgets.map((w) => w['title']).join(', ')}
- Managers: ${managers.isEmpty ? '(none)' : managers.map((m) => m['className']).join(', ')}
- Models: ${models.isEmpty ? '(none)' : models.map((m) => m['name']).join(', ')}

Widget components live in `entry/src/main/ets/widgets/`. Import and use them in
your pages, e.g. `import { MyWidget } from '../widgets/MyWidget';`.
''';
  }
}
