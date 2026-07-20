# ArkUI Build - Quick Start

## ✨ Features

### 1. **Split-Screen View**
- 🎬 On the left: GIF preview showing widget animations
- 💻 On the right: Copiable ArkTS code
- 🎨 Modern dark theme code editor

### 2. **Easy to Use**
- 🔍 Powerful search function
- 🏷️ Category based filtering
- 📋 Copy code with one click
- 📱 Fully responsive design

### 3. **Widget Koleksiyonu**
- Navigation components
- Card layouts
- Input fields
- Buttons
- Profile cards
- And more...

## 🎯 Get Started Now

1. **Run the project:**
   ```bash
   flutter run -d chrome
   ```

2. **Select a widget:**
   - Click on the widget you want from the left sidebar

3. **Copy the code:**
   - Click the "Copy Code" button
   - Paste into your HarmonyOS project
   - Run it!

## 📂 Adding Widgets (Quick)

1. **Prepare your GIF:**
   - Take a screen recording of your widget
   - Save in folder `assets/gifs/`

2. **Add widget:**
   ```dart
   //to the file lib/data/sample_widgets.dart
   WidgetShowcase(
     id: 'unique_id',
     title: 'Widget Name',
     description: 'Short description',
     category: 'Category',
     gifPath: 'assets/gifs/your_gif.gif',
     code: '''YOUR_ARKTS_CODE''',
     tags: ['tag1', 'tag2'],
   ),
   ```

3. **Hot reload:**
   - Press `r` in Terminal

## 🎨 Customization

### Change Colors
`lib/main.dart` → `seedColor: const Color(0xFFYOURCOLOR)`

### Add Logo
Edit method `lib/screens/home_screen.dart` → `_buildHeader()`

### Change Font
Use `lib/main.dart` → `GoogleFonts.yourFont()`

## 🚀 Production Build

```bash
flutter build web --release
```

Build files will be in the `build/web/` folder.

## 📱 Sample Usage Scenarios

### Senaryo 1: Bottom Navigation Bar gerekiyor
1. Type "navigation" in the search box
2. Select the "Bottom Nav Bar Gradient" widget
3. Copy the code
4. Use it in your HarmonyOS project

### Scenario 2: Custom card design
1. Select the "Cards" category
2. Find the card you like
3. Customize the code as per your need

### Scenario 3: Adding a search box
1. Select "Search Bar" from the "Input" category
2. Copy its code
3. Adapt colors to your project

## 💡 Tips

- **GIF Size**: 300-500px width is ideal
- **Code Format**: Follow ArkTS syntax
- **Tags**: Use good tags for search
- **Description**: Keep it short and concise (max 100 characters)

## 🎓 More Information

- For detailed use: `USAGE_GUIDE.md`
- For project structure: `README.md`
- ArkTS documentation: [HarmonyOS Docs](https://developer.harmonyos.com/)

## 🤝 Contribute

Want to share your widgets?
1. Add new widget
2. Create GIF preview
3. Open a pull request
4. Contribute to the Community!

---

**Keyifli kodlamalar! 🚀**
