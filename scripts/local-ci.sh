#!/bin/bash
set -e  # 任何命令失败就退出
cd ..

echo "🔧 开始本地CI检查..."

# 1. 编译检查
echo "📦 编译检查..."
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j4
cd ..

# 2. 运行测试
echo "🧪 运行单元测试..."
./bin/tests.bin --gtest_output=xml:test_results.xml

# 3. 检查内存泄漏（Valgrind）
echo "🛡️  内存泄漏检查..."
if command -v valgrind &> /dev/null; then
    valgrind --leak-check=full --error-exitcode=1 ./bin/tests.bin
else
    echo "⚠️  Valgrind未安装，跳过内存检查"
    echo "    Ubuntu安装: sudo apt-get install valgrind"
    echo "    macOS安装: brew install valgrind"
fi

# 4. 代码风格检查
echo "🎨 代码风格检查..."
if command -v clang-format &> /dev/null; then
    find include tests -name "*.hpp" -o -name "*.cpp" | xargs clang-format --dry-run -n --Werror
else
    echo "⚠️  clang-format未安装，跳过代码检查"
    echo "    Ubuntu安装: sudo apt-get install clang-format"
    echo "    macOS安装: brew install clang-format"
fi

# 5. 静态分析
echo "🔍 静态分析..."
if command -v clang-tidy &> /dev/null; then
    find include tests \( -name "*.cpp" -o -name "*.hpp" \) | xargs -I {} clang-tidy \
        --config-file=.clang-tidy \
        {} \
        -- -Iinclude -std=c++20
else
    echo "⚠️  clang-tidy未安装，跳过静态分析"
fi

echo "✅ 本地CI检查完成！"