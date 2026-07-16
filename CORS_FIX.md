# 🔴 CORS Hatası - Çözüm Rehberi

## Sorun
```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' 
from origin 'http://localhost:61381' has been blocked by CORS policy
```

**Resim Firebase Storage'da var ama localhost erişemiyor!**

## ✅ Çözüm 1: Firebase Console'dan Public Erişim (En Hızlı)

### Adımlar:
1. **Firebase Storage'ı açın**: 
   https://console.firebase.google.com/project/arkuibuilder/storage

2. **Rules sekmesine gidin**

3. **Şu kuralı ekleyin**:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /widget_gifs/{allPaths=**} {
      allow read: if true;  // Public read access
      allow write: if request.auth != null;
    }
  }
}
```

4. **"Publish" butonuna tıklayın**

5. **Sayfayı yenileyin** (Cmd+R)

---

## ✅ Çözüm 2: Google Cloud SDK ile CORS Ayarlama

Eğer Google Cloud SDK yüklüyse:

### 1. Google Cloud SDK'yı yükleyin:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 2. Login olun:
```bash
gcloud auth login
```

### 3. CORS ayarlarını uygulayın:
```bash
gsutil cors set cors.json gs://arkuibuilder.appspot.com
```

---

## 🚀 Hemen Yapın:

**Firebase Console Yolu (Önerilen):**
1. Yukarıdaki linke gidin
2. Rules'u güncelleyin
3. Publish edin
4. Chrome'da sayfayı yenileyin

**Resim görünecek! 🎉**

---

## Not:
CORS sorunu sadece localhost'ta oluyor. 
Production'da (arkuibuilder.web.app) bu sorun yok çünkü aynı domain.
