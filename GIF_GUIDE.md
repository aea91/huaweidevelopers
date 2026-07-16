# 🎬 GIF Hazırlama Kılavuzu

Widget'larınız için profesyonel GIF preview'ları nasıl hazırlarsınız? İşte adım adım rehber!

## 🛠️ Gerekli Araçlar

### Ekran Kaydı İçin:
- **HarmonyOS DevEco Studio**: Built-in screen recorder
- **OBS Studio** (Ücretsiz): Windows, macOS, Linux için güçlü
- **QuickTime Player** (macOS): Sistem uygulaması
- **Windows Game Bar** (Windows): Win + G tuşları
- **AZ Screen Recorder** (Android): Mobil cihaz için

### GIF Dönüştürme İçin:
- **GIPHY Capture** (macOS): En kolay çözüm
- **ScreenToGif** (Windows): Hem kayıt hem dönüştürme
- **CloudConvert** (Web): Online dönüştürme
- **FFmpeg** (Terminal): Profesyonel kullanım
- **ezgif.com** (Web): Online GIF editörü

## 📹 Ekran Kaydı Alma

### 1. DevEco Studio'da

```bash
# HarmonyOS Emulator veya device'ta
1. Uygulamanızı çalıştırın
2. DevEco Studio → Tools → Screen Recorder
3. Widget'ınızı kullanın (2-5 saniye)
4. Stop tuşuna basın
5. Video'yu kaydedin
```

### 2. macOS'ta (QuickTime)

```bash
1. QuickTime Player açın
2. File → New Screen Recording
3. Kayıt alanını seçin
4. Widget'ınızı gösterin
5. Stop tuşuna basın
6. Video'yu kaydedin (.mov format)
```

### 3. Windows'ta (Game Bar)

```bash
1. Win + G tuşlarına basın
2. Capture widget'ını açın
3. Record tuşuna basın
4. Widget'ınızı gösterin
5. Stop tuşuna basın
6. Video'yu kaydedin
```

## 🎨 GIF'e Dönüştürme

### Yöntem 1: GIPHY Capture (macOS)

```bash
1. GIPHY Capture'ı açın
2. File → Import Video
3. Video'nuzu seçin
4. Gereksiz kısımları kesin
5. Boyutu ayarlayın (300-500px genişlik)
6. FPS: 15-24
7. Export → Save as GIF
```

### Yöntem 2: ScreenToGif (Windows)

```bash
1. ScreenToGif'i açın
2. Editor → File → Load
3. Video'nuzu yükleyin
4. Resize → Width: 400px
5. Frame rate: 20 FPS
6. File → Save as → GIF
7. Encoder settings:
   - Quality: 80-90
   - Repeat: Forever
```

### Yöntem 3: CloudConvert (Web)

```bash
1. cloudconvert.com adresine gidin
2. "Select File" → Video'nuzu yükleyin
3. Convert to: GIF
4. Settings:
   - Width: 400px
   - FPS: 20
   - Quality: High
5. Start Conversion
6. Download
```

### Yöntem 4: FFmpeg (Terminal) - Pro

```bash
# Video'dan GIF oluştur
ffmpeg -i input.mp4 -vf "fps=20,scale=400:-1:flags=lanczos" \
       -c:v gif output.gif

# Optimize et
ffmpeg -i input.gif -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
       -loop 0 output_optimized.gif
```

## ⚙️ Optimizasyon Ayarları

### İdeal Ayarlar:

| Parametre | Değer | Açıklama |
|-----------|-------|----------|
| Genişlik | 300-500px | Yeterli detay, hızlı yükleme |
| Yükseklik | Auto | Aspect ratio korunur |
| FPS | 15-24 | Smooth ama ağır değil |
| Süre | 2-5 saniye | Loop için ideal |
| Dosya Boyutu | < 3MB | Web için optimal |
| Loop | Forever | Sürekli oynatım |
| Kalite | 80-90% | İyi görünüm, makul boyut |

### Boyut Küçültme İpuçları:

1. **FPS'i düşür**: 30 → 20 → 15
2. **Boyutu küçült**: 500px → 400px → 300px
3. **Süreyi kısalt**: 5s → 3s → 2s
4. **Renk paletini sınırla**: 256 → 128 renk
5. **Gereksiz frame'leri sil**: Beklemeler, boş anlar
6. **Optimize araçları kullan**: gifsicle, ezgif.com

