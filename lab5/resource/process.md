# 实验 5 操作手册：状态机与 UART 发送（EGO1）

本手册用于实验室操作，不是实验报告。依据 2026-11-05 网站镜像、Lab5 课件及 EGO1 硬件手册编写。发送内容为 **hitsz2025310599**，共 15 个字符，不附加回车或换行。本文时间窗来自本地 Icarus 仿真；报告必须使用自己在 Vivado 和串口软件中获得的真实截图。

| 类别 | 要完成的内容 |
| --- | --- |
| 报告必做 | 串口接收截图；电子状态转移图；官方仿真通过的 Tcl Console 截图；完整数据帧波形及分析 |
| 实现必做 | 建工程、官方仿真、综合、实现、生成 bit、下载与串口接收测试 |
| 课上检查 | 实验 5 无单独课上检查，不沿用 Lab4 的检查项目 |
| 可选／排障 | UART 回环、额外本地验证、Run Linter、串口分包超时调整 |
| 不必额外制作 | 学生卡、实物照片、RTL 电路图、综合电路图；当前报告不要求这些内容 |

## 第 1 步：建立工程、加入文件

1. 准备 EGO1、可传数据的 USB 线和整个 `lab5/code/`。复制到实验室电脑纯英文路径，例如 `D:/FPGA/lab5/code/`，另建 `evidence/` 保存截图。
2. Vivado → **Create Project**，工程名 `uart_top`，工程位置如 `D:/FPGA/lab5/projects/`。选 **RTL Project**，勾选 **Do not specify sources at this time**。
3. 在 **Parts** 中选择 **xc7a35tcsg324-1**，Finish。找不到器件先检查 Artix-7 支持，不改选其他芯片。
4. 按下表通过 **Add Sources** 分别添加文件。在 **Design Sources** 中右击 `uart_top` → **Set as Top**。

| 文件 | 加入位置／用途 |
| --- | --- |
| uart_top.v | Design Sources；唯一上板顶层，产生字符 data 与单周期 valid |
| uart_send.v | Design Sources；四状态、三段式 UART 发送器 |
| uart_send_tb.v | Simulation Sources；网站提供的原始 testbench，不修改 |
| pin.xdc | Constraints；仅用于 EGO1 的时钟、复位与串口发送 |

**检查点：两个设计文件、一个仿真文件、一份约束。** 不加入 `verification/` 的辅助测试，不混入旧实验约束。报告模板中的 `uart_senf_tb.v` 是拼写笔误，实际文件和仿真模块均为 `uart_send_tb`。

约束为：`clk → P17`，S1 高有效异步复位 `rst → R17`，`uart_tx → T4`；全部 LVCMOS33。保留 `create_clock` 的 10 ns 周期。硬件手册串口名称从转换芯片侧标注，T4 括号中明确是 FPGA 发送端；不要接成接收脚 N5。

## 第 2 步：官方仿真与通过截图

1. 在 **Simulation Sources** 中右击 `uart_send_tb` → **Set as Top**；不要改变设计顶层 `uart_top`。
2. **Run Simulation → Run Behavioral Simulation**。点击 **Run All**，等到 `$finish`，不要只看默认运行的 1000 ns。
3. 五个用例分别为 `A5、3C、FF、00、5A`。Tcl Console 应出现 **All tests passed successfully!**，无 Error 或 failed；截取通过信息。Icarus 本地结束时间约为 **5.51010335 ms**，Vivado 显示精度可不同。
4. 不通过时先确认仿真顶层、设计文件和官方 testbench 没有混用旧版本；不要改测试激励来让结果通过。

**这张通过截图是报告必需材料。** 本机的 Icarus 日志不能代替 Vivado Tcl Console 截图。

## 第 3 步：完整数据帧波形与分析

在 **Scope** 选择 `uart_send_tb/u_uart_send`，从 **Objects** 加入内部信号，与顶层信号按以下顺序排列：

```text
clk, rst, valid, data, data_reg,
current_state, next_state, bit_count, bit_index, dout
```

1. `data`、`data_reg` 设为 **Hexadecimal**；状态设为 **Binary**；两个计数信号设为 **Unsigned Decimal**。总线不必展开。
2. 新增波形信号后 **Restart → Run All**，确保内部信号具有完整历史。修改源代码后用 **Relaunch Simulation** 重新编译。
3. **Zoom Fit** 后放大到 **0～1,042,500 ns**，截取第一个 `A5` 数据帧，包含复位、valid、起始位、8 个数据位、停止位和回到空闲。
4. 拉宽信号名称栏与波形区域。全帧尺度看不清单周期 valid 或现态／次态差异时，另截 **100～160 ns** 和 **104,260～104,320 ns** 的局部图；不能用局部图代替完整帧。

| 第一个 A5 帧 | 本地核对的时间／含义 |
| --- | --- |
| 接收请求 | 120～130 ns：valid 为 1；125 ns 锁存 A5 并进入 START |
| 起始位 | dout 在 135～104,295 ns 为 0 |
| 数据位 | 104,295～937,575 ns；低位先发：1、0、1、0、0、1、0、1 |
| 停止位 | 937,575～1,041,735 ns；dout 为 1，之后保持空闲高电平 |
| 位宽／帧长 | 每位 104,160 ns，即 10416 个时钟；完整 10 位为 1,041,600 ns |

