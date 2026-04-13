# 填貓相機 (FillMeow Camera) - 技術規格文件

## 1. 專案概述

**專案名稱**：填貓相機 (FillMeow Camera)  
**副標**：用世界填出一隻貓  
**平台**：iOS + Android (Flutter)  
**最小 SDK**：iOS 12.0 / Android API 21

### 核心概念
選擇一個鏤空貓咪剪影（Stencil Mask），對準現實世界拍照後，剪影內部區域會被相機捕捉的真實畫面填滿，組成「這隻貓的身體」。

---

## 2. UI/UX 規格

### 2.1 螢幕結構

```
App
├── SplashScreen (啟動頁)
├── MainCameraScreen (主相機頁)
│   ├── CameraPreview (即時相機畫面)
│   ├── StencilOverlay (剪影疊加層)
│   ├── TopToolbar (工具列：鏡頭切換、閃光、網格)
│   └── BottomBar (選貓按鈕、拍攝按鈕)
├── StencilPickerSheet (剪影選擇器)
│   ├── CategoryTabs (分類標籤)
│   ├── StencilGrid (剪影網格)
│   └── SearchBar (搜尋)
├── EditorScreen (編輯預覽頁)
│   ├── CompositePreview (合成預覽)
│   ├── ParameterSlider (參數調整)
│   └── ActionButtons (儲存、分享)
└── SettingsScreen (設定頁)
```

### 2.2 導航結構
- 使用 `go_router` 管理導航
- 主路徑：`/` (相機) → `/editor` (編輯) → `/settings` (設定)
- 剪影選擇器：底部彈出 Sheet

### 2.3 視覺設計

**顏色**
| 名稱 | 色碼 | 用途 |
|------|------|------|
| Primary | #FF9B7B | 主按鈕、主題色 |
| Secondary | #FFB87B | 次要強調 |
| Accent | #FFD4A3 | 高亮、選中狀態 |
| Background | #FFF8F5 | 背景 |
| Surface | #FFFFFF | 卡片、表面 |
| TextPrimary | #0F1419 | 主要文字 |
| TextSecondary | #536471 | 次要文字 |
| Outline | #2F3336 | 輪廓線 |

**字體**
- 主字體：系統預設（iOS: SF Pro, Android: Roboto）
- 標題：Bold 18-24sp
- 正文：Regular 14-16sp
- 按鈕：Medium 16sp

**間距系統**
- 基礎單位：4dp
- 小間距：8dp
- 中間距：16dp
- 大間距：24dp
- 安全區：遵守 iOS SafeArea / Android WindowInsets

### 2.4 動畫
- 按鈕點擊：scale 0.95, 100ms
- 剪影選中：bounce 動畫, 300ms
- 頁面轉場：slide + fade, 250ms
- 參數調整：即時響應，無延遲

---

## 3. 功能規格

### 3.1 核心功能 (MVP)

**F1. 即時相機預覽**
- 預設後置鏡頭
- 支援前置/後置切換
- 支援閃光燈開/關/自動
- 支援網格輔助線（3x3）
- 橫向模式支援

**F2. 剪影疊加**
- PNG 格式：透明背景、純輪廓線
- 支援拖曳移動
- 支援雙指縮放
- 支援雙指旋轉
- 支援左右翻轉

**F3. 參數調整**
- 輪廓線顏色：黑、白、彩色
- 輪廓線粗細：1-10px
- 輪廓樣式：實線、虛線
- 內部填滿：亮度、對比、飽和度

**F4. 拍攝**
- 單張拍攝
- 計時器：3秒、5秒、10秒
- 快門動畫與音效

**F5. 合成與編輯**
- 純填滿模式：外部白色背景
- 環境融入模式：保留完整背景
- 多層剪影：最多3層
- 基本濾鏡：黑白、暖調、復古
- 文字添加

**F6. 儲存與分享**
- 保存到相簿（JPG 100%品質）
- 一鍵分享：Instagram、Line、小紅書、Threads
- App 水印（可關閉）

### 3.2 剪影庫

**分類**
1. 基本姿勢：坐姿、站立、側躺、趴姿、伸懶腰、拱背、捲球
2. 動態動作：跳躍、追逐、探頭、舔毛、翻滾
3. 可愛搞笑：偷吃、眨眼、母子組合、胖球
4. 主題包：英短、暹羅、緬因、聖誕、萬聖節

