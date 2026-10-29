# 实验 4 操作手册：数码管控制器（EGO1）

本手册用于实验室操作，不是实验报告。依据 2026-10-29 网站镜像、Lab4 课件和 EGO1 手册编写。学号为 **2025310599**，后八位 **25310599**，后两位 **99**。文中的时间点已由本地仿真核对，但实验报告仍须使用自己在 Vivado 中运行所得的真实截图与分析。

| 类别 | 要完成的内容 |
| --- | --- |
| 报告必做 | 八位轮询波形、两次消抖计数波形、两级寄存器边沿检测波形及分析；红框标记两级寄存器的 RTL 截图 |
| 实验流程必做 | Run Linter、综合、实现、生成 bit、下载并自测；不是只运行仿真 |
| 课堂必做 | 两种显示；S3 两组计数与长按；S2 暂停和继续；0 到 20 循环；S1 复位 |
| 不必额外制作 | 其他功能的报告波形、实物照片、完整综合电路截图；这些不属于当前报告要求 |

## 第 1 步：准备文件、建立一个工程

1. 带上 EGO1、可传数据的 USB 线及整个 `lab4/code/`。复制到实验室电脑的纯英文路径，例如 `D:/FPGA/lab4/code/`。
2. Vivado → **Create Project**，工程名 `segment_ctrl`，位置如 `D:/FPGA/lab4/projects/`。选 **RTL Project**，勾选 **Do not specify sources at this time**。
3. 在 **Parts** 中选择 **xc7a35tcsg324-1**，Finish。找不到时先检查 Artix-7 器件支持，不换其他器件。
4. **Add Sources → Add or create design sources**，加入下表的四个设计文件。
5. **Add Sources → Add or create simulation sources**，加入三个 `_tb.v` 文件。
6. **Add Sources → Add or create constraints**，只加入本实验 `pin.xdc`。不要混入旧实验或 Minisys 约束。
7. 在 **Design Sources** 中右击 `segment_ctrl` → **Set as Top**。另建 `evidence/` 保存自己的截图。

| 文件 | 加入位置／用途 |
| --- | --- |
| segment_ctrl.v | Design Sources；唯一上板顶层 |
| led_ctrl_unit.v | Design Sources；扫描与段码译码 |
| key_debounce.v | Design Sources；S2、S3 消抖 |
| edge_detect.v | Design Sources；两级寄存器边沿检测 |
| led_ctrl_unit_tb.v | Simulation Sources；轮询波形 |
| segment_ctrl_tb.v | Simulation Sources；消抖计数波形 |
| edge_detect_tb.v | Simulation Sources；边沿检测波形 |
| pin.xdc | Constraints；EGO1 管脚和 100 MHz 时钟 |

**检查点：四个设计文件、三个仿真文件、一份约束；testbench 不在 Design Sources。**

## 第 2 步：三个仿真的通用操作

1. 在 **Simulation Sources** 中右击当前需要的 `_tb` 模块 → **Set as Top**。不要改 Design Sources 的顶层。
2. **Run Simulation → Run Behavioral Simulation**；打开后点击 **Run All**，等到 `$finish`。切换到另一个 testbench 前先 **Close Simulation**，重新设置仿真顶层并启动。
3. 在 **Scope** 选择下文指定实例，在 **Objects** 选信号 → 右击 **Add to Wave Window**。顶层输入可在 testbench 所在层添加。
4. 添加内部信号后，点击 **Restart** 回到 0，再 **Run All**，保证有完整历史；修改源代码后则先 **Relaunch Simulation** 重新编译，再运行。
5. **Zoom Fit** 看全程，再放大指定时间段；拉宽信号名栏和波形区。保存波形配置可选，不是报告提交要求。

**所有总线都不展开。学号数据 `display` 设为 Hexadecimal；其他多位信号保持默认进制。** 两位计数采用 BCD，每个四位字段表示一个十进制数位，例如总线 `20` 对应数码管显示“20”，不是二进制计数值的十进制解释。

| 仿真顶层 | Run All 结束时间 | 建议截图范围 |
| --- | --- | --- |
| led_ctrl_unit_tb | 1820 ns | 100 至 1720 ns；含两轮完整扫描 |
| segment_ctrl_tb | 900 ns | 0 至 900 ns；太密可分两张 |
| edge_detect_tb | 162 ns | 0 至 162 ns |

