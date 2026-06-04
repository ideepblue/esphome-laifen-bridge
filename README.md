# Laifen L1 Pro 地灯 - ESP32 Home Assistant 桥接器

通过ESP32-C3的BLE功能，将Laifen L1 Pro地灯接入Home Assistant。

## 硬件

- **开发板**: ESP32-C3-DevKitM-1 或 Super Mini
- **接口**: USB-C（供电+串口）
- **按键**: BOOT（GPIO9）和 RESET（EN）

## 快速开始

### 1. 配置WiFi

编辑 `.env` 文件：
```
WIFI_SSID=你的WiFi名称
WIFI_PASSWORD=你的WiFi密码
ESPHOME_FALLBACK_AP_PASSWORD=Laifen123
```

### 2. 编译并刷入固件

```bash
cd esphome-laifen-bridge

# 导入环境变量
export $(cat .env | grep -v '^#' | xargs)

# 编译+刷入+查看日志（推荐）
esphome run laifen-bridge.yaml

# Super Mini板子
esphome run laifen-bridge-super-mini.yaml
```

### 3. 验证连接

固件启动后：
1. 查看串口日志，确认WiFi连接成功
2. 日志中应显示 "Connected to Laifen L1 Pro"
3. 在Home Assistant中检查设备是否出现

## WiFi配置

### 方式一：环境变量（推荐）

固件读取系统环境变量，`.env`文件需要手动export：

```bash
export $(cat .env | grep -v '^#' | xargs)
esphome run laifen-bridge.yaml
```

### 方式二：Fallback AP模式

如果WiFi连接失败30秒，设备自动启动AP热点：
- **SSID**: `ESP32 Laifen Bridge Fallback`
- **密码**: `.env`中的 `ESPHOME_FALLBACK_AP_PASSWORD`
- **配置页面**: 连接后访问 `http://192.168.4.1/`

**注意**: AP模式下BLE自动禁用（ESP32-C3单核共享射频，两者同时工作不稳定）

## 常用命令

### 编译固件

```bash
esphome compile laifen-bridge.yaml
```

### 刷入固件

```bash
# 指定串口
esphome run laifen-bridge.yaml --device /dev/tty.usbmodem101
```

### 查看日志

```bash
# USB连接查看
esphome logs laifen-bridge.yaml --device /dev/tty.usbmodem101

# 网络查看（WiFi已连接时）
esphome logs laifen-bridge.yaml
```

### OTA更新

```bash
# 通过IP地址
esphome run laifen-bridge.yaml --device 192.168.1.100

# 通过mDNS
esphome run laifen-bridge.yaml --device laifen-bridge.local
```

### 清除WiFi配置

```bash
# 抹除整个flash
esptool.py --chip esp32c3 --port /dev/tty.usbmodem101 erase_flash

# 只抹除NVS（WiFi凭证）
esptool.py --chip esp32c3 --port /dev/tty.usbmodem101 \
  erase_region 0x390000 0x70000
```

### 重置按钮

固件包含 "Reset WiFi" 按钮（在Home Assistant中）：
- **平台**: `factory_reset`
- **效果**: 清除WiFi凭证并重启

或者在启动时按住BOOT键5秒。

## 分区表

```
# ESP32-C3 分区表
# 名称     类型   子类型    偏移地址   大小
nvs       data  nvs        0x9000    0x5000
otadata   data  ota        0xe000    0x2000
app0      app   ota_0      0x10000   0x140000
app1      app   ota_1      0x150000  0x140000
spiffs    data  spiffs     0x290000  0x160000
coredump  data  coredump   0x3F0000  0x10000
```

**重要**: WiFi凭证存储在NVS分区（0x9000, 0x5000字节）

## 故障排除

### WiFi "Auth Expired" 错误

这个错误表示WiFi认证失败，可能原因：

1. **密码错误**: 检查WiFi密码
2. **路由器安全模式**: 某些路由器需要WPA2/WPA3混合模式
3. **5GHz网络**: ESP32-C3只支持2.4GHz WiFi
4. **路由器缓存**: 重启路由器清除缓存凭证
5. **距离问题**: 将ESP32靠近路由器

### WiFi AP不可见

如果手机搜索不到AP网络：

1. **先抹除flash**:
   ```bash
   esptool.py --chip esp32c3 --port /dev/tty.usbmodem101 erase_flash
   ```

