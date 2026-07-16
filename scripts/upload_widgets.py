#!/usr/bin/env python3

import json
import subprocess
import sys

def main():
    print("🚀 Firebase'e sample widget'lar ekleniyor...\n")
    
    # JSON dosyasını oku
    with open('scripts/sample_widgets.json', 'r') as f:
        data = json.load(f)
    
    widgets = data['widgets']
    print(f"📦 {len(widgets)} adet widget yüklenecek...\n")
    
    success_count = 0
    error_count = 0
    
    for widget in widgets:
        try:
            # Firebase CLI ile Firestore'a veri ekle
            widget_json = json.dumps(widget)
            
            # Firestore'a ekle
            cmd = [
                'firebase', 'firestore:write',
                f'widgets/{success_count + 1}',
                '--data', widget_json,
                '--project', 'arkuibuilder'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ \"{widget['title']}\" eklendi!")
                success_count += 1
            else:
                print(f"❌ \"{widget['title']}\" eklenirken hata: {result.stderr}")
                error_count += 1
                
        except Exception as e:
            print(f"❌ \"{widget['title']}\" eklenirken hata: {e}")
            error_count += 1
    
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print(f'✅ Başarılı: {success_count}')
    print(f'❌ Hatalı: {error_count}')
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print('\n🎉 İşlem tamamlandı!')

if __name__ == '__main__':
    main()
