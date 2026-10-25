# Lab3：计数器流水灯（EGO1）

操作步骤见 [Markdown 手册](../resource/process.md)，离线打印见 [PDF 手册](../output/pdf/lab3-operation-guide.pdf)。本地准备不代表已经完成 Vivado 实现或上板验证。

| 文件 | Vivado 中的位置 / 顶层 |
| --- | --- |
| flowing_water_lights.v | Design Sources / flowing_water_lights |
| testbench.v | Simulation Sources / testbench |
| pin.xdc | Constraints；仅用于 EGO1 |

器件为 `xc7a35tcsg324-1`。只建一个工程，不将 testbench 放入 Design Sources，不混入旧实验约束。

## 接口与行为

- `clk` 接 P17（100 MHz），`rst` 接普通按键 S1/R17，高电平异步复位。
- SW0/R1 接 `freq_ctrl`：0 为 0.1 s/步，1 为 0.002 s/步。
- SW1/N4 接 `dir_ctrl`：0 向高位，1 向低位循环移位。
- SW7/P5 接 `mode_sel`：0 单灯、每步移一位；1 双灯、每步移两位。
- `led[7:0]` 接 LD2_7…LD2_0，高电平亮。低位到高位的管脚为 K2、J2、J3、H4、J4、G3、G4、F6。
- 按住 S1：`cnt=0`、`led=01`；松开后自动运行。双灯模式松开复位后，在第一个时钟上升沿初始化为 `03`。
- 切换模式：下一上升沿初始化为 `01` 或 `03` 并清零计数。切换方向：下次计数结束时按新方向移位。
- 切换频率：保留计数；若已达到或超过新上限，下一上升沿清零并移位，因此切换后的首个间隔可能不是完整的新周期。

设计只用板载时钟，`cnt_end` 是更新使能，不是新时钟。默认 `WIDTH=24`、`CNT_MAX_FAST=199_999`、`CNT_MAX_SLOW=9_999_999`；参数表示从 0 开始的最大计数值，周期为 `(CNT_MAX+1) × 10 ns`。

报告仿真覆盖 `WIDTH=4`、快档上限 6、慢档上限 11。**不要为了仿真修改设计默认值，也不要把仿真的 6/11 用于上板。**

## 本地仿真

在仓库根目录运行，产物留在已忽略的 `build/` 中：

```bash
mkdir -p lab3/code/build
iverilog -g2005 -Wall -s testbench -o lab3/code/build/lab3.vvp \
  lab3/code/flowing_water_lights.v lab3/code/testbench.v
(cd lab3/code/build && vvp lab3.vvp +vcd)
```

报告 testbench 仅提供激励，不打印 PASS，也不包含自动检查。仿真在 1180 ns 正常结束；`+vcd` 生成 `lab3_sim.vcd`，Vivado 中无需此参数即可看波形。

## 本次本地验证记录

2026-10-25 使用 Icarus Verilog 13.0 完成以下检查，临时检查文件不混入交付代码：

- 8 种频率/方向/模式组合、循环回绕、切换及非时钟边沿复位，共 1,274 次状态检查通过。
- 默认 24 位计数器实际运行，快档 200,000 个时钟、慢档 10,000,000 个时钟后更新，均通过。
- VCD 中激励时刻、全部 LED 转换、完整的 0 至 6 / 0 至 11 计数和 1180 ns 结束时间，与操作手册一致。
- 13 个端口的 EGO1 映射、管脚唯一性、LVCMOS33、10 ns 时钟及 XDC Tcl 语法检查通过。Tcl 检查使用端口桩，不调用 Vivado 器件数据库。

## 验证边界与资料

本地验证使用 Icarus Verilog；Vivado 综合、实现、时序检查与实物功能仍需在实验室完成。拨码输入未加同步器或去抖，异步复位释放也未专门同步；这是课程演示电路，不是生产级异步输入处理方案。不用虚构输入输出延时或降低 DRC 严重级别来消除告警。

要求依据为 2026-10-25 网站快照、老师课件及 EGO1 2018.04 ver2.2 硬件手册。课件中 Y18 是其他板型的时钟管脚，EGO1 使用 P17；课件“复位后停止”的表述与网站不同，本实验按已确认方案实现“按住停止、松开运行”，不额外增加启动接口。课件与网站链接见操作手册末尾。
