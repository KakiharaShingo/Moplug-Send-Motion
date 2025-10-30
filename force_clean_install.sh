#!/bin/bash
# 完全クリーンインストール

set -e

echo "🧹 完全クリーンインストール開始..."
echo ""

# 0. ビルド
echo "Step 0: ビルド..."
./quick_build.sh
echo ""

# 1. 実行中のプロセスを終了
echo "Step 1: 実行中のMoplug-Send-Motionプロセスを終了..."
killall "Moplug-Send-Motion" 2>/dev/null && echo "  ✅ プロセスを停止しました" || echo "  (既に終了しています)"
killall "Final Cut Pro" 2>/dev/null && echo "  ✅ Final Cut Proを停止しました" || echo "  (既に終了しています)"
sleep 1

# 2. 古いアプリを削除
echo "Step 2: 古いアプリを削除..."
sudo rm -rf "/Applications/Moplug Send Motion.app"
sudo rm -rf "/Applications/Moplug-Send-Motion.app"
echo "  ✅ 削除完了"

# 3. 古いShare Destinationを削除
echo "Step 3: 古いShare Destinationを削除..."
sudo rm -f "/Library/Application Support/ProApps/Share Destinations/Moplug-Send-Motion.fcpxdest"
echo "  ✅ 削除完了"

# 4. FCPキャッシュをクリア
echo "Step 4: Final Cut Proのキャッシュをクリア..."
defaults delete com.apple.FinalCut shareDestinations 2>/dev/null || echo "  (キャッシュなし)"
defaults delete com.apple.FinalCut 2>/dev/null || echo "  (設定なし)"

# 5. LaunchServicesをリセット
echo "Step 5: LaunchServicesデータベースをリセット..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
sleep 2

# 6. 出力ディレクトリを作成
echo "Step 6: 出力ディレクトリを作成..."
mkdir -p "/Users/shingo/Movies/Moplug Send Motion"
chown shingo:staff "/Users/shingo/Movies/Moplug Send Motion"
chmod 755 "/Users/shingo/Movies/Moplug Send Motion"
echo "  ✅ 作成完了"

# 7. 新しいアプリをインストール
echo "Step 7: 新しいアプリをインストール..."
sudo cp -R "./build/Release/Moplug Send Motion.app" "/Applications/Moplug Send Motion.app"
sudo chmod -R 755 "/Applications/Moplug Send Motion.app"
echo "  ✅ インストール完了"



# 9. アプリの署名を確認
echo "Step 9: アプリ署名を確認..."
codesign -vv /Applications/Moplug-Send-Motion.app 2>&1 || echo "  ⚠️ 署名の問題があります（動作には影響しない場合があります）"

echo ""
echo "✅ クリーンインストール完了！"
echo ""
echo "📋 インストール内容:"
echo "   App: /Applications/Moplug Send Motion.app"
echo "   Output: /Users/shingo/Movies/Moplug Send Motion/"
echo ""
echo "🎬 使い方:"
echo "   【単体起動】"
echo "     open /Applications/Moplug-Send-Motion.app"
echo "     → ウェルカム画面で「Select File」をクリック"
echo ""
echo "   【Final Cut Proから】"
echo "     1. Final Cut Proを起動"
echo "     2. File > Share > Moplug Send Motion を選択"
echo "     3. 次へを押す"
echo "     4. FCPXMLと.motnファイルが ~/Movies/Moplug Send Motion/ に作成されます"
