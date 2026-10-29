# Lab4 操作手册 PDF

`render_manual.py` 独立适配 Lab3 的 Markdown＋ReportLab 工具，不修改旧实验。默认读取 `../resource/process.md`，只读 Markdown，不覆盖已有输出。

## 本机渲染

从仓库根目录执行；正式路径已存在时，改用新的 `/tmp` 预览路径：

```bash
/Users/jinana/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  lab4/tools/render_manual.py \
  --markdown-python /opt/miniconda3/envs/tf2/bin/python \
  --output lab4/resource/lab4-operation-guide.pdf
```

支持 `--source` 指定 Markdown，`--font` 指定字体集合。当前字体为 macOS `Songti.ttc`，简体常规索引 6、粗体索引 1。换机器须核实真实宋体字体及索引，不能静默替换成黑体。

依赖 ReportLab、pypdf、Python-Markdown；这里使用两个已存在的解释器，不混入其他解释器的 site-packages。只支持本手册需要的标题、段落、单层紧凑列表、表格、代码块和行内格式；不是通用报告渲染器。PDF 链接保留可见文字，打开资料链接请使用 Markdown。

## 检查

脚本自动检查 Markdown 字节未改变、全部正文可从 PDF 提取、宋体覆盖所用字符；这些不能替代逐页目检。

```bash
mkdir -p /tmp/lab4-guide-check
pdftoppm -scale-to 1500 -png \
  lab4/resource/lab4-operation-guide.pdf /tmp/lab4-guide-check/page
pdffonts lab4/resource/lab4-operation-guide.pdf
```

逐页查看所有 PNG，确认无缺字、裁切、重叠、孤立标题、空白页及难读的代码／表格，宋体已嵌入。渲染时不得改写 Markdown 原文来迁就排版。
