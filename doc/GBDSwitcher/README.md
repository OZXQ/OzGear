# GBDSwitcher (v0.1)

Standalone Gear & Action Bar Auto-Switcher for Turtle WoW (1.12) specifically designed for the **Goblin Brainwashing Device (GBD)**.

---
## 🇬🇧 English Documentation

### Features
- **Zero Dependencies**: Completely independent. Does not rely on `ItemRack` or `ActionBarProfiles`.
- **Auto-Switching (Slots 1-4)**: Automatically loads saved Gear and Action Bars when selecting Spec 1-4 from a Goblin Brainwashing Device dialog.
- **Custom Profiles (Slots 5-10)**: 6 extra, renameable slots that allow you to manually save and load specialized gear/bar loadouts anytime.
- **Smart Delay**: Action bars inherently have a server delay; configure a custom delay to accurately snap them into place after a gear swap.

### Usage
Type `/gbds` in-game to open the configuration panel.

#### Interface Guide
1. **Prepare**: Equip your gear and arrange your action bars for "Spec 1".
2. **Save**: Open `/gbds` and click **Save G** (saves gear) and **Save B** (saves bars) on the `Spec 1` row. 
3. **Repeat**: Do the same for your other specs.
4. **Automate**: Next time you talk to the Goblin Brainwashing Device and click "Activate 1st Spec", your gear and bars will swap automatically.
   
- **LG / LB (Load Gear / Load Bars)**: Manually load saved gear or bars for **Custom Profiles (Slots 5-10)** since they are not triggered by GBD.

#### Slash Commands
- `/gbds` - Toggle config window
- `/gbds save <1-10>` - Save gear and bars into the specified slot
- `/gbds load <1-10>` - Manually load gear and bars from the specified slot
- `/gbds list` - Print to chat your currently saved spec data
- `/gbds toggle` - Turn auto-switching ON/OFF
- `/gbds delay <sec>` - Change the action bar load delay (default 2s)

---

## 🇨🇳 中文说明 (Chinese)

适配乌龟服 (Turtle WoW 1.12) 的独立**“地精洗脑装置 (GBD)”**双天赋/装备/按键自动切换器。

### 核心功能
- **完全独立**: 零依赖。不再依赖、挂载沉重的 `ItemRack` 或 `ActionBarProfiles` 插件。
- **自动切换 (槽位 1-4)**: 绑定 GBD 的天赋 1 到 4。当点击对话选项激活天赋时，插件将**全自动**换装、延迟加载动作条！
- **自定义方案 (槽位 5-10)**: 额外的 6 个扩展槽位，支持自定义名字（例如：“打钱套”、“PVP套”），用于手动保存和加载。这些与洗脑器无关。
- **智能延迟锁定**: 断开连接、动作条切换、拾取装备都会有延迟。你可通过滑动条精确控制读取动作条前的等待时间（默认 2 秒）。

### 使用说明
在游戏内输入 `/gbds` 打开主面板。

#### 操作指南
1. **准备方案**: 穿上你要保存配置的对应装备，然后拖拽好你想要的技能动作条。
2. **存入**: 在主面板点击任意目标行的 **Save G (存装备)** 和 **Save B (存按键)** 按钮。（比如天赋1就存在槽位1）
3. **自动化**: 再次对话地精洗脑器选择“启用 1（或 2、3）天赋”时，插件会自动将当前身上的装备和条替换为你刚刚保存的状态。
   
- **LG / LB**: 代表手动加载（Load Gear / Load Bars）。这是针对 5-10 槽位的自定义方案专属的手动读取按钮。

#### 进阶技巧与命令
- `/gbds` - 开/关主面板
- `/gbds save <1-10>` - 一键把目前状态存入指定的槽（默认 1~4 对应洗脑器的四天赋）
- `/gbds load <1-10>` - 强行手动读取指定槽位的状态
- `/gbds list` - 列出你存了哪些方案菜单（会显示存了多少件装备和多套按键）
- `/gbds toggle` - 开启/关闭 GBD 全自动运作
- `/gbds delay <秒数>` - 调整动作条换条的延迟响应（默认极稳的 2s 即可）

#### 📂 真·文件备份与转移
因为魔兽世界的安全限制，插件无法直接在桌面输出独立的 `.txt` 文件。如果希望对完整配置进行彻底的文件级备份，或想通过网盘一次性发给多位朋友，请前往以下路径复制此角色文件：
> `乌龟服文件夹 \ WTF \ Account \ 您的账号名 \ 您的服务器名 \ 您的角色名 \ SavedVariables \ GBDSwitcher.lua`
将这个几 KB 大小的 `.lua` 覆盖文件发给小号群、或覆盖到其他角色的对应目录里，也能瞬间实现“全通配置转移”。