**剪影規格**
- 解析度：1024x1024 px
- 格式：PNG (透明背景)
- 輪廓線：單色 (#000000 或 #FFFFFF)
- 最小線寬：2px (確保清晰)

### 3.3 資料管理
- 本地儲存：SharedPreferences (設定)
- 檔案儲存：path_provider + 系統相簿
- 剪影快取：乙太坊本地快取目錄

---

## 4. 技術架構

### 4.1 依賴套件

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 狀態管理
  flutter_riverpod: ^2.4.9
  
  # 導航
  go_router: ^13.1.0
  
  # 相機
  camera: ^0.10.5+9
  
  # 檔案與儲存
  path_provider: ^2.1.2
  path: ^1.8.3
  share_plus: ^7.2.1
  image_gallery_saver: ^2.0.3
  
  # 圖片處理
  image: ^4.1.4
  
  # UI 元件
  flutter_colorpicker: ^1.0.3
  
  # 工具
  permission_handler: ^11.1.0
  uuid: ^4.2.2
  
  # 本地化
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### 4.2 專案結構

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_dimensions.dart
│   ├── router/
│   │   └── app_router.dart
│   └── utils/
│       ├── image_utils.dart
│       └── permission_utils.dart
├── data/
│   ├── models/
│   │   ├── stencil_model.dart
│   │   └── editor_state.dart
│   ├── repositories/
│   │   └── stencil_repository.dart
│   └── datasources/
│       └── stencil_local_datasource.dart
├── domain/
│   └── entities/
│       └── stencil.dart
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── camera/
│   │   │   ├── camera_screen.dart
│   │   │   └── widgets/
│   │   │       ├── camera_preview_widget.dart
│   │   │       ├── stencil_overlay_widget.dart
│   │   │       ├── camera_toolbar.dart
│   │   │       └── capture_button.dart
│   │   ├── editor/
│   │   │   ├── editor_screen.dart
│   │   │   └── widgets/
│   │   │       ├── composite_preview.dart
│   │   │       └── parameter_controls.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   └── widgets/
│       ├── stencil_picker_sheet.dart
│       ├── stencil_grid_item.dart
│       └── category_tab_bar.dart
└── providers/
    ├── camera_provider.dart
    ├── stencil_provider.dart
    └── editor_provider.dart
```

### 4.3 關鍵演算法

**剪影合成**
```dart
// 使用 BlendMode 和 CustomPainter 實現
// 1. 拍攝相機畫面為 rawImage
// 2. 建立 mask：stencil PNG 轉為灰度
// 3. 使用 blendMask 合成：
//    - 輪廓區域：繪製輪廓線
//    - 內部區域：保留 rawImage
//    - 外部區域：根據模式處理（白/透明/模糊）
```

**手勢處理**
```dart
// 使用 Transform widget + GestureDetector
// 記錄：offset, scale, rotation
// 套用：Transform.translate + Transform.rotate + Transform.scale
```

---

## 5. 頁面規格

### 5.1 相機頁 (MainCameraScreen)

**佈局**
```
┌─────────────────────────────┐
│  [鏡頭] [閃光] [網格] [設定] │  ← TopToolbar (56dp)
├─────────────────────────────┤
│                             │
│                             │
│      Camera Preview         │  ← 全屏相機畫面
│                             │
│      [Stencil Overlay]     │  ← 剪影疊加層
│                             │
│                             │
├─────────────────────────────┤
│ [縮圖]    ◉    [選貓按鈕]  │  ← BottomBar (100dp)
└─────────────────────────────┘
```

**按鈕尺寸**
- 拍攝按鈕：72dp 直徑
- 工具按鈕：44dp x 44dp
- 縮圖預覽：48dp x 48dp, 圓角 8dp

### 5.2 剪影選擇器 (StencilPickerSheet)

**佈局**
```
┌─────────────────────────────┐
│ [關閉]  選擇剪影  [確定]    │
├─────────────────────────────┤
│ [全部] [坐姿] [動態] [搞笑] │  ← CategoryTabs
├─────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐  │
│ │ 剪影 │ │ 剪影 │ │ 剪影 │  │
│ │  1   │ │  2   │ │  3   │  │
│ └─────┘ └─────┘ └─────┘  │  ← StencilGrid
│ ┌─────┐ ┌─────┐ ┌─────┐  │
│ │ 剪影 │ │ 剪影 │ │ 剪影 │  │
│ │  4   │ │  5   │ │  6   │  │
│ └─────┘ └─────┘ └─────┘  │
└─────────────────────────────┘
```

### 5.3 編輯頁 (EditorScreen)

**佈局**
```
┌─────────────────────────────┐
│ [返回]    編輯預覽    [儲存]│
├─────────────────────────────┤
│                             │
│      Composite Preview      │  ← 合成預覽圖
│                             │
├─────────────────────────────┤
│  輪廓線  填滿  濾鏡  文字  │  ← 功能Tab
├─────────────────────────────┤
│  [────────●────────]       │  ← 參數滑桿
│  輪廓粗細: 3px              │
└─────────────────────────────┘
```

---

## 6. 預期成效

- APK 大小：< 50MB
- 啟動速度：< 2秒
- 相機延遲：< 100ms
- 合成速度：< 500ms
- 支援解析度：最高 4K

---

## 7. 未來擴展 (V2)

- 多層剪影（最多3層）
- 社群挑戰功能
- 用戶自訂剪影上傳
- GIF 生成
- 動畫剪影
- 進階濾鏡與特效

