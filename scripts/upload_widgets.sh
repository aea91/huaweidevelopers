#!/bin/bash

echo "🚀 Firebase'e sample widget'lar ekleniyor..."
echo ""

# Firebase project ID
PROJECT_ID="arkuibuilder"

# Widget verilerini tek tek ekle
echo "📦 5 adet widget yüklenecek..."
echo ""

# Widget 1: Bottom Navigation Bar
echo "📤 1/5: Bottom Navigation Bar ekleniyor..."
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/widgets" \
  -H "Authorization: Bearer $(firebase login:ci --no-localhost 2>&1 | grep -o 'ya29[^"]*' || firebase --token 2>&1 | grep -o 'ya29[^"]*')" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "title": {"stringValue": "Bottom Navigation Bar with Gradient"},
      "description": {"stringValue": "Modern gradient bottom navigation bar with icon and label support"},
      "category": {"stringValue": "Navigation"},
      "tags": {"arrayValue": {"values": [
        {"stringValue": "navigation"},
        {"stringValue": "bottom bar"},
        {"stringValue": "gradient"},
        {"stringValue": "icons"}
      ]}},
      "code": {"stringValue": "@Component\nexport struct GradientBottomNav {\n  @State selectedIndex: number = 0;\n  \n  private navItems: Array<{icon: string, label: string}> = [\n    { icon: '\''home'\'', label: '\''Home'\'' },\n    { icon: '\''search'\'', label: '\''Search'\'' },\n    { icon: '\''add'\'', label: '\''Add'\'' },\n    { icon: '\''notifications'\'', label: '\''Alerts'\'' },\n    { icon: '\''person'\'', label: '\''Profile'\'' }\n  ];\n  \n  build() {\n    Row() {\n      ForEach(this.navItems, (item, index) => {\n        Column() {\n          Text(item.icon)\n            .fontSize(24)\n            .fontColor(this.selectedIndex === index ? '\''#5B21B6'\'' : '\''#9CA3AF'\'')\n          \n          Text(item.label)\n            .fontSize(12)\n            .fontColor(this.selectedIndex === index ? '\''#5B21B6'\'' : '\''#6B7280'\'')\n            .margin({ top: 4 })\n        }\n        .layoutWeight(1)\n        .padding(8)\n        .onClick(() => {\n          this.selectedIndex = index;\n        })\n      }, item => item.label)\n    }\n    .width('\''100%'\'')\n    .height(64)\n    .backgroundColor(Color.White)\n    .shadow({\n      radius: 10,\n      color: '\''#00000010'\'',\n      offsetY: -2\n    })\n  }\n}"},
      "gifUrl": {"stringValue": "https://via.placeholder.com/400x300.gif?text=Bottom+Navigation"},
      "createdAt": {"timestampValue": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}
    }
  }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Bottom Navigation Bar eklendi!"
else
    echo "❌ Bottom Navigation Bar eklenirken hata oluştu"
fi

# Widget 2: Animated Product Card
echo "📤 2/5: Animated Product Card ekleniyor..."
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/widgets" \
  -H "Authorization: Bearer $(firebase login:ci --no-localhost 2>&1 | grep -o 'ya29[^"]*' || firebase --token 2>&1 | grep -o 'ya29[^"]*')" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "title": {"stringValue": "Animated Product Card"},
      "description": {"stringValue": "Product card with hover animation and shadow effects"},
      "category": {"stringValue": "Cards"},
      "tags": {"arrayValue": {"values": [
        {"stringValue": "card"},
        {"stringValue": "product"},
        {"stringValue": "animated"},
        {"stringValue": "hover"}
      ]}},
      "code": {"stringValue": "@Component\nexport struct AnimatedProductCard {\n  @State isHovered: boolean = false;\n  \n  build() {\n    Column() {\n      Image($r('\''app.media.product'\''))\n        .width('\''100%'\'')\n        .height(200)\n        .borderRadius({ topLeft: 16, topRight: 16 })\n      \n      Column() {\n        Text('\''Product Name'\'')\n          .fontSize(18)\n          .fontWeight(FontWeight.Bold)\n        \n        Text('\''Description here'\'')\n          .fontSize(14)\n          .margin({ top: 8 })\n        \n        Row() {\n          Text('\''$99.99'\'')\n            .fontSize(24)\n            .fontColor('\''#5B21B6'\'')\n          Blank()\n          Button('\''Buy'\'')\n            .backgroundColor('\''#5B21B6'\'')\n        }\n        .width('\''100%'\'')\n        .margin({ top: 16 })\n      }\n      .padding(16)\n    }\n    .width(300)\n    .backgroundColor(Color.White)\n    .borderRadius(16)\n    .shadow({\n      radius: this.isHovered ? 20 : 10,\n      offsetY: this.isHovered ? 10 : 5\n    })\n  }\n}"},
      "gifUrl": {"stringValue": "https://via.placeholder.com/400x300.gif?text=Product+Card"},
      "createdAt": {"timestampValue": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}
    }
  }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Animated Product Card eklendi!"
else
    echo "❌ Animated Product Card eklenirken hata oluştu"
fi

