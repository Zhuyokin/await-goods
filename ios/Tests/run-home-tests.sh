#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
test_dir="$(mktemp -d /tmp/await-goods-home-tests.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
bundle="$test_dir/HomeTests.app"
mkdir -p "$bundle/Contents/MacOS"
cat > "$bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>HomeTests</string>
<key>CFBundleName</key><string>HomeTests</string>
<key>CFBundleIdentifier</key><string>com.awaitgoods.home-tests</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST

cd "$project_root"
xcrun swiftc -target "$(uname -m)-apple-macosx14.0" \
    -module-cache-path "$test_dir/ModuleCache" \
    ios/AwaitGoods/Models/WishItem.swift \
    ios/AwaitGoods/Models/WidgetSavingsMutation.swift \
    ios/AwaitGoods/Models/WishStatistics.swift \
    ios/AwaitGoods/Models/WishPriority.swift \
    ios/AwaitGoods/Models/WishItemStatus.swift \
    ios/AwaitGoods/Models/MarkColor.swift \
    ios/Shared/WishSnapshot.swift \
    ios/Shared/WishBoardState.swift \
    ios/AwaitGoodsWidget/WishJarContent.swift \
    ios/Tests/WishPhotoPersistenceTests.swift \
    ios/Tests/WishStatisticsTests.swift \
    ios/Tests/WidgetBoardTests.swift \
    -o "$bundle/Contents/MacOS/HomeTests"
"$bundle/Contents/MacOS/HomeTests"
