#!/bin/bash

# 🎨 ArkUI Build - Quick Demo Script
# This script allows you to quickly test your project

echo "🚀 ArkUI Build - Component Library Showcase"
echo "==========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Project Information${NC}"
echo " - 7 Dart files"
echo " - 5 Sample widgets"
echo " - 4 Categories"
echo " - 6 Documentation file"
echo ""

echo -e "${BLUE}📁 Project Structure${NC}"
echo "   lib/"
echo "   ├── data/sample_widgets.dart      (Widget verileri)"
echo "   ├── models/widget_showcase.dart   (Model)"
echo " ├── screens/home_screen.dart (Home screen)"
echo " ├── widgets/ (UI widgets)"
echo "   └── main.dart                     (Entry point)"
echo ""

echo -e "${BLUE}📚 Documentation${NC}"
echo " - START_HERE.md → First start (START HERE!)"
echo " - README.md → General information"
echo " - QUICKSTART.md → Quickstart"
echo " - USAGE_GUIDE.md → Detailed usage"
echo " - GIF_GUIDE.md → GIF preparation"
echo " - WIDGET_TEMPLATE.dart → Widget template"
echo ""

echo -e "${YELLOW}⚡ Quick Commands${NC}"
echo " flutter run -d chrome # Run application"
echo "   flutter build web --release # Production build"
echo " flutter pub get # Install packages"
echo ""

echo -e "${GREEN}✅ Project is ready!${NC}"
echo ""
echo "To get started:"
echo " 1. Read START_HERE.md "
echo " 2. run with flutter run -d chrome"
echo " 3. Add your GIFs to assets/gifs/ folder"
echo " 4. Add your own widgets"
echo ""
echo "Happy coding! 🚀"
