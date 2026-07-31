import '../models/roadmap.dart';

/// Bundled default ArkTS / HarmonyOS learning roadmap.
///
/// Shown on the public /roadmap screen when Firestore has no roadmap yet, and
/// used by the admin "Load default content" action to seed Firestore. Once
/// seeded, admins edit the roadmap in Firestore and this file is only a
/// fallback.
const _officialDocs =
    'https://developer.huawei.com/consumer/en/doc/harmonyos-guides';

RoadmapResource _official(String label, String url) =>
    RoadmapResource(label: label, url: url, type: 'official');

final Roadmap defaultArkTsRoadmap = Roadmap(
  id: 'arkts',
  title: 'ArkTS Roadmap',
  subtitle:
      'Step-by-step guide to becoming a HarmonyOS app developer with ArkTS and ArkUI.',
  steps: [
    RoadmapStep(
      id: 'foundations',
      order: 0,
      title: 'Programming Foundations',
      summary:
          'ArkTS is a superset of TypeScript. Get comfortable with the JS/TS core before touching HarmonyOS.',
      topics: [
        RoadmapTopic(
          id: 'js-basics',
          title: 'JavaScript Basics',
          type: RoadmapTopicType.recommended,
          description:
              'Variables, functions, arrays, objects, control flow, ES modules and the event loop. ArkTS builds directly on these concepts.',
        ),
        RoadmapTopic(
          id: 'ts-basics',
          title: 'TypeScript Essentials',
          type: RoadmapTopicType.recommended,
          description:
              'Static types, interfaces, generics, enums, unions and type inference. ArkTS shares TypeScript syntax and tooling.',
        ),
        RoadmapTopic(
          id: 'oop',
          title: 'OOP Concepts',
          type: RoadmapTopicType.optional,
          description:
              'Classes, inheritance, composition and encapsulation. ArkUI components are built as classes with a declarative build method.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'environment',
      order: 1,
      title: 'Development Environment',
      summary: 'Set up the official HarmonyOS toolchain and run your first app.',
      topics: [
        RoadmapTopic(
          id: 'deveco-studio',
          title: 'DevEco Studio',
          type: RoadmapTopicType.recommended,
          description:
              'The official IDE for HarmonyOS. Install it, configure the SDK, and learn the project structure (entry, pages, resources, module.json5).',
          resources: [
            _official('HarmonyOS Guides', _officialDocs),
          ],
        ),
        RoadmapTopic(
          id: 'sdk-emulator',
          title: 'SDK, Emulator & Previewer',
          type: RoadmapTopicType.recommended,
          description:
              'Download the HarmonyOS SDK, launch the local emulator or a real device, and use the ArkUI Previewer for instant UI feedback.',
        ),
        RoadmapTopic(
          id: 'hap-structure',
          title: 'HAP / Project Structure',
          type: RoadmapTopicType.optional,
          description:
              'Understand HAP (HarmonyOS Ability Package), modules, abilities, and the module.json5 / app.json5 configuration files.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'arkts-language',
      order: 2,
      title: 'ArkTS Language',
      summary:
          'Learn the language itself, including how ArkTS deliberately restricts TypeScript for performance.',
      topics: [
        RoadmapTopic(
          id: 'types-functions',
          title: 'Types, Classes & Interfaces',
          type: RoadmapTopicType.recommended,
          description:
              'Declaring typed variables, functions, classes, interfaces and generics in ArkTS.',
        ),
        RoadmapTopic(
          id: 'arkts-restrictions',
          title: 'ArkTS Restrictions vs TypeScript',
          type: RoadmapTopicType.recommended,
          description:
              'ArkTS forbids `any`/`unknown`, dynamic object reshaping, and most runtime type mutation to enable ahead-of-time compilation. Know the rules the compiler enforces.',
          resources: [
            _official('ArkTS Language Introduction', _officialDocs),
          ],
        ),
        RoadmapTopic(
          id: 'modules-imports',
          title: 'Modules & Imports',
          type: RoadmapTopicType.optional,
          description:
              'ES module import/export, splitting UI and logic across files, and importing system kits via @ohos / @kit.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'arkui-basics',
      order: 3,
      title: 'ArkUI Declarative UI',
      summary:
          'Build user interfaces the declarative way with @Component and the build() method.',
      topics: [
        RoadmapTopic(
          id: 'components-decorators',
          title: '@Entry, @Component & build()',
          type: RoadmapTopicType.recommended,
          description:
              'Every page is an @Entry @Component whose build() method returns the UI tree. Learn how custom components compose.',
        ),
        RoadmapTopic(
          id: 'basic-components',
          title: 'Basic Components',
          type: RoadmapTopicType.recommended,
          description:
              'Text, Image, Button, TextInput, Toggle and other building blocks, plus universal attributes (padding, margin, size, borders).',
        ),
        RoadmapTopic(
          id: 'container-layout',
          title: 'Layout Containers',
          type: RoadmapTopicType.recommended,
          description:
              'Column, Row, Flex, Stack, Grid and RelativeContainer for arranging components responsively.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'state-management',
      order: 4,
      title: 'State Management',
      summary:
          'The heart of ArkUI: decorators that connect data to the UI and drive re-rendering.',
      topics: [
        RoadmapTopic(
          id: 'state-prop-link',
          title: '@State, @Prop, @Link',
          type: RoadmapTopicType.recommended,
          description:
              '@State owns local component state; @Prop passes a one-way copy to a child; @Link creates a two-way binding to the parent.',
        ),
        RoadmapTopic(
          id: 'provide-consume',
          title: '@Provide, @Consume & @Watch',
          type: RoadmapTopicType.recommended,
          description:
              'Share state across the component tree without prop drilling, and react to changes with @Watch callbacks.',
        ),
        RoadmapTopic(
          id: 'observed-objectlink',
          title: '@Observed & @ObjectLink',
          type: RoadmapTopicType.optional,
          description:
              'Make nested class instances observable so mutations to object fields trigger UI updates.',
        ),
        RoadmapTopic(
          id: 'app-local-storage',
          title: 'AppStorage & LocalStorage',
          type: RoadmapTopicType.optional,
          description:
              'App-wide and page-scoped observable state containers for cross-page data sharing.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'rendering-control',
      order: 5,
      title: 'Rendering & Reuse',
      summary:
          'Control what renders and factor out repeated UI with builders and styles.',
      topics: [
        RoadmapTopic(
          id: 'foreach-lazyforeach',
          title: 'ForEach & LazyForEach',
          type: RoadmapTopicType.recommended,
          description:
              'Render lists from data. LazyForEach with a DataSource virtualizes long lists for performance.',
        ),
        RoadmapTopic(
          id: 'conditional-render',
          title: 'Conditional Rendering',
          type: RoadmapTopicType.recommended,
          description:
              'Use if / else and conditional expressions inside build() to show or hide UI.',
        ),
        RoadmapTopic(
          id: 'builder-styles',
          title: '@Builder, @Styles & @Extend',
          type: RoadmapTopicType.optional,
          description:
              'Extract reusable UI snippets (@Builder), reusable attribute sets (@Styles), and component-specific extensions (@Extend).',
        ),
      ],
    ),
    RoadmapStep(
      id: 'navigation',
      order: 6,
      title: 'Navigation & Lifecycle',
      summary: 'Move between pages and understand the component/page lifecycle.',
      topics: [
        RoadmapTopic(
          id: 'router-navigation',
          title: 'Router & Navigation',
          type: RoadmapTopicType.recommended,
          description:
              'Navigate with the router module or the Navigation component and NavPathStack, passing parameters between pages.',
        ),
        RoadmapTopic(
          id: 'lifecycle',
          title: 'Lifecycle Callbacks',
          type: RoadmapTopicType.recommended,
          description:
              'aboutToAppear / aboutToDisappear for components and onPageShow / onPageHide / onBackPress for pages.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'data-storage',
      order: 7,
      title: 'Data & Persistence',
      summary: 'Store data locally on the device.',
      topics: [
        RoadmapTopic(
          id: 'preferences',
          title: 'Preferences (Key-Value)',
          type: RoadmapTopicType.recommended,
          description:
              'Lightweight key-value storage for user settings and small data via @ohos.data.preferences.',
        ),
        RoadmapTopic(
          id: 'relational-store',
          title: 'Relational Store (RDB)',
          type: RoadmapTopicType.optional,
          description:
              'SQLite-based relational database for structured, queryable data.',
        ),
        RoadmapTopic(
          id: 'file-management',
          title: 'File Management',
          type: RoadmapTopicType.optional,
          description:
              'Read and write files in the app sandbox with @ohos.file.fs.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'networking-async',
      order: 8,
      title: 'Networking & Concurrency',
      summary: 'Talk to the network and keep the UI thread responsive.',
      topics: [
        RoadmapTopic(
          id: 'http',
          title: 'HTTP Requests',
          type: RoadmapTopicType.recommended,
          description:
              'Fetch and post data with @ohos.net.http, handle responses and errors, and parse JSON.',
        ),
        RoadmapTopic(
          id: 'async-promises',
          title: 'Promises & async/await',
          type: RoadmapTopicType.recommended,
          description:
              'Asynchronous programming patterns for I/O without blocking the UI.',
        ),
        RoadmapTopic(
          id: 'taskpool-worker',
          title: 'TaskPool & Worker',
          type: RoadmapTopicType.optional,
          description:
              'Offload CPU-heavy work to background threads with TaskPool or Worker for true concurrency.',
        ),
      ],
    ),
    RoadmapStep(
      id: 'device-kits',
      order: 9,
      title: 'System Kits & Capabilities',
      summary:
          'Use HarmonyOS system abilities: notifications, media, location, sensors and more.',
      topics: [
        RoadmapTopic(
          id: 'ability-kit',
          title: 'Ability Kit',
          type: RoadmapTopicType.recommended,
          description:
              'UIAbility, application context, want-based navigation and inter-ability communication.',
        ),
        RoadmapTopic(
          id: 'notification-media',
          title: 'Notifications & Media',
          type: RoadmapTopicType.optional,
          description:
              'Publish notifications, play audio/video, and pick images with the relevant system kits.',
        ),
        RoadmapTopic(
          id: 'location-sensors',
          title: 'Location & Sensors',
          type: RoadmapTopicType.optional,
          description:
              'Access GPS location, device sensors, and other hardware capabilities (permission-gated).',
        ),
      ],
    ),
    RoadmapStep(
      id: 'testing-publishing',
      order: 10,
      title: 'Testing & Publishing',
      summary: 'Ship a quality app to AppGallery.',
      topics: [
        RoadmapTopic(
          id: 'testing',
          title: 'Testing (Hypium)',
          type: RoadmapTopicType.recommended,
          description:
              'Unit and UI testing with the Hypium framework, plus debugging with the DevEco debugger and Previewer.',
        ),
        RoadmapTopic(
          id: 'signing',
          title: 'App Signing',
          type: RoadmapTopicType.recommended,
          description:
              'Configure signing certificates and profiles in DevEco Studio to build a release .app package.',
        ),
        RoadmapTopic(
          id: 'appgallery',
          title: 'AppGallery Connect',
          type: RoadmapTopicType.recommended,
          description:
              'Create your app listing, upload the release build, and manage distribution through AppGallery Connect.',
        ),
      ],
    ),
  ],
);