仿真时钟周期为 10 ns。扫描上限覆盖为 9，即每 10 个时钟换一位；顶层仿真的消抖上限为 3，即连续稳定 4 个采样时钟，定时上限为 19，即每 20 个时钟计数。**覆盖仅写在 testbench 中，不能把这些仿真值用作上板默认值。**

## 第 3 步：轮询波形（报告第一部分）

仿真顶层选 **led_ctrl_unit_tb**。在 `led_ctrl_unit_tb/u_led_ctrl_unit` 加入 `scan_index`、`display_digit`，与顶层信号一起排列为：

```text
clk, rst, display, scan_index, display_digit,
led_en, led_cx, led_cx1
```

1. 将 `display` 设为 **Hexadecimal**，确认固定为 `25310599`；它是八个四位字符，不是将学号转换为二进制整数。
2. Run All 到 1820 ns，截取 **100 至 1720 ns**。轮询方向是 DK0 到 DK7，显示的空间顺序仍为左侧高位、右侧低位。
3. 对照下表检查。每个完整槽位 100 ns，八位一轮 800 ns；没有选中的那组段选为 `00`，段序均为 `{CA,CB,CC,CD,CE,CF,CG,DP}`。

| 位置 | 字符 | led_en | led_cx（右） | led_cx1（左） |
| --- | --- | --- | --- | --- |
| DK0 | 9 | 01 | F6 | 00 |
| DK1 | 9 | 02 | F6 | 00 |
| DK2 | 5 | 04 | B6 | 00 |
| DK3 | 0 | 08 | FC | 00 |
| DK4 | 1 | 10 | 00 | 60 |
| DK5 | 3 | 20 | 00 | F2 |
| DK6 | 5 | 40 | 00 | B6 |
| DK7 | 2 | 80 | 00 | DA |

表内位选、段选为十六进制。115 ns 进入 DK1，之后每隔 100 ns 切换；815 ns 回到 DK0。复位在 20 ns 释放，最初的 DK0 槽位不是完整 100 ns，因此截图选后续完整轮询。相邻字符相同时段码可以不变，不能把“不跳变”判为失败。

分析应说明 `display` 固定、所取四位字符随扫描位置变化，位选与对应段码一起决定当前字符；EGO1 两组段线独立且高有效。**不要把整个 display 改成随时间依次显示单个数字，也不要遗漏左组段选。**

## 第 4 步：消抖计数波形（报告第一部分）

关闭仿真，仿真顶层切换为 **segment_ctrl_tb**。在 `segment_ctrl_tb/u_segment_ctrl` 添加内部信号，并按以下顺序排列：

```text
clk, rst, button_s3, s3_raw_press, s3_clean,
s3_clean_press, count_raw, count_clean
```

1. Run All 到 **900 ns**。该激励只有两次物理按键动作，每次均含按下、释放抖动，并包含稳定长按。
2. 建议先截 **0 至 900 ns**；若文字太密，分别截 **40 至 400 ns**、**430 至 850 ns**，每张保留两组计数和输入波形。
3. 按实际波形核对下表，再写分析；不要把本表直接当作自己的截图。

| 观察项 | 本激励对应时间／结果 |
| --- | --- |
| 第一次稳定按下 | S3 最后一次按下抖动在 110 ns；s3_clean 在 165 ns 变高 |
| 第一次消抖计数 | s3_clean_press 在 175 至 185 ns 为高；count_clean 在 185 ns 变为 01 |
| 第一次释放确认 | 释放抖动结束于 310 ns；s3_clean 在 365 ns 变低，不增加消抖计数 |
| 第二次稳定按下 | 最后一次按下抖动在 510 ns；s3_clean 在 565 ns 变高 |
| 第二次消抖计数 | 脉冲在 575 至 585 ns 为高；count_clean 在 585 ns 变为 02 |
| 最终结果 | 900 ns 结束时 count_raw=08，count_clean=02；长按不持续增加 |

未消抖计数在 **75、95、125、315、465、495、525、735 ns** 增加。释放抖动也会产生额外上升沿，所以未消抖组不保证等于物理按键次数。消抖先经过两级同步，再确认连续稳定采样，之后经边沿检测和计数寄存器更新，不能把全部延迟都说成“4 个时钟”。

**检查点：清楚展示两次消抖计数及抖动差异，分析包含长按只计一次和释放不增加消抖计数。**

## 第 5 步：边沿检测波形、Linter 与 RTL

### 5.1 边沿检测波形（报告第二部分）

