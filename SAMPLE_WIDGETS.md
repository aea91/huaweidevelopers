# 📦 Sample Widgets - Adding Guide from Admin Panel

Sample widgets for each category! You can add them from the admin panel.

---

## 🧭 Navigation Kategorisi

### Widget 1: Bottom Navigation Bar

**Title:**
```
Bottom Navigation Bar with Gradient
```

**Explanation:**
```
Modern gradient bottom navigation bar with icon and label support
```

**Category:**
```
Navigation
```

**Tagler:**
```
navigation, bottom bar, gradient, icons
```

**ArkTS Code:**
```typescript
@Component
export struct GradientBottomNav {
  @State selectedIndex: number = 0;
  
  private navItems: Array<{icon: string, label: string}> = [
    { icon: 'home', label: 'Home' },
    { icon: 'search', label: 'Search' },
    { icon: 'add', label: 'Add' },
    { icon: 'notifications', label: 'Alerts' },
    { icon: 'person', label: 'Profile' }
  ];
  
  build() {
    Row() {
      ForEach(this.navItems, (item, index) => {
        Column() {
          Text(item.icon)
            .fontSize(24)
            .fontColor(this.selectedIndex === index ? '#5B21B6' : '#9CA3AF')
          
          Text(item.label)
            .fontSize(12)
            .fontColor(this.selectedIndex === index ? '#5B21B6' : '#6B7280')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .padding(8)
        .onClick(() => {
          this.selectedIndex = index;
        })
      }, item => item.label)
    }
    .width('100%')
    .height(64)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: '#00000010',
      offsetY: -2
    })
  }
}
```

---

## 🎴 Cards Kategorisi

### Widget 2: Animated Product Card

**Title:**
```
Animated Product Card
```

**Explanation:**
```
Product card with hover animation and shadow effects
```

**Category:**
```
Cards
```

**Tagler:**
```
card, product, animated, hover
```

**ArkTS Code:**
```typescript
@Component
export struct AnimatedProductCard {
  @State isHovered: boolean = false;
  
  build() {
    Column() {
      Image($r('app.media.product'))
        .width('100%')
        .height(200)
        .borderRadius({ topLeft: 16, topRight: 16 })
      
      Column() {
        Text('Product Name')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        
        Text('Description here')
          .fontSize(14)
          .margin({ top: 8 })
        
        Row() {
          Text('$99.99')
            .fontSize(24)
            .fontColor('#5B21B6')
          Blank()
          Button('Buy')
            .backgroundColor('#5B21B6')
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .padding(16)
    }
    .width(300)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: this.isHovered ? 20 : 10,
      offsetY: this.isHovered ? 10 : 5
    })
  }
}
```

---

## ⌨️ Input Kategorisi

### Widget 3: Modern Search Bar

**Title:**
```
Modern Search Bar
```

**Explanation:**
```
Clean search input with icon and focus animation
```

**Category:**
```
Input
```

**Tagler:**
```
search, input, textfield
```

**ArkTS Code:**
```typescript
@Component
export struct ModernSearchBar {
  @State searchText: string = '';
  @State isFocused: boolean = false;
  
  build() {
    Row() {
      Image($r('app.media.search'))
        .width(20)
        .height(20)
        .margin({ left: 16 })
      
      TextInput({ 
        placeholder: 'Search...',
        text: this.searchText 
      })
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .onFocus(() => this.isFocused = true)
        .onBlur(() => this.isFocused = false)
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .borderRadius(28)
    .border({
      width: 2,
      color: this.isFocused ? '#5B21B6' : '#E5E7EB'
    })
  }
}
```

---

## 🔘 Buttons Kategorisi

### Widget 4: Gradient Button

**Title:**
```
Gradient Button with Icon
```

**Explanation:**
```
Eye-catching gradient button with press animation
```

**Category:**
```
Buttons
```

**Tagler:**
```
button, gradient, animated
```

**ArkTS Code:**
```typescript
@Component
export struct GradientButton {
  @State isPressed: boolean = false;
  
  build() {
    Row() {
      Text('Get Started')
        .fontSize(16)
        .fontColor(Color.White)
      
      Image($r('app.media.arrow'))
        .width(20)
        .height(20)
        .margin({ left: 8 })
    }
    .width(200)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .borderRadius(28)
    .linearGradient({
      colors: [[0x5B21B6, 0.0], [0x7C3AED, 1.0]]
    })
    .scale({
      x: this.isPressed ? 0.95 : 1,
      y: this.isPressed ? 0.95 : 1
    })
    .onClick(() => {
      console.log('Clicked');
    })
  }
}
```

---

## 👤 Layout Kategorisi

### Widget 5: Profile Header

**Title:**
```
Profile Header with Stats
```

**Explanation:**
```
User profile header with avatar and statistics
```

**Category:**
```
Layout
```

**Tagler:**
```
profile, user, stats
```

**ArkTS Code:**
```typescript
@Component
export struct ProfileHeader {
  build() {
    Column() {
      Row() {
        Image($r('app.media.avatar'))
          .width(80)
          .height(80)
          .borderRadius(40)
        
        Column() {
          Text('John Doe')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          
          Text('Developer')
            .fontSize(14)
            .margin({ top: 4 })
        }
        .margin({ left: 16 })
      }
      
      Row() {
        Column() {
          Text('89')
            .fontSize(24)
            .fontColor('#5B21B6')
          Text('Followers')
            .fontSize(12)
        }
        
        Column() {
          Text('234')
            .fontSize(24)
            .fontColor('#5B21B6')
          Text('Following')
            .fontSize(12)
        }
      }
      .margin({ top: 20 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
  }
}
```

---

Steps to Add ## 📝

1. Log in to the admin panel
2. Click "Add Widget" for each widget
3. Select a GIF (any .gif as placeholder)
4. Copy the information above
5. Kaydedin!

**Add 5 widgets in 5 minutes! 🚀**
