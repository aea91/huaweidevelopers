import '../models/widget_showcase.dart';

final List<WidgetShowcase> sampleWidgets = [
  WidgetShowcase(
    id: '1',
    title: 'Bottom Nav Bar Gradient',
    description: 'Modern gradient bottom navigation bar with smooth animations',
    category: 'Navigation',
    gifPath: 'assets/gifs/bottom_nav.gif', // Placeholder - GIF'inizi buraya ekleyin
    code: '''@Entry
@Component
struct BottomNavBarGradient {
  @State currentIndex: number = 0;
  
  final primaryColor = Color(0xff4338CA);
  final secondaryColor = Color(0xff6D28D9);
  final accentColor = Color(0xffffffff);
  final backgroundColor = Color(0xffffffff);
  final errorColor = Color(0xffEF4444);
  
  @Override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient:
          LinearGradient(colors: [Color(0xff4338CA),
            Color(0xff6D28D9)]),
        ),
      child: BottomAppBar(
        elevation: 0,
        color: Colors.transparent,
        child: SizedBox(
          height: 56,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(left: 25.0, right: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: currentIndex == 0 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    currentIndex = 0;
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: currentIndex == 1 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    currentIndex = 1;
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_box,
                    color: currentIndex == 2 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    currentIndex = 2;
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart,
                    color: currentIndex == 3 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    currentIndex = 3;
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.calendar_today,
                    color: currentIndex == 4 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.5),
                  ),
                  onPressed: () {
                    currentIndex = 4;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}''',
    tags: ['navigation', 'gradient', 'bottom bar'],
  ),
  WidgetShowcase(
    id: '2',
    title: 'Animated Card',
    description: 'Beautiful card with hover animations and shadow effects',
    category: 'Cards',
    gifPath: 'assets/gifs/animated_card.gif',
    code: '''@Component
struct AnimatedCard {
  @State isHovered: boolean = false;
  
  build() {
    Container() {
      Column() {
        Image(\$r('app.media.placeholder'))
          .width('100%')
          .height(200)
          .borderRadius({ topLeft: 16, topRight: 16 })
          .objectFit(ImageFit.Cover)
        
        Column() {
          Text('Card Title')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
          
          Text('This is a beautiful card with smooth animations')
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(20)
        }
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width(300)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: this.isHovered ? 20 : 10,
      color: '#1F000000',
      offsetX: 0,
      offsetY: this.isHovered ? 10 : 5
    })
    .scale({ 
      x: this.isHovered ? 1.05 : 1, 
      y: this.isHovered ? 1.05 : 1 
    })
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
    .onHover((isHover: boolean) => {
      this.isHovered = isHover;
    })
  }
}''',
    tags: ['card', 'animation', 'hover'],
  ),
  WidgetShowcase(
    id: '3',
    title: 'Search Bar',
    description: 'Modern search input with icon and smooth focus effects',
    category: 'Input',
    gifPath: 'assets/gifs/search_bar.gif',
    code: '''@Component
struct SearchBar {
  @State searchText: string = '';
  @State isFocused: boolean = false;
  
  build() {
    Row() {
      Image(\$r('app.media.ic_search'))
        .width(20)
        .height(20)
        .margin({ left: 16, right: 12 })
        .fillColor(this.isFocused ? '#5B21B6' : '#9CA3AF')
      
      TextInput({ 
        placeholder: 'Search widgets...',
        text: this.searchText 
      })
        .placeholderColor('#9CA3AF')
        .fontSize(16)
        .fontColor('#1F2937')
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.searchText = value;
        })
        .onFocus(() => {
          this.isFocused = true;
        })
        .onBlur(() => {
          this.isFocused = false;
        })
      
      if (this.searchText.length > 0) {
        Image(\$r('app.media.ic_close'))
          .width(20)
          .height(20)
          .margin({ right: 16 })
          .onClick(() => {
            this.searchText = '';
          })
      }
    }
    .width('100%')
    .height(50)
    .backgroundColor(Color.White)
    .borderRadius(25)
    .border({
      width: 2,
      color: this.isFocused ? '#5B21B6' : '#E5E7EB'
    })
    .shadow({
      radius: this.isFocused ? 15 : 5,
      color: this.isFocused ? '#5B21B620' : '#00000010',
      offsetY: 2
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }
}''',
    tags: ['search', 'input', 'textfield'],
  ),
  WidgetShowcase(
    id: '4',
    title: 'Button with Icon',
    description: 'Elegant button with icon and ripple effect',
    category: 'Buttons',
    gifPath: 'assets/gifs/button_icon.gif',
    code: '''@Component
struct ButtonWithIcon {
  @State isPressed: boolean = false;
  
  build() {
    Row() {
      Image(\$r('app.media.ic_star'))
        .width(20)
        .height(20)
        .fillColor(Color.White)
        .margin({ right: 8 })
      
      Text('Get Started')
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .width(200)
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(
      this.isPressed ? '#4C1D95' : '#5B21B6'
    )
    .borderRadius(25)
    .shadow({
      radius: 15,
      color: '#5B21B650',
      offsetY: 5
    })
    .scale({
      x: this.isPressed ? 0.95 : 1,
      y: this.isPressed ? 0.95 : 1
    })
    .animation({
      duration: 150,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      console.log('Button clicked');
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up) {
        this.isPressed = false;
      }
    })
  }
}''',
    tags: ['button', 'icon', 'interactive'],
  ),
  WidgetShowcase(
    id: '5',
    title: 'Profile Card',
    description: 'User profile card with avatar and information',
    category: 'Cards',
    gifPath: 'assets/gifs/profile_card.gif',
    code: '''@Component
struct ProfileCard {
  build() {
    Column() {
      // Avatar
      Image(\$r('app.media.avatar'))
        .width(80)
        .height(80)
        .borderRadius(40)
        .border({ width: 3, color: '#5B21B6' })
        .margin({ bottom: 16 })
      
      // Name
      Text('John Doe')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .margin({ bottom: 4 })
      
      // Role
      Text('ArkUI Developer')
        .fontSize(14)
        .fontColor('#6B7280')
        .margin({ bottom: 24 })
      
      // Stats
      Row() {
        Column() {
          Text('125')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5B21B6')
          Text('Projects')
            .fontSize(12)
            .fontColor('#9CA3AF')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        
        Divider()
          .vertical(true)
          .height(40)
          .color('#E5E7EB')
        
        Column() {
          Text('89')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5B21B6')
          Text('Followers')
            .fontSize(12)
            .fontColor('#9CA3AF')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        
        Divider()
          .vertical(true)
          .height(40)
          .color('#E5E7EB')
        
        Column() {
          Text('234')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5B21B6')
          Text('Following')
            .fontSize(12)
            .fontColor('#9CA3AF')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width(320)
    .padding(32)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({
      radius: 20,
      color: '#0000001A',
      offsetY: 10
    })
  }
}''',
    tags: ['profile', 'card', 'user'],
  ),
];
