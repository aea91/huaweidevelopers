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
      'Learn HarmonyOS Next system kits — Location, Network, Ability, Data, Media, Camera and Notification.',
  description:
      'Kit courses teach system capabilities such as location, networking, app abilities, '
      'data persistence, media, camera and notifications. Lessons focus on architecture, '
      'permissions, and API patterns with copy-ready .ets samples. Practice questions check '
      'concepts (permission names, API choices). Device features require DevEco on a device or '
      'emulator — not the in-browser ArkTS runner.',
  learningOutcomes: [
    'Explain what a HarmonyOS Kit is and how it fits an application',
    'Identify the import module and key permission for each kit',
    'Recognize core APIs and typical call flow per kit',
    'Choose the right kit for networking, data, media, camera and notifications',
    'Know what belongs in DevEco vs this document-first course',
  ],
  lessons: [
    _locationKitIntro,
    _locationPermissions,
    _locationApiFlow,
    _networkKit,
    _abilityKit,
    _arkDataKit,
    _mediaKit,
    _cameraKit,
    _notificationKit,
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

const _networkKit = CourseLesson(
  id: 'network-kit',
  number: 4,
  title: 'Network Kit',
  summary: 'HTTP requests, the INTERNET permission, and JSON handling.',
  durationLabel: '16 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/network-kit',
  sourceLabel: 'Official: Network Kit',
  content: [
    CourseHeading('What Network Kit provides'),
    CourseParagraph(
      'Network Kit exposes HTTP(S) requests, WebSocket connections, and connection '
      'management. Most apps start with the HTTP data request API to call REST endpoints.',
    ),
    CourseHeading('Import and permission'),
    CourseBulletList([
      "Import: import { http } from '@kit.NetworkKit'",
      'Permission: ohos.permission.INTERNET (declared in module.json5)',
      'Always parse and validate responses; handle non-2xx and timeouts',
    ]),
    CourseCodeSnippet(
      title: 'http-get',
      code: '''import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

async function loadUsers(): Promise<void> {
  const request = http.createHttp()
  try {
    const res = await request.request('https://api.example.com/users', {
      method: http.RequestMethod.GET,
      header: { 'Content-Type': 'application/json' },
      connectTimeout: 10000,
      readTimeout: 10000,
    })
    if (res.responseCode === 200) {
      const data = JSON.parse(res.result as string)
      console.info('users: ' + data.length)
    }
  } catch (err) {
    const e = err as BusinessError
    console.error('request failed: ' + e.code)
  } finally {
    request.destroy()
  }
}
''',
      caption: 'Reference only — run inside DevEco. Remember to destroy() the request.',
    ),
    CourseCallout(
      title: 'Common mistake',
      text:
          'Forgetting the ohos.permission.INTERNET declaration causes requests to fail at '
          'runtime even though the code compiles.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'net-e1',
      title: 'Permission string',
      explanation: 'Memorize the network permission id.',
      code: '''$_printDecl

print("ohos.permission.INTERNET")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-net-q1',
      number: 1,
      title: 'Import module',
      prompt: 'Print the Network Kit import path: @kit.NetworkKit',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.NetworkKit',
      hint: 'print("@kit.NetworkKit")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-net-q2',
      number: 2,
      title: 'Network permission',
      prompt: 'Print ohos.permission.INTERNET',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'ohos.permission.INTERNET',
      hint: 'Exact string match.',
    ),
  ],
);

const _abilityKit = CourseLesson(
  id: 'ability-kit',
  number: 5,
  title: 'Ability Kit',
  summary: 'UIAbility, application context, and Want-based navigation.',
  durationLabel: '17 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ability-kit',
  sourceLabel: 'Official: Ability Kit',
  content: [
    CourseHeading('The building block of an app'),
    CourseParagraph(
      'Ability Kit defines UIAbility — the entry component that hosts your pages and owns the '
      'application lifecycle. A Want is the message used to start an ability or navigate '
      'between abilities and apps.',
    ),
    CourseBulletList([
      "Import: import { UIAbility, Want } from '@kit.AbilityKit'",
      'EntryAbility extends UIAbility and implements onCreate / onWindowStageCreate',
      'Use context.startAbility(want) to launch another ability',
      'AbilityStage and context provide app-level resources',
    ]),
    CourseCodeSnippet(
      title: 'start-ability',
      code: '''import { UIAbility, Want } from '@kit.AbilityKit'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want): void {
    console.info('entry ability created')
  }
}

// Launch another ability from a page context:
function openDetail(context: Context): void {
  const want: Want = {
    bundleName: 'com.example.app',
    abilityName: 'DetailAbility',
    parameters: { id: 42 },
  }
  context.startAbility(want)
}
''',
      caption: 'Illustrative — field names depend on API version.',
    ),
    CourseCallout(
      title: 'Mental model',
      text:
          'UIAbility ≈ the app entry + lifecycle owner. Want ≈ the intent/message that says '
          'which ability to open and what data to pass.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'ability-e1',
      title: 'Entry component',
      explanation: 'Name the entry component type.',
      code: '''$_printDecl

print("UIAbility")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-ability-q1',
      number: 1,
      title: 'Import module',
      prompt: 'Print the Ability Kit import path: @kit.AbilityKit',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.AbilityKit',
      hint: 'print("@kit.AbilityKit")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-ability-q2',
      number: 2,
      title: 'Navigation message',
      prompt: 'Print the object type used to start an ability: Want',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'Want',
      hint: 'startAbility takes a Want.',
    ),
  ],
);

