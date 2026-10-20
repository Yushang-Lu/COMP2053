# 实验工作交接

截至 2026-10-20，用户已确认实验一完成。本目录仅为后续 AI 提供参考，不要求重新检查或修改已经完成的成果。

## 先找哪些资料

- `website/download.py`、`website/README.md`：网站下载工具与运行说明。
- `website/mirror/README.md`：本地网站目录；`manifest.json` 含抓取时间、页面和资源记录。镜像默认被 Git 忽略，换机器可能不存在。
- `website/mirror/pages/lab1/lab-content/index.md`：实验一要求、官方激励、报告模板和提交清单。
- `website/mirror/pages/codingstyle/codingstyle/index.md`：课程 Verilog 规范。
- `lab1/resource/`：EGO1、Minisys 手册，实验说明 PDF，原教程长图及核对笔记。
- `lab1/code/README.md`：EGO1 的操作步骤、引脚、仿真及本地验证命令。
- `lab1/report/report.md`、`lab1/report/images/`：用户亲自完成的报告及实物、仿真和电路图。
- `lab1/report/2025310599_卢语上.pdf`：已完成、已提交到仓库的最终报告。不要把历史临时目录 `output/pdf/` 当成当前正式位置。

后续实验应有自己的目录、代码、报告和约束；不要把 Lab1 的提交要求直接套到其他实验。查当前网站或平台时也不要覆盖已完成的实验成果。

## 用户偏好与踩坑记录

1. 用户非常明确：**不要改他的 Markdown 文字内容**。请求排版时，只控制字体、尺寸、间距、分页，不替换措辞、补分析、改编号或删除模板文字；有建议先提出来。
2. 审核报告与生成 PDF 是分开的阶段。用户说“等渲染要求”时不要提前生成。
3. 中文使用宋体，不做花哨封面、配色或装饰；Markdown 标题、列表、图片正常呈现，标点和下划线不能乱码。
4. 真实截图优先。代码与波形不一致，先确认实际运行的激励，不能用“应该输出什么”改造证据。
5. 复核实物照片时看实际开关与 LED，不能仅凭程序推定实验结果。学生卡属于报告要求，不要把个人信息另行发布。
6. 需要执行 Git 提交时，明确暂存范围；不要用 `git add .` 顺手包含其他改动。

## Lab1 技术经验

### 硬件和工程

- 用户确认使用 EGO1，Vivado 器件为 `xc7a35tcsg324-1`。
- SW0…SW7：`R1 N4 M4 R2 P2 P3 P4 P5`。
- mux：a 接 SW3…SW0，b 接 SW7…SW4；DIP0/T5 接 en，DIP1/T3 接 mux_sel。
- LD2_0…LD2_7：`K2 J2 J3 H4 J4 G3 G4 F6`，高电平亮；mux 使用低四位。
- 手册 PDF 第 7–8 页与课程 EGO1 映射一致。DIP 组和大拨码开关均有从 0 开始的编号，须用丝印管脚区分。
- Minisys 手册和网站的 GLD/YLD 引脚标注有冲突，不能将其映射套到 EGO1。
- mux 与译码器分别建工程，设计文件与 Simulation Sources 分开，两份 `pin.xdc` 不要混加。

### 仿真和验证

- RTL 保持组合逻辑：`always @(*)`、阻塞赋值、完整分支，不添加无关时钟或复位。
- `mux_sim.v` 保留官网 10 组激励，55 ns 结束；报告波形应覆盖禁用、加法、减法，不能只截到 30 ns。
- `mux_check.v` 是辅助穷举自检，1024 种组合；`decoder_38_sim.v` 检查 64 种组合。报告仿真顶层为 `mux_sim`，不是 `mux_check`。
- 先前已通过 Icarus Verilog 自检、官网激励的输出核对、XDC 的 Tcl 语法与端口完整性检查。它们不代替 Vivado 综合、实现、DRC 或实物测试。
- **最终报告截图的特殊情况**：实验室手抄激励在 40–45 ns 将 b=4 写成 b=8，因此截图为 8−8=0。用户已在报告说明；仓库 `mux_sim.v` 仍是官方 b=4 的版本。不要为了消除这一已解释的差异擅改报告或仿真文件，也不要宣称二者完全一致。
- 本机曾检测到 Icarus Verilog 13.0、VS Code 的 `mshr-h.veriloghdl` 扩展（支持 `.v`、`.sv`、`.xdc`），未检测到 Vivado。后续运行前应重新检查环境，不能假设工具永远存在。

### 报告清单

Lab1 要求三种上板情况（禁用、加法、减法）的照片及输入输出说明；学生卡姓名和学号可读；仿真波形及分析；RTL Schematic 和综合后 Schematic，不能用 Device 图代替。

最终 ZIP 要求 `mux.v`、实际使用的 `pin.xdc`、`学号_姓名.pdf`。不要提交整个 Vivado 工程；其他实验以各自要求为准。截止日期查提交平台，不从旧快照推断。

## 保留的 PDF 渲染工具

`render_lab1_pdf.py` 根据最后一次成功渲染的临时脚本整理，仅新增命令行参数和防覆盖保护。它不写 Markdown、不修改原图片，也不会默认覆盖最终报告。

### 安装和试用

需要 Python、ReportLab、Pillow、pypdf。建议独立虚拟环境，不改动网站下载工具的环境：

```bash
python3 -m venv /tmp/comp2053-pdf-venv
/tmp/comp2053-pdf-venv/bin/python -m pip install -r agent-notes/requirements-pdf.txt
/tmp/comp2053-pdf-venv/bin/python agent-notes/render_lab1_pdf.py \
  --output /tmp/lab1-preview.pdf
```

脚本默认读取 `lab1/report/report.md`，路径按脚本所在仓库解析，不依赖当前工作目录。输出路径必须明确指定且不能已存在；想重新试排请指定另一个新路径。没有强制覆盖选项。

字体默认为 macOS `/System/Library/Fonts/Supplemental/Songti.ttc`，简体常规字体索引 6，粗体索引 1。这只是该机器的字体集合布局；其他系统须确认真实宋体字体及索引后传入 `--font`、`--bold-font`、`--font-index`、`--bold-font-index`，不能静默用黑体替代。

### 能力边界

- **这是 Lab1 的专用布局脚本，不是 CommonMark 或完整 Markdown 引擎。**
- 支持当前报告的一号标题、中文章节、小节标签、普通文本、列表及独占一行的本地图片；保留所有文字，包括模板提示。
- 章节分页、照片 140 mm 宽、截图 165 mm 宽、A4 页边距和宋体样式均沿用 Lab1。当前报告为 5 页。
- 不解析表格、公式、代码围栏、一般链接或复杂行内格式。新实验有这些内容时要选用真正的 Markdown 渲染方案，不要硬套该脚本。
- 长图或大段落可能超过一页，需要调整渲染逻辑；不能为了排版删改原文。不要把页面数量视作固定要求。

### 验收，不能省略

脚本自动检查：Markdown 字节未变、正文文字均出现在 PDF 的可提取文本中、图片数量吻合。仍需人工视觉检查：

```bash
mkdir -p /tmp/lab1-pdf-check
pdftoppm -scale-to 1500 -png /tmp/lab1-preview.pdf /tmp/lab1-pdf-check/page
pdffonts /tmp/lab1-preview.pdf
```

逐页查看生成的 PNG，确认没有文字溢出、标点缺字、图片失真、跨页割裂或空白页；宋体应嵌入 PDF；姓名学号、波形数值和电路标注可读。文本检查不能替代图片与分页检查。**用户批准新的输出前，不替换现有最终 PDF。**
