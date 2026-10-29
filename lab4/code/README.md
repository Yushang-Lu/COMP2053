# Lab4：数码管控制器（EGO1）

照着操作见 [Markdown 手册](../resource/process.md)，打印见 [PDF 手册](../resource/lab4-operation-guide.pdf)。手册与实验报告不同；已有 `lab4/report/report.md` 保持原样，需在实验室取得真实截图后自行完成。

## 文件与工程

器件为 `xc7a35tcsg324-1`，只建一个工程。

| 文件 | Vivado 中的位置／顶层 |
| --- | --- |
| segment_ctrl.v | Design Sources，上板顶层 segment_ctrl |
| led_ctrl_unit.v | Design Sources，扫描／译码模块 |
| key_debounce.v | Design Sources，稳定采样消抖模块 |
| edge_detect.v | Design Sources，两级寄存器边沿检测模块 |
| led_ctrl_unit_tb.v | Simulation Sources，顶层 led_ctrl_unit_tb |
| segment_ctrl_tb.v | Simulation Sources，顶层 segment_ctrl_tb |
| edge_detect_tb.v | Simulation Sources，顶层 edge_detect_tb |
| pin.xdc | Constraints，仅适用于 EGO1 |

一次只选择一个仿真顶层，切换前关闭旧仿真；Design Sources 顶层始终为 `segment_ctrl`。报告 testbench 只提供激励，不含断言、自动评分或 VCD 导出。

## 接口与行为

- `clk`：P17，100 MHz；`rst`：普通按键 S1/R17，高有效异步复位。所有寄存器均复位，按住时数码管全灭，释放后自动开始计时。
- `mode_sel`：大拨码 SW0/R1；上拨 1 固定显示 `25310599`，下拨 0 显示 `{99, count_raw, count_clean, count_auto}`。切换只影响显示，计数与运行状态不清零。
- `button_s3`：S3/V1；同时驱动未消抖和消抖的两位 BCD 计数，均为 `00–99` 循环，长按不连续计数。未消抖组可能记录按下及释放抖动的多个上升沿。
- `button_s2`：S2/R15；消抖后的每次按下切换定时计数的暂停／继续。长按不反复切换；暂停保留数值与计时进度。启停事件优先于同一拍的定时更新。
- `count_auto`：每 0.1 s 从 `00` 计至 `20` 再回 `00`，复位后 `running=1`。
- `display[31:0]`：内部八个四位字符，每个四位字段直接译码；不是将整个学号转换成二进制整数。
- `led_en[7:0]`：DK7 至 DK0，高有效独热扫描；`led_cx[7:0]` 驱动右四位，`led_cx1[7:0]` 驱动左四位。两组的位序均为 `{CA,CB,CC,CD,CE,CF,CG,DP}`，高有效，小数点关闭，未选中组输出 0。

| 参数 | 默认最大计数值 | 稳态时间 | 报告仿真覆盖 |
| --- | --- | --- | --- |
| SCAN_CNT_MAX（17 位） | 99,999 | 每位 1 ms，整屏 8 ms | 9，每位 10 个时钟 |
| DEBOUNCE_CNT_MAX（21 位） | 1,999,999 | 同步后连续稳定 20 ms | 3，连续稳定 4 个时钟 |
| TICK_CNT_MAX（24 位） | 9,999,999 | 每次计数 0.1 s | 19，每次计数 20 个时钟 |

参数表示从 0 开始的计数上限，周期为 `(CNT_MAX + 1) × 10 ns`，允许范围为对应位宽的无符号值。**不要把 testbench 的覆盖值改到设计默认值中。** 扫描在复位释放到首个切换点之间有一个不完整初始槽位，后续槽位符合上述周期。

消抖模块对按下、释放都生效：两级同步后，采样值持续不同于当前输出达到门限才更新输出；期间回到原输出电平则重新计时。边沿检测用 `sig_r0 & ~sig_r1`，计数寄存器在脉冲被时钟采到时更新。

## 本地报告仿真

从仓库根目录执行：

