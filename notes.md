# My-Handy-Tools 项目备忘录

## 1. 目的

本文档旨在详细记录 `projects/my-handy-tools` 目录下的跨平台软件自动化部署工具集项目，为本项目的开发、维护和使用提供便利。

**重要提示：** 每次新增或修改功能后，请务必更新此备忘录，确保文档的准确性和时效性。

## 2. 项目概览

### 2.1 基本信息
- **项目类型**: 跨平台软件自动化部署工具集
- **支持平台**: Windows (10/11) + macOS (10.15+)
- **开发语言**: Python 3.8+ + PowerShell + Bash
- **包管理器**: Windows (Winget) + macOS (Homebrew Cask + Mac App Store)

### 2.2 核心特性
- ✅ 跨平台软件清单统一管理（Windows + macOS）
- ✅ README文档自动生成系统
- ✅ macOS智能接管脚本（强制统一软件来源）
- ✅ 分类化软件管理（OS增强、文件管理、日常使用、生产工具）
- ✅ 多种安装类型支持（winget/cask/mas/brew/manual）
- ✅ 自动化部署流程

---

## 3. 整体架构

### 3.1 系统架构

```
Configuration Files
├── Windows: Win_app_manager.ps1 (PowerShell)
└── macOS:   Brewfile (Homebrew Bundle)
        │
        ▼
Python Parser Engine
├── readme_updater.py (数据提取与格式化)
└── AppInfo数据类统一表示
        │
        ▼
Output Systems
├── README.md (自动生成)
├── brew_adoption.sh (智能接管)
└── Win_app_manager_run.bat (Windows启动)
```

### 3.2 数据流设计
1. **配置解析**: PowerShell/Brewfile → AppInfo对象
2. **数据处理**: 分类、排序、格式化
3. **文档生成**: Markdown格式输出
4. **部署执行**: 包管理器命令执行

---

## 4. 文件结构

### 4.1 完整目录结构

```
my-handy-tools/
├── README.md              # 项目主文档（自动生成）
├── notes.md              # 本文档
├── readme_updater.py     # README自动生成器（Python）
├── Brewfile              # macOS软件清单（Homebrew Bundle格式）
├── Win_app_manager.ps1   # Windows软件清单（PowerShell格式）
├── Win_app_manager_run.bat # Windows运行脚本（双击启动）
├── brew_adoption.sh      # macOS智能接管脚本（Bash）
└── LICENSE               # 开源许可证
```

### 4.2 关键文件说明

**配置文件**:
- `Win_app_manager.ps1`: Windows软件清单，PowerShell Hashtable格式
- `Brewfile`: macOS软件清单，Homebrew Bundle格式

**核心脚本**:
- `readme_updater.py`: Python解析引擎，从配置文件提取数据并生成README
- `brew_adoption.sh`: macOS智能接管脚本，强制统一软件来源管理
- `Win_app_manager_run.bat`: Windows启动脚本，双击运行PowerShell管理器

**输出文档**:
- `README.md`: 自动生成的项目文档，包含所有软件的安装说明
- `notes.md`: 项目内部技术文档（本文档）

---

## 5. 技术实现

### 5.1 数据模型设计

#### 5.1.1 AppInfo 数据类
文件: `readme_updater.py`

```python
@dataclass
class AppInfo:
    name: str           # 软件名称
    category: str       # 分类
    install_type: str   # 安装方式 (winget/cask/mas/brew/manual)
    description: str    # 描述信息
    link: str = ""      # 下载链接 (manual类型)
    id: str = ""        # winget ID
    brew_name: str = "" # brew/cask包名
    mas_id: str = ""    # Mac App Store ID
```

#### 5.1.2 分类系统
- **操作系统增强** (OS Enhancements)
- **文件与软件管理** (File & Software Management)
- **日常使用** (Daily Use)
- **生产工具** (Production Tools)

### 5.2 解析器引擎

#### 5.2.1 PowerShell解析器
功能: 解析 `Win_app_manager.ps1` 文件

**支持的数据格式**:
```powershell
@{Type="Title";Name="OS Enhancements"}
@{Type="Winget";Id="Eassos.DiskGenius";Name="DiskGenius (Disk Recovery)"}
@{Type="Manual";Name="Clash Verge Rev";Link="https://...";Desc="Proxy Client"}
```

**注意**:
- 分类标题使用英文名称（如 "OS Enhancements"）
- Winget应用的描述可以放在`Name`字段的括号中，或使用`Desc`字段
- Manual应用需要`Link`字段和可选的`Desc`字段

#### 5.2.2 Brewfile解析器
功能: 解析 `Brewfile` 文件

**支持的数据格式**:
```bash
# OS Enhancements
mas "Cleaner One Pro", id: 1549813210
cask "raycast"
brew "wget"
# manual "Clash Verge Rev", link: https://github.com/...
```

**解析能力**:
- `cask`: Homebrew Cask 图形应用程序
- `mas`: Mac App Store 应用程序
- `brew`: Homebrew 命令行工具
- `manual`: 手动安装应用程序（注释格式）

### 5.3 文档生成系统

#### 5.3.1 格式化引擎
文件: `readme_updater.py` 中的 `format_app_list()` 函数

**生成逻辑**:
1. 按分类分组软件
2. 每个分类生成 Markdown 标题
3. 每个软件生成名称、描述、安装命令
4. 软件间用空行分隔

#### 5.3.2 README更新策略
文件: `readme_updater.py` 中的 `update_readme()` 函数

**更新逻辑**:
1. 读取现有 README.md
2. 查找 `## Windows` 和 `## Mac` 部分
3. 用新生成的内容替换这些部分
4. 保留其他内容

