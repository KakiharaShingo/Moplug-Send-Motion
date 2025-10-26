# Moplug Send Motion

Moplug Send MotionはFinal Cut Pro XのタイムラインをApple Motion 5のプロジェクトに変換するShare Extensionです。Xsend Motionと同等の機能を提供します。

## 機能

### 主要機能
- Final Cut Pro Xの共有メニューから直接タイムラインを送信
- FCPXML形式の解析と変換
- Motionプロジェクトファイルの生成
- 元のメディアファイルを参照（新規メディアは作成しない）

### 変換対応要素
- **トランスフォーム**: Position（位置）、Scale（スケール）、Rotation（回転）
- **不透明度**: Opacity
- **ブレンドモード**: 各種ブレンドモード（Normal、Multiply、Screen等）
- **タイトル**: テキストレイヤーとして変換
- **クリップタイミング**: オフセット、デュレーション

## プロジェクト構造

```
Moplug-Send-Motion/
├── MoplugSendMotion-App/
│   ├── MoplugSendMotion-App/              # ホストアプリケーション
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   ├── MoplugSendMotion-App.entitlements
│   │   └── Base.lproj/
│   │       └── Main.storyboard
│   └── SendToMotion-ShareExtension/       # Share Extension
│       ├── ShareViewController.swift      # メインの実装
│       ├── FCPXMLParser.swift            # FCPXML解析
│       ├── MotionProjectGenerator.swift  # Motionプロジェクト生成
│       ├── TransformConverter.swift      # 変換ユーティリティ
│       ├── Info.plist
│       └── SendToMotion-ShareExtension.entitlements
└── MIGRATION_GUIDE.md                     # 移行ガイド
```

## ビルド方法

### 前提条件
- Xcode 15.0以降
- macOS 12.0以降
- Apple Developer アカウント（コード署名用）

### Xcodeでのビルド

1. **新しいXcodeプロジェクトを作成**:
   - Xcodeを起動
   - "Create a new Xcode project" を選択
   - macOS → App を選択
   - Product Name: `MoplugSendMotion-App`
   - Bundle Identifier: `com.moplug.sendmotion`
   - 保存先: このディレクトリ

2. **Share Extensionターゲットを追加**:
   - プロジェクトナビゲーターでプロジェクトを選択
   - 下部の "+" ボタンをクリック
   - "Share Extension" を選択
   - Product Name: `SendToMotion-ShareExtension`

3. **既存ファイルを追加**:
   - `MoplugSendMotion-App/` ディレクトリ内の全ファイルをプロジェクトに追加

4. **ビルド設定**:
   - Deployment Target: macOS 12.0以上
   - Code Signing: Automatic
   - Entitlementsファイルを各ターゲットに設定

5. **ビルド実行**:
   - ⌘+B でビルド

詳細な手順は `MIGRATION_GUIDE.md` を参照してください。

## インストール

1. アプリケーションをビルド
2. ビルドされた `MoplugSendMotion-App.app` を `/Applications` にコピー
3. Final Cut Pro Xを再起動

```bash
# アプリをApplicationsフォルダにコピー
cp -r /path/to/build/MoplugSendMotion-App.app /Applications/
```

## 使用方法

### タイムラインの送信
1. Final Cut Pro Xでプロジェクトを開く
2. File → Share → "Send to Motion" を選択
3. 保存場所を指定してMotionプロジェクトファイルを保存
4. 自動的にMotionが起動

### 動作確認

Share Extensionが正しく認識されているか確認:
```bash
pluginkit -m | grep com.moplug.sendmotion
```

ログの確認:
```bash
log show --predicate 'subsystem == "com.moplug.sendmotion"' --last 1h
```

## 技術仕様

### アーキテクチャ
- **実装方式**: macOS Share Extension（NSExtension）
- **Extension Point**: `com.apple.share-services`
- **対応UTI**: `public.xml`, `com.apple.finalcutpro.xml`

### システム要件
- **対応バージョン**: Final Cut Pro X 10.2以降、Motion 5
- **対応プラットフォーム**: macOS 12.0以降（Apple Silicon & Intel）
- **開発言語**: Swift 5.0
- **フレームワーク**: Foundation、Cocoa、Social

### セキュリティ
- App Sandbox有効
- ファイルアクセス権限:
  - `com.apple.security.files.user-selected.read-write`
  - `com.apple.security.files.downloads.read-write`

## データモデル

### Timeline（タイムライン）
- name: プロジェクト名
- duration: 継続時間
- tracks: トラック配列

### Clip（クリップ）
- type: クリップタイプ（clip, title, gap）
- name: クリップ名
- offset: オフセット時間
- duration: 継続時間
- transform: トランスフォーム情報
- opacity: 不透明度
- blendMode: ブレンドモード

### MotionProject（Motionプロジェクト）
- name: プロジェクト名
- duration: 継続時間
- frameRate: フレームレート
- groups: グループ配列（Final Cut Proのトラックに対応）

## 制限事項

- すべてのエフェクトが変換されるわけではありません
- 複雑なトランジション効果は変換されない可能性があります
- 一部のサードパーティエフェクトは完全には変換されない場合があります

## トラブルシューティング

### Share Extensionが表示されない
1. アプリが `/Applications` にインストールされているか確認
2. Final Cut Proを再起動
3. システム設定 → プライバシーとセキュリティで権限を確認
4. `pluginkit -m` でExtensionが認識されているか確認

### XMLデータが取得できない
1. NSExtensionActivationRuleの設定を確認
2. PHSupportedMediaTypesに適切なUTIが含まれているか確認
3. ログでエラーメッセージを確認

## 開発者向け情報

### 主要クラス

- `ShareViewController`: メインのShare Extension実装、extensionContextの処理
- `FCPXMLParser`: FCPXML形式の解析を担当
- `MotionProjectGenerator`: Motionプロジェクトファイルの生成
- `TransformConverter`: トランスフォーム関連の変換処理

### データフロー

```
FCPXML → ShareViewController → FCPXMLParser → Timeline
→ MotionProjectGenerator → MotionProject → ファイル保存 → Motion起動
```

### FxPlugからの移行

以前のFxPlugベースの実装からShare Extensionベースに移行しました。
詳細は `MIGRATION_GUIDE.md` を参照してください。

主な変更点:
- `.fxplug` バンドル → `.app` バンドル内のShare Extension
- FxPlugAPI → NSExtension API
- 自動検出 → 「共有」メニューに明示的に表示

## ライセンス

Copyright © 2024 Moplug. All rights reserved.

## サポート

このプロジェクトはXsend Motionの機能仕様を基に実装されたオープンソースの代替品です。