```bash
mkdir -p lab4/code/build
for top in led_ctrl_unit_tb segment_ctrl_tb edge_detect_tb; do
  iverilog -g2005 -Wall -s "$top" \
    -o "lab4/code/build/$top.vvp" lab4/code/*.v &&
  vvp "lab4/code/build/$top.vvp" || break
done
```

| 仿真 | 实际结束时间 | 核对结果 |
| --- | --- | --- |
| led_ctrl_unit_tb | 1820 ns | display=25310599；每 100 ns 换位；两组段选对应正确 |
| segment_ctrl_tb | 900 ns | count_clean 在 185、585 ns 增加，最终 02；count_raw 最终 08 |
| edge_detect_tb | 162 ns | 上升沿脉冲为 35–45 ns、105–115 ns，均宽 10 ns |

正常输出 `$finish`，不打印 PASS；没有 VCD 文件，传入 `+vcd` 也不会导出。Vivado 的内置波形窗口不需要 VCD。报告截图范围、实例路径及进制要求见操作手册。

## 2026-10-29 本地验证记录

使用 Icarus Verilog 13.0，三个报告 testbench 均以 `-g2005 -Wall` 独立编译、运行通过，无编译警告。额外测试位于 `/tmp`，不纳入交付代码：

1. **264,849 次状态检查通过**：用整数计数参考和连续采样窗口参考逐拍比对设计，覆盖 415 个未消抖事件、358 个消抖事件、22 次定时回绕、244 次启停、10 次启停与计时终点重合。
2. 定向检查包括 3 时钟毛刺过滤、4 时钟门限接受、长按、两组 `99→00`、`20→00`、暂停期间保留进度、切换显示模式、非时钟边沿复位、0–F 全部段码及最小扫描上限 0。
3. **真实默认参数运行 10,000,000 个时钟通过**：换位恰为 100,000 拍，整轮 800,000 拍，消抖按下及释放均在 2,000,000 次稳定采样后确认；从同步输入端算还需两级同步延迟。定时计数在第 10,000,000 拍首次增加，终点前不提前更新。
4. 临时 VCD 探针未改动报告 testbench，逐项核对上述报告时间点、八位段码及扫描间隔通过；这些 VCD 不是实验报告截图。
5. XDC Tcl 桩检查通过：29 个端口位均有正确且唯一的 EGO1 管脚，全部 LVCMOS33，只有一个 10 ns 的 `sys_clk` 约束。桩不访问 Vivado 器件数据库。

本次临时检查命令（仅本轮 `/tmp` 文件存在时可复跑；长期使用上面的报告仿真命令）：

```bash
iverilog -g2005 -Wall -s lab4_check \
  -o /tmp/comp2053-lab4-check.vvp \
  lab4/code/*.v /tmp/comp2053-lab4-check.v
vvp /tmp/comp2053-lab4-check.vvp
iverilog -g2005 -Wall -s defaults_check \
  -o /tmp/comp2053-lab4-defaults.vvp \
  lab4/code/*.v /tmp/comp2053-lab4-defaults.v
vvp /tmp/comp2053-lab4-defaults.vvp
tclsh /tmp/comp2053-lab4-xdc.tcl
```

## 验证边界

本机 PATH 未发现 Vivado、Verilator 或 Yosys；没有声称完成 Vivado Linter、综合、实现、DRC、时序或实物验收。Icarus 编译和 XDC 桩检查不能代替这些步骤，也不生成可下载 bit。

S2/S3 消抖输入有两级同步器；未消抖通道按课程结构从两级寄存器的输出检测边沿，不能把第一级参与逻辑的结构称作完善的亚稳态隔离。模式输入和异步复位释放未额外同步；这是课程演示设计，不是生产级 CDC 方案。不要靠虚构输入输出延时或降低 DRC 严重级别消除提示。

依据为 2026-10-29 网站本地快照、Lab4 课件和 EGO1 2018.04 ver2.2 手册；具体入口见操作手册。课堂演示和报告截图须实际完成，不以本地预期结果冒充上板实测。
