import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  print('🚀 Initializing Firebase connection...');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('✅ Firebase connection established!\n');

  // Firestore reference
  final firestore = FirebaseFirestore.instance;

  // Sample widget data
  final sampleWidgets = [
    {
      'title': 'Bottom Navigation Bar with Gradient',
      'description':
          'Modern gradient bottom navigation bar with icon and label support',
      'category': 'Navigation',
      'tags': ['navigation', 'bottom bar', 'gradient', 'icons'],
      'gifUrl':
          'https://via.placeholder.com/400x300.gif?text=Bottom+Navigation',
      'code': '''@Component
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
}''',
    },
    {
      'title': 'Animated Product Card',
      'description': 'Product card with hover animation and shadow effects',
      'category': 'Cards',
      'tags': ['card', 'product', 'animated', 'hover'],
      'gifUrl': 'https://via.placeholder.com/400x300.gif?text=Product+Card',
      'code': '''@Component
export struct AnimatedProductCard {
  @State isHovered: boolean = false;
  
  build() {
    Column() {
      Image(\$r('app.media.product'))
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
          Text('\$99.99')
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
}''',
    },
    {
      'title': 'Modern Search Bar',
      'description': 'Clean search input with icon and focus animation',
      'category': 'Input',
      'tags': ['search', 'input', 'textfield'],
      'gifUrl': 'https://via.placeholder.com/400x300.gif?text=Search+Bar',
      'code': '''@Component
export struct ModernSearchBar {
  @State searchText: string = '';
  @State isFocused: boolean = false;
  
  build() {
    Row() {
      Image(\$r('app.media.search'))
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
}''',
    },
    {
      'title': 'Gradient Button with Icon',
      'description': 'Eye-catching gradient button with press animation',
      'category': 'Buttons',
      'tags': ['button', 'gradient', 'animated'],
      'gifUrl': 'https://via.placeholder.com/400x300.gif?text=Gradient+Button',
      'code': '''@Component
export struct GradientButton {
  @State isPressed: boolean = false;
  
  build() {
    Row() {
      Text('Get Started')
        .fontSize(16)
        .fontColor(Color.White)
      
      Image(\$r('app.media.arrow'))
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
}''',
    },
    {
      'title': 'Profile Header with Stats',
      'description': 'User profile header with avatar and statistics',
      'category': 'Layout',
      'tags': ['profile', 'user', 'stats'],
      'gifUrl': 'https://via.placeholder.com/400x300.gif?text=Profile+Header',
      'code': '''@Component
export struct ProfileHeader {
  build() {
    Column() {
      Row() {
        Image(\$r('app.media.avatar'))
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
}''',
    },
  ];

  print('📦 Uploading ${sampleWidgets.length} widgets...\n');

  int successCount = 0;
  int errorCount = 0;

  for (var widgetData in sampleWidgets) {
    try {
      // Add the widget to Firestore
      await firestore.collection('widgets').add({
        'title': widgetData['title'],
        'description': widgetData['description'],
        'category': widgetData['category'],
        'tags': widgetData['tags'],
        'code': widgetData['code'],
        'gifUrl': widgetData['gifUrl'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ "${widgetData['title']}" uploaded!');
      successCount++;
    } catch (e) {
      print('❌ "${widgetData['title']}" failed to upload: $e');
      errorCount++;
    }
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ Successful: $successCount');
  print('❌ Failed: $errorCount');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('\n🎉 Operation complete!');
  print('🌐 View widgets at: https://arkuibuilder.web.app\n');
}
