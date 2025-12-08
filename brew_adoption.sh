#!/usr/bin/env bash

# ==========================================
# Homebrew & App Store "智能接管"脚本
# 功能：读取 Brewfile，智能识别软件来源，强制覆盖安装所有可管理的软件
# 目的：将手动安装的软件移交给 Homebrew 或 App Store (mas) 管理
# 原则：优先使用 Homebrew Cask，其次 App Store，最后标记为手动安装
# ==========================================

set -euo pipefail

# 检查 bash 版本
bash_version_line=$(bash --version | head -1)
bash_major_version=$(echo "$bash_version_line" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
if [ -z "$bash_major_version" ] || [ "$bash_major_version" -lt 4 ]; then
    echo "错误：需要 bash 4.0 或更高版本，当前版本: $bash_version_line"
    echo "请通过 Homebrew 安装新版本: brew install bash"
    echo "然后重新运行脚本: /opt/homebrew/bin/bash ./adoption.sh"
    exit 1
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 文件路径
BREWFILE="Brewfile"
LOG_FILE="adoption.log"

# 全局数组声明
declare -A cask_apps mas_apps manual_apps app_validation takeover_plan

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# 检查依赖
check_dependencies() {
    log "检查系统依赖..."

    if ! command -v brew &> /dev/null; then
        error "Homebrew 未安装，请先安装 Homebrew"
        echo "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    if ! command -v mas &> /dev/null; then
        warning "mas (Mac App Store CLI) 未安装，正在安装..."
        brew install mas
        if [ $? -ne 0 ]; then
            error "mas 安装失败，请手动安装: brew install mas"
            exit 1
        fi
        success "mas 安装成功"
    fi

    # 检查 brew 和 mas 登录状态（跳过 brew doctor，避免长时间等待）
    # if ! brew doctor &> /dev/null; then
    #     warning "Homebrew 状态检查失败，但继续执行..."
    # fi

    log "依赖检查完成"
}

# 解析 Brewfile
parse_brewfile() {
    log "解析 Brewfile: $BREWFILE"

    if [ ! -f "$BREWFILE" ]; then
        error "找不到 Brewfile: $BREWFILE"
        exit 1
    fi

    # 初始化数组
    cask_apps=()
    mas_apps=()      # key: name, value: id
    manual_apps=()   # key: name, value: link

    local line_num=0
    while IFS= read -r line; do
        ((line_num++)) || true
        line_trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # 跳过空行和纯注释行
        if [[ -z "$line_trimmed" ]] || [[ "$line_trimmed" == \#* ]]; then
            continue
        fi

        # 解析 cask
        if [[ "$line_trimmed" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
            app_name="${BASH_REMATCH[1]}"
            cask_apps["$app_name"]="pending"
            log "发现 cask 应用: $app_name (行 $line_num)"

        # 解析 mas (格式: mas "App Name", id: 123456789)
        elif [[ "$line_trimmed" =~ ^mas[[:space:]]+\"([^\"]+)\",[[:space:]]*id:[[:space:]]*([0-9]+) ]]; then
            app_name="${BASH_REMATCH[1]}"
            app_id="${BASH_REMATCH[2]}"
            mas_apps["$app_name"]="$app_id"
            log "发现 App Store 应用: $app_name (ID: $app_id, 行 $line_num)"

        # 解析 manual (注释格式: # manual "App Name", link: https://...)
        elif [[ "$line_trimmed" =~ ^\#[[:space:]]*manual[[:space:]]+\"([^\"]+)\",[[:space:]]*link:[[:space:]]*(.+) ]]; then
            app_name="${BASH_REMATCH[1]}"
            app_link="${BASH_REMATCH[2]}"
            manual_apps["$app_name"]="$app_link"
            log "发现手动安装应用: $app_name (链接: $app_link, 行 $line_num)"
        fi
    done < "$BREWFILE"

    log "Brewfile 解析完成:"
    log "  - Cask 应用: ${#cask_apps[@]} 个"
    log "  - App Store 应用: ${#mas_apps[@]} 个"
    log "  - 手动安装应用: ${#manual_apps[@]} 个"
}

# 检查 cask 是否存在
check_cask_exists() {
    local app_name="$1"
    if brew info --cask "$app_name" &>/dev/null; then
        return 0  # 存在
    else
        return 1  # 不存在
    fi
}

# 检查 mas 应用是否存在（通过名称搜索）
find_mas_app() {
    local app_name="$1"
    # 尝试搜索应用
    local search_result
    search_result=$(mas search "$app_name" 2>/dev/null | head -5)

    if [ -z "$search_result" ]; then
        echo ""  # 未找到
        return 1
    fi

    # 解析第一行结果（格式: ID App Name (价格)）
    local first_line
    first_line=$(echo "$search_result" | head -1)

    if [[ "$first_line" =~ ^([0-9]+)[[:space:]]+(.+?)[[:space:]]+\( ]]; then
        local found_id="${BASH_REMATCH[1]}"
        local found_name="${BASH_REMATCH[2]}"
        echo "$found_id:$found_name"
        return 0
    else
        echo ""
        return 1
    fi
}

# 验证应用可用性并确定最佳安装方式
validate_apps() {
    log "开始验证应用可用性..."

    app_validation=()

    local total_apps=$(( ${#cask_apps[@]} + ${#mas_apps[@]} + ${#manual_apps[@]} ))
    local current=0

    # 验证 cask 应用
    for app_name in "${!cask_apps[@]}"; do
        ((current++)) || true
        log "[$current/$total_apps] 验证 cask: $app_name"

        if check_cask_exists "$app_name"; then
            app_validation["$app_name"]="cask:valid"
            success "  ✅ 在 Homebrew Cask 仓库中找到"
        else
            # 检查是否在 App Store 中
            local mas_info
            mas_info=$(find_mas_app "$app_name")
            if [ -n "$mas_info" ]; then
                local mas_id="${mas_info%%:*}"
                local mas_name="${mas_info#*:}"
                app_validation["$app_name"]="mas:$mas_id"
                warning "  🔄 未在 Cask 中找到，但在 App Store 中发现: $mas_name (ID: $mas_id)"
            else
                app_validation["$app_name"]="manual:not_found"
                warning "  ❌ 在 Cask 和 App Store 中均未找到，标记为手动安装"
            fi
        fi
    done

    # 验证 mas 应用
    for app_name in "${!mas_apps[@]}"; do
        ((current++)) || true
        local expected_id="${mas_apps[$app_name]}"
        log "[$current/$total_apps] 验证 App Store 应用: $app_name (预期ID: $expected_id)"

        # 首先检查预期ID是否有效
        if mas info "$expected_id" &>/dev/null; then
            app_validation["$app_name"]="mas:$expected_id"
            success "  ✅ App Store ID 有效"
        else
            # 尝试通过名称搜索
            local mas_info
            mas_info=$(find_mas_app "$app_name")
            if [ -n "$mas_info" ]; then
                local found_id="${mas_info%%:*}"
                local found_name="${mas_info#*:}"
                app_validation["$app_name"]="mas:$found_id"
                warning "  🔄 预期ID $expected_id 无效，但找到: $found_name (ID: $found_id)"
            else
                # 检查是否在 Cask 中
                if check_cask_exists "$app_name"; then
                    app_validation["$app_name"]="cask:valid"
                    warning "  🔄 未在 App Store 中找到，但在 Cask 中发现"
                else
                    app_validation["$app_name"]="manual:not_found"
                    warning "  ❌ 在 App Store 和 Cask 中均未找到，标记为手动安装"
                fi
            fi
        fi
    done

    # 验证 manual 应用（仅检查是否实际上在仓库中）
    for app_name in "${!manual_apps[@]}"; do
        ((current++)) || true
        log "[$current/$total_apps] 验证手动安装应用: $app_name"

        if check_cask_exists "$app_name"; then
            app_validation["$app_name"]="cask:valid"
            warning "  🔄 标记为手动安装，但在 Cask 仓库中找到"
        else
            local mas_info
            mas_info=$(find_mas_app "$app_name")
            if [ -n "$mas_info" ]; then
                local mas_id="${mas_info%%:*}"
                app_validation["$app_name"]="mas:$mas_id"
                warning "  🔄 标记为手动安装，但在 App Store 中发现 (ID: $mas_id)"
            else
                app_validation["$app_name"]="manual:confirmed"
                success "  ✅ 确认为手动安装"
            fi
        fi
    done

    log "应用验证完成"
}

# 显示接管计划并确认
show_plan_and_confirm() {
    log "生成接管计划..."

    takeover_plan=()
    local cask_count=0
    local mas_count=0
    local skip_count=0

    echo ""
    echo "==================================================="
    echo "                   接管计划                         "
    echo "==================================================="
    echo ""

    # 检查每个应用的状态并制定计划
    for app_name in "${!app_validation[@]}"; do
        local status="${app_validation[$app_name]}"
        local type="${status%%:*}"
        local detail="${status#*:}"

        case "$type" in
            "cask")
                # 检查是否已由 Homebrew 管理
                if brew list --cask "$app_name" &>/dev/null; then
                    echo -e "📦 ${GREEN}[已管理]${NC} $app_name (Homebrew Cask)"
                    skip_count=$((skip_count + 1))
                else
                    echo -e "📦 ${YELLOW}[将接管]${NC} $app_name (Homebrew Cask)"
                    takeover_plan["$app_name"]="cask"
                    cask_count=$((cask_count + 1))
                fi
                ;;

            "mas")
                local mas_id="$detail"
                # 检查是否已安装（通过 mas list）
                if mas list | grep -q "^$mas_id "; then
                    echo -e "🛒 ${GREEN}[已管理]${NC} $app_name (App Store, ID: $mas_id)"
                    skip_count=$((skip_count + 1))
                else
                    echo -e "🛒 ${YELLOW}[将接管]${NC} $app_name (App Store, ID: $mas_id)"
                    takeover_plan["$app_name"]="mas:$mas_id"
                    mas_count=$((mas_count + 1))
                fi
                ;;

            "manual")
                echo -e "📝 ${BLUE}[手动安装]${NC} $app_name"
                skip_count=$((skip_count + 1))
                ;;
        esac
    done

    echo ""
    echo "==================================================="
    echo "计划摘要:"
    echo -e "  - 将接管 ${YELLOW}$cask_count${NC} 个 Homebrew Cask 应用"
    echo -e "  - 将接管 ${YELLOW}$mas_count${NC} 个 App Store 应用"
    echo -e "  - 跳过 ${GREEN}$skip_count${NC} 个应用（已管理或手动安装）"
    echo "==================================================="
    echo ""

    if [ $((cask_count + mas_count)) -eq 0 ]; then
        success "所有应用都已管理，无需接管操作"
        exit 0
    fi

    # 用户确认
    echo -e "⚠️  ${RED}警告:${NC} 接管操作将覆盖 /Applications 下的同名应用"
    echo "    用户数据通常会被保留，但无法保证完全无损"
    echo ""
    echo -e "📋 ${YELLOW}请确认以下事项:${NC}"
    echo "  1. 已备份重要数据"
    echo "  2. 接受可能的应用配置重置"
    echo "  3. 网络连接稳定"
    echo ""

    # 干跑模式：不执行实际接管
    if [ "${DRY_RUN:-false}" = "true" ]; then
        warning "干跑模式：只显示计划，不执行实际操作"
        user_confirm="no"
    else
        read -p "是否继续执行接管操作？(输入 'yes' 继续): " user_confirm
    fi

    if [ "$user_confirm" != "yes" ]; then
        error "用户取消操作"
        exit 0
    fi

    success "确认完成，开始执行接管操作"
}

# 执行接管操作
execute_takeover() {
    log "开始执行接管操作..."

    local total=${#takeover_plan[@]}
    local current=0
    local success_count=0
    local fail_count=0
    local failed_apps=()

    for app_name in "${!takeover_plan[@]}"; do
        ((current++)) || true
        local plan="${takeover_plan[$app_name]}"

        echo ""
        log "[$current/$total] 接管: $app_name"

        if [[ "$plan" == "cask" ]]; then
            # Homebrew Cask 接管
            echo "  类型: Homebrew Cask"
            echo "  命令: brew install --cask --force \"$app_name\""

            if brew install --cask --force "$app_name"; then
                success "  ✅ 接管成功"
                success_count=$((success_count + 1))
            else
                error "  ❌ 接管失败"
                fail_count=$((fail_count + 1))
                failed_apps+=("$app_name (cask)")
            fi

        elif [[ "$plan" == mas:* ]]; then
            # App Store 接管
            local mas_id="${plan#mas:}"
            echo "  类型: App Store (mas)"
            echo "  命令: mas install \"$mas_id\""

            if mas install "$mas_id"; then
                success "  ✅ 接管成功"
                success_count=$((success_count + 1))
            else
                error "  ❌ 接管失败"
                fail_count=$((fail_count + 1))
                failed_apps+=("$app_name (mas:$mas_id)")
            fi
        fi

        # 短暂暂停，避免请求过快
        sleep 1
    done

    echo ""
    echo "==================================================="
    echo "接管操作完成"
    echo "==================================================="
    echo "  ✅ 成功: $success_count 个应用"
    echo "  ❌ 失败: $fail_count 个应用"

    if [ $fail_count -gt 0 ]; then
        echo ""
        echo "失败的应用:"
        for failed_app in "${failed_apps[@]}"; do
            echo "  - $failed_app"
        done
        echo ""
        warning "部分应用接管失败，请检查网络连接或手动安装"
    fi

    if [ $success_count -gt 0 ]; then
        echo ""
        success "恭喜！你的 Mac 软件现已实现 Infrastructure as Code"
        echo ""
        echo "后续建议:"
        echo "  1. 运行 'brew upgrade' 更新所有 Homebrew 软件"
        echo "  2. 运行 'mas upgrade' 更新所有 App Store 软件"
        echo "  3. 定期运行 'brew bundle' 确保环境一致"
    fi
}

# 主函数
main() {
    echo ""
    echo "==================================================="
    echo "       Homebrew & App Store 智能接管脚本           "
    echo "==================================================="
    echo ""

    # 清理旧日志
    > "$LOG_FILE"

    # 执行步骤
    check_dependencies
    parse_brewfile
    validate_apps
    show_plan_and_confirm
    execute_takeover

    echo ""
    log "脚本执行完成，详细日志请查看: $LOG_FILE"
}

# 运行主函数
main "$@"