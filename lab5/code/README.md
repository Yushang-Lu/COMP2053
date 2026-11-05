# Lab5：状态机与 UART 发送（EGO1）

## 文件与使用

- `uart_top.v`：上板顶层，循环发送完整的 `hitsz2025310599`（15 字符，无 CR/LF）。
- `uart_send.v`：官方固定接口，四状态、三段式 UART 发送器。
- `uart_send_tb.v`：2026-11-05 镜像中的官方文件，逐字节复制，没有增删测试或加入波形导出。
- `pin.xdc`：EGO1 的 P17 时钟、S1/R17 高有效异步复位、T4 串口发送；10 ns 时钟约束。

Vivado 器件：`xc7a35tcsg324-1`。设计顶层为 `uart_top`，报告仿真顶层为 `uart_send_tb`。testbench 只加入 Simulation Sources，不能直接把 `uart_send` 作为上板顶层。

手把手步骤见 [Markdown 手册](../resource/process.md) 和 [PDF 手册](../resource/lab5-operation-guide.pdf)。正式报告模板保持原样，网站模板的 `uart_senf_tb.v` 为笔误。

## 实现约定

`uart_send(clk, rst, valid, data[7:0], dout)` 不增加 busy/ready 端口。IDLE 时在上升沿接收 valid 并锁存 data；忙时 valid 被忽略，不排队。输入方负责只在空闲时提供请求。复位中止当前帧，线路恢复高电平。

三个部分分别为状态寄存器、组合次态逻辑、时序输出逻辑；数据锁存和计数各自独立。dout 按上升沿前的状态和位索引更新，因此相对状态转移晚一拍，与课件的时序输出三段式模板一致。所有设计时序逻辑均使用非阻塞赋值，不产生派生时钟、不使用 initial 初始化。

| 项目 | 默认上板值 |
| --- | --- |
| 时钟／串口配置 | 100 MHz，9600，8N1，LSB 先发 |
| 单个位／完整帧 | 10416 拍／104160 拍，即 104.16 µs／1.0416 ms |
| 字符起始间隔 | 200000 拍，即 2 ms；帧后空闲 0.9584 ms |
| 末字符至下一轮首字符起始间隔 | 25200000 拍，即 252 ms；帧后空闲 250.9584 ms |
| 整条字符串重复周期 | 14 × 2 + 252 = 280 ms |

设计无仿真加速参数，本地顶层检查使用同一组真实上板计数值。按 S1 后从 h 重新发送；截报告图前清屏等完整行。

## 可复跑验证

在仓库根目录执行，需要 Python 3 和 PATH 中的 `iverilog`、`vvp`：

```bash
python3 lab5/verification/run_checks.py
```

检查脚本将编译产物和日志存入系统临时目录，并打印路径；任何编译错误、超时或测试失败都会非零退出。官方 testbench 即使失败也可能正常 `$finish`，脚本同时检查五个成功用例和最终通过文本，不能只凭退出码判定通过。

2026-11-05 本机实际验证结果（Icarus Verilog 13.0 stable）：

| 检查 | 结果 |
| --- | --- |
| 官方 testbench SHA256、EGO1 管脚与顶层端口、100 MHz 约束 | 通过 |
| 官方 A5、3C、FF、00、5A 五组用例 | 全部通过；结束于 5.51010335 ms |
| 补充核心测试 | 256 个字节逐拍检查；数据锁存、忙时请求、空闲保持、再次发送均通过 |
| 复位测试 | IDLE、START、DATA、STOP 中异步复位及恢复均通过 |
| 补充顶层测试 | 31 帧：两轮完整字符串及第三轮首字符；两次重复间隔及复位重发通过 |
| 编译 | `-Wall` 下上述测试无编译告警 |

官方文件 SHA256：

```text
f7e2fde78f12aa4450e13dcfbe60d5e829da5463e1414c33d88ee2d30570aa9f
```

辅助文件位于 `../verification/`，不属于报告要求的 testbench。`official_timing.v` 仅旁路打印首帧现态和输出变化时刻，不改变官方激励，也不加入 Vivado 报告工程。额外断言只用于本地自检，没有放入设计文件或官方 testbench。

官方 testbench 的 `CLOCK_FREQ` 等常量含实数运算，`DIVIDER` 的实际采样时间不能只看 `%d` 打印出来的整数；没有为了测试改动官方文件。以首帧实测为准：125 ns 进入 START，135 ns dout 拉低，104295 ns 开始输出数据，937575 ns 开始停止位，1041735 ns 完成完整帧。

**未执行 Vivado 综合、实现、DRC、时序收敛或真实串口上板测试。** Icarus 的通过日志不替代实验报告中的 Vivado 和 SuperCom 真实截图。代码初步验证也不能保证物理实现已通过。

## 来源与交付

- [网站 Lab5 要求](../../website/mirror/pages/lab5-fsm-uart/lab-content/index.md)、[UART 实验原理](../../website/mirror/pages/lab5-fsm-uart/uart-send-principle/index.md)。
- [Lab5 课件](../resource/lab5-状态机.pdf)、[EGO1 硬件手册](../../lab1/resource/Ego1开发板硬件手册V2.pdf)。
- [状态图 SVG](../resource/uart_send-state.svg)、[可编辑 draw.io](../resource/uart_send-state.drawio)；图与时序输出实现配套，保留下方的一拍延迟说明。

通常提交自己写的两个设计 `.v`、`pin.xdc` 和 PDF 实验报告，最终以平台清单为准。不打包整个 Vivado 工程、缓存、辅助测试、手册或网站镜像。本次未填写报告、未代造截图、未提交 Git。
