#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

//Initialize Firebase Admin SDK
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'arkuibuilder.appspot.com'
});

const db = admin.firestore();
const storage = admin.storage().bucket();

async function uploadSampleWidgets() {
  try {
    console.log('🚀 Firebase connection successful!');
    
    // read JSON file
    const jsonPath = path.join(__dirname, 'sample_widgets.json');
    const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    
    console.log(`\n📦 ${data.widgets.length} widgets will be loaded...\n`);
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const widget of data.widgets) {
      try {
        //Add widget to Firestore
        const docRef = await db.collection('widgets').add({
          title: widget.title,
          description: widget.description,
          category: widget.category,
          tags: widget.tags,
          code: widget.code,
          gifUrl: widget.gifUrl,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`✅ "${widget.title}" added! (ID: ${docRef.id})`);
        successCount++;
      } catch (e) {
        console.log(`❌ Error adding "${widget.title}": ${e.message}`);
        errorCount++;
      }
    }
    
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ Success: ${successCount}`);
    console.log(`❌ Error: ${errorCount}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n🎉 Operation completed!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

uploadSampleWidgets();
