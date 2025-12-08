'''
File: readme_updater.py
Project: my-handy-tools
Created: 2025-12-08 10:10:49
Author: Victor Cheng
Email: hi@victor42.work
Description: 自动从 .ps1 和 Brewfile 生成 README.md 内容
'''

import os
import sys

# 自动切换到脚本所在目录
script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir:
    os.chdir(script_dir)

from dataclasses import dataclass
from typing import List, Optional
import re


@dataclass
class AppInfo:
    """应用信息数据类"""
    name: str           # 软件名称 (显示用)
    category: str       # 分类
    install_type: str   # 安装方式 (winget/cask/mas/brew/manual)
    description: str    # 描述信息
    link: str = ""      # 下载链接 (manual 类型需要)
    id: str = ""        # winget ID (winget 类型需要)
    brew_name: str = "" # brew/cask 包名 (macOS 类型需要)
    mas_id: str = ""    # Mac App Store ID (mas 类型需要)


def parse_ps1(filepath: str) -> List[AppInfo]:
    """解析 PowerShell 脚本，提取 Windows 软件列表"""
    apps = []
    current_category = ""

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        in_app_list = False

        for line in lines:
            line = line.strip()

            # 找到 AppList 开始
            if '$AppList = @(' in line:
                in_app_list = True
                continue

            if not in_app_list:
                continue

            # 找到 AppList 结束 - 单独的 ')' 行
            if line == ')':
                break

            # 跳过空行和注释
            if not line or line.startswith('#'):
                continue

            # 解析分类标题
            if 'Type="Title"' in line:
                match = re.search(r'Name="([^"]+)"', line)
                if match:
                    current_category = match.group(1)
                continue

            # 解析 Winget 应用
            if 'Type="Winget"' in line:
                id_match = re.search(r'Id="([^"]+)"', line)
                name_match = re.search(r'Name="([^"]+)"', line)
                desc_match = re.search(r'Desc="([^"]+)"', line)

                if id_match and name_match:
                    app_id = id_match.group(1)
                    app_name = name_match.group(1)
                    description = desc_match.group(1) if desc_match else app_name

                    apps.append(AppInfo(
                        name=app_name,
                        category=current_category,
                        install_type="winget",
                        description=description,
                        id=app_id
                    ))
                continue

            # 解析 Manual 应用
            if 'Type="Manual"' in line:
                link_match = re.search(r'Link="([^"]+)"', line)
                name_match = re.search(r'Name="([^"]+)"', line)
                desc_match = re.search(r'Desc="([^"]+)"', line)

                if name_match:
                    app_name = name_match.group(1)
                    link = link_match.group(1) if link_match else ""
                    description = desc_match.group(1) if desc_match else app_name

                    apps.append(AppInfo(
                        name=app_name,
                        category=current_category,
                        install_type="manual",
                        description=description,
                        link=link
                    ))

    except FileNotFoundError:
        print(f"错误：找不到文件 {filepath}")
    except Exception as e:
        print(f"解析 PowerShell 文件时出错：{e}")

    return apps


