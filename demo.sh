#!/bin/bash

# 🎨 ArkUI Build - Quick Demo Script
# Bu script projenizi hızlıca test etmenizi sağlar

echo "🚀 ArkUI Build - Component Library Showcase"
echo "==========================================="
echo ""

# Renk kodları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Proje Bilgileri${NC}"
echo "   - 7 Dart dosyası"
echo "   - 5 Örnek widget"
echo "   - 4 Kategori"
echo "   - 6 Dokümantasyon dosyası"
echo ""

echo -e "${BLUE}📁 Proje Yapısı${NC}"
echo "   lib/"
echo "   ├── data/sample_widgets.dart      (Widget verileri)"
echo "   ├── models/widget_showcase.dart   (Model)"
echo "   ├── screens/home_screen.dart      (Ana ekran)"
echo "   ├── widgets/                      (UI bileşenleri)"
echo "   └── main.dart                     (Entry point)"
echo ""

echo -e "${BLUE}📚 Dokümantasyon${NC}"
echo "   - START_HERE.md      → İlk başlangıç (BURADAN BAŞLAYIN!)"
echo "   - README.md          → Genel bilgi"
echo "   - QUICKSTART.md      → Hızlı başlangıç"
echo "   - USAGE_GUIDE.md     → Detaylı kullanım"
echo "   - GIF_GUIDE.md       → GIF hazırlama"
echo "   - WIDGET_TEMPLATE.dart → Widget şablonu"
echo ""

echo -e "${YELLOW}⚡ Hızlı Komutlar${NC}"
echo "   flutter run -d chrome       # Uygulamayı çalıştır"
echo "   flutter build web --release # Production build"
echo "   flutter pub get             # Paketleri yükle"
echo ""

echo -e "${GREEN}✅ Proje hazır!${NC}"
echo ""
echo "Başlamak için:"
echo "  1. START_HERE.md dosyasını okuyun"
echo "  2. flutter run -d chrome ile çalıştırın"
echo "  3. GIF'lerinizi assets/gifs/ klasörüne ekleyin"
echo "  4. Kendi widget'larınızı ekleyin"
echo ""
echo "İyi kodlamalar! 🚀"