# Widget 3: Modern Search Bar
echo "📤 3/5: Modern Search Bar ekleniyor..."
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/widgets" \
  -H "Authorization: Bearer $(firebase login:ci --no-localhost 2>&1 | grep -o 'ya29[^"]*' || firebase --token 2>&1 | grep -o 'ya29[^"]*')" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "title": {"stringValue": "Modern Search Bar"},
      "description": {"stringValue": "Clean search input with icon and focus animation"},
      "category": {"stringValue": "Input"},
      "tags": {"arrayValue": {"values": [
        {"stringValue": "search"},
        {"stringValue": "input"},
        {"stringValue": "textfield"}
      ]}},
      "code": {"stringValue": "@Component\nexport struct ModernSearchBar {\n  @State searchText: string = '\'''\'';\n  @State isFocused: boolean = false;\n  \n  build() {\n    Row() {\n      Image($r('\''app.media.search'\''))\n        .width(20)\n        .height(20)\n        .margin({ left: 16 })\n      \n      TextInput({ \n        placeholder: '\''Search...'\'',\n        text: this.searchText \n      })\n        .layoutWeight(1)\n        .backgroundColor(Color.Transparent)\n        .onFocus(() => this.isFocused = true)\n        .onBlur(() => this.isFocused = false)\n    }\n    .width('\''100%'\'')\n    .height(56)\n    .backgroundColor(Color.White)\n    .borderRadius(28)\n    .border({\n      width: 2,\n      color: this.isFocused ? '\''#5B21B6'\'' : '\''#E5E7EB'\''\n    })\n  }\n}"},
      "gifUrl": {"stringValue": "https://via.placeholder.com/400x300.gif?text=Search+Bar"},
      "createdAt": {"timestampValue": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}
    }
  }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Modern Search Bar eklendi!"
else
    echo "❌ Modern Search Bar eklenirken hata oluştu"
fi

# Widget 4: Gradient Button
echo "📤 4/5: Gradient Button ekleniyor..."
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/widgets" \
  -H "Authorization: Bearer $(firebase login:ci --no-localhost 2>&1 | grep -o 'ya29[^"]*' || firebase --token 2>&1 | grep -o 'ya29[^"]*')" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "title": {"stringValue": "Gradient Button with Icon"},
      "description": {"stringValue": "Eye-catching gradient button with press animation"},
      "category": {"stringValue": "Buttons"},
      "tags": {"arrayValue": {"values": [
        {"stringValue": "button"},
        {"stringValue": "gradient"},
        {"stringValue": "animated"}
      ]}},
      "code": {"stringValue": "@Component\nexport struct GradientButton {\n  @State isPressed: boolean = false;\n  \n  build() {\n    Row() {\n      Text('\''Get Started'\'')\n        .fontSize(16)\n        .fontColor(Color.White)\n      \n      Image($r('\''app.media.arrow'\''))\n        .width(20)\n        .height(20)\n        .margin({ left: 8 })\n    }\n    .width(200)\n    .height(56)\n    .justifyContent(FlexAlign.Center)\n    .borderRadius(28)\n    .linearGradient({\n      colors: [[0x5B21B6, 0.0], [0x7C3AED, 1.0]]\n    })\n    .scale({\n      x: this.isPressed ? 0.95 : 1,\n      y: this.isPressed ? 0.95 : 1\n    })\n    .onClick(() => {\n      console.log('\''Clicked'\'');\n    })\n  }\n}"},
      "gifUrl": {"stringValue": "https://via.placeholder.com/400x300.gif?text=Gradient+Button"},
      "createdAt": {"timestampValue": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}
    }
  }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Gradient Button eklendi!"
else
    echo "❌ Gradient Button eklenirken hata oluştu"
fi

# Widget 5: Profile Header
echo "📤 5/5: Profile Header ekleniyor..."
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/widgets" \
  -H "Authorization: Bearer $(firebase login:ci --no-localhost 2>&1 | grep -o 'ya29[^"]*' || firebase --token 2>&1 | grep -o 'ya29[^"]*')" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "title": {"stringValue": "Profile Header with Stats"},
      "description": {"stringValue": "User profile header with avatar and statistics"},
      "category": {"stringValue": "Layout"},
      "tags": {"arrayValue": {"values": [
        {"stringValue": "profile"},
        {"stringValue": "user"},
        {"stringValue": "stats"}
      ]}},
      "code": {"stringValue": "@Component\nexport struct ProfileHeader {\n  build() {\n    Column() {\n      Row() {\n        Image($r('\''app.media.avatar'\''))\n          .width(80)\n          .height(80)\n          .borderRadius(40)\n        \n        Column() {\n          Text('\''John Doe'\'')\n            .fontSize(24)\n            .fontWeight(FontWeight.Bold)\n          \n          Text('\''Developer'\'')\n            .fontSize(14)\n            .margin({ top: 4 })\n        }\n        .margin({ left: 16 })\n      }\n      \n      Row() {\n        Column() {\n          Text('\''89'\'')\n            .fontSize(24)\n            .fontColor('\''#5B21B6'\'')\n          Text('\''Followers'\'')\n            .fontSize(12)\n        }\n        \n        Column() {\n          Text('\''234'\'')\n            .fontSize(24)\n            .fontColor('\''#5B21B6'\'')\n          Text('\''Following'\'')\n            .fontSize(12)\n        }\n      }\n      .margin({ top: 20 })\n    }\n    .padding(20)\n    .backgroundColor(Color.White)\n    .borderRadius(20)\n  }\n}"},
      "gifUrl": {"stringValue": "https://via.placeholder.com/400x300.gif?text=Profile+Header"},
      "createdAt": {"timestampValue": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}
    }
  }' > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Profile Header eklendi!"
else
    echo "❌ Profile Header eklenirken hata oluştu"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 İşlem tamamlandı!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ https://arkuibuilder.web.app adresinden widget'ları görebilirsiniz!"
