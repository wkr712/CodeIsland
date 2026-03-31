# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- 项目初始化

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
