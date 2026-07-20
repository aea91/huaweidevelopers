# 🎬 GIF Making Guide

How do you create professional GIF previews for your widgets? Here is the step by step guide!

## 🛠️ Tools Required

### For Screen Recording:
- **HarmonyOS DevEco Studio**: Built-in screen recorder
- **OBS Studio** (Free): Powerful for Windows, macOS, Linux
- **QuickTime Player** (macOS): System application
- **Windows Game Bar** (Windows): Win + G keys
- **AZ Screen Recorder** (Android): For mobile device

### For GIF Conversion:
- **GIPHY Capture** (macOS): The easiest solution
- **ScreenToGif** (Windows): Both recording and conversion
- **CloudConvert** (Web): Online conversion
- **FFmpeg** (Terminal): Professional use
- **ezgif.com** (Web): Online GIF editor

## 📹 Screen Recording

### 1. In DevEco Studio

```bash
# On HarmonyOS Emulator or device
1. Run your app
2. DevEco Studio → Tools → Screen Recorder
3. Use your widget (2-5 seconds)
4. Press the Stop key
5. Video'yu kaydedin
```

### 2. on macOS (QuickTime)

```bash
1. Open QuickTime Player
2. File → New Screen Recording
3. Select the recording area
4. Show off your widget
5. Press the Stop key
6. Save the video (.mov format)
```

### 3. In Windows (Game Bar)

```bash
1. Press Win + G
2. Open the Capture widget
3. Press Record
4. Show off your widget
5. Press the Stop key
6. Video'yu kaydedin
```

## 🎨 Convert to GIF

### Method 1: GIPHY Capture (macOS)

```bash
1. Open GIPHY Capture
2. File → Import Video
3. Select your video
4. Cut out unnecessary parts
5. Adjust the size (300-500px width)
6. FPS: 15-24
7. Export → Save as GIF
```

### Method 2: ScreenToGif (Windows)

```bash
1. Open ScreenToGif
2. Editor → File → Load
3. Upload your video
4. Resize → Width: 400px
5. Frame rate: 20 FPS
6. File → Save as → GIF
7. Encoder settings:
   - Quality: 80-90
   - Repeat: Forever
```

### Method 3: CloudConvert (Web)

```bash
1. Go to cloudconvert.com
2. "Select File" → Upload your video
3. Convert to: GIF
4. Settings:
   - Width: 400px
   - FPS: 20
   - Quality: High
5. Start Conversion
6. Download
```

### Method 4: FFmpeg (Terminal) - Pro

```bash
# Create GIF from Video
ffmpeg -i input.mp4 -vf "fps=20,scale=400:-1:flags=lanczos" \
       -c:v gif output.gif

# Optimize
ffmpeg -i input.gif -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
       -loop 0 output_optimized.gif
```

## ⚙️ Optimization Settings

### Ideal Settings:

| Parameter | Value | Description |
|-----------|-------|----------|
| Width | 300-500px | Decent detail, fast loading |
| Height | Auto | Aspect ratio is preserved |
| FPS | 15-24 | Smooth but not heavy |
| Duration | 2-5 seconds | Ideal for loop |
| File Size | < 3MB | Optimal for web |
| Loop | Forever | Continuous playback |
| Quality | 80-90% | Good appearance, reasonable size |

### Size Reduction Tips:

1. **Reduce FPS**: 30 → 20 → 15
2. **Reduce size**: 500px → 400px → 300px
3. **Shorten the time**: 5s → 3s → 2s
4. **Limit color palette**: 256 → 128 colors
5. **Delete unnecessary frames**: Waits, empty moments
6. **Use optimized tools**: gifsicle, ezgif.com

## 📐 Composition Tips

### Framing the Widget:

```
┌─────────────────────┐
│  [Padding]          │
│    ┌───────────┐    │
│    │  Widget   │    │  ← Widget merkeze
│    │           │    │
│    └───────────┘    │
│  [Padding]          │
└─────────────────────┘
```

### Good Practices:

✅ Widget odakta olsun
✅ Leave enough padding
✅ Use clean background
✅ Show animations
✅ Show user interaction
✅ Let the loop be smooth (last frame = first frame)

❌ Too much content
❌ Complex background
❌ Fast transitions
❌ Long waiting times
❌ Kesik loop

## 📱 Adding Device Frame (Optional)

### Online Tools:
- **mockuphone.com**: Free
- **shotsnapp.com**: Modern frames
- **facebook.com/devices**: Facebook Design
- **deviceframes.com**: Huge variety

### Example Usage:
```bash
1. Prepare your GIF
2. Go to mockuphone.com
3. Select HarmonyOS or Android device
4. Upload GIF
5. Frame'li versiyonu indirin
```

## 🎬 Shooting Script Examples

### Button Widget:
```
0-1s: Normal status
1-2s: Hover effect
2-3s: Click animasyonu
3-4s: Return to normal state
[Loop]
```

### Card Widget:
```
0-2s: Show card
2-3s: Hover effect
3-4s: Expansion animation
4-5s: Return to normal state
[Loop]
```

### Navigation Bar:
```
0-1s: Home page selected
1-2s: Switch to second tab
2-3s: Switch to third tab
3-4s: Return to home page
[Loop]
```

### Search Bar:
```
0-1s: Idle state
1-2s: Focus olma
2-3s: Text typing animation
3-4s: Clear and return to the beginning
[Loop]
```

## 💾 File Organization

```
assets/
└── gifs/
    ├── navigation/
    │   ├── bottom_nav_gradient.gif
    │   ├── tab_bar_animated.gif
    │   └── drawer_menu.gif
    ├── cards/
    │   ├── profile_card.gif
    │   ├── product_card.gif
    │   └── info_card.gif
    ├── buttons/
    │   ├── primary_button.gif
    │   ├── icon_button.gif
    │   └── fab_button.gif
    └── input/
        ├── search_bar.gif
        ├── text_field.gif
        └── form_input.gif
```

## 🔧 Troubleshooting

### GIF too large (>3MB)
```bash
- Reduce FPS to 15
- Reduce width to 400px
- Shorten the time
- Use ezgif.com/optimize
```

### GIF looks poor quality
```bash
- Increase recording resolution
- Increase quality setting
- Add dithering
- Increase color palette
```

### Loop is not smooth
```bash
- Edit last frame
- First and last frame must be the same
- Add transition frame
- Reverse playback dene
```

### Animation fast/slow
```bash
- Set FPS: between 15-24
- Duplicate frames (to slow down)
- Delete frames (to speed up)
```

## 📚 Ek Kaynaklar

- [GIPHY Engineering Blog](https://engineering.giphy.com/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [GIF Optimization Guide](https://developers.google.com/speed/docs/insights/OptimizeImages)

## ✅ Checklist

Before installing:
- [ ] Size: 300-500px width
- [ ] File size: < 3MB
- [ ] FPS: 15-24
- [ ] Duration: 2-5 seconds
- [ ] Loop: Sorunsuz
- [ ] Quality: Clear and clear
- [ ] Format: .gif
- [ ] Filename: significant and lowercase

---

**Happy shooting! 🎬**
