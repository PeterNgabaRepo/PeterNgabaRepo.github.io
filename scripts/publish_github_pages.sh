#!/usr/bin/env bash
set -euo pipefail

APPROVAL_TEXT="${1:-}"
REQUIRED_APPROVAL="APPROVE SITE PUBLICATION"
OWNER="PeterNgabaRepo"
REPO="PeterNgabaRepo.github.io"
DESCRIPTION="Professional portfolio site for Peter Ngaba: software engineering, systems coursework, AI/IP analysis, and automation workflows."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="$(cd "${SITE_DIR}/.." && pwd)"

if [[ "${APPROVAL_TEXT}" != "${REQUIRED_APPROVAL}" ]]; then
  echo "Refusing to publish: pass exact approval text '${REQUIRED_APPROVAL}'." >&2
  exit 2
fi

cd "${WORKSPACE_ROOT}"
python3 portfolio_audit/scripts/validate_portfolio_site.py
python3 portfolio_audit/scripts/validate_publication_readiness.py
python3 portfolio_audit/scripts/validate_public_safety.py
gh auth status

cd "${SITE_DIR}"
if [[ -n "$(git status --short)" ]]; then
  echo "Refusing to publish: portfolio_site git status is not clean." >&2
  git status --short
  exit 3
fi

git branch -M main

if gh repo view "${OWNER}/${REPO}" >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/${OWNER}/${REPO}.git"
  else
    git remote add origin "https://github.com/${OWNER}/${REPO}.git"
  fi
  git push -u origin main
else
  gh repo create "${OWNER}/${REPO}" \
    --public \
    --description "${DESCRIPTION}" \
    --source=. \
    --remote=origin \
    --push
fi

gh repo view "${OWNER}/${REPO}" --json nameWithOwner,visibility,url,defaultBranchRef,isPrivate
echo "Expected Pages URL: https://${OWNER}.github.io/"
