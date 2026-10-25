# 实验 3 操作手册：计数器流水灯（EGO1）

本手册用于到实验室后照着操作，不是实验报告。依据 2026-10-25 网站快照和老师课件编写；以下波形、LED 现象均为**待核对的预期结果**，报告必须使用自己的真实仿真截图。

**报告必做：复位、频率切换、模式切换的波形及分析；20 Hz 最大计数值计算。课上必做：上板演示复位、频率、方向、模式切换。** 当前报告不要求方向切换波形、实物照片或电路图；无需专门截图，但综合、实现和上板仍要完成。

## 第 1 步：准备文件并建立工程

目的：只建立一个 EGO1 流水灯工程，分清设计、仿真和约束。

1. 带上 EGO1、可传输数据的 USB 线和 `lab3/code/`。将代码复制到实验室电脑的纯英文目录，例如 `D:/FPGA/lab3/code/`。
2. 打开 Vivado，点击 **Create Project → Next**；工程名填 `flowing_water_lights`，位置可选 `D:/FPGA/lab3/projects/`，保留 Create project subdirectory。
3. 选择 **RTL Project**，勾选 Do not specify sources at this time，下一步。
4. Default Part 选 **Parts**，搜索并选择 **xc7a35tcsg324-1**，Finish。搜索不到时先检查 Artix-7 器件支持，不要换成其他器件。
5. **Add Sources → Add or create design sources → Add Files**，添加 `flowing_water_lights.v`。
6. 再次 Add Sources，选 **Add or create simulation sources**，添加 `testbench.v`。
7. 在 Sources 中，确认 Design Sources 的顶层为 `flowing_water_lights`，Simulation Sources 的顶层为 `testbench`。需要时右击对应模块 → Set as Top。

| 文件 | 添加位置 | 用途 |
| --- | --- | --- |
| flowing_water_lights.v | Design Sources | 可综合设计，上板用默认参数 |
| testbench.v | Simulation Sources | 报告激励，仅仿真覆盖参数 |
| pin.xdc | Constraints，第 4 步添加 | EGO1 管脚与 100 MHz 时钟 |

另建 `evidence/` 文件夹存放真实截图。**检查点：testbench 没有放入设计源，工程没有导入 Lab1/Lab2 的代码或 XDC。**

## 第 2 步：运行仿真并加入内部计数信号

目的：使用缩小的计数值，在短时间内看清完整周期。

1. 点击 **Run Simulation → Run Behavioral Simulation**。默认运行 1000 ns 还未结束，点击工具栏 **Run All**，等待仿真停止于 **1180 ns**。
2. 在 Scope 窗口展开 `testbench`，选中 `u_flowing_water_lights`；在 Objects 中找到内部信号 **cnt**，右击 **Add to Wave Window**。
3. 添加内部信号后重新运行：点击 **Relaunch Simulation**，再 Run All；确认 `cnt` 有完整的历史波形。若重启后显示列表被重置，重新添加 `cnt`；必要时先 Restart，再添加并 Run All。
4. 波形按 `clk、rst、freq_ctrl、dir_ctrl、mode_sel、cnt、led` 排列，删除重复项。顶层信号可在 Scope 选 `testbench` 后从 Objects 添加。
5. **右击 cnt → Radix → Unsigned Decimal。其他多位信号保持默认进制，不展开 led 或 cnt 的各个位。**
6. 点击 **Zoom Fit** 查看全程，再用放大/缩小和拖动选区观察局部。拉宽信号名及波形区，让数字、信号名和时间刻度清楚。

如果波形窗口被关闭，通过 Window → Waveform 找回。修改 Verilog 后必须 Relaunch 重新编译；Restart 只重新运行已编译的设计。这里的 testbench 不打印 PASS，是否正确应以波形为准。

仿真时钟周期为 10 ns。设计默认上限是 199,999 和 9,999,999，testbench 通过参数改为 6 和 11，所以仿真每 70 ns 或 120 ns 移位一次；它们**不是上板的实际时间间隔**。

