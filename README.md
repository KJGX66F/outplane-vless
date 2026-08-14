# OutPlane + Cloudflare Quick Tunnel + VLESS WS

基于 **OutPlane + Xray + Cloudflare Quick Tunnel** 的轻量化 VLESS WebSocket 部署方案。

无需购买域名、无需配置 Cloudflare DNS、无需服务器公网 IP。部署成功后自动获取：

```text
*.trycloudflare.com
```

临时 Cloudflare Tunnel 域名，并自动生成可导入：

* v2rayN
* Mihomo / Clash Meta
* Shadowrocket
* sing-box

的 VLESS 节点。

同时支持配置 **Cloudflare 优选 IP**
---

## 项目特点

* 0 域名部署
* 无需 Cloudflare 账号
* 无需配置证书
* Cloudflare Quick Tunnel
* VLESS + WebSocket
* 自动开启 TLS
* 自动生成 UUID
* 支持固定 UUID
* 自动获取 `trycloudflare.com`
* 自动输出 VLESS 分享链接
* 支持 OutPlane Dockerfile 一键部署
* 支持 v2rayN
* 支持 Mihomo / Clash Meta
* 支持 Shadowrocket

---

# 一、工作原理

整体结构：

```text
客户端
   │
   │ VLESS + WS + TLS
   ↓
Cloudflare 优选 IP
或
xxxx.trycloudflare.com
   │
   ↓
Cloudflare Edge
   │
   ↓
Cloudflare Quick Tunnel
   │
   ↓
OutPlane
   │
   ↓
cloudflared
   │
   ↓
127.0.0.1:8080
   │
   ↓
Xray
   │
   ↓
Internet
```

如果不使用优选 IP：

```text
客户端
↓
xxxx.trycloudflare.com
↓
Cloudflare
↓
OutPlane
```

如果使用优选 IP：

```text
客户端
↓
Cloudflare 优选 IP
↓
Cloudflare
↓
xxxx.trycloudflare.com
↓
Tunnel
↓
OutPlane
```

必须保留真实 Tunnel 域名。

---

# OutPlane 部署

打开：

```text
https://outplane.com/
```

登录控制台。

选择：

```text
Create
↓
Application
```

选择从 Git 仓库部署。

填写：

```text
https://github.com/你的用户名/outplane-vless
```

构建方式：

```text
Dockerfile
```

启动命令：

```text
留空
```

因为 Dockerfile 已经包含：

```dockerfile
CMD ["/start.sh"]
```

---

# 环境变量

进入：

```text
Application
↓
Settings
↓
Environment
```

建议添加：

```text
UUID
PORT
WS_PATH
CF_IP_1
CF_IP_2
CF_IP_3
```

---

## UUID

例如：

```text
UUID=1d63806e-5b04-4db1-9daf-5a26f9c9581d
```

如果不填写：

```text
UUID
```

程序启动时会自动生成一个。

但是建议固定，否则重新部署后 UUID 可能变化。

---

## PORT

```text
PORT=8080
```

一般不需要修改。

---

## WS_PATH

例如：

```text
WS_PATH=/ws
```

也可以自定义：

```text
WS_PATH=/vless
```

或者：

```text
WS_PATH=/123456
```

---



# 查看节点

打开：

```text
Application
↓
Logs
```

正常情况下会看到：

```text
Cloudflare Tunnel created successfully!

Tunnel Domain:

example-random-name.trycloudflare.com

UUID:

1d63806e-5b04-4db1-9daf-5a26f9c9581d

Port:

443

Transport:

WebSocket

WS Path:

/ws

TLS:

Enabled
```

然后：

```text
Original Cloudflare Node
```

类似：

```text
vless://UUID@example-random-name.trycloudflare.com:443?encryption=none&security=tls&sni=example-random-name.trycloudflare.com&type=ws&host=example-random-name.trycloudflare.com&path=%2Fws#OutPlane-CF
```



# v2rayN

复制日志里的：

```text
vless://...
```

打开 v2rayN。

选择：

```text
服务器
↓
从剪贴板导入批量 URL
```

即可。

---

# Shadowrocket

可以直接复制：

```text
vless://...
```

然后：

```text
Shadowrocket
↓
从剪贴板导入
```

如果手动设置：

```text
类型：
VLESS
```

服务器：

```text
Cloudflare 优选 IP
```

端口：

```text
443
```

UUID：

```text
你的 UUID
```

传输：

```text
WebSocket
```

Path：

```text
/ws
```

Host：

```text
xxxx.trycloudflare.com
```

TLS：

```text
开启
```

SNI：

```text
xxxx.trycloudflare.com
```

---

# Mihomo / Clash Meta

假设：

```text
UUID:
1d63806e-5b04-4db1-9daf-5a26f9c9581d
```

Tunnel：

```text
abc-example.trycloudflare.com
```

三个优选 IP：

```text
104.16.10.20

104.17.25.36

172.64.100.50
```

配置：

