# ArkUI Build - Component Library Showcase

Modern, FlutterBricks tarzında ArkUI widget'ları için showcase web uygulaması. ArkTS kod örneklerini GIF preview'ları ile birlikte sunan profesyonel bir platform.

## 🎨 Özellikler

- **Split-Screen Layout**: Sol tarafta animasyonlu GIF preview, sağ tarafta kopyalanabilir ArkTS kodu
- **Kod Vurgulama**: ArkTS için syntax highlighting desteği
- **Kopyala Butonu**: Tek tıkla kod kopyalama özelliği
- **Kategori Filtreleme**: Widget'ları kategorilere göre filtreleme
- **Arama Fonksiyonu**: Widget'ları isim, açıklama veya tag'lere göre arama
- **Responsive Tasarım**: Mobil, tablet ve masaüstü desteği
- **Modern UI**: Gradient renkler, animasyonlar ve gölgeler ile modern arayüz

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.8.1 veya üzeri)
- Dart SDK
- Firebase CLI (deploy için)

### Adımlar

1. Projeyi klonlayın:
```bash
git clone <your-repo-url>
cd arkuibuild
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run -d chrome
```

4. Firebase Deploy (Opsiyonel):
```bash
./deploy.sh
# veya
flutter build web --release
firebase deploy
```

## 📁 Proje Yapısı

```
lib/
├── data/
│   └── sample_widgets.dart      # Örnek widget verileri
├── models/
│   └── widget_showcase.dart     # Widget model sınıfı
├── screens/
│   └── home_screen.dart         # Ana sayfa
├── widgets/
│   ├── category_chip.dart       # Kategori chip widget'ı
│   ├── code_viewer.dart         # Kod görüntüleme widget'ı
│   └── widget_preview.dart      # GIF preview widget'ı
└── main.dart                    # Uygulama giriş noktası
```

## 🎯 Yeni Widget Ekleme

Yeni bir widget eklemek için `lib/data/sample_widgets.dart` dosyasına yeni bir `WidgetShowcase` nesnesi ekleyin:

```dart
WidgetShowcase(
  id: 'unique_id',
  title: 'Widget Başlığı',
  description: 'Widget açıklaması',
  category: 'Kategori',
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

## 📦 GIF'leri Ekleme

1. GIF dosyalarınızı `assets/gifs/` klasörüne ekleyin
2. `pubspec.yaml` dosyasının assets bölümüne dahil edildiğinden emin olun (zaten yapılandırılmış)
3. Widget tanımınızda doğru yolu kullanın: `assets/gifs/your_gif.gif`

## 🛠️ Kullanılan Teknolojiler

- **Flutter**: Web uygulaması framework'ü
- **Google Fonts**: Inter ve JetBrains Mono fontları
- **flutter_highlight**: ArkTS kod syntax highlighting
- **url_launcher**: Dış linkleri açma
- **Firebase Hosting**: Production deployment
- **Firebase Core**: Web konfigürasyonu

## 🎨 Tasarım Özellikleri

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

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 🌐 Deployment

### Firebase Hosting (Önerilen)
```bash
# Hızlı deploy
./deploy.sh

# veya manuel
flutter build web --release
firebase deploy --only hosting
```

**Production URL**: https://arkuibuilder.web.app

Detaylı deployment bilgisi için `FIREBASE_DEPLOYMENT.md` dosyasına bakın.

### Diğer Deployment Seçenekleri

**GitHub Pages:**
```bash
flutter build web --release
# build/web/ klasörünü GitHub Pages'e push edin
```

**Vercel:**
```bash
flutter build web --release
vercel --prod
```

**Netlify:**
- Web arayüzünden `build/web/` klasörünü deploy edin

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 🔗 İlgili Linkler

- [HarmonyOS Documentation](https://developer.harmonyos.com/)
- [ArkTS Documentation](https://developer.harmonyos.com/en/docs/documentation/doc-guides-V3/arkts-get-started-0000001504769321-V3)
- [Flutter Documentation](https://flutter.dev/docs)

## 📸 Ekran Görüntüleri

(Web uygulamanızın ekran görüntülerini buraya ekleyebilirsiniz)

---

**Not**: Bu proje FlutterBricks'ten ilham alınarak ArkUI ekosistemi için geliştirilmiştir.
# huaweidevelopers
