import '../models/arkts_course.dart';
import '../models/arkts_quiz_challenge.dart';

const _printDecl = 'declare function print(arg: any): any';

/// HarmonyOS Next kits pathway — document + examples + conceptual quizzes.
/// Kit APIs do not run in the language playground; challenges verify knowledge via print().
const LearningCourse harmonyOsKitsCourse = LearningCourse(
  id: 'harmonyos-kits',
  track: CourseTrack.harmonyos,
  title: 'HarmonyOS Kits',
  subtitle:
      'Learn system kits for HarmonyOS Next — start with Location Kit, then expand.',
  description:
      'Kit courses teach capabilities such as location, network, and media. Lessons focus on '
      'architecture, permissions, and API patterns with copy-ready .ets samples. Practice '
      'questions check concepts (permission names, API choices). Live GPS requires DevEco '
      'on a device or emulator — not the in-browser ArkTS runner.',
  learningOutcomes: [
    'Explain what a HarmonyOS Kit is and how it fits an application',
    'List Location Kit permissions and privacy considerations',
    'Recognize core location APIs and typical call flow',
    'Know what belongs in DevEco vs this document-first course',
  ],
  lessons: [
    _locationKitIntro,
    _locationPermissions,
    _locationApiFlow,
  ],
);

const _locationKitIntro = CourseLesson(
  id: 'location-intro',
  number: 1,
  title: 'Location Kit overview',
  summary: 'What Location Kit provides and how kits fit HarmonyOS Next apps.',
  durationLabel: '12 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/location-kit',
  sourceLabel: 'Official: Location Kit',
  content: [
    CourseHeading('What is a Kit?'),
    CourseParagraph(
      'HarmonyOS Next exposes device and system capabilities through Kits — modular API '
      'sets such as Location Kit, Network Kit, and Camera Kit. Your app imports the kit '
      'module, declares permissions, then calls typed ArkTS APIs.',
    ),
    CourseHeading('Location Kit at a glance'),
    CourseBulletList([
      'Obtain the device’s current location (GNSS / network fusion depending on device)',
      'Listen for location updates',
      'Support map and navigation scenarios when combined with Map Kit',
      'Require explicit user-facing permissions and privacy disclosures',
    ]),
    CourseCallout(
      title: 'Playground limit',
      text:
          'The in-browser runner cannot access GPS hardware. Use examples as reference '
          'code for DevEco Studio; quizzes here ask you to print the correct concept or API name.',
    ),
    CourseHeading('Typical import'),
    CourseCodeSnippet(
      title: 'import',
      code: '''import { geoLocationManager } from '@kit.LocationKit'

// Then request permissions and call location APIs in an Ability / page.
''',
      caption: 'Module name may vary slightly by API version — always check current docs.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'loc-e1',
      title: 'Mental model',
      explanation: 'Kits are capabilities; print a reminder label.',
      code: '''$_printDecl

print("LocationKit")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-loc-q1',
      number: 1,
      title: 'Kit name',
      prompt: 'Print exactly LocationKit (one word, no spaces).',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'LocationKit',
      hint: 'print("LocationKit")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-loc-q2',
      number: 2,
      title: 'Import module',
      prompt:
          'Print the kit import path text: @kit.LocationKit',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.LocationKit',
      hint: 'print("@kit.LocationKit")',
    ),
  ],
);

const _locationPermissions = CourseLesson(
  id: 'location-permissions',
  number: 2,
  title: 'Location permissions & privacy',
  summary: 'Approximate vs precise location, module.json5 entries, and user consent.',
  durationLabel: '15 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/location-kit',
  sourceLabel: 'Official: Location Kit permissions',
  content: [
    CourseHeading('Why permissions matter'),
    CourseParagraph(
      'Location is sensitive personal data. HarmonyOS requires declared permissions in '
      'module.json5 (or the project config) and a runtime request with a clear purpose string.',
    ),
    CourseHeading('Common permission names'),
    CourseBulletList([
      'ohos.permission.APPROXIMATELY_LOCATION — coarse location',
      'ohos.permission.LOCATION — precise location (often with approximate)',
      'Background location needs additional capability and stronger justification',
    ]),
    CourseCodeSnippet(
      title: 'module-snippet',
      code: '''// module.json5 (illustrative)
{
  "requestPermissions": [
    {
      "name": "ohos.permission.APPROXIMATELY_LOCATION",
      "reason": "\$string:location_reason",
      "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
    },
    {
      "name": "ohos.permission.LOCATION",
      "reason": "\$string:location_reason",
      "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
    }
  ]
}
''',
    ),
    CourseCallout(
      title: 'UX tip',
      text:
          'Ask only when needed, explain why, and degrade gracefully if the user denies.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'perm-e1',
      title: 'Permission string',
      explanation: 'Memorize the precise location permission id.',
      code: '''$_printDecl

print("ohos.permission.LOCATION")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-perm-q1',
      number: 1,
      title: 'Precise permission',
      prompt: 'Print the precise location permission: ohos.permission.LOCATION',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'ohos.permission.LOCATION',
      hint: 'Exact string match.',
    ),
    ArkTsQuizChallenge(
      id: 'hos-perm-q2',
      number: 2,
      title: 'Approximate permission',
      prompt: 'Print ohos.permission.APPROXIMATELY_LOCATION',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'ohos.permission.APPROXIMATELY_LOCATION',
      hint: 'Exact string match.',
    ),
  ],
);

