#!/bin/bash

# 🚀 Firebase Deployment Script
# Otomatik build ve deploy

set -e  # Hata durumunda durdur

echo "🚀 ArkUI Build - Firebase Deployment"
echo "====================================="
echo ""

# Renk kodları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Flutter Clean (opsiyonel)
echo -e "${BLUE}🧹 Temizlik yapılıyor...${NC}"
flutter clean
echo ""

# 2. Dependencies
echo -e "${BLUE}📦 Paketler yükleniyor...${NC}"
flutter pub get
echo ""

# 3. Build
echo -e "${BLUE}🔨 Production build oluşturuluyor...${NC}"
echo "   Bu işlem 1-2 dakika sürebilir..."
flutter build web --release
echo ""

# Build kontrolü
if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Build başarısız! build/web klasörü bulunamadı.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build başarılı!${NC}"
echo ""

# 4. Firebase Deploy
echo -e "${BLUE}🚀 Firebase'e deploy ediliyor...${NC}"
firebase deploy --only hosting

# Deploy kontrolü
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Deploy başarılı!${NC}"
    echo ""
    echo -e "${GREEN}🌐 Siteniz yayında:${NC}"
    echo "   https://arkuibuilder.web.app"
    echo "   https://arkuibuilder.firebaseapp.com"
    echo ""
    echo -e "${YELLOW}📊 Firebase Console:${NC}"
    echo "   https://console.firebase.google.com/project/arkuibuilder"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Deploy başarısız!${NC}"
    echo "   Lütfen Firebase login durumunu kontrol edin:"
    echo "   firebase login"
    exit 1
fi

# İstatistikler
echo -e "${BLUE}📈 Build İstatistikleri:${NC}"
BUILD_SIZE=$(du -sh build/web | cut -f1)
echo "   Build boyutu: $BUILD_SIZE"
echo ""

echo -e "${GREEN}🎉 İşlem tamamlandı!${NC}"
