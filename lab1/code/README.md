# 实验 1：EGO1 代码与操作说明

使用开发板 **EGO1**，Vivado 器件选择 **`xc7a35tcsg324-1`**。这里的约束不能用于 Minisys。

## 文件选择

| 文件 | 用途 | Vivado 添加位置 |
| --- | --- | --- |
| `mux.v` | 本实验要提交的组合逻辑设计 | Design Sources，顶层 `mux` |
| `mux_sim.v` | 与官网相同的 10 组激励，供报告截图 | Simulation Sources，顶层 `mux_sim` |
| `pin.xdc` | mux 的 EGO1 引脚约束 | Constraints |
| `mux_check.v` | 独立的 1024 组合穷举自检 | 可选 Simulation Sources，顶层 `mux_check` |
| `decoder/decoder_38.v` | 前置 3–8 译码器练习 | **单独工程**的 Design Sources |
| `decoder/decoder_38_sim.v` | 译码器 64 组合自检 | 译码器工程的 Simulation Sources |
| `decoder/pin.xdc` | 译码器的 EGO1 引脚约束 | **仅**译码器工程的 Constraints |

**不要递归把此目录所有文件加入同一个工程。** 两份 `pin.xdc` 属于不同设计；仿真文件不要放到 Design Sources。正式报告使用 `mux_sim`，不是 `mux_check`。

设计采用组合逻辑，不需要时钟或复位，也没有锁存器所需的保持分支。`mux` 在 en=0 时输出 1111；en=1 时选择加法或减法，赋给 4 位输出时自然只保留低 4 位。LED 高电平亮，因此不额外取反。

## mux 的开关与 LED

本次约定：**DIP0=T5 为 en，DIP1=T3 为 mux_sel**。这里的 DIP0/1 指手册和课程网站中 DIP 组的第 0/1 位，**不是**大拨码开关 SW0/1。请根据板上 `T5`、`T3` 标注识别，别只按开关塑料外壳上的序号猜。

| 代码端口 | EGO1 器件 | FPGA 管脚 |
| --- | --- | --- |
| `en` | SW_DIP0 | T5 |
| `mux_sel` | SW_DIP1 | T3 |
| `input_a[0]` | SW0 | R1 |
| `input_a[1]` | SW1 | N4 |
| `input_a[2]` | SW2 | M4 |
| `input_a[3]` | SW3 | R2 |
| `input_b[0]` | SW4 | P2 |
| `input_b[1]` | SW5 | P3 |
| `input_b[2]` | SW6 | P4 |
| `input_b[3]` | SW7 | P5 |
| `output_c[0]` | LD2_0 | K2 |
| `output_c[1]` | LD2_1 | J2 |
| `output_c[2]` | LD2_2 | J3 |
| `output_c[3]` | LD2_3 | H4 |

板子正面向上、电源接口置于顶部、拨码开关置于底部。按课程说明，上拨为 1，下拨为 0。读取结果时按 **LD2_3 → LD2_0** 的顺序组成二进制数；不要看错另一组 LD1。

依据：[EGO1 硬件手册](../resource/Ego1开发板硬件手册V2.pdf) PDF 第 7–8 页（印刷页码 6–7），以及[课程约束说明](../../website/mirror/pages/vivado/s4-add-constraints/index.md)。手册中 LED2、D2 和课程中 LD2 指这里使用的第二组 LED。

## 先完成译码器练习

1. 单独创建译码器 RTL 工程，器件也选 `xc7a35tcsg324-1`。
2. Design Sources 只添加 `decoder/decoder_38.v`，设计顶层为 `decoder_38`。
3. Constraints 只添加 `decoder/pin.xdc`；可添加 `decoder_38_sim.v` 做自检。
4. 综合、实现、生成 bit 并下载，按下表自行上板验证；之后再做 mux 工程。

译码器的使能不是 DIP：`en[2:0]` 接 **SW7、SW6、SW5**，`data_in[2:0]` 接 **SW2、SW1、SW0**，输出接 LD2_7…LD2_0。

| SW7…SW5 | SW2…SW0 | 预期输出 | 预期 LED |
| --- | --- | --- | --- |
| 000 | 任意 | 11111111 | LD2 八灯全亮 |
| 100 | 000 | 11111110 | LD2_0 灭，其余亮 |
| 100 | 001 | 11111101 | LD2_1 灭，其余亮 |

译码器仅为官网要求的前置练习，不在本次提交清单中。

## mux 的 Vivado 步骤

