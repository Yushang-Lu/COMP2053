# Lab5 手册和状态图工具

`render_manual.py` 从 Lab4 的 Markdown＋ReportLab 工具独立适配，只处理本手册使用的元素；按操作阶段分页，不是通用报告渲染器。它不改写 Markdown、不覆盖已有 PDF，并检查正文提取完整性及宋体字形。

从仓库根目录运行；以下解释器在本机已验证可用：

```bash
/Users/jinana/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  lab5/tools/render_manual.py \
  --markdown-python /opt/miniconda3/envs/tf2/bin/python \
  --output /tmp/lab5-guide-new-preview.pdf
```

默认源文件为 `../resource/process.md`。正式输出在 `../resource/lab5-operation-guide.pdf`；已有文件须先生成新的预览并检查，不直接覆盖。依赖 ReportLab、pypdf、Python-Markdown；可用同一环境安装全部依赖，也可像上面分别指定 Markdown 解释器。

中文为 macOS `Songti.ttc`（简体常规索引 6、粗体索引 1）。跨机器使用时先核实字体及索引，不静默换黑体。每次渲染还需用 `pdftoppm` 生成图片，逐页检查；自动文字校验不能替代目检。

`render_state_diagram.py` 用同一份节点和转移数据生成 `.drawio` 与 SVG，支持额外输出用于目检的 PDF；生成的不是仿真波形或实验测量。现有图不覆盖，复验可指定新临时目录：

```bash
/Users/jinana/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  lab5/tools/render_state_diagram.py \
  --output-dir /tmp/lab5-diagram-new \
  --preview-pdf /tmp/lab5-state-new.pdf
```

图中的状态名、编码、条件与 RTL 对应。输出说明特意写明：状态圆内是时序赋值规则，dout 相对状态与位索引更新晚一拍；不能删去该说明后将其误读为无延迟组合输出。

验证入口及实际通过结果见 `../code/README.md`。工具和补充测试不需要加入 Vivado，也不属于实验报告要求的代码附件。
