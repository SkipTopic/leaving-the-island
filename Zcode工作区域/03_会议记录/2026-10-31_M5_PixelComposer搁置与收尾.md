# 开发记录：Pixel Composer 尝试搁置 + 收尾（2026-10-31 晚）

> 用户指令："卡住了就查 GitHub 源码，不行就放弃，换更好的办法" → 最终拍板：**放弃 PC，特效改用
> Godot 自带粒子系统**（下轮 T2 任务）。

## 做成的事（成果保留，全部可复用）

1. **全局安装**：`C:\Users\admin\.zcode\tools\PixelComposer`（Steam 版 1.22.0.5，357MB；用户购买的原件在
   `工具\Pixel Composer` 未动）。
2. **Steam 绕过**：本机无 Steam 导致 exe 秒退（退出码 0、不写日志）。用 **gbe_fork（Goldberg）模拟器**
   替换 `steam_api64.dll`（原件备份 .bak）→ 启动成功、日志确认 SteamAPI_Init 通过。
3. **.pxc 格式逆向**：`PXCX` + u32(主数据偏移) + THMB(zlib RGBA 缩略图) + META(u32版本+版本串) + zlib(JSON+NUL)；
   集合 .pxcc = 裸 JSON。**`pxc_lib.py`** 可程序化读/写/造工程（含节点/连线样板）。
4. **CLI 无头导出管线打通**：`PixelComposer.exe 工程.pxc -h -sl` → Solid→Export 最小工程实测导出 PNG。
   坑：命令行会把**中文路径**切碎（参数乱飞）——工程与输出必须纯 ASCII。
5. **源码定位**（GitHub main 分支）：Project 类 = `scripts/project_data/project_data.gml`；
   Node 基类 = `scripts/node_data/node_data.gml`（inputs 按位置密集应用）；加载循环 =
   `objects/project_loader/Step_0.gml`（nodeLoad 逐个创建，返回空则静默跳过）。

## 卡住点（止损原因）

官方 `Generator/Effects/Explosion.pxcc` 的 Node_Shape/Node_Gradient 两节点被 nodeLoad **静默返回空**
（无异常文本），六种修法（降版本/清输入/补 input_fix_len/data_length/归一化 inspectInputs/删节点重连）
均无效——删掉两节点后工程能加载导出，但导出的是空白第 0 帧，序列帧导出（Type 枚举/输入映射）还有第二层
未解坑。按用户指令止损。

**全部细节与恢复指南**：`Zcode工作区域/06_工具脚本/README_pxc管线.md`

## 决定与去向

- **特效改用 Godot 自带 CPUParticles2D**（项目粒子管线 M4 已建好、冒烟全绿），接入点已写进
  交接文档 §11「T2 爆发特效」——新会话第一个任务。
- 交接文档 §3/§11、记忆文件均已更新；工程保持 73/73 全绿状态，无未收尾改动。