def parse_brewfile(filepath: str) -> List[AppInfo]:
    """解析 Brewfile，提取 macOS 软件列表"""
    apps = []
    current_category = ""

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        for i, line in enumerate(lines):
            line = line.strip()

            # 跳过空行
            if not line:
                continue

            # 解析分类标题 - 格式为:
            # # ==========================================
            # # 分类名
            # # ==========================================
            if line.startswith('# =') and line.endswith('='):
                # 检查下一行是否是分类名
                if i + 1 < len(lines):
                    next_line = lines[i + 1].strip()
                    if next_line.startswith('# ') and not next_line.startswith('# ='):
                        # 提取分类名（移除 emoji）
                        category_match = re.search(r'^#\s*(.+)$', next_line)
                        if category_match:
                            category = category_match.group(1).strip()
                            # 移除 emoji (⚙️, 📁, 🌴, ⚔️ 等)
                            category = re.sub(r'[^\w\s&]', '', category).strip()
                            current_category = category
                continue

            # 解析手动安装的软件（注释行中的 manual）
            if line.strip().startswith('# manual '):
                # 提取包名、链接和描述
                # 移除开头的 # 和空格
                manual_line = line.strip()[1:].strip()
                match = re.match(r'manual\s+"([^"]+)",\s*link:\s*([^#\s]+)\s*(?:#\s*(.+))?', manual_line)
                if match:
                    app_name = match.group(1)
                    link = match.group(2)
                    comment = match.group(3) if match.group(3) else ""

                    # 提取描述
                    description = extract_description_from_comment(comment) or app_name

                    apps.append(AppInfo(
                        name=app_name,
                        category=current_category,
                        install_type="manual",
                        description=description,
                        link=link
                    ))
                continue

            # 跳过其他注释行
            if line.startswith('#'):
                continue

            # 解析 cask
            if line.startswith('cask '):
                # 提取包名和注释
                match = re.match(r'cask\s+"([^"]+)"\s*(?:#\s*(.+))?', line)
                if match:
                    brew_name = match.group(1)
                    comment = match.group(2) if match.group(2) else ""

                    # 直接使用包名作为名称
                    app_name = brew_name

                    # 提取描述
                    description = extract_description_from_comment(comment) or app_name

                    apps.append(AppInfo(
                        name=app_name,
                        category=current_category,
                        install_type="cask",
                        description=description,
                        brew_name=brew_name
                    ))
                continue

            # 解析 mas
            if line.startswith('mas '):
                # 提取应用名和 ID
                match = re.match(r'mas\s+"([^"]+)"(?:,\s*id:\s*(\d+))?\s*(?:#\s*(.+))?', line)
                if match:
                    app_name = match.group(1)
                    mas_id = match.group(2) if match.group(2) else ""
                    comment = match.group(3) if match.group(3) else ""

                    # 直接使用应用名
                    display_name = app_name

                    # 提取描述
                    description = extract_description_from_comment(comment) or display_name

                    apps.append(AppInfo(
                        name=display_name,
                        category=current_category,
                        install_type="mas",
                        description=description,
                        brew_name=app_name,
                        mas_id=mas_id
                    ))
                continue


            # 解析 brew (命令行工具)
            if line.startswith('brew '):
                match = re.match(r'brew\s+"([^"]+)"\s*(?:#\s*(.+))?', line)
                if match:
                    brew_name = match.group(1)
                    comment = match.group(2) if match.group(2) else ""

                    # 直接使用包名作为名称
                    app_name = brew_name
                    description = extract_description_from_comment(comment) or app_name

                    apps.append(AppInfo(
                        name=app_name,
                        category=current_category,
                        install_type="brew",
                        description=description,
                        brew_name=brew_name
                    ))
                continue


    except FileNotFoundError:
        print(f"错误：找不到文件 {filepath}")
    except Exception as e:
        print(f"解析 Brewfile 时出错：{e}")

    return apps


def extract_description_from_comment(comment: str) -> str:
    """从注释中提取描述"""
    if not comment:
        return ""

    # 移除括号内容作为描述
    if '(' in comment and ')' in comment:
        desc_match = re.search(r'\(([^)]+)\)', comment)
        if desc_match:
            return desc_match.group(1)

    return comment


