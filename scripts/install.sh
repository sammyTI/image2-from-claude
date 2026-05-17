#!/usr/bin/env bash
# image2-from-claude installer
# Usage:
#   ローカル実行:  ./scripts/install.sh
#   ワンライナー: curl -fsSL https://raw.githubusercontent.com/<user>/image2-from-claude/main/scripts/install.sh | bash

set -euo pipefail

REPO_OWNER="${IMAGE2_REPO_OWNER:-sammyti}"
REPO_NAME="${IMAGE2_REPO_NAME:-image2-from-claude}"
REPO_BRANCH="${IMAGE2_REPO_BRANCH:-main}"
ARCHIVE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REPO_BRANCH}.tar.gz"

SKILLS_DEST="${HOME}/.claude/skills"
SKILLS_TO_INSTALL=("lp-from-codex" "slides-from-codex")

# ────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────
color() { printf "\033[%sm%s\033[0m" "$1" "$2"; }
ok()    { color "32" "✓ $1"; echo; }
warn()  { color "33" "! $1"; echo; }
err()   { color "31" "✗ $1"; echo; }
hdr()   { echo; color "36" "── $1 ──"; echo; }

abort() { err "$1"; exit 1; }

# ────────────────────────────────────────────────
# Resolve source: ローカル実行 or ワンライナー実行
# ────────────────────────────────────────────────
resolve_source() {
  # スクリプト自身の場所を取得（curl | bash の場合は失敗）
  local script_dir
  if script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" \
     && [ -d "${script_dir}/../plugins/lp-from-codex/skills/lp-from-codex" ]; then
    SOURCE_MODE="local"
    SOURCE_DIR="$(cd "${script_dir}/.." && pwd)"
    ok "ローカル実行を検出: ${SOURCE_DIR}"
  else
    SOURCE_MODE="remote"
    SOURCE_DIR="$(mktemp -d -t image2-from-claude.XXXXXX)"
    warn "ワンライナー実行を検出。GitHub から取得します"
    hdr "ソース取得"
    curl -fsSL "${ARCHIVE_URL}" | tar -xz -C "${SOURCE_DIR}" --strip-components=1 \
      || abort "GitHub からの取得に失敗。URL: ${ARCHIVE_URL}"
    ok "取得完了: ${SOURCE_DIR}"
  fi
}

# ────────────────────────────────────────────────
# Prereq check（簡易版・本格版は check-prereqs.sh）
# ────────────────────────────────────────────────
run_prereq_check() {
  hdr "前提条件チェック"
  local has_codex=0 has_auth=0 has_claude=0

  if command -v codex >/dev/null 2>&1; then
    ok "codex CLI が見つかりました ($(codex --version 2>/dev/null | head -1))"
    has_codex=1
  else
    warn "codex CLI が見つかりません → brew install openai/tap/codex"
  fi

  if [ -f "${HOME}/.codex/auth.json" ]; then
    ok "Codex 認証ファイルあり (~/.codex/auth.json)"
    has_auth=1
  else
    warn "Codex 未ログイン → codex login で ChatGPT アカウントを選んでください"
  fi

  if [ -d "${HOME}/.claude" ]; then
    ok "Claude Code 設定ディレクトリあり (~/.claude/)"
    has_claude=1
  else
    warn "Claude Code 設定ディレクトリがありません → 先に Claude Code をインストール"
  fi

  if [ $has_codex -eq 0 ] || [ $has_claude -eq 0 ]; then
    echo
    err "必須前提が不足しています。上記を満たしてから再実行してください"
    if [ "${IMAGE2_FORCE:-0}" = "1" ]; then
      warn "IMAGE2_FORCE=1 のため続行します"
    else
      exit 1
    fi
  fi

  [ $has_auth -eq 0 ] && warn "Codex 未ログインでも配置は進めます。利用前に codex login を実行してください"
}

# ────────────────────────────────────────────────
# Install skills
# ────────────────────────────────────────────────
install_skills() {
  hdr "スキル配置"
  mkdir -p "${SKILLS_DEST}"

  for skill in "${SKILLS_TO_INSTALL[@]}"; do
    local src="${SOURCE_DIR}/plugins/${skill}/skills/${skill}"
    local dst="${SKILLS_DEST}/${skill}"

    if [ ! -d "${src}" ]; then
      err "ソースが見つかりません: ${src}"
      continue
    fi

    if [ -d "${dst}" ]; then
      if [ "${IMAGE2_FORCE:-0}" = "1" ]; then
        warn "${skill} は既に存在します → 上書き (IMAGE2_FORCE=1)"
        rm -rf "${dst}"
      else
        # インタラクティブが可能なら聞く
        if [ -t 0 ]; then
          read -r -p "${skill} は既に存在します。上書きしますか? [y/N] " ans
          case "${ans}" in
            y|Y|yes|YES) rm -rf "${dst}" ;;
            *) warn "${skill} はスキップ"; continue ;;
          esac
        else
          warn "${skill} は既に存在します → スキップ (上書きするなら IMAGE2_FORCE=1)"
          continue
        fi
      fi
    fi

    cp -R "${src}" "${dst}"
    ok "${skill} を配置: ${dst}"
  done
}

# ────────────────────────────────────────────────
# Print MCP config snippet
# ────────────────────────────────────────────────
print_mcp_hint() {
  hdr "Codex MCP の設定"
  cat <<'EOF'
Claude Code のグローバル設定 (~/.claude.json) またはプロジェクトの .mcp.json に
以下のエントリがあるか確認してください。なければ追記:

  "mcpServers": {
    "codex": {
      "command": "npx",
      "args": ["@openai/codex", "mcp-server"]
    }
  }

追記後は Claude Code を再起動してください。
EOF
}

# ────────────────────────────────────────────────
# Final summary
# ────────────────────────────────────────────────
print_summary() {
  hdr "インストール完了"
  echo "配置済みスキル:"
  for skill in "${SKILLS_TO_INSTALL[@]}"; do
    [ -d "${SKILLS_DEST}/${skill}" ] && echo "  → ${SKILLS_DEST}/${skill}"
  done

  echo
  echo "動作確認 (Claude Code から):"
  echo "  → 「スライド作って」と話しかける（slides-from-codex 起動）"
  echo "  → 「LP作って」と話しかける（lp-from-codex 起動）"
  echo
  echo "詳細: https://github.com/${REPO_OWNER}/${REPO_NAME}"
}

# ────────────────────────────────────────────────
# Cleanup
# ────────────────────────────────────────────────
cleanup() {
  if [ "${SOURCE_MODE:-}" = "remote" ] && [ -d "${SOURCE_DIR:-}" ]; then
    rm -rf "${SOURCE_DIR}"
  fi
}
trap cleanup EXIT

# ────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────
echo
color "1;36" "image2-from-claude installer"
echo
echo "Claude Code から Codex 経由で Image 2.0、スライドもLPもこれ1本。"

resolve_source
run_prereq_check
install_skills
print_mcp_hint
print_summary