状态编码：`IDLE=00、START=01、DATA=10、STOP=11`。`bit_count` 每位从 0 数到 10415；DATA 中 `bit_index` 从 0 到 7。状态在 125、104285、937565、1041725 ns 分别进入 START、DATA、STOP、IDLE。

**输出 dout 使用时序寄存器。** 每个上升沿按更新前的 `current_state` 和 `bit_index` 生成输出，因此输出边界比对应状态／位索引更新晚一拍（10 ns），不是位宽少一拍。停止位与空闲均为高电平，二者交界没有电平跳变，需结合状态和计数器判断。

分析时用自己的波形说明：valid 如何触发发送；data_reg 如何锁存；四状态如何转移；为何低位先发；每位与整帧时长；复位和空闲输出。第三个 FF 用例在 valid 撤销后将 data 改为 00，可用于核对锁存，不强制额外截图。

## 第 4 步：电子状态转移图

`resource/uart_send-state.drawio` 可在 draw.io 中打开编辑；同目录 `uart_send-state.svg` 是清晰矢量图。图中标出了复位、自环、条件及输出赋值；可作为报告状态图素材，但须理解并核对与提交代码一致。

- IDLE：valid=1 转 START，否则保持；START：bit_count=10415 转 DATA，否则保持。
- DATA：bit_count=10415 且 bit_index=7 转 STOP，否则保持。每个数据位结束时 bit_index 加一，状态仍可保持 DATA。
- STOP：bit_count=10415 转 IDLE，否则保持；任意时刻 rst=1 异步回到 IDLE。
- 圆内输出为时序赋值规则：START 输出 0，DATA 输出 data_reg[bit_index]，其他状态输出 1；实际 dout 相对状态更新晚一拍，图下说明须一并保留。

**不必额外制作 RTL 电路截图。** 本实验需要的是状态转移图，不是综合后的电路图。

## 第 5 步：综合、实现与下载

1. 关闭仿真，确认 **Design Sources 顶层仍为 uart_top**。可选运行 **Run Linter**；它不属于本实验单独的报告截图要求。
2. 依次执行 **Run Synthesis → Run Implementation → Generate Bitstream**。检查 Messages，修复错误；不能忽略锁存器、多驱动、未约束端口或时序违例等关键告警。
3. 实现后查看 **Report Timing Summary**，确认时序约束存在且已满足。没有 Vivado 实际结果时不能写“时序通过”。
4. 连接 EGO1、开电源。**Open Hardware Manager → Open Target → Auto Connect → Program Device**，选择刚生成的 `uart_top.bit` 并下载。
5. 按下 S1 应中止发送并保持线路空闲；松开后从首字符 h 重新开始。复位可能截断当前一行，截报告图前清屏等待稳定的完整行。

## 第 6 步：串口接收与报告截图

1. Windows 打开 **设备管理器 → 端口（COM 和 LPT）**，用插拔前后变化确认 EGO1 对应 COM 号。识别不到时先换可传数据的线，再按芯片型号检查 CP210x 驱动。
2. 打开实验室已有的 **SuperCom**，选对应 COM 号。确认 **9600 波特率、8 数据位、无校验、1 停止位、无流控**，其余保持默认；勾选 **加时间戳**，使用字符显示而非 HEX，再连接。
3. 正常情况下每行完整显示 `hitsz2025310599`，持续重复，无乱码和额外字符。字符起始间隔 2 ms；末字符到下一轮首字符的起始间隔 252 ms，停止位结束后的空闲约 250.9584 ms。
4. 清屏后等待多行稳定结果，用系统截图保存窗口，清楚显示接收内容与配置；**不要手机拍照，不用放学生卡**。这是报告第一部分的证据。

无数据时依次检查 COM、连接状态、下载的 bit、T4 约束与板卡电源。乱码时检查 9600/8N1 和 100 MHz 时钟；可切 HEX 辅助观察，再切回字符模式。

**仅在随机分行时**，尝试将 SuperCom 分包超时调到 100 ms；不要一开始就改默认设置，也不要添加回车换行去掩盖发送间隔问题。回环测试可帮助排查连接，但非必做，若另做回环工程，之后必须重新下载本实验 bit。

## 第 7 步：提交前核对

- 报告第一部分：真实串口截图，收到自己的完整学号。
- 第二部分：清晰电子状态图，含转移条件、输出、复位及必要说明。
- 第三部分：官方仿真通过的 Tcl Console 截图、完整帧波形及自己的分析。
- 将自己写的 `uart_top.v、uart_send.v、pin.xdc` 和 PDF 实验报告打包 ZIP，文件命名以提交平台要求为准；不打包整个 Vivado 工程、缓存、辅助验证或操作手册。官方 testbench 留作复现，若平台另有要求则随要求附上。

原始 `report/report.md` 只作为模板保留，本手册没有填写或改写它。**本地初步仿真通过，不等于 Vivado 综合、时序或 EGO1 上板通过。**
