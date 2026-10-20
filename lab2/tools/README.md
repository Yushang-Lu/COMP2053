# Lab2 手册 PDF 导出

`render_manual.py` 只读 `../resource/process.md`，不改写 Markdown，不覆盖已有 PDF。使用真正的 Python-Markdown 解析标题、列表、表格、代码块和行内标记，再用 ReportLab 排版。本手册的链接在 PDF 中保留可见文字；相对链接请在 Markdown 中打开。暂不支持图片、嵌套列表等其他结构，遇到未支持的元素会报错，不静默丢失。

这不是 Lab1 的专用渲染脚本，也不会修改 `lab1/`。按步骤标题分页，中文宋体，A4 黑白排版。自动核对正文文字、字体字形和 Markdown 未被修改；仍必须逐页检查最终页面图片。

## 使用已有环境，不额外安装

本机应用预装 Python 已有 ReportLab、Pillow、pypdf；conda `tf2` 已有 Python-Markdown。通过子进程分工，不混用两个解释器的 site-packages，不安装到系统 Python。

从仓库根目录执行：

```bash
/Users/jinana/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  lab2/tools/render_manual.py \
  --markdown-python /opt/miniconda3/envs/tf2/bin/python \
  --output lab2/output/pdf/lab2-operation-guide.pdf
```

如果 PDF 已存在，请换一个输出路径，例如 `/tmp/lab2-guide-preview.pdf`。预装环境路径不是跨机器保证，换机器后先检查现有环境；不要假定只能使用系统 Python，也不要未检查就自动下载安装。

默认字体是 macOS `Songti.ttc`，简体常规索引 6、粗体索引 1；其他系统须核实字体文件和索引，不能静默退回黑体。

## 导出后检查

```bash
mkdir -p /tmp/lab2-guide-check
pdftoppm -scale-to 1500 -png \
  lab2/output/pdf/lab2-operation-guide.pdf /tmp/lab2-guide-check/page
pdffonts lab2/output/pdf/lab2-operation-guide.pdf
```

逐页打开 PNG，确认标题不落单、表格不越界、代码不裁切、中文不缺字、没有空白尾页。字体应嵌入。PDF 是操作手册，不能作为课程要求的个人实验报告提交。