**检查点：仿真运行到 1180 ns，cnt 可见且为十进制，led 没有展开，复位后无持续 X/Z。**

## 第 3 步：保存报告波形并写分析

目的：**按复位 → 频率切换 → 模式切换的顺序留证据**，截图与分析逐一对应。以下表格只是预期，不可直接当作实测记录；表中 led 为十六进制，cnt 为十进制。

| 时间 / ns | 输入或状态 | 预期行为 |
| --- | --- | --- |
| 0 至 20 | rst=1；快档、单灯、向高位 | cnt=0，led=01 |
| 20 | rst=0 | 恢复计数；25 ns 时 cnt=1 |
| 75 / 85 | 首次计到 6 / 下一上升沿 | cnt 从 6 回到 0，led 在 85 ns 变为 02 |
| 155 / 225 / 295 | 后续快档更新 | led 依次为 04、08、10 |
| 300 | freq_ctrl 从 1 变 0 | 切慢档，上限从 6 改为 11 |
| 305 至 415 | cnt 从 1 计到 11 后回零 | 405 ns 为 11；415 ns 回零，led=20 |
| 535 / 655 | 后续慢档更新 | led 依次为 40、80 |
| 660 / 665 | mode_sel 变 1 / 下一上升沿 | 双灯初始化，cnt=0，led=03 |
| 785 / 905 / 1025 / 1145 | 双灯每 120 ns 更新 | led 依次为 0C、30、C0、03 |

建议保存三张局部图，信号顺序一致，不截整屏代码或桌面：

1. **复位图**：约 0 至 100 ns，保存 `evidence/01_reset.png`。说明高电平复位令计数清零、只亮 LED0，释放后重新计数。此图展示初始复位，不应声称仅凭它证明了任意时刻的异步响应。
2. **频率切换图**：约 215 至 550 ns，保存 `evidence/02_frequency.png`。必须能读清切换前完整的 `0,1,…,6,0` 和切换后完整的 `0,1,…,11,0`；若挤不下，可补两张局部图，并保留含 300 ns 切换点的截图。指出周期从 7 个时钟变为 12 个时钟。
3. **模式切换图**：约 625 至 1180 ns，保存 `evidence/03_mode.png`。说明 660 ns 选择双灯，665 ns 初始化为 03，以后按 `03 → 0C → 30 → C0 → 03` 循环，即每步移动两位。

**分析中写清是哪张图、哪一时刻、输入如何变化、cnt 与 led 如何响应。** 频率切换和模式切换各体现一次即可，不必补方向切换波形。若实际结果与表格不同，先核对代码、参数、仿真顶层和是否重新编译，不修改截图凑结果。

## 第 4 步：添加 EGO1 约束，综合并生成 bit

目的：用上板默认参数生成真实硬件配置。

1. 关闭仿真返回工程，点击 **Add Sources → Add or create constraints → Add Files**，添加本实验的 `pin.xdc`。
2. 确认设计顶层仍为 `flowing_water_lights`，没有把仿真的 6/11 设置为综合参数。设计默认 `WIDTH=24`，快档最大值 199,999，慢档最大值 9,999,999。
3. 点击 **Run Synthesis**，完成后点击 **Run Implementation**。
4. 实现完成后检查 Messages 和实现报告：有 ERROR、未约束端口或时序失败时先定位原因。**不要通过降低 DRC 严重级别来绕过错误。**
5. 点击 **Generate Bitstream**。成功后记下文件位置，通常在工程目录的 `flowing_water_lights.runs/impl_1/flowing_water_lights.bit`。

| 信号 | EGO1 连接 | 含义 |
| --- | --- | --- |
| clk | 板载晶振 P17 | 100 MHz，约束周期 10 ns |
| rst | 普通按键 S1 / R17 | 按下为 1，异步复位 |
| freq_ctrl | SW0 / R1 | 0：0.1 s；1：0.002 s |
| dir_ctrl | SW1 / N4 | 0：向高位；1：向低位 |
| mode_sel | SW7 / P5 | 0：单灯；1：双灯 |
| led[7:0] | LD2_7…LD2_0 | 高电平亮；不用另一组 LED |

