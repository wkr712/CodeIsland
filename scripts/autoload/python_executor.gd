## Python代码执行器 - 核心单例
## 负责执行和验证用户编写的Python代码
## 通过外部Python进程实现代码执行
class_name PythonExecutor
extends Node

# ==================== 信号 ====================
signal execution_started()
signal execution_completed(result: Dictionary)
signal execution_error(error: String)
signal validation_passed(lesson_id: String)
signal validation_failed(lesson_id: String, errors: Array)

# ==================== 常量 ====================
const EXECUTION_TIMEOUT := 10.0  # 执行超时时间（秒）
const PYTHON_COMMAND := "python"  # Python命令

# 允许的模块白名单
const ALLOWED_MODULES := [
	"math", "random", "datetime", "json", "re", "string",
	"collections", "itertools", "functools", "typing"
]

# 禁止的危险函数
const FORBIDDEN_FUNCTIONS := [
	"exec", "eval", "compile", "__import__", "open",
	"input", "breakpoint", "exit", "quit"
]

# ==================== 变量 ====================
var _python_path: String = ""
var _is_executing: bool = false
var _execution_queue: Array[Dictionary] = []


# ==================== 生命周期 ====================
func _ready() -> void:
	print("[PythonExecutor] 初始化Python执行器...")
	_detect_python()


# ==================== 公共方法 ====================
## 检测Python是否可用
func is_python_available() -> bool:
	return _python_path != ""


## 执行Python代码
func execute(code: String, context: Dictionary = {}) -> Dictionary:
	if _is_executing:
		# 加入队列等待
		var result := await _queue_execution(code, context)
		return result

	_is_executing = true
	emit_signal("execution_started")

	var result := await _execute_code(code, context)

	_is_executing = false
	emit_signal("execution_completed", result)

	# 处理队列中的下一个
	_process_queue()

	return result


## 验证代码
func validate(code: String, lesson_id: String, validation_rules: Dictionary) -> Dictionary:
	var result := {
		"valid": false,
		"errors": [],
		"warnings": [],
		"output": "",
		"suggestions": []
	}

	# 1. 代码静态检查
	var static_errors := _static_check(code)
	result.errors.append_array(static_errors)

	if not result.errors.is_empty():
		emit_signal("validation_failed", lesson_id, result.errors)
		return result

	# 2. 执行代码
	var exec_result := await execute(code)

	if not exec_result.success:
		result.errors.append("代码执行失败: " + exec_result.error)
		emit_signal("validation_failed", lesson_id, result.errors)
		return result

	result.output = exec_result.output

	# 3. 验证规则检查
	var validation_result := _apply_validation_rules(code, exec_result, validation_rules)
	result.errors.append_array(validation_result.errors)
	result.warnings.append_array(validation_result.warnings)
	result.suggestions.append_array(validation_result.suggestions)

	# 4. 最终结果
	result.valid = result.errors.is_empty()

	if result.valid:
		emit_signal("validation_passed", lesson_id)
	else:
		emit_signal("validation_failed", lesson_id, result.errors)

	return result


## 获取代码提示
func get_code_hints(code: String, lesson_id: String) -> Array[String]:
	var hints: Array[String] = []

	# 基于课程内容提供提示
	# 这里可以根据lesson_id和代码分析提供针对性提示

	if "def " not in code and lesson_id.contains("function"):
		hints.append("提示: 这个任务需要定义一个函数")

	if "for " not in code and lesson_id.contains("loop"):
		hints.append("提示: 考虑使用循环来处理重复操作")

	if "if " not in code and lesson_id.contains("condition"):
		hints.append("提示: 需要使用条件判断来处理不同情况")

	return hints


## 格式化代码
func format_code(code: String) -> String:
	# 简单的代码格式化
	var lines := code.split("\n")
	var formatted_lines: Array[String] = []
	var indent_level := 0

	for line in lines:
		var stripped := line.strip_edges()

		if stripped.is_empty():
			formatted_lines.append("")
			continue

		# 减少缩进
		if stripped.begins_with("else") or stripped.begins_with("elif") or stripped.begins_with("except") or stripped.begins_with("finally"):
			indent_level = maxi(0, indent_level - 1)

		# 添加缩进后的行
		var indent := "    ".repeat(indent_level)
		formatted_lines.append(indent + stripped)

		# 增加缩进
		if stripped.ends_with(":"):
			indent_level += 1

	return "\n".join(formatted_lines)


# ==================== 私有方法 ====================
func _detect_python() -> void:
	# 尝试检测Python安装路径
	var commands := ["python", "python3", "py"]

	for cmd in commands:
		var output := []
		var exit_code := OS.execute(cmd, ["--version"], output)

		if exit_code == 0:
			_python_path = cmd
			print("[PythonExecutor] 检测到Python: %s (%s)" % [cmd, output[0].strip_edges()])
			return

	push_warning("[PythonExecutor] 未检测到Python环境，代码执行功能受限")


