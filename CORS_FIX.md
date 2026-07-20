# 🔴 CORS Error - Solution Guide

## Problem
```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' 
from origin 'http://localhost:61381' has been blocked by CORS policy
```

**Image exists in Firebase Storage but localhost can't access it!**

## ✅ Solution 1: Public Access from Firebase Console (Fastest)

### Steps:
1. **Turn on Firebase Storage**:
   https://console.firebase.google.com/project/arkuibuilder/storage

2. **Go to the Rules tab**

3. **Add this rule**:
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

4. **Click the "Publish" button**

5. **Refresh the page** (Cmd+R)

---

## ✅ Solution 2: Setting CORS with Google Cloud SDK

If Google Cloud SDK is installed:

### 1. Install Google Cloud SDK:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 2. Login olun:
```bash
gcloud auth login
```

### 3. Apply CORS settings:
```bash
gsutil cors set cors.json gs://arkuibuilder.appspot.com
```

---

## 🚀 Do Now:

**Firebase Console Path (Recommended):**
1. Go to the link above
2. Update Rules
3. Publish
4. Refresh the page in Chrome

**Image will appear! 🎉**

---

## Note:
CORS issue only occurs on localhost.
This problem does not exist in Production (arkuibuilder.web.app) because it is the same domain.
