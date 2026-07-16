// 🎨 WIDGET ŞABLONU
// Bu dosyayı kullanarak kolayca yeni widget'lar ekleyebilirsiniz

import '../models/widget_showcase.dart';

// ADIM 1: Bu şablonu kopyalayın
// ADIM 2: Bilgileri doldurun
// ADIM 3: lib/data/sample_widgets.dart dosyasındaki listeye ekleyin

final templateWidget = WidgetShowcase(
  // Benzersiz ID - Sadece rakam veya harf kullanın
  id: 'YOUR_UNIQUE_ID',
  
  // Widget başlığı - Kısa ve açıklayıcı
  title: 'Your Widget Title',
  
  // Widget açıklaması - Max 100 karakter önerilir
  description: 'Brief description of what this widget does',
  
  // Kategori - Mevcut: Navigation, Cards, Input, Buttons
  // Veya yeni bir kategori adı ekleyin
  category: 'Your Category',
  
  // GIF dosya yolu - assets/gifs/ klasöründeki GIF
  gifPath: 'assets/gifs/your_widget.gif',
  
  // ArkTS Kodu - Tam çalışan kod örneği
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

// KULLANIM ÖRNEĞİ:
// @Entry
// @Component  
// struct Index {
//   build() {
//     YourWidgetName()
//   }
// }
''',
  
  // Tag'ler - Arama için kullanılır (2-5 tag önerilir)
  tags: ['tag1', 'tag2', 'tag3'],
);

/* 
 * 💡 İPUÇLARI
 * ===========
 * 
 * 1. ID seçimi:
 *    ✅ 'custom_button_1'
 *    ✅ 'profile_card'
 *    ❌ 'my widget' (boşluk yok!)
 *    ❌ 'button@123' (özel karakter yok!)
 * 
 * 2. Başlık örnekleri:
 *    ✅ 'Animated Button'
 *    ✅ 'Profile Card with Avatar'
 *    ✅ 'Gradient Background'
 *    ❌ 'button' (çok kısa!)
 *    ❌ 'This is a very long title that explains everything' (çok uzun!)
 * 
 * 3. Açıklama örnekleri:
 *    ✅ 'Modern button with ripple effect and icon support'
 *    ✅ 'User profile card displaying avatar, name and stats'
 *    ❌ 'Button' (çok kısa!)
 * 
 * 4. Kategori önerileri:
 *    - Navigation (Bottom bars, Tab bars, Drawers)
 *    - Cards (Profile cards, Product cards, Info cards)
 *    - Input (Text fields, Search bars, Forms)
 *    - Buttons (Primary, Secondary, Icon buttons)
 *    - Lists (List items, Grid items)
 *    - Layout (Containers, Wrappers, Spacers)
 *    - Animation (Transitions, Effects)
 *    - Media (Image viewers, Video players)
 * 
 * 5. Tag örnekleri:
 *    ✅ ['button', 'animated', 'gradient']
 *    ✅ ['card', 'profile', 'user']
 *    ✅ ['input', 'search', 'icon']
 *    ❌ ['Button', 'ANIMATED'] (küçük harf kullanın!)
 * 
 * 6. Kod yazımı:
 *    - Tam çalışan kod yazın
 *    - Yorumlar ekleyin
 *    - Girintilemeye dikkat edin
 *    - State yönetimini gösterin
 *    - Kullanım örneği ekleyin (yorumda)
 * 
 * 7. GIF hazırlama:
 *    - Boyut: 300-500px genişlik
 *    - Süre: 2-5 saniye
 *    - Loop: Evet
 *    - FPS: 15-24
 *    - Format: GIF
 *    - Dosya boyutu: < 3MB
 * 
 * 
 * 📋 KONTROL LİSTESİ
 * ==================
 * 
 * Eklemeden önce kontrol edin:
 * □ ID benzersiz mi?
 * □ Başlık açıklayıcı mı?
 * □ Açıklama 100 karakterden kısa mı?
 * □ Kategori anlamlı mı?
 * □ GIF dosyası mevcut mu?
 * □ Kod çalışıyor mu?
 * □ Kod düzgün girintili mi?
 * □ Tag'ler küçük harfli mi?
 * □ En az 2 tag var mı?
 * 
 * 
 * 🚀 EKLEME ADIMLARI
 * ===================
 * 
 * 1. Bu şablonu kopyalayın
 * 2. Bilgileri doldurun
 * 3. lib/data/sample_widgets.dart açın
 * 4. sampleWidgets listesinin sonuna ekleyin:
 * 
 *    final List<WidgetShowcase> sampleWidgets = [
 *      // ... mevcut widget'lar
 *      
 *      // Yeni widget'ınız
 *      WidgetShowcase(
 *        id: 'your_id',
 *        title: 'Your Title',
 *        // ...
 *      ),
 *    ];
 * 
 * 5. Hot reload için terminal'de 'r' tuşuna basın
 * 6. Web uygulamasında widget'ınızı görün!
 * 
 * 
 * 📦 ÖRNEK WIDGET (Kopyalayıp kullanabilirsiniz)
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

// KULLANIM:
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
 * 🎓 DAHA FAZLA BİLGİ
 * ====================
 * 
 * - Detaylı kullanım: USAGE_GUIDE.md
 * - Hızlı başlangıç: QUICKSTART.md
 * - ArkTS Docs: https://developer.harmonyos.com/
 * 
 * 
 * 💬 YARDIM
 * ==========
 * 
 * Sorunuz mu var? 
 * - GitHub Issues açın
 * - Dokümantasyonu okuyun
 * - Community'ye katılın
 * 
 * İyi kodlamalar! 🚀
 */
