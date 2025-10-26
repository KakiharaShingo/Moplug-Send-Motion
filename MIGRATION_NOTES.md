# FxPlugからmacOSアプリケーションへの移行

## 問題点
元の実装はFxPlug (`.fxplug`) 形式で`FxShareAPI`を使用していましたが、**FxShareAPIはFxPlug SDKに存在しません**。Final Cut ProのShare Destinationは、FxPlugプラグインではなく、独立したmacOSアプリケーション (`.app`) として実装する必要があります。

## 解決策
Xsend Motionやその他のFCP Share Destinationで使用されているアーキテクチャに従い、プロジェクトを`.fxplug`プラグインから`.app`アプリケーションに変換しました。

## 主な変更点

### 1. アプリケーション構造
- プラグインバンドル (`.fxplug`) からアプリケーションバンドル (`.app`) に変更
- `CFBundlePackageType`を`BNDL`から`APPL`に変更
- `NSPrincipalClass`を`MoplugSendMotionPlugin`から`MoplugApplication`に変更
- Apple Eventsサポートのため`NSAppleScriptEnabled`と`OSAScriptingDefinition`を追加

### 2. Apple Eventsサポート
ProVideo Asset Management suiteを実装した`OSAScriptingDefinition.sdef`ファイルを作成:
- Final Cut ProからFCPXMLファイルを受け取るための`open`コマンドを定義
- メディアアセット管理のための`asset`クラスを定義
- Final Cut Pro統合のためのスクリプティングインターフェースを提供

### 3. アプリケーションクラス
プラグインからアプリケーションへコードを再構築:
- **MoplugApplication**: NSApplicationのサブクラス
- **MoplugAppDelegate**: アプリケーションのライフサイクルとファイル開封を処理
- **MoplugAsset**: メディアアセットを表現
- **MoplugMakeCommand**: アセット作成コマンドを処理
- **main.swift**: アプリケーションのエントリーポイント

### 4. Share Destinationファイル (.fcpxdest)
NSKeyedArchiver形式で`.fcpxdest`ファイルを生成するPythonスクリプトを作成:
- Final Cut Proの「ファイル」>「共有」メニューに「Moplug Send Motion」を登録
- `/Applications/Moplug Send Motion.app`を指定
- 互換性のためXsend Motionと同じ構造を使用

### 5. ファイル処理
FxPlugの`shareWithTimeline()`メソッドからApple Eventsに変更:
- Final Cut ProがFCPXMLをエクスポートし、"open" Apple Eventを送信
- アプリは`application(_:openFile:)`デリゲートメソッドでファイルを受信
- FCPXMLを処理し、Motionプロジェクトを生成して、Motionで開く

## Xcodeプロジェクトの変更が必要

`.app`としてビルドするには、Xcodeで以下の設定を更新してください:

1. **Product Type**: macOS Application
2. **Wrapper Extension**: `app` (`fxplug`の代わりに)
3. **Info.plist**: 更新された`Moplug-Send-Motion.fxplug/Contents/Info.plist`を使用
4. **Build Settings**:
   - FxPlug SDKへの参照を削除
   - Cocoaフレームワークを追加
   - デプロイメントターゲットをmacOS 12.0+に設定

### Xcodeでの手動手順:
1. `Moplug-Send-Motion.xcodeproj`を開く
2. ターゲットを選択
3. 「Build Settings」に移動
4. 「Wrapper Extension」を検索
5. 値を`fxplug`から`app`に変更
6. 「General」タブで以下を確認:
   - Product Name: `Moplug Send Motion`
   - Bundle Identifier: `com.moplug.sendmotion`
   - Deployment Target: macOS 12.0以降
7. 「Build Phases」で、`main.swift`をメインエントリーポイントとして追加
8. 「Copy Bundle Resources」に`OSAScriptingDefinition.sdef`を追加

## ビルドとインストール

```bash
# スクリプトに実行権限を付与
chmod +x build_and_install.sh create_share_destination.py

# ビルドとインストール
./build_and_install.sh
```

このスクリプトは以下を実行します:
1. アプリケーションを`.app`としてビルド
2. `.fcpxdest`ファイルを作成
3. `/Applications/`にインストール
4. `.fcpxdest`をFinal Cut ProのShare Destinationsにコピー

## テスト方法

1. Final Cut Proを再起動
2. プロジェクトを開く
3. 「ファイル」>「共有」を選択
4. 送信先リストで「Moplug Send Motion」を探す
5. クリップ/タイムラインを選択してエクスポート
6. アプリが開き、FCPXMLを処理してMotionプロジェクトを作成するはず

## Xsend Motionとの比較

| 機能 | Xsend Motion | Moplug Send Motion |
|------|--------------|-------------------|
| 形式 | .app | .app ✓ |
| 統合方法 | Apple Events | Apple Events ✓ |
| .fcpxdest | あり | あり ✓ |
| .sdefファイル | あり | あり ✓ |
| Motionで開く | あり | あり ✓ |
| ProVideo Asset Management | あり | あり ✓ |

## 参考資料
- AppleのProVideo Asset Management suite
- Xsend Motionの実装
- Final Cut Proワークフロー拡張機能
