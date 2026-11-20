#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

# macOS 的 MacTeX 默认安装位置；其余平台使用 PATH 中的 XeLaTeX。
if ! command -v xelatex >/dev/null 2>&1 && [[ -x /Library/TeX/texbin/xelatex ]]; then
  export PATH="/Library/TeX/texbin:$PATH"
fi
if ! command -v xelatex >/dev/null 2>&1; then
  printf '%s\n' '需要安装包含 XeLaTeX 的 TeX Live 或 MacTeX。' >&2
  exit 1
fi

mkdir -p .build
for pass in 1 2; do
  if ! xelatex -no-shell-escape -interaction=nonstopmode -halt-on-error \
    -output-directory=.build main.tex > ".build/pass-${pass}.log" 2>&1; then
    cat ".build/pass-${pass}.log" >&2
    exit 1
  fi
done
cp .build/main.pdf ../report.pdf
printf '%s\n' '已生成 lab6/report/report.pdf'
