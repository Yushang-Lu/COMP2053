# Lab6 附加题：打地鼠（EGO1）

独立 Vivado 工程，器件为 `xc7a35tcsg324-1`，时钟为 100 MHz。必做题仍使用 `../../code/`，两套工程分别下载、分别演示。本目录实现全部打地鼠要求，不需要矩阵键盘或外接蜂鸣器。

## 入口与文件

- [操作手册](operation-guide.md)：建工程、仿真、串口、上板和验收。
- [PDF 操作手册](operation-guide.pdf)：中文宋体打印版。
- [设计说明](design.md)：模块接口、框图、状态机和边界行为。
- [验证记录](verification.md)：本地检查结果与尚未完成项目。
- `../src/`：全部 Verilog、测试文件和 `pin.xdc`。
- `../src/render_manual.py`：本手册专用 PDF 渲染工具，不加入 Vivado。

| 源文件 | 用途 |
| --- | --- |
| top.v | 顶层，仅例化和连接 |
| key_press.v | S2 两级同步、稳定消抖和单拍按下脉冲 |
| uart_recv.v | 9600 baud、8N1 接收，字节有效脉冲 |
| lfsr.v | 16 位持续运行的伪随机序列 |
| game_control.v | 三段式游戏状态机、BCD 分数与倒计时 |
| game_display.v | 显示布局和位使能 |
| segment_scan.v | 八位扫描与两组独立段选 |
| effect_led.v | 反馈频率、事件时长和静音 |
| top_tb.v | 简洁加速仿真，只加入 Simulation Sources |
| pin.xdc | EGO1 管脚与 100 MHz 时钟约束 |

## 操作规则

S0 复位，S2 开始或重新开始，DIP0 上拨静音。注意附加题用 S0，与基础题 S1 不同。按住 S0 时关闭显示和反馈灯，松开后待机；下载后先按一次 S0 初始化。

DK7-DK6 为分数，DK5-DK4 为剩余秒数，DK0 为地鼠洞位，DK3-DK1 始终关闭。待机显示 `00 20`，无洞位。游戏 20 秒，串口发送 ASCII `1` 至 `8`，等于洞位即命中加分并换地鼠；打错保持洞位，非 `1` 至 `8` 字符忽略。

游戏结束显示最终分数与 `00` 秒，洞位关闭。分数最多 99；下一只地鼠允许出现在同一洞位。游戏中 S2 无效，持续按住 S2 不会在结束时自动开局，须稳定松开再按。

LD1_0 用不同闪烁频率代替音效：待机 1 Hz、游戏 2 Hz、命中 8 Hz 持续 0.5 秒、错误 4 Hz 持续 0.5 秒、结束 3 Hz 持续 3 秒。静音仅关闭此灯，不暂停游戏或反馈计时。

## 快速仿真

在仓库根目录运行：

```sh
iverilog -g2012 -Wall -s top_tb -o /tmp/mole-sim lab6/whack-a-mole/src/*.v
vvp /tmp/mole-sim
```

testbench 约 233.67 微秒结束，用参数缩短硬件等待时间；它不是 20 秒实时时序截图。设计文件没有 `initial` 初始化，testbench 没有断言、自动评分或 VCD 导出。Vivado 内置波形可直接观察。

## 资料依据

2026-11-18 核对课程[打地鼠页面](https://diglogic.p.cs-lab.top/lab6-uart-recv/whack-a-mole-game/)，与 2026-11-12 本地镜像内容一致；同时参考 `../../resource/lab6-综合实验.pdf`、课程 Verilog 规范及 `../../../lab1/resource/Ego1开发板硬件手册V2.pdf`。本实现采用改动后的 20 秒、串口击打和数码管洞位，不实现旧基础演示中的洞位 LED 与击打拨码开关。
