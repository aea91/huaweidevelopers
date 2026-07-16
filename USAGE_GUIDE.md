# Kullanım Kılavuzu

## 🎯 Projenizi Özelleştirme

### 1. GIF Dosyalarınızı Ekleme

GIF dosyalarınızı widget preview'ları için eklemek için:

1. HarmonyOS uygulamanızda widget'ı kaydederken ekran kaydı alın
2. Kaydı GIF formatına dönüştürün (önerilen araçlar: GIPHY Capture, ScreenToGif, CloudConvert)
3. GIF'i `assets/gifs/` klasörüne kopyalayın
4. Dosya adını anlamlı yapın (örn: `bottom_nav_gradient.gif`)

### 2. Yeni Widget Ekleme

`lib/data/sample_widgets.dart` dosyasını açın ve `sampleWidgets` listesine yeni bir widget ekleyin:

```dart
WidgetShowcase(
  id: '6', // Benzersiz ID
  title: 'Custom Button',
  description: 'Özel tasarlanmış buton widget\'ı',
  category: 'Buttons', // Mevcut kategoriler: Navigation, Cards, Input, Buttons
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

### 3. Kategori Ekleme

Yeni bir kategori eklemek için sadece yeni widget'ınıza farklı bir `category` değeri verin. Kategori otomatik olarak üst menüde görünecektir.

### 4. Renk Temasını Değiştirme

Ana renkleri değiştirmek için:

**Ana Tema** (`lib/main.dart`):
```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF5B21B6), // Bu rengi değiştirin
)
```

**Gradient Header** (`lib/screens/home_screen.dart`):
```dart
gradient: const LinearGradient(
  colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)], // Bu renkleri değiştirin
)
```

### 5. Font Değiştirme

Font'ları değiştirmek için `pubspec.yaml` dosyasına font ekleyin:

```yaml
flutter:
  fonts:
    - family: CustomFont
      fonts:
        - asset: fonts/CustomFont-Regular.ttf
        - asset: fonts/CustomFont-Bold.ttf
          weight: 700
```

Sonra `lib/main.dart` dosyasında:
```dart
textTheme: GoogleFonts.customFontTextTheme(), // Font adını buraya
```

## 🎨 Tasarım İpuçları

### GIF Optimizasyonu

- Boyut: 300-500px genişlik önerilir
- Süre: 2-5 saniye döngü ideal
- FPS: 15-24 fps yeterli
- Dosya boyutu: 1-3 MB hedefleyin

### Kod Örnekleri

- Tam çalışan kod parçaları ekleyin
- Yorumlar ekleyerek kodu açıklayın
- Okunabilir girintileme kullanın
- Import ifadelerini gerektiğinde ekleyin

### Widget Açıklamaları

- Kısa ve öz tutun (max 100 karakter)
- Widget'ın ne yaptığını açıklayın
- Özel özellikleri vurgulayın

### Tag'ler

- 2-4 tag kullanın
- İlgili anahtar kelimeleri seçin
- Küçük harfle yazın
- Arama optimizasyonu için kullanın

## 🚀 Deployment

### GitHub Pages'e Deploy

1. Web build oluşturun:
```bash
flutter build web
```

2. `build/web` klasörünü GitHub Pages'e deploy edin

### Firebase Hosting

1. Firebase CLI yükleyin:
```bash
npm install -g firebase-tools
```

2. Firebase'i initialize edin:
```bash
firebase init hosting
```

3. Deploy edin:
```bash
flutter build web
firebase deploy
```

### Vercel

1. Vercel CLI yükleyin:
```bash
npm install -g vercel
```

2. Deploy edin:
```bash
flutter build web
vercel --prod
```

## 🐛 Sorun Giderme

### GIF'ler görünmüyor
- Asset yolunu kontrol edin
- `flutter pub get` komutunu çalıştırın
- Hot restart yapın (R tuşu)

### Syntax highlighting çalışmıyor
- `flutter_highlight` paketinin yüklü olduğundan emin olun
- Language parametresini 'typescript' olarak ayarlayın

### Responsive sorunları
- Tarayıcı geliştirici araçlarını kullanın
- Farklı ekran boyutlarını test edin
- MediaQuery değerlerini kontrol edin

## 📞 Destek

Sorunlarınız için:
- GitHub Issues açın
- Dokümantasyonu kontrol edin
- Community'ye sorun

## 🎓 Ek Kaynaklar

- [Flutter Web Dokümantasyonu](https://flutter.dev/web)
- [ArkTS Syntax Guide](https://developer.harmonyos.com/en/docs/documentation/doc-guides-V3/arkts-basic-syntax-overview-0000001531611153-V3)
- [Material Design Guidelines](https://material.io/design)
- [Google Fonts](https://fonts.google.com/)