```yaml
proxies:

  - name: CF-Preferred-01
    type: vless
    server: 104.16.10.20
    port: 443
    uuid: 1d63806e-5b04-4db1-9daf-5a26f9c9581d
    tls: true
    servername: abc-example.trycloudflare.com
    network: ws
    ws-opts:
      path: /ws
      headers:
        Host: abc-example.trycloudflare.com

  - name: CF-Preferred-02
    type: vless
    server: 104.17.25.36
    port: 443
    uuid: 1d63806e-5b04-4db1-9daf-5a26f9c9581d
    tls: true
    servername: abc-example.trycloudflare.com
    network: ws
    ws-opts:
      path: /ws
      headers:
        Host: abc-example.trycloudflare.com

  - name: CF-Preferred-03
    type: vless
    server: 172.64.100.50
    port: 443
    uuid: 1d63806e-5b04-4db1-9daf-5a26f9c9581d
    tls: true
    servername: abc-example.trycloudflare.com
    network: ws
    ws-opts:
      path: /ws
      headers:
        Host: abc-example.trycloudflare.com
```

---

# Mihomo 自动选择最快 IP

可以创建：

```yaml
proxy-groups:

  - name: CF-Auto
    type: url-test

    proxies:
      - CF-Preferred-01
      - CF-Preferred-02
      - CF-Preferred-03

    url: https://www.gstatic.com/generate_204

    interval: 300
```

这样 Mihomo 会定期测试：

```text
CF-Preferred-01

CF-Preferred-02

CF-Preferred-03
```

并选择当前延迟表现较好的节点。

---

# Cloudflare Tunnel 创建失败

查看 OutPlane Logs。

如果看到：

```text
QUIC timeout
```

本项目已经默认：

```text
--protocol http2
```

因此会通过 HTTP/2 建立 Tunnel。

核心命令：

```bash
cloudflared tunnel \
    --no-autoupdate \
    --protocol http2 \
    --url http://127.0.0.1:8080
```

---

# 出现 502

如果 Cloudflare 返回：

```text
502 Bad Gateway
```

重点检查：

```text
Xray 是否启动
```

```text
PORT 是否一致
```

例如：

```text
PORT=8080
```

cloudflared 也必须：

```text
127.0.0.1:8080
```

---

# 节点连不上

检查以下参数：

```text
协议：
VLESS
```

```text
端口：
443
```

```text
传输：
WebSocket
```

```text
TLS：
开启
```

```text
Path：
/ws
```

并确认：

```text
Host
```

和：

```text
SNI
```

都是：

```text
xxxx.trycloudflare.com
```

而不是 Cloudflare 优选 IP。

---

# OutPlane 重启后节点失效

Cloudflare Quick Tunnel 使用：

```text
*.trycloudflare.com
```

随机临时域名。

重新启动 cloudflared 后可能得到：

```text
新的 trycloudflare.com 域名
```

因此：

```text
旧 Host
旧 SNI
旧节点链接
```

可能失效。

此时进入：

```text
OutPlane
↓
Application
↓
Logs
```

复制最新：

```text
VLESS LINK
```

即可。

如果配置了：

```text
CF_IP_1
CF_IP_2
CF_IP_3
```

脚本也会自动重新生成新的 3 条优选节点。

---

# 为什么优选 IP 不会固定 Tunnel？

优选 IP 只是客户端连接：

```text
Cloudflare Edge
```

使用的入口 IP。

真正识别目标 Tunnel 的仍然是：

```text
Host
```

以及：

```text
SNI
```

因此：

```text
Cloudflare 优选 IP
```

可以保持不变。

但如果：

```text
trycloudflare.com
```

域名发生变化，那么：

```text
Host
```

和：

```text
SNI
```

必须同时更新。

---

# 推荐环境变量

建议最终使用：

```text
UUID=你的固定UUID

PORT=8080

WS_PATH=/ws

```

例如：

```text
UUID=1d63806e-5b04-4db1-9daf-5a26f9c9581d

PORT=8080

WS_PATH=/ws

```

---

# 最终效果

完成部署后日志自动输出：

```text
Cloudflare Tunnel

↓
abc-example.trycloudflare.com

↓
原始节点

OutPlane-CF

```

也就是说只需要：

```text
GitHub
↓
OutPlane Deploy
↓
查看 Logs
↓
复制节点
```

不需要自己手动拼接 VLESS 链接。

---

# 注意事项

Cloudflare Quick Tunnel 属于临时 Tunnel，主要用于测试和开发。

因此可能存在：

* Tunnel 域名变化
* 重启后节点需要更新
* 不适合作为长期固定域名入口
* 不保证使用 Cloudflare 优选 IP 一定比域名直连速度快

优选 IP 实际效果与：

```text
运营商

地区

时间段

网络线路

Cloudflare 节点状态
```

有关。

建议定期重新测试。

---

# License

本项目仅用于技术学习、网络测试及个人用途。

请遵守当地法律法规以及 OutPlane、Cloudflare 等相关服务的使用条款。

使用本项目产生的任何风险由使用者自行承担。
