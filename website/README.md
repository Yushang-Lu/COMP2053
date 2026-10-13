# 实验指导网站离线下载

将 <https://diglogic.p.cs-lab.top/> 的实验指导正文下载为多个 Markdown 文件，保存图片及站内附件，供离线阅读。

## 运行

需要 Python 3.10 或更新版本。在仓库根目录执行：

```bash
python3 -m venv website/.venv
website/.venv/bin/python -m pip install -r website/requirements.txt
website/.venv/bin/python website/download.py
```

Windows 可将上述 `website/.venv/bin/python` 替换为 `website\.venv\Scripts\python.exe`。

下载后打开 `website/mirror/README.md`，按目录进入各页面。默认输出路径相对于脚本，而非当前工作目录。

```bash
website/.venv/bin/python website/download.py --output website/mirror --delay 0.5
website/.venv/bin/python website/download.py --help
```

## 输出结构

```text
website/
├── download.py
├── requirements.txt
└── mirror/
    ├── README.md                       # 离线页面目录
    ├── manifest.json                   # 来源、下载时间、资源校验值和失败记录
    ├── pages/
    │   ├── index.md                    # 网站首页
    │   ├── lab1/lab-content/index.md
    │   └── ...
    ├── assets/<域名>/<URL哈希>-<文件名>  # 图片、附件；避免同名覆盖
    └── html/                           # 原始 HTML，供核对正文
```

## 下载范围与更新

- 综合站点地图、MkDocs 搜索索引及页面链接递归发现同源页面，包括搜索索引中未出现在导航栏的页面。只能发现公开入口中可达的页面，不能枚举服务器上未公开的文件。
- 提取正文，保留标题、列表、代码块、表格、提示内容及原始章节锚点；复杂合并单元格表格保留为 HTML。站内页面链接改为相对 Markdown 链接。
- 下载正文图片（包括外站图片）、媒体资源和站内附件，改写为相对路径；外站普通链接保持在线地址，不递归镜像外部网站，也不下载主题脚本、样式和字体。
- 保存原始 HTML 用于核对，不作为可离线运行的完整网站。JavaScript 动态内容、登录后内容及第三方嵌入页面不保证离线可用。
- 遵守站点 `robots.txt`；默认请求间隔 0.2 秒，网络/服务端错误最多重试两次。可通过 `--delay`、`--timeout`、`--retries` 调整。
- 每次运行重新获取页面和资源，覆盖相同路径的文件，但不删除旧文件。当前快照以 `manifest.json` 为准；需要清理已撤下内容时，请使用新的空输出目录。
- 失败不会被静默忽略：写入 `manifest.json` 的 `failures`，进程返回非零退出码；已成功下载的内容仍可阅读。修复网络等问题后重新运行即可。`warnings` 记录第三方嵌入内容等离线限制。

生成的 `mirror/` 默认不进入 Git，避免提交大体积第三方资料；需要版本管理快照时可调整根目录 `.gitignore`。原始资料的版权归原作者所有，仓库的代码许可证不改变这些资料的许可条件。