2. **使用简单测试固件**:
   ```bash
   esphome run test-ap-only.yaml
   ```

3. **确认AP可用**后再刷完整固件

### BLE连接失败

1. **检查Laifen设备是否开机**
2. **验证MAC地址**是否匹配
3. **查看Home Assistant日志**

### 串口无输出

1. **安装CP210x驱动**（ESP32-C3-DevKitM-1）
2. **安装CH340驱动**（Super Mini）
3. **检查USB线**是否支持数据传输
4. **尝试其他USB端口**

### 编译错误

1. **清除构建缓存**:
   ```bash
   rm -rf .esphome/build/
   ```

2. **更新ESPHome**:
   ```bash
   pip install --upgrade esphome
   ```

3. **检查YAML语法**:
   ```bash
   esphome config laifen-bridge.yaml
   ```

## BLE命令组合

固件支持一次性发送多个属性（开关+亮度+色温）：

### 组合命令协议

```
[0xAA, 0x03, 0x06, 0x00, 0x00, 0x07, 0x00,
 upper_on, upper_brightness, lower_on, lower_brightness,
 color_temp_high, color_temp_low, checksum]
```

| 方法 | BLE写入次数 | 延迟 | 可靠性 |
|------|-------------|------|--------|
| 组合命令 (0x06) | 1次 | ~50ms | 高 |
| 逐个发送 | 3-4次 | ~750ms | 中 |

### Home Assistant自动化示例

**方式一：使用组合命令服务（推荐，1条BLE命令）**

固件暴露了 `laifen_set_all` 服务，可以一次性设置所有参数：

```yaml
action:
  - service: esphome.esp32_c3_laifen_bridge_laifen_set_all
    data:
      upper_on: true
      upper_brightness: 80
      lower_on: true
      lower_brightness: 60
      kelvin: 4000
```

**方式二：逐个设置（多条BLE命令）**

```yaml
action:
  - service: switch.turn_on
    target:
      entity_id: switch.laifen_upper_light
  - service: number.set_value
    target:
      entity_id: number.laifen_upper_brightness
    data:
      value: 80
  - service: number.set_value
    target:
      entity_id: number.laifen_color_temperature
    data:
      value: 4000
```

**方式三：使用场景**

1. 在HA中创建场景，设置所有实体状态
2. 应用场景后，调用 `button.laifen_query_status` 触发组合命令发送

## 固件版本管理

### 版本号

简单版本号（如 `v1`, `v2`），当前版本：**v2**

版本存储在：
- ESPHome flash内存（HA设备信息可见）
- 传感器：`sensor.firmware_version`

### 一键编译+归档

自动加载 `.env`，编译两个板子，归档到 `firmware-archives/`：

```bash
./scripts/build-and-archive.sh
```

### 仅归档已编译的固件

如果已经编译过，只执行归档：

```bash
./scripts/archive-firmware.sh
```

脚本会自动：
- 从YAML读取版本号
- 归档两个板子（laifen-bridge 和 laifen-bridge-super-mini）

### OTA回滚

恢复到旧版本：

1. 在 `firmware-archives/` 中找到目标版本
2. 通过ESPHome CLI上传：
   ```bash
   esphome upload laifen-bridge.yaml --device <ip> --file firmware-archives/v1/esp32-c3-laifen-bridge-v1.ota.bin
   ```
3. 或通过Home Assistant：设置 → 设备 → ESPHome → 更新 → 手动

## 文件说明

- `laifen-bridge.yaml` - ESP32-C3-DevKitM-1 主配置
- `laifen-bridge-super-mini.yaml` - Super Mini板子配置
- `laifen-bridge-simple.yaml` - 简化固件（仅WiFi）
- `test-ap-only.yaml` - AP模式测试固件
- `.env` - WiFi凭证（不提交到git）
- `scripts/build-and-archive.sh` - 一键编译+归档脚本
- `scripts/archive-firmware.sh` - 仅归档已编译固件
- `firmware-archives/` - 版本化固件二进制文件

## 资源链接

- [ESPHome文档](https://esphome.io/)
- [ESP32-C3数据手册](https://www.espressif.com/sites/default/files/documentation/esp32-c3_datasheet_en.pdf)
- [Laifen L1 Pro](https://www.laifentech.com/)
- [Home Assistant ESPHome集成](https://www.home-assistant.io/integrations/esphome/)
