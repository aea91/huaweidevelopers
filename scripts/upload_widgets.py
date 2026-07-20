#!/usr/bin/env python3

import json
import subprocess
import sys

def main():
    print("🚀 Sample widgets are being added to Firebase...\n")
    
    # Read JSON file
    with open('scripts/sample_widgets.json', 'r') as f:
        data = json.load(f)
    
    widgets = data['widgets']
    print(f"📦 {len(widgets)} widgets will be loaded...\n")
    
    success_count = 0
    error_count = 0
    
    for widget in widgets:
        try:
            # Add data to Firestore with Firebase CLI
            widget_json = json.dumps(widget)
            
            # Add to Firestore
            cmd = [
                'firebase', 'firestore:write',
                f'widgets/{success_count + 1}',
                '--data', widget_json,
                '--project', 'arkuibuilder'
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ \"{widget['title']}\" added!")
                success_count += 1
            else:
                print(f"❌ Error adding \"{widget['title']}\": {result.stderr}")
                error_count += 1
                
        except Exception as e:
            print(f"❌ Error adding \"{widget['title']}\": {e}")
            error_count += 1
    
    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print(f'✅ Success: {success_count}')
    print(f'❌ Error: {error_count}')
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print('\n🎉 Operation completed!')

if __name__ == '__main__':
    main()
