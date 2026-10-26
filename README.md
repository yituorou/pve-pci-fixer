# PvePciFixer 🚀

[English](./README_EN.md) | 中文说明

**作者：一坨肉 (yiTuoRou)**

这是一个为 PVE (Proxmox VE) 用户设计的自动化工具，专门解决由于增加/减少硬件（如 OCulink 设备、外置显卡、NVMe 硬盘）导致的 PCI 地址（BDF）变动，从而引起虚拟机无法启动或直通失效的问题。

### 核心功能
- ✅ **自动追踪**：基于设备名称关键字识别硬件，彻底告变 BDF 地址漂移困扰。
- ✅ **Web 界面**：响应式管理后台，傻瓜式点选虚拟机与硬件，一键完成绑定。
- ✅ **开机自愈**：集成 Systemd 服务，宿主机开机瞬间自动对齐所有 VM 配置。
- ✅ **规范化补全**：自动处理 `0000:` 前缀，严格遵循 Proxmox PCI 分配规范。
- ✅ **轻量安全**：Rust 编写，单文件运行，不修改系统底层，仅修正 `.conf` 文本。

### 快速安装 (推荐)
在 PVE 终端执行以下命令，即可全自动完成下载、安装、配置服务及开机自启（默认安装最新版本）：
```bash
curl -sSL https://ghfast.top/https://raw.githubusercontent.com/yituorou/pve-pci-fixer/master/install.sh | GH_PROXY=https://ghfast.top/ bash
```

- 命令通过 GitHub 加速代理 `ghfast.top` 下载，适合国内网络。若该代理不可用，把命令中两处 `https://ghfast.top/` 换成其他 GitHub 加速代理即可。
- 能直连 GitHub 时可不使用代理：
  ```bash
  curl -sSL https://raw.githubusercontent.com/yituorou/pve-pci-fixer/master/install.sh | bash
  ```
- 安装指定版本：在 `bash` 前加上 `VERSION=v0.2.0`。
- 升级：重新执行安装命令即可，已有的 `config.yml` 会保留。