const _arkDataKit = CourseLesson(
  id: 'arkdata-kit',
  number: 6,
  title: 'ArkData (Preferences)',
  summary: 'Lightweight key-value persistence for settings and small data.',
  durationLabel: '14 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/arkdata',
  sourceLabel: 'Official: ArkData',
  content: [
    CourseHeading('Where to store small data'),
    CourseParagraph(
      'ArkData groups the data-management APIs. For simple key-value settings, use '
      'Preferences; for structured, queryable data use the Relational Store (RDB). This '
      'lesson focuses on Preferences.',
    ),
    CourseBulletList([
      "Import: import { preferences } from '@kit.ArkData'",
      'Best for flags, tokens, and small user settings',
      'Not a database — use RDB for large or relational data',
    ]),
    CourseCodeSnippet(
      title: 'preferences',
      code: '''import { preferences } from '@kit.ArkData'

async function saveTheme(context: Context, dark: boolean): Promise<void> {
  const store = await preferences.getPreferences(context, 'settings')
  await store.put('darkMode', dark)
  await store.flush()
}

async function readTheme(context: Context): Promise<boolean> {
  const store = await preferences.getPreferences(context, 'settings')
  return await store.get('darkMode', false) as boolean
}
''',
      caption: 'Reference only — call flush() to persist changes.',
    ),
    CourseCallout(
      title: 'Remember',
      text: 'Changes are in-memory until flush(); forgetting flush() loses data on restart.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'arkdata-e1',
      title: 'Persist call',
      explanation: 'Name the call that writes changes to disk.',
      code: '''$_printDecl

print("flush")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-data-q1',
      number: 1,
      title: 'Import module',
      prompt: 'Print the ArkData import path: @kit.ArkData',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.ArkData',
      hint: 'print("@kit.ArkData")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-data-q2',
      number: 2,
      title: 'Persist changes',
      prompt: 'Print the method that persists Preferences changes: flush',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'flush',
      hint: 'store.flush()',
    ),
  ],
);

const _mediaKit = CourseLesson(
  id: 'media-kit',
  number: 7,
  title: 'Media Kit',
  summary: 'Play audio and video with AVPlayer.',
  durationLabel: '15 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/media-kit',
  sourceLabel: 'Official: Media Kit',
  content: [
    CourseHeading('Playback with Media Kit'),
    CourseParagraph(
      'Media Kit provides audio and video playback and recording. AVPlayer is the common '
      'entry point for streaming or local playback with a state-machine driven lifecycle.',
    ),
    CourseBulletList([
      "Import: import { media } from '@kit.MediaKit'",
      'Create an AVPlayer, set the source url/fd, then prepare and play',
      'React to state changes (initialized, prepared, playing, paused, completed)',
      'Release the player when done to free resources',
    ]),
    CourseCodeSnippet(
      title: 'avplayer',
      code: '''import { media } from '@kit.MediaKit'

async function playAudio(url: string): Promise<void> {
  const player = await media.createAVPlayer()
  player.on('stateChange', (state: string) => {
    if (state === 'initialized') player.prepare()
    if (state === 'prepared') player.play()
  })
  player.url = url
}
''',
      caption: 'Illustrative — always release the player to avoid leaks.',
    ),
    CourseCallout(
      title: 'Lifecycle',
      text:
          'AVPlayer is state-driven: set the source, wait for initialized/prepared, then play. '
          'Skipping states causes errors.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'media-e1',
      title: 'Player type',
      explanation: 'Name the common playback class.',
      code: '''$_printDecl

print("AVPlayer")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-media-q1',
      number: 1,
      title: 'Import module',
      prompt: 'Print the Media Kit import path: @kit.MediaKit',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.MediaKit',
      hint: 'print("@kit.MediaKit")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-media-q2',
      number: 2,
      title: 'Playback class',
      prompt: 'Print the class used for audio/video playback: AVPlayer',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'AVPlayer',
      hint: 'media.createAVPlayer()',
    ),
  ],
);

