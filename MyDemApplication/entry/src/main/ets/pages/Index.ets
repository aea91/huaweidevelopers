import { AppTheme } from '@mydemo/core';
import { PrimaryButton } from '@mydemo/uikit';

@Entry
@Component
struct Index {
  build() {
    Column({ space: 12 }) {
      Text('MyDemApplication')
        .fontSize(22)
        .fontColor(AppTheme.colors.textPrimary)

      PrimaryButton({ title: 'Hello from UIKit', onClick: () => {} })
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.colors.background)
  }
}

