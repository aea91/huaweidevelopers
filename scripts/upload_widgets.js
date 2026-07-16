#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Firebase Admin SDK'yı başlat
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'arkuibuilder.appspot.com'
});

const db = admin.firestore();
const storage = admin.storage().bucket();

async function uploadSampleWidgets() {
  try {
    console.log('🚀 Firebase bağlantısı başarılı!');
    
    // JSON dosyasını oku
    const jsonPath = path.join(__dirname, 'sample_widgets.json');
    const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    
    console.log(`\n📦 ${data.widgets.length} adet widget yüklenecek...\n`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const widget of data.widgets) {
      try {
        // Firestore'a widget ekle
        const docRef = await db.collection('widgets').add({
          title: widget.title,
          description: widget.description,
          category: widget.category,
          tags: widget.tags,
          code: widget.code,
          gifUrl: widget.gifUrl,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`✅ "${widget.title}" eklendi! (ID: ${docRef.id})`);
        successCount++;
      } catch (e) {
        console.log(`❌ "${widget.title}" eklenirken hata: ${e.message}`);
        errorCount++;
      }
    }
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Başarılı: ${successCount}`);
    console.log(`❌ Hatalı: ${errorCount}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n🎉 İşlem tamamlandı!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Hata:', error);
    process.exit(1);
  }
}

uploadSampleWidgets();
