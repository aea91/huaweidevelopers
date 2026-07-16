# ArkUI Build - Quick Start

## ✨ Özellikler

### 1. **Split-Screen Görünüm**
- 🎬 Sol tarafta: Widget animasyonlarını gösteren GIF preview
- 💻 Sağ tarafta: Kopyalanabilir ArkTS kodu
- 🎨 Modern dark theme kod editörü

### 2. **Kolay Kullanım**
- 🔍 Güçlü arama fonksiyonu
- 🏷️ Kategori bazlı filtreleme
- 📋 Tek tıkla kod kopyalama
- 📱 Tam responsive tasarım

### 3. **Widget Koleksiyonu**
- Navigation components
- Card layouts
- Input fields
- Buttons
- Profile cards
- Ve daha fazlası...

## 🎯 Hemen Başlayın

1. **Projeyi çalıştırın:**
   ```bash
   flutter run -d chrome
   ```

2. **Bir widget seçin:**
   - Sol sidebar'dan istediğiniz widget'a tıklayın

3. **Kodu kopyalayın:**
   - "Copy Code" butonuna tıklayın
   - HarmonyOS projenize yapıştırın
   - Çalıştırın!

## 📂 Widget Ekleme (Hızlı)

1. **GIF'inizi hazırlayın:**
   - Widget'ınızın ekran kaydını alın
   - `assets/gifs/` klasörüne kaydedin

2. **Widget'ı ekleyin:**
   ```dart
   // lib/data/sample_widgets.dart dosyasına
   WidgetShowcase(
     id: 'unique_id',
     title: 'Widget Adı',
     description: 'Kısa açıklama',
     category: 'Kategori',
     gifPath: 'assets/gifs/your_gif.gif',
     code: '''YOUR_ARKTS_CODE''',
     tags: ['tag1', 'tag2'],
   ),
   ```

3. **Hot reload:**
   - Terminal'de `r` tuşuna basın

## 🎨 Özelleştirme

### Renkleri Değiştirin
`lib/main.dart` → `seedColor: const Color(0xFFYOURCOLOR)`

### Logo Ekleyin
`lib/screens/home_screen.dart` → `_buildHeader()` metodunu düzenleyin

### Font Değiştirin
`lib/main.dart` → `GoogleFonts.yourFont()` kullanın

## 🚀 Production Build

```bash
flutter build web --release
```

Build dosyaları `build/web/` klasöründe olacak.

## 📱 Örnek Kullanım Senaryoları

### Senaryo 1: Bottom Navigation Bar gerekiyor
1. Arama kutusuna "navigation" yazın
2. "Bottom Nav Bar Gradient" widget'ını seçin
3. Kodu kopyalayın
4. HarmonyOS projenizde kullanın

### Senaryo 2: Özel kart tasarımı
1. "Cards" kategorisini seçin
2. Beğendiğiniz kartı bulun
3. Kodu ihtiyacınıza göre özelleştirin

### Senaryo 3: Arama kutusu ekleme
1. "Input" kategorisinden "Search Bar" seçin
2. Kodunu kopyalayın
3. Renklerini projenize uyarlayın

## 💡 İpuçları

- **GIF Boyutu**: 300-500px genişlik ideal
- **Kod Formatı**: ArkTS syntax'ını takip edin
- **Tag'ler**: Arama için iyi tag'ler kullanın
- **Açıklama**: Kısa ve öz tutun (max 100 karakter)

## 🎓 Daha Fazla Bilgi

- Detaylı kullanım için: `USAGE_GUIDE.md`
- Proje yapısı için: `README.md`
- ArkTS dokümantasyonu: [HarmonyOS Docs](https://developer.harmonyos.com/)

## 🤝 Katkıda Bulunun

Widget'larınızı paylaşmak ister misiniz?
1. Yeni widget ekleyin
2. GIF preview oluşturun
3. Pull request açın
4. Community'ye katkıda bulunun!

---

**Keyifli kodlamalar! 🚀**
