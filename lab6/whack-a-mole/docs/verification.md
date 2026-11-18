# 本地验证记录

日期：2026-11-18。结果来自 Icarus Verilog、本地脚本与 PDF 检查，不是 Vivado 或 EGO1 实测。

| 检查 | 结果 |
| --- | --- |
| 设计顶层 Verilog-2005 编译，-Wall | 通过，无编译告警 |
| 交付 top_tb 编译与运行 | 通过，233.67 微秒结束；本身不自动评分 |
| 游戏控制临时自检 | 通过：BCD 进位、105 次命中后饱和 99、洞位 1 至 8、错误数字与无效字符 |
| 计时临时自检 | 通过：每秒 100 拍的加速配置，完整 2000 拍结束，逐拍核对 BCD 秒数，截止同拍命中不计分 |
| 状态与复位 | 通过：待机和结束忽略字节、开局清零、重新开始、异步复位 |
| LFSR 周期 | 通过：遍历 65535 个非零且互不重复的状态 |
| 整机临时监测 | 通过：串口连续帧、正确/错误/回车输入、短抖动过滤、长按单次触发、重开清零 |
| 显示监测 | 通过：位选至多一位、禁用位关闭、两组段选互斥、BCD 字形与洞位字形 |
| 反馈独立自检 | 通过：CLK_HZ=96，五种频率的半周期分别为 48、24、6、12、16 拍；半秒事件计数、事件覆盖、结束优先、静音期间计数继续、结束到期灭灯 |
| 官方 UART 十组测试 | 通过，默认 9600 配置，输出 All test cases passed |
| XDC 静态检查 | 通过：30 个端口位、30 个独立管脚、S0/DIP0/LD1_0 映射、数码管与基础题 EGO1 映射一致、10 ns 时钟约束存在 |
| PDF | 4 页，87 个文本块完整、Markdown 哈希不变、宋体嵌入，逐页检查无溢出、缺字或拆分表格 |

额外自检位于 /tmp/mole-check.v、/tmp/mole-integration-check.v、/tmp/mole-effects-check.v，仅为本次验证临时文件，不作为报告 testbench 交付，临时目录可能被系统清理。交付 top_tb 保持简洁，不含断言、评分或 VCD 导出。

## 可重复的基础检查

以下命令在仓库根目录运行：

```sh
iverilog -g2005 -Wall -s top -o /tmp/mole-top lab6/whack-a-mole/src/*.v
iverilog -g2012 -Wall -s top_tb -o /tmp/mole-sim lab6/whack-a-mole/src/*.v
vvp /tmp/mole-sim
iverilog -g2005 -Wall -s uart_recv_tb -o /tmp/mole-uart lab6/code/uart_recv_tb.v lab6/whack-a-mole/src/uart_recv.v
vvp /tmp/mole-uart
```

官方 UART 测试源中的参数名为 byte，属于 SystemVerilog 保留字，须用 Verilog-2005 模式；首次误用 -g2012 的语法错误已通过改用原模式解决，未修改官方测试源。

PDF 渲染器位于 src/render_manual.py，依赖 ReportLab、pypdf 和 Python-Markdown；默认读取 docs/operation-guide.md。用 `--output` 指定一个尚不存在的输出文件，必要时用 `--markdown-python` 指定装有 Markdown 的 Python。宋体默认使用 macOS Songti.ttc，其他系统需适配字体及字体集合索引。渲染器是此手册专用，不是通用报告工具，重新生成后仍须逐页查看。

## 尚待实验室完成

Vivado Run Linter、综合、实现、DRC、100 MHz 时序收敛、bitstream 生成与 EGO1 上板验收尚未执行。本机未检测到 Vivado，当前不提供 bitstream，不声明已通过实物检查。测试加速参数不能替代硬件默认参数的实时时序测量。