const _cameraKit = CourseLesson(
  id: 'camera-kit',
  number: 8,
  title: 'Camera Kit',
  summary: 'Capture photos/video; the CAMERA permission and session flow.',
  durationLabel: '16 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/camera-kit',
  sourceLabel: 'Official: Camera Kit',
  content: [
    CourseHeading('Capturing with Camera Kit'),
    CourseParagraph(
      'Camera Kit gives low-level control over camera devices, preview, photo and video '
      'capture through a capture session. It requires an explicit runtime permission.',
    ),
    CourseBulletList([
      "Import: import { camera } from '@kit.CameraKit'",
      'Permission: ohos.permission.CAMERA (and MICROPHONE for video with audio)',
      'Flow: get camera manager → create session → add input/output → start',
      'Prefer a higher-level picker when you only need a single photo',
    ]),
    CourseCodeSnippet(
      title: 'camera-manager',
      code: '''import { camera } from '@kit.CameraKit'

function listCameras(context: Context): void {
  const manager = camera.getCameraManager(context)
  const devices = manager.getSupportedCameras()
  console.info('cameras: ' + devices.length)
  // Then create a session, add a preview + photo output, and start capture.
}
''',
      caption: 'Reference only — full capture needs a session and surface in DevEco.',
    ),
    CourseCallout(
      title: 'Privacy',
      text:
          'Camera and microphone are sensitive. Request permission with a clear reason and '
          'release the session when the screen closes.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'camera-e1',
      title: 'Permission string',
      explanation: 'Memorize the camera permission id.',
      code: '''$_printDecl

print("ohos.permission.CAMERA")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-camera-q1',
      number: 1,
      title: 'Import module',
      prompt: 'Print the Camera Kit import path: @kit.CameraKit',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.CameraKit',
      hint: 'print("@kit.CameraKit")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-camera-q2',
      number: 2,
      title: 'Camera permission',
      prompt: 'Print ohos.permission.CAMERA',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'ohos.permission.CAMERA',
      hint: 'Exact string match.',
    ),
  ],
);

const _notificationKit = CourseLesson(
  id: 'notification-kit',
  number: 9,
  title: 'Notification Kit',
  summary: 'Publish local notifications with notificationManager.',
  durationLabel: '13 min',
  sourceUrl:
      'https://developer.huawei.com/consumer/en/doc/harmonyos-guides/notification-kit',
  sourceLabel: 'Official: Notification Kit',
  content: [
    CourseHeading('Telling the user something'),
    CourseParagraph(
      'Notification Kit publishes local notifications — text, progress, and rich content — '
      'through notificationManager. Remote push is handled separately by Push Kit.',
    ),
    CourseBulletList([
      "Import: import { notificationManager } from '@kit.NotificationKit'",
      'Build a NotificationRequest with an id and content type',
      'Call notificationManager.publish(request)',
      'Users can disable notifications — never assume delivery',
    ]),
    CourseCodeSnippet(
      title: 'publish',
      code: '''import { notificationManager } from '@kit.NotificationKit'

async function notify(): Promise<void> {
  const request: notificationManager.NotificationRequest = {
    id: 1,
    content: {
      notificationContentType:
        notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: { title: 'Sync complete', text: 'Your data is up to date.' },
    },
  }
  await notificationManager.publish(request)
}
''',
      caption: 'Illustrative — field names depend on API version.',
    ),
    CourseCallout(
      title: 'Local vs remote',
      text:
          'Notification Kit = local notifications from your app. Push Kit = messages delivered '
          'from a server through Huawei Push.',
    ),
  ],
  examples: [
    CourseExample(
      id: 'notif-e1',
      title: 'Publish call',
      explanation: 'Name the method that shows a notification.',
      code: '''$_printDecl

print("publish")
''',
    ),
  ],
  challenges: [
    ArkTsQuizChallenge(
      id: 'hos-notif-q1',
      number: 1,
      title: 'Import module',
      prompt: 'Print the Notification Kit import path: @kit.NotificationKit',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: '@kit.NotificationKit',
      hint: 'print("@kit.NotificationKit")',
    ),
    ArkTsQuizChallenge(
      id: 'hos-notif-q2',
      number: 2,
      title: 'Show a notification',
      prompt: 'Print the method that publishes a notification: publish',
      difficulty: QuizDifficulty.easy,
      starterCode: '''$_printDecl

// TODO
''',
      expectedOutput: 'publish',
      hint: 'notificationManager.publish(request)',
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
