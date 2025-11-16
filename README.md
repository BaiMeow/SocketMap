# SocketMap

基于 iptables 的端口映射工具

## 功能

将本地端口映射到远程主机的指定端口，支持 TCP 和 UDP 协议。

## 实现原理

- 在 PREROUTING 链中创建 SOCKET_MAP_DNAT 链，对匹配的流量打上 fwmark 并进行 DNAT
- 在 POSTROUTING 链中根据 fwmark 进行 SNAT

## 安装

### 方式一：自动安装（推荐）

从 GitHub Releases 下载预编译的二进制文件：

```bash
curl -fsSL https://raw.githubusercontent.com/BaiMeow/SocketMap/main/install.sh | sudo bash
```

或下载后执行：

```bash
wget https://raw.githubusercontent.com/BaiMeow/SocketMap/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

脚本会自动：
- 检测系统架构和操作系统
- 下载最新版本的预编译二进制文件
- 安装到 `/usr/bin/socketmap`
- 创建 systemd 服务
- 生成配置文件示例

### 方式二：从源码编译

```bash
go build -o socketmap main.go
sudo cp socketmap /usr/bin/
sudo cp sockekmap.service /etc/systemd/system/socketmap.service
sudo systemctl daemon-reload
```

## 配置

配置文件默认路径：`/etc/socketmap.yaml`

```yaml
- protocol: tcp
  localPort: 8080
  remote: 192.168.1.100:80

- protocol: udp
  localPort: 53
  remote: 8.8.8.8:53
```

## 使用

### 命令行参数

- `-c` 指定配置文件路径，默认为 `/etc/socketmap.yaml`
- `-s` 指定 SNAT 源地址，默认为默认网卡 IP

### systemd 服务

```bash
# 启动服务
sudo systemctl start socketmap

# 开机自启
sudo systemctl enable socketmap

# 查看状态
sudo systemctl status socketmap

# 查看日志
sudo journalctl -u socketmap -f
```

### 直接运行

```bash
sudo socketmap -c /path/to/config.yaml
```

## 系统要求

- Linux 系统
- iptables
- root 权限

## License

MIT
