# Laifen ESPHome Bridge

通过 ESP32-C3 BLE 桥接徕芬 L1 Pro 落地灯到 Home Assistant。

## 文件说明

| 文件 | 用途 |
|------|------|
| `laifen-bridge.yaml` | 徕芬桥接固件主配置 |
| `ble-scanner-active.yaml` | BLE 扫描器（调试用，主动扫描） |
| `.env` | WiFi 凭据和环境变量（不要提交到 git） |
| `.env.example` | 环境变量模板 |

## 硬件要求

- ESP32-C3 开发板
- 徕芬 L1 Pro 落地灯
- USB 数据线

## 快速开始

### 1. 安装 ESPHome

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install esphome
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填入你的 WiFi 信息：

```env
WIFI_SSID=你的WiFi名称
WIFI_PASSWORD=你的WiFi密码
ESPHOME_FALLBACK_AP_PASSWORD=Laifen123
```

### 3. 查找徕芬灯 MAC 地址

如果不知道灯的 MAC 地址，先刷扫描器固件：

```bash
set -a && source .env && set +a
esphome run ble-scanner-active.yaml --device /dev/cu.usbmodemXXXX
```

扫描 3 分钟，找到徕芬灯的 MAC 地址（格式：`XX:XX:XX:XX:XX:XX`）。

### 4. 配置徕芬灯 MAC 地址

编辑 `laifen-bridge.yaml`，修改第 4 行：

```yaml
laifen_mac: "你的徕芬灯MAC地址"
```

### 5. 编译并刷入固件

```bash
set -a && source .env && set +a
esphome run laifen-bridge.yaml --device /dev/cu.usbmodemXXXX
```

### 6. 验证

刷入成功后，访问 `http://esp32-c3-laifen-bridge.local` 应该能看到 Web 控制界面。

## 控制方式

### Web 界面
访问 `http://esp32-laifen-bridge.local`

### HTTP API
```bash
# 开灯
curl -X POST -H "Content-Length: 0" "http://esp32-laifen-bridge.local/switch/laifen_master_light/turn_on"

# 关灯
curl -X POST -H "Content-Length: 0" "http://esp32-laifen-bridge.local/switch/laifen_master_light/turn_off"

# 设置亮度 (1-100)
curl -X POST -H "Content-Length: 0" "http://esp32-laifen-bridge.local/number/laifen_upper_brightness/set?value=50"

# 设置色温 (2700-6500K)
curl -X POST -H "Content-Length: 0" "http://esp32-laifen-bridge.local/number/laifen_color_temperature/set?value=4000"
```

### Home Assistant
如果配置了 ESPHome 集成，灯会自动出现在 HA 中。

## 环境变量

创建 `.env` 文件（参考 `.env.example`）：

```bash
cp .env.example .env
```

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `WIFI_SSID` | WiFi 名称（不设置则使用 AP 模式） | 空 |
| `WIFI_PASSWORD` | WiFi 密码 | 空 |
| `ESPHOME_FALLBACK_AP_PASSWORD` | ESP32 备用热点密码 | `Laifen123` |

## 故障排查

### ESP32 无法连接 WiFi
1. 检查 `.env` 中的 `WIFI_SSID` 和 `WIFI_PASSWORD`
2. 确保刷入时已加载环境变量：`set -a && source .env && set +a`
3. 连接 ESP32 的备用热点 `ESP32 Laifen Bridge`（密码：`Laifen123`）
4. 访问 `192.168.4.1` 重新配置 WiFi

### 无法找到徕芬灯
1. 确保灯已开机
2. 确保灯在 ESP32 附近（1-2 米内）
3. 确保灯在配对模式（可能需要长按电源键）
4. 使用 `ble-scanner-active.yaml` 扫描确认灯的 MAC 地址

### 灯不响应命令
1. 检查 BLE 连接状态（日志中应显示 `State: ESTABLISHED`）
2. 重启 ESP32
3. 重启徕芬灯

## 技术细节

- BLE Service UUID: `0000ff01-0000-1000-8000-00805f9b34fb`
- BLE Control Characteristic UUID: `0000ff02-0000-1000-8000-00805f9b34fb`
- 协议来源：Android HCI snoop 逆向

## 许可证

MIT License
