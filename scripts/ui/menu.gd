## 主菜单 - UI脚本
## 游戏的主入口界面
class_name MainMenu
extends Control

# ==================== 节点引用 ====================
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var new_game_button: Button = $VBoxContainer/MenuButtons/NewGameButton
@onready var continue_button: Button = $VBoxContainer/MenuButtons/ContinueButton
@onready var settings_button: Button = $VBoxContainer/MenuButtons/SettingsButton
@onready var credits_button: Button = $VBoxContainer/MenuButtons/CreditsButton
@onready var quit_button: Button = $VBoxContainer/MenuButtons/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var save_slots_container: Control = $SaveSlotsContainer
@onready var settings_panel: Control = $SettingsPanel

# ==================== 变量 ====================
var _has_saves: bool = false


# ==================== 生命周期 ====================
func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_check_saves()
	_play_intro_animation()


# ==================== 公共方法 ====================
## 刷新存档状态
func refresh_save_status() -> void:
	_check_saves()


# ==================== 私有方法 ====================
func _setup_ui() -> void:
	# 设置版本号
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.2.0")

	# 初始隐藏子面板
	if save_slots_container:
		save_slots_container.hide()
	if settings_panel:
		settings_panel.hide()


func _connect_signals() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _check_saves() -> void:
	_has_saves = false

	for slot in range(SaveManager.MAX_SAVE_SLOTS):
		if SaveManager.has_save(slot):
			_has_saves = true
			break

	continue_button.disabled = not _has_saves
	if _has_saves:
		continue_button.tooltip_text = "继续上次的冒险"
	else:
		continue_button.tooltip_text = "没有存档"


func _play_intro_animation() -> void:
	# 标题淡入动画
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# 按钮依次出现动画
	var buttons := [new_game_button, continue_button, settings_button, credits_button, quit_button]
	for i in buttons.size():
		var button: Button = buttons[i]
		button.modulate.a = 0.0
		button.rect_position.y += 20

		var btn_tween := create_tween()
		btn_tween.set_ease(Tween.EASE_OUT)
		btn_tween.set_trans(Tween.TRANS_BACK)
		btn_tween.tween_interval(0.3 + i * 0.1)
		btn_tween.parallel().tween_property(button, "modulate:a", 1.0, 0.3)
		btn_tween.parallel().tween_property(button, "rect_position:y", button.rect_position.y - 20, 0.3)


# ==================== 信号处理 ====================
func _on_new_game_pressed() -> void:
	AudioManager.play_ui_sound("click")

	# 检查是否有存档
	if _has_saves:
		# 显示确认对话框
		_show_new_game_confirmation()
	else:
		_start_new_game()


func _on_continue_pressed() -> void:
	AudioManager.play_ui_sound("click")

	if _has_saves:
		_show_save_slots()
	else:
		# 如果没有存档，开始新游戏
		_start_new_game()


func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound("click")
	_show_settings()


func _on_credits_pressed() -> void:
	AudioManager.play_ui_sound("click")
	_show_credits()


func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound("click")
	_quit_game()


# ==================== 辅助方法 ====================
func _start_new_game() -> void:
	# 播放过渡动画
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	GameManager.start_new_game()


func _show_save_slots() -> void:
	if save_slots_container:
		save_slots_container.show()
		$VBoxContainer.hide()


func _show_settings() -> void:
	if settings_panel:
		settings_panel.show()
		$VBoxContainer.hide()


func _show_credits() -> void:
	# TODO: 实现制作人员界面
	pass


func _show_new_game_confirmation() -> void:
	# TODO: 显示确认对话框
	# 暂时直接开始新游戏
	_start_new_game()


func _quit_game() -> void:
	# 播放退出动画
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished

	get_tree().quit()
