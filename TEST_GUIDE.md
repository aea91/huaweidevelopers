# 🧪 Test Guide - Grid View

## ✅ Application Launched!

Flutter application opened automatically in Chrome.

---

## 🎯 Test Scenarios

### 1️⃣ Grid View Test (All Category)

**Steps:**
1. See category chips on the home page
2. Click on the **"All"** category
3. ✅ **Check:**
   - Has the left sidebar disappeared?
   - Are widgets displayed in a grid?
   - Does Desktop have 3 columns?
   - Do pictures + information appear on each card?

### 2️⃣ Widget Card Test

**Steps:**
1. Click a widget card in the grid view
2. ✅ **Check:**
   - Is the detail page opened?
   - Is the widget's category automatically selected?
   - Did the sidebar + list appear on the left?
   - Did the image + code appear on the right?

### 3️⃣ Image Display Test

**Steps:**
1. Choose a widget
2. ✅ **Check:**
   - Is the image loading?
   - Is the image centered according to the code field?
   - No CORS errors? (on F12 Console)

### 4️⃣ Code View Test

**Steps:**
1. Examine the code field
2. ✅ **Check:**
   - Are the first 24 lines visible?
   - Does scroll work?
   - Is there a "Copy Code" button?
   - Is syntax highlighting correct?

### 5️⃣ Category Filtering Test

**Steps:**
1. Click on different categories (Navigation, Cards, Input, etc.)
2. ✅ **Check:**
   - Is left sidebar + list view enabled?
   - Are only widgets from that category shown?
   - Does widget selection work?

### 6️⃣ Search Test

**Steps:**
1. Type anything in the search box at the top
2. ✅ **Check:**
   - Are widgets filtered?
   - Are the results updated instantly?

### 7️⃣ Responsive Testi

**Steps:**
1. Minimize/maximize browser window
2. ✅ **Check:**
   - Desktop: 3 column grid
   - Tablet: 2 column grid
   - Mobile: List view

---

## 🐛 Possible Problems

### CORS Error (Localhost)
**Symptom:** Images not loading
**Solution:** Normal! CORS is already configured, but there may still be problems on localhost.
**Alternative:** Test in Production: https://arkuibuilder.web.app

### No Image Found
**Symptom:** Placeholder icon appears
**Solution:** Make sure to upload an image when adding widgets from the admin panel.

---

## 📊 Test Results Form

Please share your test results:

- [ ] Is the grid view working? (All category)
- [ ] Do the widget cards appear correctly?
- [ ] Does card click work?
- [ ] Are the images loading?
- [ ] Is the image centered?
- [ ] Is the code area 24 lines + scroll?
- [ ] Does category filtering work?
- [ ] Is the search working?
- [ ] Is responsive design correct?

---

## 🌐 Production Test

If there is a problem with localhost:
**https://arkuibuilder.web.app**

Everything will work perfectly in Production! 🚀

Share the results! 🎯