const _locationApiFlow = CourseLesson(
  id: 'location-api-flow',
  number: 3,
  title: 'Location API flow',
  summary: 'Request permission → get current location → handle errors; sample shape for DevEco.',
  durationLabel: '18 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/location-kit',
  sourceLabel: 'Official: Location Kit APIs',
  content: [
    CourseHeading('Happy path'),
    CourseBulletList([
      'Ensure location service is enabled on the device',
      'Request the needed permissions at runtime',
      'Call getCurrentLocation / subscribe to updates',
      'Handle timeouts, denied permission, and empty results',
    ]),
    CourseHeading('Illustrative ArkTS shape'),
    CourseCodeSnippet(
      title: 'get-current',
      code: '''import { geoLocationManager } from '@kit.LocationKit'
import { BusinessError } from '@kit.BasicServicesKit'

async function fetchLocation(): Promise<void> {
  const requestInfo: geoLocationManager.CurrentLocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    // scenario / timeout fields depend on API version
  }
  try {
    const location = await geoLocationManager.getCurrentLocation(requestInfo)
    console.info('lat=' + location.latitude + ' lon=' + location.longitude)
  } catch (err) {
    const e = err as BusinessError
    console.error('location failed: ' + e.code + ' ' + e.message)
  }
}
''',
      caption: 'Reference only — run inside DevEco with permissions granted.',
    ),
    CourseCallout(
      title: 'Next kits',
      text:
          'This course will grow with Network Kit, Camera Kit, and more. The catalog stays '
          'under HarmonyOS so new kit modules drop in as new lessons or sibling courses.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'api-e1',
      title: 'API symbol',
      explanation: 'Remember the manager name used in samples.',
      code: '''$_printDecl

print("geoLocationManager")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-api-q1',
      number: 1,
      title: 'Manager name',
      prompt: 'Print geoLocationManager',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'geoLocationManager',
      hint: 'print("geoLocationManager")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-api-q2',
      number: 2,
      title: 'First step',
      prompt:
          'Print the first step word of the happy path: permissions',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'permissions',
      hint: 'Always request permissions before reading location.',
    ),
  ],
);

const LearningCourse arkUiCoursePlaceholder = LearningCourse(
  id: 'arkui-basics',
  track: CourseTrack.arkui,
  title: 'ArkUI Basics',
  subtitle: 'Declarative UI, components, and state — coming soon.',
  description:
      'ArkUI course content will cover declarative components, layout, state management, '
      'and common patterns. Reserved in the catalog so new UI courses plug in beside ArkTS '
      'and HarmonyOS Kits.',
  learningOutcomes: [
    'Build screens with ArkUI components',
    'Manage UI state and updates',
    'Apply layout and interaction patterns',
  ],
  lessons: [],
  comingSoon: true,
);
