# 🔍 Resim Yükleme Sorununu Debug Etme

## Debug Adımları

### 1️⃣ Chrome Console'u Kontrol Edin
1. Chrome'da **F12** veya **Cmd+Option+I** ile DevTools açın
2. **Console** sekmesine gidin
3. Şu log mesajlarını arayın:
   ```
   WidgetPreview gifPath: [URL_BURAYA]
   Is HTTP URL: true/false
   ```

### 2️⃣ Firebase Console'da Verileri Kontrol Edin
1. **Firestore'u kontrol edin**: https://console.firebase.google.com/project/arkuibuilder/firestore
2. `widgets` koleksiyonunu açın
3. Eklediğiniz widget'ı seçin
4. **`gifUrl`** alanını kontrol edin:
   - ✅ URL varsa ve `https://` ile başlıyorsa: URL'yi kopyalayın
   - ❌ URL yoksa veya boşsa: Widget'ı yeniden yükleyin

### 3️⃣ Firebase Storage'ı Kontrol Edin
1. **Storage'ı kontrol edin**: https://console.firebase.google.com/project/arkuibuilder/storage
2. `widget_gifs/` klasörünü açın
3. Yüklediğiniz resim var mı?
   - ✅ Varsa: Dosyaya tıklayın, URL'yi kopyalayın
   - ❌ Yoksa: Resim yükleme başarısız olmuş

### 4️⃣ CORS Sorunu Kontrolü
Chrome Console'da şu hatayı görüyor musunuz?
```
Access to fetch at 'https://...' has been blocked by CORS policy
```

Eğer görüyorsanız, Firebase Storage CORS ayarlarını yapmalıyız.

## 🆘 Hızlı Test

Chrome Console'a şunu yazın:
```javascript
console.log(document.querySelector('img'))
```

Resim elementi var mı? `src` attribute'u ne?

---

## Bana Bildirecekleriniz:

1. **Chrome Console'da ne yazıyor?**
2. **Firebase Firestore'da `gifUrl` değeri ne?**
3. **Firebase Storage'da resim var mı?**
4. **Hangi hata mesajını görüyorsunuz?** (ekran görüntüsü alabilirsiniz)

Bu bilgilerle sorunu kesin çözeriz! 🔧
