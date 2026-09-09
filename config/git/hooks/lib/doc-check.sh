#!/usr/bin/env bash
# Documentation freshness check, shared by every repository's pre-commit hook.
#
# Sourcing this file defines doc_check_run and has no other effect. A hook that
# needs extra project-specific gates can run them first and then call this,
# instead of keeping its own drifting copy of the logic.
#
# doc_check_run exits the shell directly (0 to allow the commit, 1 to block),
# matching how a hook behaves.

doc_check_run() {
  # Colors for output
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color

  # Get project root
  PROJECT_ROOT=$(git rev-parse --show-toplevel)
  cd "$PROJECT_ROOT" || exit 1

  echo -e "${BLUE}🔍 Running pre-commit documentation checks...${NC}"

  # Check if there are any changes staged
  if git diff --cached --quiet; then
      echo -e "${YELLOW}⚠️  No changes staged for commit${NC}"
      exit 0
  fi

  # Get list of changed files
  CHANGED_FILES=$(git diff --cached --name-only)
  CHANGED_COUNT=$(echo "$CHANGED_FILES" | wc -l)

  echo -e "${BLUE}📝 Detected $CHANGED_COUNT file(s) changed${NC}"

  # Flags for what changed
  SECURITY_CHANGED=false
  FEATURE_CHANGED=false
  CONFIG_CHANGED=false
  CORE_CHANGED=false
  DOCS_UPDATED=false

  # Check what types of files changed
  while IFS= read -r file; do
      # Skip if file doesn't exist (deleted files)
      [ ! -f "$file" ] && continue

      # Check for security-related changes.
      # Generated lockfiles are pure noise here: base64 integrity hashes contain
      # substrings like "KEy", and package names like "idb-keyval" or
      # "@azure/keyvault-secrets" match too. Skip them outright.
      case "$(basename "$file")" in
          package-lock.json|npm-shrinkwrap.json|yarn.lock|pnpm-lock.yaml|poetry.lock|uv.lock|Cargo.lock|composer.lock|go.sum|Gemfile.lock)
              IS_LOCKFILE=true ;;
          *)
              IS_LOCKFILE=false ;;
      esac

      # Scan ADDED lines only (not context or removals).
      # Boundaries are [^a-zA-Z0-9] rather than \b on purpose: \b treats "_" as a
      # word character, so \bsecret\b MISSES "SECRET_TOKEN" and \bkey\b misses
      # "API_KEY" -- the exact identifiers worth catching. This form matches those
      # while still rejecting "idb-keyval", "keyvault-secrets", and base64 blobs
      # like "sha512-9KEyW..." where the hit is flanked by alphanumerics.
      SEC_RE='(^|[^a-zA-Z0-9])(password|credential|secret|token|key|auth|vulnerability|injection|StrictHostKeyChecking)([^a-zA-Z0-9]|$)'
      if [ "$IS_LOCKFILE" = false ] && \
         git diff --cached -U0 -- "$file" | grep '^+' | grep -v '^+++' \
         | grep -qiE "$SEC_RE"; then
          SECURITY_CHANGED=true
      fi

      # Check for feature additions
      if git diff --cached "$file" | grep -q "^+.*def \|^+.*class \|^+.*function "; then
          FEATURE_CHANGED=true
      fi

      # Check if config files changed
      if [[ "$file" =~ \.(yaml|yml|json|toml|ini|conf)$ ]]; then
          CONFIG_CHANGED=true
      fi

      # Check if core source files changed
      if [[ "$file" =~ \.(py|js|ts|go|rs|java|c|cpp)$ ]]; then
          CORE_CHANGED=true
      fi

      # Check if documentation was updated.
      # CLAUDE.md is the canonical per-project doc in this environment (AGENTS.md
      # is a symlink to it), so a CLAUDE.md edit counts as documenting the change.
      case "$file" in
          README.md|CHANGELOG.md|CLAUDE.md|AGENTS.md|.claude/context.md|docs/*.md)
              DOCS_UPDATED=true ;;
      esac
  done <<< "$CHANGED_FILES"

  # Determine if documentation update is needed
  DOCS_NEEDED=false
  REASONS=()

  if [ "$SECURITY_CHANGED" = true ]; then
      DOCS_NEEDED=true
      REASONS+=("🔒 Security-related changes detected")
  fi

  if [ "$FEATURE_CHANGED" = true ]; then
      DOCS_NEEDED=true
      REASONS+=("✨ New functions/classes added")
  fi

  if [ "$CONFIG_CHANGED" = true ] && [ "$CORE_CHANGED" = true ]; then
      DOCS_NEEDED=true
      REASONS+=("⚙️  Configuration files changed")
  fi

  # If docs needed but not updated, warn user
  if [ "$DOCS_NEEDED" = true ] && [ "$DOCS_UPDATED" = false ]; then
      echo ""
      echo -e "${YELLOW}⚠️  Documentation Update Recommended${NC}"
      echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

      for reason in "${REASONS[@]}"; do
          echo -e "${YELLOW}  $reason${NC}"
      done

      echo ""
      echo -e "${BLUE}📚 Suggested actions:${NC}"

      if [ -f ".claude/context.md" ]; then
          echo -e "  • Update ${GREEN}.claude/context.md${NC} with your changes"
      else
          echo -e "  • Create ${GREEN}.claude/context.md${NC} to document this project"
      fi

      if [ -f "README.md" ]; then
          echo -e "  • Update ${GREEN}README.md${NC} if user-facing changes"
      fi

      echo ""
      echo -e "${BLUE}💡 Quick help:${NC}"
      echo -e "  Run: ${GREEN}claude${NC} and use the ${GREEN}project-finalizer${NC} agent"
      echo -e "  Say:  \"Use project-finalizer to update docs\""
      echo ""

      # Check for environment variable to skip
      if [ -n "$SKIP_DOC_CHECK" ]; then
          echo -e "${YELLOW}⏭️  Skipping doc check (SKIP_DOC_CHECK is set)${NC}"
          exit 0
      fi

      # Git runs pre-commit hooks with stdin on /dev/null, so a bare `read` can
      # never reach the user -- it hits EOF and, under `set -e`, dies with a
      # misleading "Invalid choice". Reattach to the terminal on fd 3 to prompt
      # a human; when there is no terminal (agent, script, CI) fail closed with
      # the real reason and the exact bypass.
      if exec 3</dev/tty 2>/dev/null; then
          HAVE_TTY=true
      else
          HAVE_TTY=false
      fi

      if [ "$HAVE_TTY" = false ]; then
          echo -e "${RED}❌ Commit aborted: docs look stale and there is no terminal to ask.${NC}"
          echo -e "${BLUE}   Update CLAUDE.md / README.md, or bypass deliberately:${NC}"
          echo -e "   ${GREEN}SKIP_DOC_CHECK=1 git commit ...${NC}"
          exit 1
      fi

      # Ask user what to do
      echo -e "${YELLOW}Options:${NC}"
      echo -e "  ${GREEN}1)${NC} Abort and update docs first (recommended)"
      echo -e "  ${GREEN}2)${NC} Commit anyway (docs can be updated later)"
      echo -e "  ${GREEN}3)${NC} Skip this check for this commit only"
      echo ""

      REPLY=""
      read -u 3 -p "Choose [1/2/3]: " -n 1 -r || true
      exec 3<&-
      echo ""

      case $REPLY in
          1)
              echo -e "${RED}❌ Commit aborted. Please update documentation first.${NC}"
              echo -e "${BLUE}Tip: Run 'claude' and use the project-finalizer agent${NC}"
              exit 1
              ;;
          2)
              echo -e "${YELLOW}⚠️  Proceeding without doc updates...${NC}"
              echo -e "${YELLOW}   Don't forget to document these changes later!${NC}"
              ;;
          3)
              echo -e "${YELLOW}⏭️  Skipping doc check for this commit${NC}"
              ;;
          *)
              echo -e "${RED}❌ Invalid choice. Aborting commit.${NC}"
              exit 1
              ;;
      esac
  fi

  # Check if context.md was updated but README wasn't (and vice versa)
  if [ "$DOCS_UPDATED" = true ]; then
      CONTEXT_UPDATED=false
      README_UPDATED=false

      echo "$CHANGED_FILES" | grep -q "\.claude/context\.md" && CONTEXT_UPDATED=true
      echo "$CHANGED_FILES" | grep -q "^README\.md$" && README_UPDATED=true

      # If one was updated but significant changes exist, remind about the other
      if [ "$CONTEXT_UPDATED" = true ] && [ "$README_UPDATED" = false ] && [ "$FEATURE_CHANGED" = true ]; then
          echo -e "${YELLOW}💡 Tip: You updated context.md but not README.md${NC}"
          echo -e "${YELLOW}   Consider updating README if this affects users${NC}"
          echo ""
      fi

      if [ "$README_UPDATED" = true ] && [ "$CONTEXT_UPDATED" = false ] && [ "$CORE_CHANGED" = true ]; then
          echo -e "${YELLOW}💡 Tip: You updated README.md but not .claude/context.md${NC}"
          echo -e "${YELLOW}   Consider updating context.md for future Claude sessions${NC}"
          echo ""
      fi
  fi

  # Success!
  if [ "$DOCS_UPDATED" = true ]; then
      echo -e "${GREEN}✅ Documentation updated - looking good!${NC}"
  else
      echo -e "${GREEN}✅ Pre-commit checks passed${NC}"
  fi

  exit 0
}