关闭仿真，仿真顶层选 **edge_detect_tb**。在 `edge_detect_tb/u_edge_detect` 加入 `sig_r0`、`sig_r1`，按 `clk、rst、signal、sig_r0、sig_r1、pos_edge` 排列；Run All 到 **162 ns**，截取全程。

- `signal` 在 32 ns 上升；`sig_r0` 在 35 ns 采到 1，`sig_r1` 在 45 ns 才变为 1。因此 `pos_edge = sig_r0 & ~sig_r1` 在 **35 至 45 ns** 为高。
- 第二次输入上升在 102 ns，输出脉冲为 **105 至 115 ns**。输入持续为高时不再产生新脉冲；下降沿不产生上升沿脉冲。
- 两级寄存器在同一个时钟沿更新，非阻塞赋值使第二级取得第一级的旧值。实际输入等待下个采样沿的时间取决于输入相位，不要写成从输入跳变起固定延迟 10 ns。

### 5.2 Run Linter（实验流程必做）

1. 关闭仿真，确认 Design Sources 顶层仍是 **segment_ctrl**。
2. **RTL Analysis → Run Linter**；逐项查看结果，修正语法、位宽、锁存器或多驱动问题，再运行。
3. 无法消除的提示先核对原因，不通过降低严重级别或随意改约束来隐藏。实验室版本若没有该菜单，向老师确认可用版本或替代流程，不能把 Icarus 编译当作已完成 Run Linter。

### 5.3 边沿检测 RTL（报告第三部分）

1. **RTL Analysis → Open Elaborated Design → Schematic**。
2. 在层次中找到顶层下的 **u_s3_raw_edge**；双击或展开该实例，查看模块内部 RTL，而不是只截一个黑盒。
3. 找到 `sig_r0`、`sig_r1` 两级寄存器及它们的串联连接，调整缩放，让寄存器名称、连线和输出逻辑清楚。
4. 保存真实截图，用图片标注工具加**红框，准确圈出两级级联寄存器**。只加标注，不改动电路内容。

**报告顺序：轮询与消抖计数 → 边沿检测波形 → 红框 RTL。无需再制作完整综合电路截图。**

## 第 6 步：综合、实现并下载

1. 确认 `pin.xdc` 已启用，设计顶层为 `segment_ctrl`，没有在工程参数中保留仿真覆盖值。
2. **Run Synthesis → Run Implementation → Generate Bitstream**。查看 Messages、DRC 和时序结果；错误必须解决，时序失败也不能当成通过。
3. EGO1 使用 **100 MHz、P17**，`create_clock` 必须保留；它是时序约束，不产生时钟。不要换成课件中其他板型的管脚。
4. 连接供电和 USB/JTAG，**Open Hardware Manager → Open Target → Auto Connect → Program Device**，选择刚生成的 `segment_ctrl.bit`。
5. 下载后按下并松开 **S1**，再按第 7 步自测。普通 S1/R17 才是本设计复位，不是专用 FPGA_RESET/P15。

| 上板参数 | 默认值与含义 |
| --- | --- |
| SCAN_CNT_MAX | 99,999；100,000 个时钟，即每位 1 ms，整屏 8 ms |
| DEBOUNCE_CNT_MAX | 1,999,999；同步后连续稳定 2,000,000 次采样，即 20 ms |
| TICK_CNT_MAX | 9,999,999；10,000,000 个有效运行时钟，即 0.1 s |

消抖还包含同步及后续检测延迟。暂停期间保留定时进度，继续后先走完剩余时间；无需额外增加启动按键。这里仅通过 Program Device 配置 FPGA，未执行 Flash 固化；断电后需重新下载本实验 bit。

## 第 7 步：课堂验收前自测（必做）

SW0 指大拨码开关的 **SW0/R1**，不是 DIP 组的 T5。上拨为 1、下拨为 0；数码管从左到右为 DK7 至 DK0。