LED 从第 0 位到第 7 位的管脚为 **K2、J2、J3、H4、J4、G3、G4、F6**。所有 I/O 为 LVCMOS33。SW2 至 SW6 和 DIP 组不使用，保持向下即可。

时钟 P17 来自 EGO1 手册；课件中的 Y18 不能用于本板。左右方向以 LED 编号升降为准，不凭开发板在桌面上的摆放方向判断。

**检查点：成功生成本工程的 bit 文件。** 报告不要求 RTL/Synthesis Schematic，无需专门截图；感兴趣时可打开查看，但不能因此跳过综合和实现。

## 第 5 步：连接开发板并下载

目的：把 bit 配置到 FPGA，不是把 Verilog 源码复制到开发板。

1. 用数据线连接 EGO1 的 USB-UART/JTAG 接口，确认供电正常。先将 SW0、SW1、SW7 拨为 0。
2. Vivado 中选择 **Open Hardware Manager → Open Target → Auto Connect**。
3. 找到 FPGA 后右击器件 → **Program Device**；Bitstream file 选择第 4 步生成的 bit，点击 Program。
4. 下载成功后，**按住再松开普通按键 S1/R17**，让电路从已知状态运行；不要按 PROG 清配置键。
5. 预期慢档单灯从 LD2_0 开始，按编号增大的方向流动。若不符，按第 8 步排查，不直接认定代码正确或板卡损坏。

断电后通常需要重新下载。备份已经验证的 bit，下次可直接从 Vivado 首页 Open Hardware Manager 连接并下载，不必每次重新生成。

**检查点：下载成功并已按 S1 复位；慢档下能观察到单灯移动。**

## 第 6 步：课上功能自查与演示

目的：**先自己验证完，再举手请老师检查**。以下均为课上功能要求，即使报告不要求照片也要实际操作。

| 检查项 | 操作 | 应观察到的现象 |
| --- | --- | --- |
| 复位与恢复 | 按住 S1，再松开 | 按住时只亮 LD2_0、不流动；松开自动运行 |
| 单灯正向 | SW0=0、SW1=0、SW7=0 | 单灯按 0→1→…→7→0 流动 |
| 单灯反向 | 保持慢档，将 SW1=1 | 下一步起按相反方向循环 |
| 双灯正向 | SW1=0，将 SW7=1 | 从 0、1 两灯开始，再到 2、3；4、5；6、7 |
| 双灯反向 | 保持双灯，将 SW1=1 | 相邻灯对反向循环，每次移动两位 |
| 返回单灯 | SW7=0 | 从 LD2_0 重新开始，恢复单灯流动 |
| 快慢切换 | SW0=1，再拨回 0 | 快档明显加快；回慢档后恢复可辨认的流动 |
| 双灯中复位 | SW7=1 时按住再松开 S1 | 按住仍仅亮 LD2_0；松开后进入双灯流动 |

开关上下以板上丝印和实际逻辑为准，本手册按上拨为 1、下拨为 0 使用。**500 Hz 是每秒更新 500 次，肉眼通常不能逐步追踪，可能看成多灯同时发光；用 10 Hz 慢档检查方向、单双灯和循环。** 不要把快档“看似全亮”当作程序要求所有灯常亮，也不要声称肉眼测出了精确频率。

模式切换会重新定位并清零计数；方向切换不重新定位；频率切换保留计数，切换瞬间的首个间隔可能不完整。连续运行后，各档应使用对应的稳定间隔。

课件提到“复位后停止”和“启停”，网站没有单独的启动输入。本工程采用已确认解释：**按住 S1 停止，松开运行**，不增加启动开关。如老师现场另有明确要求，先确认再改，不自行混用两个版本。

检查时间以当前课程通知和平台为准，不把课件的“下周”推算成固定日期。**检查点：复位、两档速度、双向、单双灯均已实际演示通过，并保留好 bit。**

