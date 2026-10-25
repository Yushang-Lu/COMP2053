# Lab3 操作手册 PDF

`render_manual.py` 从 Lab2 的 Markdown＋ReportLab 工具适配，独立放在 Lab3，不改旧工具。标题自然分页，中文宋体，黑白 A4；只读 Markdown，不覆盖已有 PDF。

## 使用本机已有环境

从仓库根目录执行：

```bash
/Users/jinana/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  lab3/tools/render_manual.py \
  --markdown-python /opt/miniconda3/envs/tf2/bin/python \
  --output lab3/output/pdf/lab3-operation-guide.pdf
```

若目标已存在，先用新的预览路径（例如 `/tmp/lab3-guide-preview.pdf`），检查后再决定是否替换。脚本也接受 `--source` 指定 Markdown。

依赖已有 ReportLab、pypdf、Python-Markdown；不安装或混用不同解释器的 site-packages。换电脑时重新确认解释器和字体路径。默认宋体为 macOS `Songti.ttc`，简体常规索引 6、粗体索引 1；其他系统需要核实并适配，不能静默换字体。

支持本手册使用的标题、段落、单层列表、表格、代码块、粗体和行内标记；链接仅保留可见文字，打开链接请使用 Markdown。图片、复杂嵌套列表等不在支持范围，不作为通用 Markdown/PDF 引擎。

## 检查

```bash
mkdir -p /tmp/lab3-guide-check
pdftoppm -scale-to 1500 -png \
  lab3/output/pdf/lab3-operation-guide.pdf /tmp/lab3-guide-check/page
pdffonts lab3/output/pdf/lab3-operation-guide.pdf
```

脚本检查正文提取、字体字形和 Markdown 字节未变；还必须逐页查看 PNG，确认标题不落单、表格/代码不裁切、无缺字或空白页。手册与实验报告是两个不同文件。