| 操作 | 应核对的现象 |
| --- | --- |
| 按住 S1，再松开 | 按住时全部熄灭；松开后恢复显示，两组按键计数从 00 开始，定时计数自动运行 |
| SW0 上拨 | 左到右稳定显示 25310599，无颠倒或缺段 |
| SW0 下拨 | 从左到右为 99、未消抖 S3 计数、消抖 S3 计数、0 至 20 定时计数 |
| 多次短按 S3 | 消抖组每次有效按键加 1；未消抖组可能多计。每次按住和松开均留至少 20 ms |
| 长按 S3 再松开 | 消抖组只增加一次；未消抖组稳定按住期间不连续增加，但按下／松开抖动可能多计 |
| 按一下 S2 | 最右两位暂停；S3 两组计数仍能使用 |
| 再按一下 S2 | 最右两位继续；长按 S2 不应反复启停 |
| 持续观察最右两位 | 00 到 20 后回到 00；每步约 0.1 s，不能用肉眼声称精确测得该间隔 |
| 切换 SW0 再返回 | 仅改变显示内容，S3 计数、运行／暂停状态不因切换清零；运行中的定时计数继续 |

未消抖组不一定每次都会多计，真实机械抖动取决于按键和操作；若一次没有出现差异，可以多试几次，不能伪造现象。两组 S3 计数均在 99 后回到 00；本地已验证该边界，课堂如老师要求再演示，不必为此准备额外报告截图。

**提前下载 bit 并自行确认全部功能，再举手等老师检查。** 检查日期以当次课程通知为准，不将课件里的“下周”擅自换算为日期。

## 第 8 步：整理报告和提交

1. 打开现有 `lab4/report/report.md`，填写个人信息，按模板顺序加入自己的三类波形、分析和红框 RTL 图。模板原文不要因排版而删改。
2. 导出 `2025310599_卢语上.pdf`，逐页检查宋体、波形数值、时间刻度和红框是否清晰。
3. 将**四个设计文件、三个 testbench、实际使用的 pin.xdc、个人报告 PDF** 打成 ZIP，上传课程平台并确认成功。
4. 不打包整个 Vivado 工程、build、VCD、临时自检文件、老师课件或本手册。保存 bit 供课堂下载，当前课后提交清单不要求额外打包 bit。

## 可选：本地复验与快速排查

本地命令不是新增报告任务。仓库根目录运行下列命令；要求已有 Icarus Verilog，所有产物保存在已忽略的 `build/`：

```bash
mkdir -p lab4/code/build
for top in led_ctrl_unit_tb segment_ctrl_tb edge_detect_tb; do
  iverilog -g2005 -Wall -s "$top" \
    -o "lab4/code/build/$top.vvp" lab4/code/*.v &&
  vvp "lab4/code/build/$top.vvp" || break
done
```

三个 testbench 不导出 VCD、不打印 PASS，正常输出 `$finish` 和结束时间。Vivado 自带波形显示不需要 VCD，也不要照旧手册添加 `+vcd`。

| 问题 | 优先检查 |
| --- | --- |
| 仿真显示另一项内容 | 是否改了 Simulation Sources 的顶层，并关闭旧仿真重新启动 |
| 找不到内部信号／没有历史 | Scope 是否选到指定实例；添加后 Restart，再 Run All |
| 修改代码后结果没变 | 使用 Relaunch 重新编译，不是只 Restart |
| 左右颠倒、缺段或全灭 | EGO1 专用 XDC、两组段线、段序与高有效；S1 是否按住 |
| 上板计数太快或显示异常 | 不要把 testbench 的 9／3／19 设为设计默认值 |
| S2 没有切换 | 按下、释放都留够时间；核对 S2/R15，不是 S3/V1 |
| 找不到开发板 | 可传数据的 USB 线、供电、驱动、Auto Connect |

**验证边界：本地仿真、XDC Tcl 检查不等于 Vivado Linter、综合、实现、时序或实物通过。** S2/S3 消抖前有同步器，但未消抖通道按课程要求直接采用两级寄存器边沿检测；模式输入和异步复位释放未额外同步。这是课程演示设计，不宣称具有完整的生产级跨时钟域防护。

资料入口：[实验要求](../../website/mirror/pages/lab4-segment-ctrl/lab-content/index.md)、[实验原理与 EGO1 管脚](../../website/mirror/pages/lab4-segment-ctrl/segment-ctrl-principle/index.md)、[Run Linter](../../website/mirror/pages/vivado/s9-linter/index.md)、[Verilog 规范](../../website/mirror/pages/codingstyle/codingstyle/index.md)、[老师课件](lab4-数码管控制器.pdf)、[EGO1 手册](../../lab1/resource/Ego1开发板硬件手册V2.pdf)。EGO1 手册版本为 2018.04 ver2.2；PDF 第 4 页为时钟、第 6 页为按键、第 7 页为拨码、第 8 至 9 页为数码管。网站镜像可能不随 Git 分发；资料链接请在 Markdown 中打开。
