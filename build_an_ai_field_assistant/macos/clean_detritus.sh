#!/bin/bash

# Target app path from Xcode build environment or fallback for CLI
TARGET_APP="${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app"

if [ -z "$TARGET_BUILD_DIR" ] || [ -z "$PRODUCT_NAME" ]; then
  TARGET_APP="${1:-$(pwd)/build/macos/Build/Products/Debug/build_an_ai_field_assistant.app}"
fi

if [ -d "$TARGET_APP" ]; then
  xattr -d com.apple.FinderInfo "$TARGET_APP" 2>/dev/null || true
  xattr -d 'com.apple.fileprovider.fpfs#P' "$TARGET_APP" 2>/dev/null || true
  xattr -d com.apple.ResourceFork "$TARGET_APP" 2>/dev/null || true
  find "$TARGET_APP" -name "._*" -delete 2>/dev/null || true
  find "$TARGET_APP" -name ".DS_Store" -delete 2>/dev/null || true
fi

exit 0
