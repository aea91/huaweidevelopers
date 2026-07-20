#!/bin/bash

# 🚀 Firebase Deployment Script
# Automatic build and deploy

set -e # Stop on error

echo "🚀 ArkUI Build - Firebase Deployment"
echo "====================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Flutter Clean (opsiyonel)
echo -e "${BLUE}🧹 Cleaning in progress...${NC}"
flutter clean
echo ""

# 2. Dependencies
echo -e "${BLUE}📦 Installing packages...${NC}"
flutter pub get
echo ""

# 3. Build
echo -e "${BLUE}🔨 Creating production build...${NC}"
echo "This process may take 1-2 minutes..."
flutter build web --release
echo ""

# Build control
if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Build failed! Build/web folder not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"
echo ""

#4. Firebase Deploy
echo -e "${BLUE}🚀 Deploying to Firebase...${NC}"
firebase deploy --only hosting

# Deployment control
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Deploy successful!${NC}"
    echo ""
    echo -e "${GREEN}🌐 Your site is live:${NC}"
    echo "   https://arkuibuilder.web.app"
    echo "   https://arkuibuilder.firebaseapp.com"
    echo ""
    echo -e "${YELLOW}📊 Firebase Console:${NC}"
    echo "   https://console.firebase.google.com/project/arkuibuilder"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Deploy failed!${NC}"
    echo "Please check Firebase login status:"
    echo "   firebase login"
    exit 1
fi

# Statistics
echo -e "${BLUE}📈 Build Stats:${NC}"
BUILD_SIZE=$(du -sh build/web | cut -f1)
echo "Build size: $BUILD_SIZE"
echo ""

echo -e "${GREEN}🎉 Operation completed!${NC}"
