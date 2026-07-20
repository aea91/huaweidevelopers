// 🎨 WIDGET TEMPLATE
// You can easily add new widgets using this file

import '../models/widget_showcase.dart';

// STEP 1: Copy this template
// STEP 2: Fill in the information
// STEP 3: Add to list in lib/data/sample_widgets.dart file

final templateWidget = WidgetShowcase(
  //Unique ID - Use only numbers or letters
  id: 'YOUR_UNIQUE_ID',

  // Widget title - Short and descriptive
  title: 'Your Widget Title',

  // Widget description - Max 100 characters recommended
  description: 'Brief description of what this widget does',

  // Category - Available: Navigation, Cards, Input, Buttons
  //Or add a new category name
  category: 'Your Category',

  // GIF file path - GIF in folder assets/gifs/
  gifPath: 'assets/gifs/your_widget.gif',

  // ArkTS Code - Fully working code example
  code: '''
@Component
struct YourWidgetName {
  @State yourState: string = 'initial value';
  
  build() {
    Column() {
      // Your UI code here
      Text(this.yourState)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding(16)
  }
}

// USE EXAMPLE:
// @Entry
// @Component  
// struct Index {
//   build() {
//     YourWidgetName()
//   }
// }
''',

  // Tags - Used for search (2-5 tags recommended)
  tags: ['tag1', 'tag2', 'tag3'],
);

/* 
 * 💡 TIPS
 * ===========
 *
 * 1. ID selection:
 *    ✅ 'custom_button_1'
 *    ✅ 'profile_card'
 * ❌ 'my widget' (no spaces!)
 * ❌ 'button@123' (no special characters!)
 *
 * 2. Title examples:
 *    ✅ 'Animated Button'
 *    ✅ 'Profile Card with Avatar'
 *    ✅ 'Gradient Background'
 * ❌ 'button' (too short!)
 * ❌ 'This is a very long title that explains everything' (very long!)
 * 
 * 3. Explanation examples:
 *    ✅ 'Modern button with ripple effect and icon support'
 *    ✅ 'User profile card displaying avatar, name and stats'
 * ❌ 'Button' (too short!)
 * 
 * 4. Category recommendations:
 *    - Navigation (Bottom bars, Tab bars, Drawers)
 *    - Cards (Profile cards, Product cards, Info cards)
 *    - Input (Text fields, Search bars, Forms)
 *    - Buttons (Primary, Secondary, Icon buttons)
 *    - Lists (List items, Grid items)
 *    - Layout (Containers, Wrappers, Spacers)
 *    - Animation (Transitions, Effects)
 *    - Media (Image viewers, Video players)
 * 
 * 5. Tag examples:
 *    ✅ ['button', 'animated', 'gradient']
 *    ✅ ['card', 'profile', 'user']
 *    ✅ ['input', 'search', 'icon']
 * ❌ ['Button', 'ANIMATED'] (use lowercase!)
 *
 * 6. Code writing:
 * - Write fully working code
 * - Add comments
 * - Be careful with indentation
 * - Show state management
 * - Add usage example (in comment)
 *
 * 7. GIF preparation:
 * - Size: 300-500px width
 * - Duration: 2-5 seconds
 * - Loop: Yes
 *    - FPS: 15-24
 * - Format: GIF
 * - File size: < 3MB
 * 
 * 
 * 📋 CHECKLIST
 * ==================
 * 
 *Check before adding:
 * □ ID benzersiz mi?
 * □ Is the title descriptive?
 * □ Is the description less than 100 characters?
 * □ Does the category make sense?
 * □ Is GIF file available?
 * □ Does the code work?
 * □ Is the code properly indented?
 * □ Are tags in lowercase letters?
 * □ Are there at least 2 tags?
 * 
 * 
 * 🚀 ADDING STEPS
 * ===================
 * 
 * 1. Copy this template
 * 2. Fill in the information
 * 3. Open lib/data/sample_widgets.dart
 * 4. Add to the end of the sampleWidgets list:
 * 
 *    final List<WidgetShowcase> sampleWidgets = [
 * // ... available widgets
 *      
 * // Your new widget
 *      WidgetShowcase(
 *        id: 'your_id',
 *        title: 'Your Title',
 *        // ...
 *      ),
 *    ];
 * 
 * 5. Press 'r' in terminal for hot reload
 * 6. See your widget in the web app!
 * 
 * 
 * 📦 SAMPLE WIDGET (You can copy and use)
 * ================================================
 */

final exampleAnimatedButton = WidgetShowcase(
  id: 'animated_button_example',
  title: 'Pulse Button',
  description: 'Button with pulse animation effect on press',
  category: 'Buttons',
  gifPath: 'assets/gifs/pulse_button.gif',
  code: '''
@Component
struct PulseButton {
  @State isPressed: boolean = false;
  @State scale: number = 1.0;
  
  build() {
    Button('Press Me')
      .width(200)
      .height(50)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor('#5B21B6')
      .borderRadius(25)
      .scale({ x: this.scale, y: this.scale })
      .animation({
        duration: 200,
        curve: Curve.EaseOut,
        iterations: 1
      })
      .onClick(() => {
        // Pulse animation
        this.scale = 0.9;
        setTimeout(() => {
          this.scale = 1.0;
        }, 200);
        
        console.log('Button clicked!');
      })
  }
}

// USAGE:
// @Entry
// @Component
// struct Index {
//   build() {
//     Column() {
//       PulseButton()
//     }
//     .width('100%')
//     .height('100%')
//     .justifyContent(FlexAlign.Center)
//   }
// }
''',
  tags: ['button', 'animation', 'pulse', 'interactive'],
);

/*
 * 🎓 MORE INFORMATION
 * ====================
 * 
 * - Detailed usage: USAGE_GUIDE.md
 * - Quick start: QUICKSTART.md
 * - ArkTS Docs: https://developer.harmonyos.com/
 * 
 * 
 * 💬 YARDIM
 * ==========
 * 
 * Have questions?
 * - Open GitHub Issues
 * - Read the documentation
 * - Join the Community
 * 
 * Happy coding! 🚀
 */
