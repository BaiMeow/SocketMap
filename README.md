# SocketMap

使用 iptables 进行端口映射

## 实现

SocketMap 会添加一系列 iptables 规则使得本机的某个端口被映射到另一台机器的某个端口上

写入的规则会先在 PREROUTING 链中过滤所有来自默认网卡的流量进 SOCKET_MAP_DNAT 链，在这个链中给端口满足要求的流量打上 fwmark 并做DNAT

在 POSTROUTING 链中，会根据 fwmark 进行 SNAT

## 使用

提供了两个命令行参数

- -c 指定配置文件路径，默认为 `/etc/socketMap.yaml`
- -s 指定 SNAT 的源地址，默认为默认网卡的IP

还提供了一个 service 文件，可以将其放入 `/etc/systemd/system/` 下，修改后使用 `systemctl enable socketmap` 启用