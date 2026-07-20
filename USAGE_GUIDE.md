# User Guide

## 🎯 Customizing Your Project

### 1. Adding Your GIF Files

To add your GIF files for widget previews:

1. Take a screen recording while recording the widget in your HarmonyOS app
2. Convert the recording to GIF format (recommended tools: GIPHY Capture, ScreenToGif, CloudConvert)
3. Copy the GIF to `assets/gifs/` folder
4. Make the file name meaningful (ex: `bottom_nav_gradient.gif`)

### 2. Adding New Widget

Open `lib/data/sample_widgets.dart` and add a new widget to the `sampleWidgets` list:

```dart
WidgetShowcase(
  id: '6', // Benzersiz ID
  title: 'Custom Button',
  description: 'Custom designed button widget',
  category: 'Buttons', // Available categories: Navigation, Cards, Input, Buttons
  gifPath: 'assets/gifs/custom_button.gif',
  code: '''
@Component
struct CustomButton {
  @State isPressed: boolean = false;
  
  build() {
    Button('Click Me')
      .backgroundColor('#5B21B6')
      .borderRadius(8)
  }
}
''',
  tags: ['button', 'custom', 'interactive'],
),
```

### 3. Adding a Category

To add a new category, just give your new widget a different `category` value. The category will automatically appear in the top menu.

### 4. Changing Color Theme

To change primary colors:

**Main Theme** (`lib/main.dart`):
```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF5B21B6), // Change this color
)
```

**Gradient Header** (`lib/screens/home_screen.dart`):
```dart
gradient: const LinearGradient(
  colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)], // Change these colors
)
```

### 5. Changing Font

To replace fonts, add fonts to `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: CustomFont
      fonts:
        - asset: fonts/CustomFont-Regular.ttf
        - asset: fonts/CustomFont-Bold.ttf
          weight: 700
```

Then in file `lib/main.dart`:
```dart
textTheme: GoogleFonts.customFontTextTheme(), // Enter the font name here
```

## 🎨 Design Tips

### GIF Optimizasyonu

- Size: 300-500px width recommended
- Duration: 2-5 seconds cycle ideal
- FPS: 15-24 fps yeterli
- File size: aim for 1-3 MB

### Code Examples

- Add fully working code snippets
- Explain the code by adding comments
- Use readable indentation
- Add import statements as needed

### Widget Descriptions

- Keep it short and concise (max 100 characters)
- Explain what the widget does
- Highlight special features

### Tags

- Use 2-4 tags
- Select relevant keywords
- Write in lowercase letters
- Use for search optimization

## 🚀 Deployment

### Deploy to GitHub Pages

1. Create web build:
```bash
flutter build web
```

2. Deploy the `build/web` folder to GitHub Pages

### Firebase Hosting

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Initialize Firebase:
```bash
firebase init hosting
```

3. Deploy:
```bash
flutter build web
deploy firebase
```

### Vercel

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Deploy:
```bash
flutter build web
vercel --prod
```

## 🐛 Troubleshooting

### GIFs not visible
- Check asset path
- run the command `flutter pub get`
- Do a hot restart (R key)

### Syntax highlighting not working
- Make sure the `flutter_highlight` package is installed
- Set the Language parameter to 'typescript'

### Responsive issues
- Use browser developer tools
- Test different screen sizes
- Check MediaQuery values

## 📞 Support

For your problems:
- Open GitHub Issues
- Check documentation
- Ask Community

## 🎓 Ek Kaynaklar

- [Flutter Web Documentation](https://flutter.dev/web)
- [ArkTS Syntax Guide](https://developer.harmonyos.com/en/docs/documentation/doc-guides-V3/arkts-basic-syntax-overview-0000001531611153-V3)
- [Material Design Guidelines](https://material.io/design)
- [Google Fonts](https://fonts.google.com/)
