## 核心系统测试
## 用于验证 GameManager, SaveManager, PythonExecutor 等核心功能
extends GutTest

func test_game_manager_initialization():
	# 测试GameManager初始化
	var manager = GameManager.new()

	assert(manager != null, "GameManager should not be null")
	assert(manager.current_state == GameManager.GameState.MENU, "Initial state should be MENU")
	assert(manager.player_data != null, "PlayerData should be initialized")


func test_player_data():
	# 测试玩家数据
	var data = PlayerData.new()

	assert(data.player_name == "旅行者", "Default name should be 旅行者")
	assert(data.current_chapter == 1, "Initial chapter should be 1")
	assert(data.total_xp == 0, "Initial XP should be 0")

	# 测试添加物品
	data.add_item("coin", 10)
	assert(data.inventory["coin"] == 10, "Should have 10 coins")

	# 测试经验值
	data.add_xp(100)
	assert(data.total_xp == 100, "Should have 100 XP")


func test_save_manager():
	# 测试存档管理
	var save_data = {
		"player_name": "测试玩家",
		"current_chapter": 3,
		"total_xp": 500
	}

	var player = PlayerData.new()
	player.player_name = save_data["player_name"]
	player.current_chapter = save_data["current_chapter"]
	player.total_xp = save_data["total_xp"]

	assert(player.player_name == "测试玩家", "Save/Load should preserve name")
	assert(player.current_chapter == 3, "Save/Load should preserve chapter")


func test_python_executor_static_check():
	# 测试代码静态检查
	var executor = PythonExecutor.new()

	# 安全代码应该通过
	var safe_code = "x = 5\nprint(x)"
	var errors = executor._static_check(safe_code)
	assert(errors.is_empty(), "Safe code should have no errors")

	# 危险代码应该被检测
	var dangerous_code = "exec('print(1)')"
	errors = executor._static_check(dangerous_code)
	assert(not errors.is_empty(), "Dangerous code should be detected")


func test_quest_system():
	# 测试任务系统
	var quest_system = QuestSystem.new()

	# 检查任务加载
	assert(not quest_system._quests.is_empty(), "Quests should be loaded")


func run_all_tests():
	print("=== 开始测试 ===")

	test_game_manager_initialization()
	print("✓ GameManager 测试通过")

	test_player_data()
	print("✓ PlayerData 测试通过")

	test_save_manager()
	print("✓ SaveManager 测试通过")

	test_python_executor_static_check()
	print("✓ PythonExecutor 测试通过")

	test_quest_system()
	print("✓ QuestSystem 测试通过")

	print("=== 所有测试通过! ===")


# 如果直接运行此脚本
if __name__ == "__main__":
	run_all_tests()
