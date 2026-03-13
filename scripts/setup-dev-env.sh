#!/bin/bash
#
# Happy Coder 开发环境配置脚本
#

set -e

echo "🚀 Happy Coder Development Environment Setup"
echo "=============================================="

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查系统
SYSTEM=$(uname -s)
ARCH=$(uname -m)
echo -e "${BLUE}System:${NC} $SYSTEM $ARCH"

# ========== Flutter ==========

if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✓ Flutter${NC} $(flutter --version 2>/dev/null | head -1)"
else
    echo -e "${YELLOW}⚠ Flutter not found in PATH${NC}"
    if [ -d "/opt/homebrew/Caskroom/flutter" ]; then
        echo -e "${BLUE}→ Flutter installed via Homebrew, adding to PATH...${NC}"
        export PATH="/opt/homebrew/bin:$PATH"
        if command -v flutter &> /dev/null; then
            echo -e "${GREEN}✓ Flutter available: $(which flutter)${NC}"
        fi
    fi
fi

# ========== Node.js ==========

if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js${NC} $(node --version)"
else
    echo -e "${YELLOW}⚠ Node.js not found${NC}"
fi

# ========== Homebrew ==========

if command -v brew &> /dev/null; then
    echo -e "${GREEN}✓ Homebrew${NC} $(brew --version)"
else
    echo -e "${YELLOW}⚠ Homebrew not found${NC}"
fi

# ========== DevEco Studio ==========

if [ -d "/Applications/DevEco Studio.app" ]; then
    echo -e "${GREEN}✓ DevEco Studio${NC} Installed"
else
    echo -e "${YELLOW}⚠ DevEco Studio not found${NC}"
    echo -e "${BLUE}→ Download from: https://developer.huawei.com/consumer/cn/download/deveco-studio${NC}"
fi

# ========== 项目路径 ==========

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${BLUE}→ Project Root:${NC} $PROJECT_ROOT"

# ========== 环境变量配置 ==========

echo ""
echo -e "${BLUE}Setting up environment variables...${NC}"

# Flutter
export FLUTTER_ROOT="/opt/homebrew/Caskroom/flutter/3.41.2/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
export PATH="$FLUTTER_ROOT/.pub-cache/bin:$PATH"

# HarmonyOS SDK (如果存在）
if [ -d "$HOME/Library/Huawei/ohpm" ]; then
    export PATH="$HOME/Library/Huawei/ohpm/bin:$PATH"
fi

# Node.js
export NODE_PATH="$(which node)"

# ========== Flutter Doctor ==========

echo ""
echo -e "${BLUE}Running Flutter Doctor...${NC}"
echo "=========================================="

# 使用 timeout 限制运行时间
if command -v timeout &> /dev/null; then
    timeout 60 flutter doctor || echo -e "${YELLOW}Flutter doctor timed out (this is normal on first run)${NC}"
else
    flutter doctor || echo -e "${YELLOW}Flutter doctor completed with warnings${NC}"
fi

# ========== 项目依赖 ==========

echo ""
echo -e "${BLUE}Checking project dependencies...${NC}"

cd "$PROJECT_ROOT"

if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✓ Found pubspec.yaml${NC}"

    # 检查 harmony_flutter 依赖
    if grep -q "harmony_flutter" pubspec.yaml 2>/dev/null; then
        echo -e "${GREEN}✓ harmony_flutter dependency found${NC}"
    else
        echo -e "${YELLOW}⚠ harmony_flutter dependency not found${NC}"
        echo -e "${BLUE}→ Add to pubspec.yaml:${NC}"
        echo "  harmony_flutter:"
        echo "    path: harmony/"
    fi
fi

# ========== 快捷命令 ==========

echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "--------------------------------"
echo -e "${GREEN}flutter doctor${NC}      - Check Flutter environment"
echo -e "${GREEN}flutter pub get${NC}       - Install dependencies"
echo -e "${GREEN}flutter run${NC}         - Run on macOS/iOS"
echo -e "${GREEN}flutter build harmony${NC}  - Build for HarmonyOS"

# ========== Shell 配置 ==========

SHELL_CONFIG="$HOME/.zshrc"
if [ -f "$SHELL_CONFIG" ]; then
    # 检查是否已添加 Flutter 到 PATH
    if ! grep -q "opt/homebrew/bin" "$SHELL_CONFIG"; then
        echo ""
        echo -e "${YELLOW}Add this to your $SHELL_CONFIG:${NC}"
        echo 'export PATH="/opt/homebrew/bin:$PATH"'
        echo -e "${BLUE}→ Run: source ~/.zshrc${NC}"
    else
        echo -e "${GREEN}✓ Flutter already in PATH${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ Environment setup complete!${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. 安装 DevEco Studio (如果未安装)"
echo "2. 打开 DevEco Studio 并配置 HarmonyOS SDK"
echo "3. 在 DevEco Studio 中打开项目"
echo "4. 运行: cd $PROJECT_ROOT && flutter pub get"
echo ""