## 📐 Kompozisyon İpuçları

### Widget'ı Çerçeveleme:

```
┌─────────────────────┐
│  [Padding]          │
│    ┌───────────┐    │
│    │  Widget   │    │  ← Widget merkeze
│    │           │    │
│    └───────────┘    │
│  [Padding]          │
└─────────────────────┘
```

### İyi Pratikler:

✅ Widget odakta olsun
✅ Yeterli padding bırakın
✅ Temiz arka plan kullanın
✅ Animasyonları gösterin
✅ Kullanıcı etkileşimini gösterin
✅ Loop sorunsuz olsun (son frame = ilk frame)

❌ Çok fazla içerik
❌ Karmaşık arka plan
❌ Hızlı geçişler
❌ Uzun bekleme süreleri
❌ Kesik loop

## 📱 Cihaz Frame Ekleme (Opsiyonel)

### Online Araçlar:
- **mockuphone.com**: Ücretsiz
- **shotsnapp.com**: Modern çerçeveler
- **facebook.com/devices**: Facebook Design
- **deviceframes.com**: Çok çeşitli

### Örnek Kullanım:
```bash
1. GIF'inizi hazırlayın
2. mockuphone.com'a gidin
3. HarmonyOS veya Android cihaz seçin
4. GIF'i yükleyin
5. Frame'li versiyonu indirin
```

## 🎬 Çekim Senaryosu Örnekleri

### Button Widget:
```
0-1s: Normal durum
1-2s: Hover efekti
2-3s: Click animasyonu
3-4s: Normal duruma dön
[Loop]
```

### Card Widget:
```
0-2s: Kartı göster
2-3s: Hover efekti
3-4s: Genişleme animasyonu
4-5s: Normal duruma dön
[Loop]
```

### Navigation Bar:
```
0-1s: Ana sayfa seçili
1-2s: İkinci sekmeye geç
2-3s: Üçüncü sekmeye geç
3-4s: Ana sayfaya dön
[Loop]
```

### Search Bar:
```
0-1s: Boş durum
1-2s: Focus olma
2-3s: Metin yazma animasyonu
3-4s: Temizle ve başa dön
[Loop]
```

## 💾 Dosya Organizasyonu

```
assets/
└── gifs/
    ├── navigation/
    │   ├── bottom_nav_gradient.gif
    │   ├── tab_bar_animated.gif
    │   └── drawer_menu.gif
    ├── cards/
    │   ├── profile_card.gif
    │   ├── product_card.gif
    │   └── info_card.gif
    ├── buttons/
    │   ├── primary_button.gif
    │   ├── icon_button.gif
    │   └── fab_button.gif
    └── input/
        ├── search_bar.gif
        ├── text_field.gif
        └── form_input.gif
```

## 🔧 Sorun Giderme

### GIF çok büyük (>3MB)
```bash
- FPS'i 15'e düşür
- Genişliği 400px'e küçült
- Süreyi kısalt
- ezgif.com/optimize kullan
```

### GIF kalitesiz görünüyor
```bash
- Kayıt çözünürlüğünü artır
- Kalite ayarını yükselt
- Dithering ekle
- Renk paletini artır
```

### Loop sorunsuz değil
```bash
- Son frame'i düzenle
- İlk ve son frame aynı olmalı
- Geçiş frame'i ekle
- Reverse playback dene
```

### Animasyon hızlı/yavaş
```bash
- FPS ayarla: 15-24 arası
- Frame'leri duplicate et (yavaşlatmak için)
- Frame'leri sil (hızlandırmak için)
```

## 📚 Ek Kaynaklar

- [GIPHY Engineering Blog](https://engineering.giphy.com/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [GIF Optimization Guide](https://developers.google.com/speed/docs/insights/OptimizeImages)

## ✅ Kontrol Listesi

Yüklemeden önce:
- [ ] Boyut: 300-500px genişlik
- [ ] Dosya boyutu: < 3MB
- [ ] FPS: 15-24
- [ ] Süre: 2-5 saniye
- [ ] Loop: Sorunsuz
- [ ] Kalite: Net ve açık
- [ ] Format: .gif
- [ ] Dosya adı: anlamlı ve lowercase

---

**İyi çekimler! 🎬**