func _execute_code(code: String, context: Dictionary = {}) -> Dictionary:
	var result := {
		"success": false,
		"output": "",
		"error": "",
		"return_value": null,
		"execution_time": 0.0
	}

	if not is_python_available():
		result.error = "Python环境不可用"
		emit_signal("execution_error", result.error)
		return result

	# 创建临时Python文件
	var temp_file := "user://temp_code.py"
	var file := FileAccess.open(temp_file, FileAccess.WRITE)

	if file == null:
		result.error = "无法创建临时文件"
		emit_signal("execution_error", result.error)
		return result

	# 包装代码以捕获输出
	var wrapped_code := _wrap_code_for_execution(code, context)
	file.store_string(wrapped_code)
	file.close()

	# 执行Python
	var start_time := Time.get_ticks_msec()
	var output := []
	var exit_code := OS.execute(_python_path, [ProjectSettings.globalize_path(temp_file)], output)
	var end_time := Time.get_ticks_msec()

	result.execution_time = (end_time - start_time) / 1000.0

	if exit_code == 0:
		result.success = true
		result.output = output[0] if output.size() > 0 else ""
		# 解析返回值
		result.return_value = _parse_return_value(result.output)
	else:
		result.error = output[0] if output.size() > 0 else "未知错误"
		emit_signal("execution_error", result.error)

	# 清理临时文件
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_file))

	return result


func _wrap_code_for_execution(code: String, context: Dictionary) -> String:
	var wrapper := """
import sys
import io
import json

# 重定向标准输出
_old_stdout = sys.stdout
sys.stdout = io.StringIO()

# 执行代码
try:
_code_result = None

# 用户代码
%s

# 获取输出
_output = sys.stdout.getvalue()
sys.stdout = _old_stdout

# 输出结果
print(_output, end='')
except Exception as e:
    sys.stdout = _old_stdout
    print(f'ERROR: {type(e).__name__}: {e}', file=sys.stderr)
""" % code

	return wrapper


func _static_check(code: String) -> Array[String]:
	var errors: Array[String] = []

	# 检查危险函数
	for func in FORBIDDEN_FUNCTIONS:
		var pattern := func + "("
		if pattern in code:
			errors.append("不允许使用函数: %s" % func)

	# 检查import语句
	var import_pattern := RegEx.new()
	import_pattern.compile(r"import\s+(\w+)")

	for match in import_pattern.search_all(code):
		var module_name := match.get_string(1)
		if module_name not in ALLOWED_MODULES:
			errors.append("不允许导入模块: %s (允许的模块: %s)" % [module_name, ", ".join(ALLOWED_MODULES)])

	# 检查基本语法错误
	var lines := code.split("\n")
	var indent_stack := [0]

	for i in range(lines.size()):
		var line := lines[i]
		if line.strip_edges().is_empty():
			continue

		# 检查缩进一致性
		var indent := 0
		for c in line:
			if c == " ":
				indent += 1
			elif c == "\t":
				indent += 4
			else:
				break

		if indent % 4 != 0:
			errors.append("第%d行: 缩进不一致，请使用4个空格" % (i + 1))

	return errors


func _apply_validation_rules(code: String, exec_result: Dictionary, rules: Dictionary) -> Dictionary:
	var result := {
		"errors": [],
		"warnings": [],
		"suggestions": []
	}

	# 检查输出匹配
	if rules.has("expected_output"):
		var expected: String = rules.expected_output
		var actual: String = exec_result.output.strip_edges()

		if actual != expected.strip_edges():
			result.errors.append("输出不匹配\n期望: %s\n实际: %s" % [expected, actual])

	# 检查必须包含的代码模式
	if rules.has("required_patterns"):
		for pattern in rules.required_patterns:
			if pattern not in code:
				result.errors.append("代码中缺少必要的内容: %s" % pattern)

	# 检查禁止的代码模式
	if rules.has("forbidden_patterns"):
		for pattern in rules.forbidden_patterns:
			if pattern in code:
				result.warnings.append("建议不要使用: %s" % pattern)

	# 检查函数定义
	if rules.has("required_functions"):
		for func_name in rules.required_functions:
			if "def %s" % func_name not in code:
				result.errors.append("需要定义函数: %s" % func_name)

	# 检查变量使用
	if rules.has("required_variables"):
		for var_name in rules.required_variables:
			if var_name not in code:
				result.suggestions.append("考虑使用变量: %s" % var_name)

	return result


func _parse_return_value(output: String) -> Variant:
	# 尝试解析输出为JSON
	var json := JSON.new()
	if json.parse(output) == OK:
		return json.data

	# 尝试解析为数字
	if output.is_valid_int():
		return output.to_int()
	if output.is_valid_float():
		return output.to_float()

	# 返回原始字符串
	return output.strip_edges()


func _queue_execution(code: String, context: Dictionary) -> Dictionary:
	var item := {"code": code, "context": context}
	_execution_queue.append(item)

	# 等待执行完成
	await self.execution_completed

	# 返回队列中该项的结果
	# 简化实现，实际需要更复杂的队列管理
	return {}


func _process_queue() -> void:
	if _execution_queue.is_empty():
		return

	var next := _execution_queue.pop_front()
	await execute(next.code, next.context)
