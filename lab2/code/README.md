# 实验 2：EGO1 代码与操作说明

硬件：**EGO1**；Vivado 器件：**`xc7a35tcsg324-1`**。两份 XDC 都只适用于 EGO1，不能与 Minisys 或 Lab1 的约束混用。

从头操作请看 [手把手实验手册](../resource/process.md)。该手册不是实验报告，不含虚构的实物照片或 Vivado 截图。

## 文件与工程

| 工程 | 文件 | 添加位置 / 顶层 |
| --- | --- | --- |
| dff | `dff/dff.v` | Design Sources / `dff` |
| dff | `dff/dff_sim.v` | Simulation Sources / `dff_sim` |
| dff | `dff/pin.xdc` | Constraints |
| reg8file | `reg8file/reg8file.v` | Design Sources / `reg8file` |
| reg8file | `reg8file/testbench.v` | Simulation Sources / `testbench` |
| reg8file | `reg8file/pin.xdc` | Constraints |

**建两个独立工程，不要递归导入整个 code 目录。** `dff_check.v`、`reg8file_check.v` 是辅助自检，不是报告截图的仿真顶层。

`dff_sim.v` 保留官网原始激励的数值、顺序和延时，100 ns 结束；仿真模块更名为与文件一致的 `dff_sim`，移除注释并增加可选 VCD 导出，不改变激励。`testbench.v` 为本次自行编写的报告仿真，100 ns 结束。两个报告仿真均只产生激励并支持可选 VCD 导出，不计数、不自动检查、不打印 PASS；自动验证由独立自检文件和 `check_waveforms.py` 完成。

## 功能

- `dff`：`clr=1` 时异步清零，优先于 `en`；否则只在 `clk` 上升沿且 `en=1` 时采样 `d`，禁用时保持。
- `reg8file`：8 个 8 位寄存器，异步清零全部寄存器；上升沿写入 `regfile[wsel]`；组合读取 `regfile[rsel]`，读取不受 `en` 控制。
- 同地址读写时，上升沿前读取旧值，上升沿完成非阻塞赋值后读取新值。没有额外旁路，也没有把 0 号寄存器固定为零。
- RTL 不含 `initial` 或延时；时序赋值使用 `<=`，组合赋值使用 `=`。保持分支显式自赋值；复位循环是固定 8 次的硬件展开。

## 引脚速查

所有 I/O 使用 `LVCMOS33`，时钟 `P17` 的周期约束为 10 ns。

| 信号 | D 触发器 | 寄存器文件 |
| --- | --- | --- |
| clk | 100 MHz 晶振 / P17 | 相同 |
| clr | 普通按键 S1 / R17 | 相同 |
| en | SW7 / P5 | 相同 |
| d | SW0 / R1 | DIP7…DIP0 对应 d[7:0] |
| wsel | 无 | SW2…SW0 |
| rsel | 无 | SW5…SW3 |
| q | LD2_0 / K2 | LD2_7…LD2_0 |
| 未使用开关 | SW1…SW6、DIP 组 | SW6，保持向下即可 |

寄存器文件按位映射（从低位到高位）：

| 位号 | d：DIP 管脚 | q：LD2 管脚 |
| --- | --- | --- |
| 0 | T5 | K2 |
| 1 | T3 | J2 |
| 2 | R3 | J3 |
| 3 | V4 | H4 |
| 4 | V5 | J4 |
| 5 | V2 | G3 |
| 6 | U2 | G4 |
| 7 | U3 | F6 |

写选择的第 0、1、2 位管脚是 R1、N4、M4，代码端口为 `wsel[2:0]`。读选择的第 0、1、2 位管脚是 R2、P2、P3。DIP 位号以管脚丝印识别，不把塑料外壳的 1…8 编号直接当作 d[1]…d[8]。

依据：EGO1 手册 2018.04 ver2.2，PDF 第 4 页时钟、第 6 页按键、第 7 页开关、第 8 页 LED；以及 2026-10-20 下载的课程 Lab2 页面。

## 一键本地验证

依赖：`iverilog`、`vvp`、`tclsh`、`python3`。从仓库根目录执行：

```bash
sh lab2/code/run_checks.sh
```

脚本显式指定每个仿真顶层，错误即停止；所有编译和波形产物写入已忽略的 `lab2/code/build/`。不需要 Vivado、Python 第三方库或联网安装。

2026-10-21 简化报告仿真后，使用本机 Icarus Verilog 13.0 重新运行：

| 验证项 | 结果 |
| --- | --- |
| dff_check | 16 组状态/输入组合，65 次检查通过 |
| reg8file_check | 8 地址 × 256 数据，2,058 次写入，22,617 次检查通过 |
| testbench | 报告激励运行至 100 ns，由独立 VCD 检查核对波形 |
| XDC | dff 5 端口、reg8file 25 端口，管脚唯一、电平标准和时钟定义通过 |
| VCD | 两个报告仿真的输入/输出转换时刻与 100 ns 结束时间通过核对 |

自检覆盖初始清零、使能保持、全部地址/数据、同地址读写、未选寄存器保持、无时钟边沿的异步读与清零、复位优先于写入、复位后重新写入。不等于穷举所有 64 位存储状态和所有时间序列。

Icarus 的 `@* is sensitive to all 8 words in array 'regfile'` 是组合读对整个数组敏感的提示，不是测试失败。输出中任何 `FATAL` 或非零退出码都需要处理。

**验证边界：** 本机未检测到 Vivado，未执行综合、实现、时序签核或上板测试。Tcl 检查使用端口映射桩，不调用 Vivado 器件数据库；不能证明布线和时序通过。XDC 定义了管脚和内部时钟，但没有虚构人工开关相对时钟的外部延时；人工输入及异步复位释放也未加同步器/去抖。当前代码针对课程规定的演示电路，不作为生产级异步输入处理方案。

## 提交范围

课程 ZIP 只放：

```text
dff/dff.v
dff/pin.xdc
reg8file/reg8file.v
reg8file/pin.xdc
reg8file/testbench.v
学号_姓名.pdf
```

不要提交本操作手册充当报告，不要把 build、自检脚本、VCD、整个 Vivado 工程打包。截止时间以平台为准。