### 5.4 macOS智能接管系统

#### 5.4.1 设计理念
文件: `brew_adoption.sh`

**核心原则**:
1. **优先使用包管理器**: Homebrew Cask > Mac App Store > 手动安装
2. **强制统一来源**: 将手动安装的软件移交给包管理器管理
3. **智能验证**: 检查应用在Cask和App Store中的可用性
4. **安全第一**: 显示接管计划，需用户确认后才执行
5. **干跑模式**: 支持预览接管计划而不实际执行

#### 5.4.2 执行流程
1. 检查依赖: bash版本(4.0+)、Homebrew、mas
2. 解析Brewfile: 提取cask、mas、manual应用
3. 验证应用可用性: 检查Cask仓库和App Store
4. 智能匹配: 如果在Cask中找不到，尝试在App Store中查找
5. 生成接管计划: 显示哪些应用将被接管
6. 用户确认: 显示警告，需要输入'yes'确认
7. 执行接管: 使用--force参数重新安装应用
8. 生成报告: 显示成功/失败统计

#### 5.4.3 关键特性
- **版本检查**: 确保bash 4.0+以支持关联数组
- **依赖管理**: 自动安装缺失的mas命令行工具
- **应用验证**: 检查Cask包和App Store应用的真实存在性
- **智能回退**: 自动在Cask和App Store之间寻找最佳来源
- **安全警告**: 明确告知用户接管可能重置应用配置
- **日志记录**: 详细日志记录到`adoption.log`文件
- **干跑模式**: 设置`DRY_RUN=true`可预览计划而不执行

### 5.5 跨平台一致性设计

#### 5.5.1 分类一致性
```
Windows 和 macOS 使用相同的分类结构：

平台      分类名称
Windows  OS Enhancements
macOS    ⚙️ OS Enhancements

Windows  File & Software Management
macOS    📁 File & Software Management

Windows  Daily Use
macOS    🌴 Daily Use

Windows  Production Tools
macOS    ⚔️ Production Tools

注：macOS 分类使用 emoji 前缀增强可读性，但核心分类名称相同。
```

#### 5.5.2 安装命令标准化
```
平台      类型        命令格式
Windows  winget      winget install [ID]
macOS    cask        brew install --cask [name]
macOS    mas         mas install [id]
macOS    brew        brew install [name]
```

---

## 6. 核心配置

### 6.1 PowerShell配置文件 (`Win_app_manager.ps1`)

**基础结构**:
```powershell
$AppList = @(
    # 分类标题
    @{Type="Title";Name="OS Enhancements"}

    # Winget软件
    @{Type="Winget";Id="Eassos.DiskGenius";Name="DiskGenius (Disk Recovery)"}

    # 手动安装软件
    @{Type="Manual";Name="Clash Verge Rev";Link="https://...";Desc="Proxy Client"}
)
```

### 6.2 Homebrew Bundle配置文件 (`Brewfile`)

**语法规范**:
```bash
# 注释行
# manual "软件名", link: https://example.com  # 描述
cask "包名"  # 描述
mas "应用名", id: 1234567890  # 描述
brew "工具名"  # 描述
```

**分类标记**:
```bash
# ==========================================
# ⚙️ OS Enhancements
# ==========================================
# 这里放置操作系统增强类软件
```

---

## 7. 使用指南

### 7.1 快速开始

#### 7.1.1 新设备部署流程
```
# Windows
1. 安装 Winget (Windows 11已内置)
2. 双击 Win_app_manager_run.bat
3. 按提示选择要安装的软件

# macOS
1. 安装 Homebrew
2. 安装 mas: brew install mas
3. 进入项目目录，运行: brew bundle
4. 运行智能接管: ./brew_adoption.sh
```

#### 7.1.2 日常维护流程
```
# 更新软件列表后
1. 编辑 Win_app_manager.ps1 或 Brewfile
2. 运行: python readme_updater.py
3. 提交更新的 README.md
```

### 7.2 添加新软件

#### 7.2.1 Windows平台
1. 编辑 `Win_app_manager.ps1`
2. 在相应分类下添加软件配置
3. 运行 `python readme_updater.py` 更新文档

#### 7.2.2 macOS平台
1. 编辑 `Brewfile`
2. 在相应分类下添加软件配置
3. 运行 `python readme_updater.py` 更新文档
4. 可选: 运行 `./brew_adoption.sh` 进行智能接管

### 7.3 故障排除

#### 7.3.1 README生成失败
**可能原因**:
1. Python版本不兼容（需要3.8+）
2. 配置文件语法错误

**解决方法**:
```bash
# 检查Python版本
python --version

# 手动运行解析器查看错误
python -c "from readme_updater import parse_ps1; print(parse_ps1('Win_app_manager.ps1'))"
```

#### 7.3.2 macOS智能接管失败
**可能原因**:
1. bash版本太低（需要4.0+以支持关联数组）
2. Homebrew未安装
3. mas命令行工具未安装
4. 网络连接问题导致无法验证应用
5. 应用在Cask或App Store中不存在

**解决方法**:
```bash
# 检查bash版本
bash --version

# 安装缺失的依赖
brew install mas

# 使用新版本bash运行
/opt/homebrew/bin/bash ./brew_adoption.sh

# 使用干跑模式预览计划而不执行
DRY_RUN=true ./brew_adoption.sh

# 查看详细日志
cat adoption.log
```

---

## 8. 附录

### 8.1 相关资源
- **Winget文档**: https://learn.microsoft.com/en-us/windows/package-manager/
- **Homebrew Bundle**: https://github.com/Homebrew/homebrew-bundle
- **Mac App Store CLI**: https://github.com/mas-cli/mas
