# 构建说明 / Build Instructions

## 方式一：使用 GitHub Actions 自动构建（推荐）

### 步骤 1：上传代码到 GitHub
```bash
# 如果你还没有克隆仓库，先克隆
git clone https://gitee.com/wtrw09/TestPaperGeneratorV2.0.git
cd TestPaperGeneratorV2.0

# 添加 GitHub 远程仓库（需要你先在 GitHub 上创建空仓库）
git remote add github https://github.com/YOUR_USERNAME/TestPaperGeneratorV2.0.git

# 推送代码到 GitHub
git push github main
```

### 步骤 2：配置 libxl 库

**libxl 是商业库，需要手动下载配置：**

1. 访问 https://www.libxl.com/ 注册下载
2. 下载 C++ 版本（支持 MinGW）
3. 解压后，将文件按以下结构放置：

```
TestPaperGeneratorV2.0/
├── libxl/
│   ├── include_cpp/
│   │   └── libxl.h
│   ├── lib64/
│   │   └── libxl.lib
│   └── bin/
│       └── libxl.dll
├── .github/
│   └── workflows/
│       └── build.yml
└── ... 其他文件
```

### 步骤 3：触发构建
1. 访问你的 GitHub 仓库
2. 点击 **Actions** 标签
3. 点击 **Build Windows Executable** 工作流
4. 点击 **Run workflow** 按钮

### 步骤 4：下载构建结果
构建完成后，在 **Actions** 页面下载 artifacts：
- `TestPaperGenerator-Windows` - 单独的 .exe 文件
- `TestPaperGenerator-Release-Full` - 完整的可运行目录（含 DLL）

---

## 方式二：本地 Windows 构建

### 环境要求
- **Windows 10/11** 系统
- **Qt 5.15.2** + **MinGW 7.3.0** (需支持 C++20)
- **libxl 3.8+** (C++ 版本)
- **minidocx** (已包含在项目中)

### 详细步骤

#### 1. 安装 Qt
下载 Qt Online Installer: https://www.qt.io/download-qt-installer

选择组件：
- Qt 5.15.2 → MinGW 7.3.0 64-bit
- Qt Quick Controls 2
- Qt Quick 2

#### 2. 安装 MinGW (如需)
如果 Qt 自带的 MinGW 不支持 C++20：
1. 下载 MinGW 13.1.0: https://github.com/niXman/mingw-builds-binaries/releases
2. 解压到 `C:\Qt\Tools\`
3. 在 Qt Creator 中配置编译器

#### 3. 配置 libxl
1. 下载 libxl: https://www.libxl.com/
2. 编辑 `TestPaperDemo1.pro`，修改 libxl 路径：
```qmake
INCLUDEPATH += C:/path/to/libxl/include_cpp
LIBS += C:/path/to/libxl/lib64/libxl.lib
```
3. 将 `libxl.dll` 复制到编译输出目录

#### 4. 编译项目
```bash
# 在项目目录打开命令行
cd TestPaperGeneratorV2.0

# 运行 qmake
C:\Qt\5.15.2\mingw73_64\bin\qmake.exe TestPaperDemo1.pro -spec win32-g++

# 编译
mingw32-make -j4

# 清理
mingw32-make clean
```

#### 5. 运行程序
将以下文件复制到 `release/` 目录：
- `release/TestPaperDemo1.exe`
- `libxl/bin/libxl.dll`
- Qt 运行时 DLL（从 Qt 安装目录复制）
- `platforms/qwindows.dll`（Qt 平台插件）

---

## 常见问题

### Q: 编译报错 "cannot find -lxl"
A: libxl 路径配置错误，或使用了 32 位/64 位不匹配的库。确认 `libxl/lib64/` 下的 `.lib` 文件存在。

### Q: 编译报错 "undefined reference to xlCreateBook"
A: 同上，确保使用 64 位 libxl 库（lib64 目录）。

### Q: 程序运行时闪退
A: 缺少 DLL 文件。使用 Dependency Walker 或 Everything 搜索缺失的 DLL 并复制到程序目录。

### Q: C++20 特性不支持
A: 需要 MinGW 13.1.0，将 `\bin` 目录添加到系统 PATH，并在 Qt Creator 中配置。
