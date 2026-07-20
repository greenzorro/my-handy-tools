#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/brew-adoption-test.XXXXXX")
trap 'find "$TEST_DIR" -type f -delete; rmdir "$TEST_DIR"' EXIT

source "$PROJECT_DIR/brew_adoption.sh"

BREWFILE="$PROJECT_DIR/Brewfile"
LOG_FILE="$TEST_DIR/adoption.log"
parse_brewfile >/dev/null

[[ ${#manual_apps[@]} -eq 5 ]]
[[ ${manual_apps["dozer"]} == "https://github.com/Mortennn/Dozer" ]]
[[ ${manual_apps["Zhipu GLM Input"]} == "https://autoglm.zhipuai.cn/autotyper/" ]]

echo "brew_adoption parser: passed"