## 第 7 步：完成报告与提交

目的：只提交课程需要的材料，不把操作手册当报告。

1. 打开 `lab3/report/report.md`，填写姓名、学号、班级；按现有模板补入第 3 步的真实波形截图和对应分析。
2. **第二部分写 20 Hz 最大计数值计算**：每次更新间隔 `T = 1/20 s = 0.05 s`；100 MHz 的周期为 `10 ns`；需要 `N = 100,000,000/20 = 5,000,000` 个时钟。由于 cnt 从 0 开始，最大值为 **N−1 = 4,999,999**。
3. 此处计数结束产生一次移位使能，**不是输出方波每半周期翻转一次**，因此不要再除以 2。20 Hz 仅为报告计算题，不需要给电路增加第三档速度。
4. 报告转为 `学号_姓名.pdf`，逐页核对截图刻度、计数值、中文和分页。当前手册 PDF 不能代替个人报告。
5. 将自己写的代码、实际使用的约束和报告 PDF 打包成 ZIP，上传课程平台，确认上传成功。

建议 ZIP 内容：

```text
flowing_water_lights.v
testbench.v
pin.xdc
学号_姓名.pdf
```

不打包整个 Vivado 工程、build、VCD、老师课件、本操作手册或临时测试。实物照片、电路图、方向切换波形不是当前报告必需项，无需为它们额外制作材料。

**检查点：报告覆盖要求的三个仿真阶段和 20 Hz 计算，ZIP 内文件完整且上传成功。**

## 第 8 步：快速排查与本地复验

| 问题 | 优先检查 |
| --- | --- |
| 仿真 led 不动 | 是否选择 testbench；是否覆盖为 6/11；是否 Run All |
| cnt 不存在或没有历史 | 选中设计实例而非 testbench；加入信号后重新运行 |
| 波形修改后没变化 | 用 Relaunch 重新编译，不是只点 Restart |
| 只有最初一盏灯 | S1 是否一直按住；时钟是否 P17；是否正确下载 |
| 上板看似全亮或太快 | SW0 是否为 1；是否误用仿真参数；先切慢档 |
| 灯组或方向对不上 | 确认 LD2 组和编号；核对本实验 pin.xdc |
| 找不到开发板 | 换可传数据的线；核对接口、供电、驱动和 Auto Connect |
| 综合出现延时或多顶层问题 | testbench 是否误入设计源；设计顶层是否正确 |

如需在本机重跑仿真，从仓库根目录执行以下命令；需要已有 `iverilog` 和 `vvp`，不需要下载 Python 包：

```bash
mkdir -p lab3/code/build
iverilog -g2005 -Wall -s testbench \
  -o lab3/code/build/lab3.vvp \
  lab3/code/flowing_water_lights.v lab3/code/testbench.v
(cd lab3/code/build && vvp lab3.vvp +vcd)
```

输出 `lab3/code/build/lab3_sim.vcd`，1180 ns 结束。报告截图仍应在实验室 Vivado 中按课程要求获取，不能用本地预制图片冒充。

**验证边界：本地仿真和管脚检查不代表 Vivado 综合、实现、时序或上板已经通过。** 人工开关没有额外同步/去抖，复位释放也未专门同步；本设计是课程演示，不是生产级异步输入处理方案。

资料入口：[网站实验内容](../../website/mirror/pages/lab3-counter/lab-content/index.md)、[实验原理及双灯示意](../../website/mirror/pages/lab3-counter/counter-principle/index.md)、[Verilog 规范](../../website/mirror/pages/codingstyle/codingstyle/index.md)、[老师课件](lab3-计数器.pdf)、[EGO1 硬件手册](../../lab1/resource/Ego1开发板硬件手册V2.pdf)。硬件手册版本 2018.04 ver2.2，PDF 阅读器第 4 页为时钟、第 6 页为按键、第 7 页为开关、第 8 页为 LED。镜像和工具环境可能随机器变化，新的课程要求以当时通知为准。
