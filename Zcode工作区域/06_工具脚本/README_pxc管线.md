# Pixel Composer 无头管线 — 存档（2026-10-31 搁置）

> 状态：**已搁置**（用户决定改用 Godot 自带粒子系统做特效）。
> 本文档保留全部逆向成果，以后若要恢复（比如换台能跑 GUI 的机器），从这里继续。

## 已打通的部分（全部可用）

1. **安装**：`C:\Users\admin\.zcode\tools\PixelComposer\`（Steam 版 1.22.0.5 全量副本 357MB）。
   Steam 校验已用 **Goldberg 模拟器**绕过：`steam_api64.dll` 已替换为
   gbe_fork（Detanup01/gbe_fork release-2026_09_27 debug/regular/x64），原 DLL 备份为
   `steam_api64.dll.steam.bak`。本机无 Steam 也能启动。
2. **CLI 无头导出**（已实测成功）：
   ```
   PixelComposer.exe <工程.pxc> -h -sl
   ```
   `-h` 无头 `-sl` 跳过 Lua；工程里必须有 **Export 节点**；输出路径必须是**纯 ASCII**
   （GameMaker 命令行会把中文路径切碎成参数——血泪教训）。
3. **.pxc 二进制格式**（逆向自 1.21.8 样例，1.22 向下兼容可读）：
   ```
   b'PXCX' + u32(主数据偏移) + b'THMB'+u32+zlib(256*256*4 RGBA) + b'META'+u32(u32版本号+版本串+NUL) + zlib(JSON+NUL)
   ```
   集合 `.pxcc` = 裸 JSON `{versionStr, version, nodes[]}`。
4. **`pxc_lib.py`（本目录）**：`write_pxc/read_pxc/make_node/inp/base_project`。
   - 工程骨架取自官方样例 hlsl.pxc（键/类型全兼容，勿手写骨架——缺键会让 1.22 反序列化炸）。
   - 节点连接：目标节点 `inputs[i]` 里写 `from_node`(源id)/`from_index`/`from_tag:0`/`linked:true`。
   - 实测：Solid→Export 最小工程 CLI 导出 PNG 成功。

## 卡住的地方（恢复时从这里继续）

- 官方集合 `Generator/Effects/Explosion.pxcc` 的 24 节点中 **Node_Shape / Node_Gradient 两个
  在 1.22 无头加载时被静默跳过**（nodeLoad 返回空、无异常文本），导致后续连线断。
  已试过：降版本 121092→121056、清空 inputs、补 input_fix_len/data_length、归一化 inspectInputs——全无效。
- **下一步线索**：加载循环在 `objects/project_loader/Step_0.gml`（try/catch 包 `nodeLoad`），
  `nodeLoad` 函数本体还没找到（4390 个脚本；Project 类在 `scripts/project_data/project_data.gml`，
  Node 基类在 `scripts/node_data/node_data.gml`，输入应用=按位置密集 min(实长,存长)）。
  建议：`git clone --depth 1 https://github.com/Ttanasart-pt/Pixel-Composer` 后本地 grep `nodeLoad`。
- Export 节点输入索引表（源码 `scripts/node_export/node_export.gml` 已确认）：
  0=Surface 1=Directory(**目录**非文件名) 20=File name 2=Template"%d%n" 3=Type(0单图 1序列 2动画)
  9=Format(0=.png) 19=Scale 12=FrameRange 8=Framerate。注意 newInput 有空洞索引（5/11/14/21/24/25 无），
  存档 inputs 数组的映射规则未最终确认（密集按序 vs 按索引），这是第二个未解坑。
- 调试手法：CLI 的 stdout 有完整日志（`STATUS:/LOAD:/CLI:`），每次改完直接跑命令看输出；
  `LOAD: File version mismatch : loading file version 121070 to 122003` 是**正常**的旧版兼容提示，不是错误。

## 为什么搁置

 Explosion 序列帧在当日无法保证短时间内修通（用户判断止损），改用 Godot 自带
 CPUParticles2D 实时粒子（项目内管线已就绪、测试全绿），见交接文档 §11 下一轮任务。
