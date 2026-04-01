# CodeIsland 测试计划

## 测试目标
验证项目的各个核心组件是否正常工作，确保代码质量和功能完整性。

---

## 1. 单元测试

### 1.1 核心系统测试

#### GameManager 测试
- [ ] 新游戏初始化
- [ ] 存档/读档功能
- [ ] 场景切换
- [ ] 课程完成逻辑

#### SaveManager 测试
- [ ] 存档创建
- [ ] 存档读取
- [ ] 存档删除
- [ ] 自动保存

#### PythonExecutor 测试
- [ ] 代码执行
- [ ] 安全检查
- [ ] 验证规则

### 1.2 数据系统测试

#### QuestSystem 测试
- [ ] 任务加载
- [ ] 任务接受
- [ ] 进度更新
- [ ] 任务完成

#### LessonManager 测试
- [ ] 课程加载
- [ ] 进度追踪
- [ ] 章节解锁

---

## 2. 集成测试

### 2.1 游戏流程测试
```
1. 启动游戏 → 主菜单
2. 新游戏 → 创建玩家
3. 进入村庄 → 移动探索
4. 与NPC对话 → 接受任务
5. 打开代码编辑器 → 编写代码
6. 运行验证 → 完成课程
7. 获得奖励 → 继续下一课
```

### 2.2 存档流程测试
```
1. 游戏中保存
2. 退出游戏
3. 继续游戏 → 加载存档
4. 验证数据恢复
```

---

## 3. 测试用例示例

### 3.1 代码执行测试

```python
# 测试1: 简单print
test_code = 'print("Hello")'
expected = "Hello"

# 测试2: 变量操作
test_code = 'x = 5\ny = 3\nprint(x + y)'
expected = "8"

# 测试3: 条件判断
test_code = 'if True:\n    print("Yes")\nelse:\n    print("No")'
expected = "Yes"
```

### 3.2 课程验证测试

```python
# 第1课: 变量定义
code = 'name = "旅行者"'
patterns = ["name = "]
should_pass = True

# 第3课: print函数
code = 'print("Hello, Code Island!")'
expected_output = "Hello, Code Island!"
should_pass = True
```

---

## 4. 测试执行

### 4.1 手动测试清单

1. **启动测试**
   - [ ] 运行项目无报错
   - [ ] 主菜单正常显示
   - [ ] 按钮可点击

2. **玩家系统测试**
   - [ ] 玩家可以移动
   - [ ] 玩家可以与NPC交互
   - [ ] 碰撞检测正常

3. **代码编辑器测试**
   - [ ] 编辑器可输入
   - [ ] 运行按钮工作
   - [ ] 输出正确显示

4. **课程系统测试**
   - [ ] 课程列表显示
   - [ ] 代码验证工作
   - [ ] 奖励正确发放

### 4.2 自动化测试

创建 `tests/` 目录存放测试脚本：

```
tests/
├── test_game_manager.gd
├── test_save_manager.gd
├── test_python_executor.gd
├── test_quest_system.gd
└── test_lesson_manager.gd
```

---

## 5. 性能测试

- [ ] 加载时间 < 3秒
- [ ] 场景切换 < 1秒
- [ ] 代码执行 < 2秒
- [ ] 内存占用合理

---

## 6. 兼容性测试
- [ ] Windows 10/11 ✓
- [ ] 不同分辨率
- [ ] 不同DPI设置

---

*测试计划创建完成*
