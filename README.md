# ArkUI Build - Component Library Showcase

Showcase web app for ArkUI widgets in a modern, FlutterBricks style. ArkTS is a professional platform that offers code samples with GIF previews.

## 🎨 Features

- **Split-Screen Layout**: Animated GIF preview on the left, copyable ArkTS code on the right
- **Code Highlighting**: Syntax highlighting support for ArkTS
- **Copy Button**: One-click code copy feature
- **Category Filter**: Filter widgets by categories
- **Search Function**: Search for widgets by name, description or tags
- **Responsive Design**: Mobile, tablet and desktop support
- **Modern UI**: Modern interface with gradient colors, animations and shadows

## 🚀 Installation

### Requirements

- Flutter SDK (3.8.1 or above)
- Dart SDK
- Firebase CLI (for deployment)

### Steps

1. Clone the project:
```bash
git clone <your-repo-url>
cd arkuibuild
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d chrome
```

4. Firebase Deploy (Optional):
```bash
./deploy.sh
# or
flutter build web --release
deploy firebase
```

## 📁 Project Structure

```
lib/
├── data/
│ └── sample_widgets.dart # Sample widget data
├── models/
│ └── widget_showcase.dart # Widget model class
├── screens/
│ └── home_screen.dart # Home page
├── widgets/
│ ├── category_chip.dart # Category chip widget
│ ├── code_viewer.dart # Code viewer widget
│ └── widget_preview.dart # GIF preview widget
└── main.dart # Application entry point
```

## 🎯 Add New Widget

To add a new widget, add a new `WidgetShowcase` object to the `lib/data/sample_widgets.dart` file:

```dart
WidgetShowcase(
  id: 'unique_id',
  title: 'Widget Title',
  description: 'Widget description',
  category: 'Category',
  gifPath: 'assets/gifs/your_gif.gif',
  code: '''
// ArkTS kodunuz buraya
@Component
struct YourComponent {
  build() {
    // ...
  }
}
''',
  tags: ['tag1', 'tag2'],
),
```

## 📦 Add GIFs

1. Add your GIF files to `assets/gifs/` folder
2. Make sure that `pubspec.yaml` is included in the assets section (already configured)
3. Use the correct path in your widget definition: `assets/gifs/your_gif.gif`

## 🛠️ Technologies Used

- **Flutter**: Web application framework
- **Google Fonts**: Inter and JetBrains Mono fonts
- **flutter_highlight**: ArkTS code syntax highlighting
- **url_launcher**: Opening external links
- **Firebase Hosting**: Production deployment
- **Firebase Core**: Web configuration

## 🎨 Design Features

- **Renk Paleti**: 
  - Primary: #5B21B6 (Purple)
  - Secondary: #7C3AED (Light Purple)
  - Accent: White
  - Background: #F9FAFB (Light Gray)

- **Tipografi**:
  - UI Text: Inter
  - Code: JetBrains Mono

## 📱 Responsive Breakpoints

- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

## 🤝 Contribute

1. Fork
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push your branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## 🌐 Deployment

### Firebase Hosting (Recommended)
```bash
#Fastdeploy
./deploy.sh

# or manual
flutter build web --release
firebase deploy --only hosting
```

**Production URL**: https://arkuibuilder.web.app

For detailed deployment information, see file `FIREBASE_DEPLOYMENT.md`.

### Other Deployment Options

**GitHub Pages:**
```bash
flutter build web --release
# push the build/web/ folder to GitHub Pages
```

**Vercel:**
```bash
flutter build web --release
vercel --prod
```

**Netlify:**
- Deploy `build/web/` folder from the web interface

## 📄 Lisans

This project is licensed under the MIT license.

## 🔗 Related Links

- [HarmonyOS Documentation](https://developer.harmonyos.com/)
- [ArkTS Documentation](https://developer.harmonyos.com/en/docs/documentation/doc-guides-V3/arkts-get-started-0000001504769321-V3)
- [Flutter Documentation](https://flutter.dev/docs)

## 📸 Screenshots

(You can add screenshots of your web application here)

---

**Note**: This project was developed for the ArkUI ecosystem, inspired by FlutterBricks.
# huaweidevelopers
