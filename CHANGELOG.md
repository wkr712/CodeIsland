# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 项目初始化

---

## [0.7.0] - 2026-03-24

### Added
- **第7章课程**: 图书管理员 (5课) - 文件操作、异常处理、模块、JSON
- **第8章课程**: 岛屿守护者 (8课) - 项目规划、综合实战、毕业典礼

### 课程内容
#### 第7章: 图书管理员
- lesson_7_1: 古老的卷轴 (文件读取)
- lesson_7_2: 记录魔法 (文件写入)
- lesson_7_3: 防护结界 (try/except异常处理)
- lesson_7_4: 魔法模块 (模块导入)
- lesson_7_5: 图书管理员毕业 (JSON数据处理)

#### 第8章: 岛屿守护者
- lesson_8_1: 项目规划 (项目结构)
- lesson_8_2: 玩家系统 (类设计实践)
- lesson_8_3: 敌人系统 (敌人类设计)
- lesson_8_4: 战斗系统 (战斗逻辑)
- lesson_8_5: 存档系统 (游戏存档)
- lesson_8_6: 游戏主循环 (游戏循环)
- lesson_8_7: 守护者试炼 (综合项目)
- lesson_8_8: 毕业典礼 (项目总结)

### Milestone
- 🎉 全部8章43课教学内容完成！
- 🎓 完整Python学习体系：从入门到项目实战

---

## [0.6.0] - 2026-03-24

### Added
- **第5章课程**: 魔法学院 (7课) - 函数定义、参数、返回值、递归
- **第6章课程**: 宠物驯养师 (6课) - 类与对象、继承、类属性

### 课程内容
#### 第5章: 魔法学院
- lesson_5_1: 第一个咒语 (函数定义)
- lesson_5_2: 咒语参数 (函数参数)
- lesson_5_3: 多重参数 (多参数函数)
- lesson_5_4: 返回值 (return语句)
- lesson_5_5: 默认参数 (默认参数值)
- lesson_5_6: 递归魔法 (递归函数)
- lesson_5_7: 魔法毕业考 (综合练习)

#### 第6章: 宠物驯养师
- lesson_6_1: 认识宠物 (类与对象)
- lesson_6_2: 宠物属性 (实例属性)
- lesson_6_3: 宠物行动 (实例方法)
- lesson_6_4: 宠物家族 (继承)
- lesson_6_5: 魔法属性 (类属性和静态方法)
- lesson_6_6: 驯养大师 (综合练习-宠物战斗系统)

---

## [0.5.0] - 2026-03-24

### Added
- **第3章课程**: 森林迷宫 - 5课 (if/elif/else、逻辑运算符、嵌套判断)
- **第4章课程**: 矿工的秘密 - 6课 (for循环、while循环、列表操作、列表推导式)

### 课程内容
#### 第3章: 森林迷宫
- lesson_3_1: 岔路口的选择 (if语句)
- lesson_3_2: 多重选择 (elif语句)
- lesson_3_3: 逻辑与或非 (and/or/not)
- lesson_3_4: 嵌套判断 (嵌套if)
- lesson_3_5: 森林宝箱 (综合练习)

#### 第4章: 矿工的秘密
- lesson_4_1: 数矿石 (for循环基础)
- lesson_4_2: range的力量 (range函数)
- lesson_4_3: 累加计算 (循环累加)
- lesson_4_4: 持续挖掘 (while循环)
- lesson_4_5: 列表操作 (append/remove/pop)
- lesson_4_6: 矿石分类 (列表推导式)

---

## [0.4.0] - 2026-03-24

### Added
- **第1章课程**: 5个完整课程 (变量、数据类型、print函数、布尔值)
- **第2章课程**: 6个完整课程 (算术运算符、整除取余、比较运算符、字符串操作)
- **LessonPanel**: 课程选择UI界面
- **LessonManager**: 课程管理和章节解锁系统

### 课程内容
#### 第1章: 初入代码岛
- lesson_1_1: 第一个变量
- lesson_1_2: 数字的力量
- lesson_1_3: 输出你的声音
- lesson_1_4: 变量的魔法
- lesson_1_5: 真假之间

#### 第2章: 商人的请求
- lesson_2_1: 加减乘除
- lesson_2_2: 整数除法
- lesson_2_3: 比较大小
- lesson_2_4: 字符串拼接
- lesson_2_5: 字符串方法
- lesson_2_6: 格式化字符串

---

## [0.3.0] - 2026-03-24

### Added
- **Player**: 玩家控制器 (移动、动画、交互、冲刺)
- **NPC**: NPC系统 (行为模式、对话触发、任务提供)
- **DialogueSystem**: 对话系统 (加载、显示、选项)
- **HUD**: 游戏界面 (玩家状态、经验值、任务追踪)
- **Village**: 新手村场景 (出生点、NPC位置、触发器)

### Scenes
- `scenes/entities/player.tscn`: 玩家场景
- `scenes/entities/npc.tscn`: NPC场景
- `scenes/ui/hud.tscn`: HUD界面
- `scenes/world/village.tscn`: 新手村场景

### Technical
- 玩家输入映射: WASD/方向键移动, Shift冲刺, E交互
- NPC行为: STATIC/PATROL/RANDOM/FOLLOW
- 对话格式: JSON数据文件

---

## [0.2.0] - 2026-03-24

### Added
- **GameManager**: 游戏状态管理、场景切换、玩家数据管理
- **AudioManager**: 背景音乐和音效播放控制
- **SaveManager**: 游戏存档/读取、设置管理、自动保存
- **PythonExecutor**: Python代码执行器、安全检查、代码验证
- **QuestSystem**: 任务管理、进度追踪、奖励发放
- **PlayerData**: 玩家数据类 (等级、背包、成就等)
- **CodeEditor**: 代码编辑器UI、语法高亮、运行/验证功能
- **MainMenu**: 主菜单UI、新游戏/继续/设置按钮
- 课程数据结构 (第1章5课)
- 任务数据结构
- 对话数据结构
- 物品数据结构

### Technical
- 自动加载单例: GameManager, AudioManager, SaveManager, PythonExecutor
- 场景结构: scenes/main.tscn, scenes/ui/menu.tscn, scenes/ui/code_editor.tscn
- 数据文件格式: JSON

---

## [0.1.0] - 2026-03-24

### Added
- 初始化Godot 4.3项目结构
- 创建完整目录结构 (assets, scenes, scripts, data, resources, addons)
- 添加项目配置文件 (project.godot)
- 添加项目图标 (icon.svg)
- 创建README.md项目说明文档
- 创建MIT开源协议文件
- 创建CHANGELOG.md版本日志
- 配置Git版本控制
- 配置GitHub远程仓库

### Technical
- 游戏分辨率: 1280x720
- 渲染方式: Forward Plus
- 输入映射: WASD/方向键移动, E交互

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| v0.1.0 | 2026-03-24 | 项目初始化 |
| v0.2.0 | TBD | 核心系统开发 |
| v0.3.0 | TBD | 游戏世界创建 |
| v0.4.0 | TBD | 第1-2章教学内容 |
| v0.5.0 | TBD | 第3-4章教学内容 |
| v0.6.0 | TBD | 第5-6章教学内容 |
| v0.7.0 | TBD | 第7-8章教学内容 |
| v0.8.0 | TBD | 内测版本 |
| v0.9.0 | TBD | 公测版本 |
| v1.0.0 | TBD | 正式发布 |

---

[Unreleased]: https://github.com/YOUR_USERNAME/CodeIsland/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YOUR_USERNAME/CodeIsland/releases/tag/v0.1.0