1. **Create Project**：工程名必须为 `mux`，使用英文路径，选择 RTL Project 和器件 `xc7a35tcsg324-1`。
2. 加入 `mux.v`（Design Sources）、`mux_sim.v`（Simulation Sources）和本目录的 `pin.xdc`（Constraints）。设计顶层 `mux`，仿真顶层 `mux_sim`。
3. **Run Simulation → Run Behavioral Simulation → Run All**。显示 `en`、`mux_sel`、`input_a`、`input_b`、`output_c`；缩放到 **0–55 ns**。若添加信号时仿真已结束，Restart 后 Run All。
4. 保存带信号名、时间轴和数值的真实波形截图，可分两张，不能只截 0–30 ns。根据下表和实际波形写分析。
5. **RTL Analysis → Open Elaborated Design → Schematic**，保存 RTL 电路图。
6. **Run Synthesis → Open Synthesized Design → Schematic**，保存综合后电路图，不能用 Device 图代替。
7. **Run Implementation → Generate Bitstream**。有错误先修复，不能通过降低未约束端口等 DRC 错误等级来跳过问题。
8. 连接 EGO1 数据线并供电，**Open Hardware Manager → Open Target → Auto Connect → Program Device**，选本 mux 工程生成的 `mux.bit`。
9. 按后面的三种情况测试、拍照，写真实观察结果。用完先关板上电源，再拔线。

`mux_sim.v` 保留官网激励和值、延时及 55 ns 结束时刻，仅增加可选的 `+vcd` 波形导出，默认不导出。它**不会输出穷举 PASS**；想做穷举自检时另外运行 `mux_check`，之后把仿真顶层切回 `mux_sim` 再截图。

### 官网激励与预期结果

| 时间/ns | en | mux_sel | a（十进制） | b（十进制） | output_c（二进制） |
| --- | --- | --- | --- | --- | --- |
| 0–5 | 0 | 1 | 2 | 1 | 1111 |
| 5–10 | 0 | 0 | 2 | 1 | 1111 |
| 10–15 | 1 | 0 | 1 | 0 | 0001 |
| 15–20 | 1 | 0 | 1 | 1 | 0010 |
| 20–25 | 1 | 0 | 8 | 4 | 1100 |
| 25–30 | 1 | 0 | 4 | 1 | 0101 |
| 30–35 | 1 | 1 | 1 | 0 | 0001 |
| 35–40 | 1 | 1 | 1 | 1 | 0000 |
| 40–45 | 1 | 1 | 8 | 4 | 0100 |
| 45–55 | 1 | 1 | 4 | 1 | 0011 |

### 三种上板照片

下表的开关序列均从高位到低位书写。SW7…SW0 = **b 的四位 + a 的四位**，不是仿真中的 `{en, mux_sel, input_a, input_b}` 排列。

| 情况 | DIP0 / en | DIP1 / mux_sel | SW7…SW0 | 预期输出 LD2_3…LD2_0 | 亮灯 |
| --- | --- | --- | --- | --- | --- |
| 禁用，a=2，b=1 | 0 | 0 | 0001_0010 | 1111 | LD2_0、1、2、3 |
| 加法，2+1=3 | 1 | 0 | 0001_0010 | 0011 | LD2_0、1 |
| 减法，5−3=2 | 1 | 1 | 0011_0101 | 0010 | LD2_1 |

禁用时还要改变 a、b，确认四灯始终全亮。每种情况拍照时，将学生卡与开发板放在一起，确保姓名、学号、开关状态和 LED 结果清晰；照片及分析必须来自实测。

## 本地验证

本机已安装支持 `.v`、`.sv`、`.xdc` 的 VS Code Verilog-HDL/SystemVerilog 扩展，以及 Icarus Verilog。编辑器语法高亮不等于 Vivado 综合或自动生成电路图。

在 `lab1/code/` 执行以下命令（需要 `iverilog` 和 `vvp`）：

```bash
mkdir -p build
iverilog -g2012 -Wall -s mux_check -o build/mux_check.vvp mux.v mux_check.v
vvp build/mux_check.vvp
iverilog -g2012 -Wall -s decoder_38_sim -o build/decoder_38_sim.vvp decoder/decoder_38.v decoder/decoder_38_sim.v
vvp build/decoder_38_sim.vvp
iverilog -g2012 -Wall -s mux_sim -o build/mux_sim.vvp mux.v mux_sim.v
(cd build && vvp mux_sim.vvp +vcd)
```

最后一条产生 `build/mux_sim.vcd`。前两项自检成功分别显示：

```text
PASS: mux, 1024 combinations checked.
PASS: decoder_38, 64 combinations checked.
```

2026-10-13 已运行以上验证，穷举全部通过，且已从 VCD 核对官网 10 组激励的实际输出和 55 ns 结束时间。另已检查两份 XDC 的 Tcl 语法、14 个端口映射、引脚无重复及 LVCMOS33 设置。**这不等于通过 Vivado 器件检查、综合、实现或实物测试**；本机未检测到 Vivado，这些步骤要在实验室完成。

## 提交

将本目录的 `mux.v`、本目录的 **mux 专用** `pin.xdc` 和完成的 `学号_姓名.pdf` 放在 ZIP 根目录。报告需要三种上板结果及文字说明、仿真波形及分析、RTL 图和综合后 Schematic。不要把译码器约束、整个 Vivado 工程或本地 build 文件夹混进去。

代码应读懂后再使用；报告按自己的实测材料撰写，不把本说明或 AI 生成分析原样当作实验记录。