def format_app_list(apps: List[AppInfo]) -> str:
    """将 AppInfo 列表格式化为 Markdown"""
    output = []
    current_category = ""

    for app in apps:
        if app.category != current_category:
            current_category = app.category
            output.append(f"### {current_category}\n")

        # 添加软件信息块 - 应用名使用加粗而不是 H3
        output.append(f"**{app.name}**")
        output.append("")  # 空行
        output.append(f"{app.description}")
        output.append("")  # 空行

        # 根据安装类型生成不同的安装指令
        if app.install_type == "manual":
            output.append(f"> Manual install: [{app.link}]({app.link})")
        elif app.install_type == "winget":
            output.append(f"```powershell")
            output.append(f"winget install {app.id}")
            output.append(f"```")
        elif app.install_type == "cask":
            output.append(f"```bash")
            output.append(f"brew install --cask {app.brew_name}")
            output.append(f"```")
        elif app.install_type == "mas":
            if app.mas_id:
                output.append(f"```bash")
                output.append(f"mas install {app.mas_id}")
                output.append(f"```")
            else:
                output.append(f"```bash")
                output.append(f"mas install \"{app.name}\"")
                output.append(f"```")
        elif app.install_type == "brew":
            output.append(f"```bash")
            output.append(f"brew install {app.brew_name}")
            output.append(f"```")

        output.append("")  # 空行分隔

    return "\n".join(output)


def update_readme(windows_apps: List[AppInfo], mac_apps: List[AppInfo], readme_path: str = "README.md"):
    """更新 README.md 文件 - 保留其他内容，只更新 Windows 和 Mac 部分"""
    try:
        # 生成新内容
        windows_content = format_app_list(windows_apps)
        mac_content = format_app_list(mac_apps)

        # 如果文件不存在，创建新文件
        if not os.path.exists(readme_path):
            new_content = f"""# my-handy-tools

## Windows

{windows_content}
## Mac

{mac_content}

"""
        else:
            # 读取现有 README
            with open(readme_path, 'r', encoding='utf-8') as f:
                content = f.read()

            lines = content.split('\n')

            # 找到 Windows、Mac 和分隔线的位置
            windows_start = -1
            mac_start = -1
            separator_start = len(lines)  # 默认值：文件末尾

            for i, line in enumerate(lines):
                if line.strip() == "## Windows":
                    windows_start = i
                elif line.strip() == "## Mac":
                    mac_start = i
                elif line.strip() == "---":
                    separator_start = i
                    break  # 找到分隔线就结束

            # 如果找不到结构，创建新的
            if windows_start == -1 or mac_start == -1:
                # 保留原有内容，在末尾添加结构
                if not content.endswith('\n'):
                    content += '\n'

                new_content = content + f"""
## Windows

{windows_content}
## Mac

{mac_content}

"""
            else:
                # 保留 Windows 之前的内容
                header = '\n'.join(lines[:windows_start])

                # 保留分隔线之后的内容（包含分隔线）
                footer = '\n'.join(lines[separator_start:]) if separator_start < len(lines) else ""

                # 构建新内容
                new_lines = [
                    header.rstrip('\n'),  # 去掉最后的换行
                    "",
                    "## Windows",
                    "",
                    windows_content,
                    "",
                    "## Mac",
                    "",
                    mac_content
                ]

                if footer.strip():
                    new_lines.append("")
                    new_lines.append(footer.lstrip('\n'))  # 去掉开头的换行

                new_content = '\n'.join(new_lines)

        # 写入文件
        with open(readme_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

        print(f"✅ README.md 已成功更新")
        print(f"   Windows 软件: {len(windows_apps)} 个")
        print(f"   Mac 软件: {len(mac_apps)} 个")

    except Exception as e:
        print(f"❌ 更新 README.md 时出错：{e}")


def main():
    """主函数"""
    print("=" * 60)
    print("  README 自动更新工具")
    print("=" * 60)
    print()

    # 解析 Windows 软件列表
    print("📖 解析 Win_app_manager.ps1...")
    windows_apps = parse_ps1("Win_app_manager.ps1")
    print(f"   发现 {len(windows_apps)} 个 Windows 软件")

    # 解析 Mac 软件列表
    print("\n📖 解析 Brewfile...")
    mac_apps = parse_brewfile("Brewfile")
    print(f"   发现 {len(mac_apps)} 个 Mac 软件")

    # 更新 README
    print("\n📝 更新 README.md...")
    update_readme(windows_apps, mac_apps)

    print("\n" + "=" * 60)
    print("  完成！")
    print("=" * 60)


if __name__ == "__main__":
    main()
