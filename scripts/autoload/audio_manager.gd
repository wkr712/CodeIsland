## 音频管理器 - 核心单例
## 负责背景音乐和音效的播放控制
class_name AudioManager
extends Node

# ==================== 信号 ====================
signal bgm_changed(track_name: String)
signal volume_changed(bus_name: String, value: float)

# ==================== 常量 ====================
const BGM_PATH := "res://assets/audio/bgm/"
const SFX_PATH := "res://assets/audio/sfx/"

# 音频总线名称
const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_SFX := "SFX"

# ==================== 变量 ====================
var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween
var _current_bgm: String = ""
var _bgm_volume: float = 1.0
var _sfx_volume: float = 1.0

# 音效播放器池
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 10

# ==================== 生命周期 ====================
func _ready() -> void:
	print("[AudioManager] 初始化音频管理器...")

	# 创建BGM播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)

	# 创建音效播放器池
	_create_sfx_pool()

	# 设置初始音量
	set_bgm_volume(_bgm_volume)
	set_sfx_volume(_sfx_volume)


# ==================== BGM 相关 ====================
## 播放背景音乐
func play_bgm(bgm_name: String, fade_duration: float = 1.0) -> void:
	if bgm_name == _current_bgm and _bgm_player.playing:
		return

	var bgm_path := BGM_PATH + bgm_name + ".ogg"

	if not ResourceLoader.exists(bgm_path):
		push_warning("[AudioManager] BGM文件不存在: %s" % bgm_path)
		return

	var stream := load(bgm_path) as AudioStream
	if stream == null:
		push_error("[AudioManager] 无法加载BGM: %s" % bgm_path)
		return

	# 淡出当前BGM
	if _bgm_player.playing:
		_fade_out_bgm(fade_duration / 2)
		await get_tree().create_timer(fade_duration / 2).timeout

	# 播放新BGM
	_bgm_player.stream = stream
	_bgm_player.volume_db = -40.0  # 从静音开始淡入
	_bgm_player.play()

	# 淡入
	_fade_in_bgm(fade_duration / 2)

	_current_bgm = bgm_name
	emit_signal("bgm_changed", bgm_name)
	print("[AudioManager] 播放BGM: %s" % bgm_name)


## 停止背景音乐
func stop_bgm(fade_duration: float = 1.0) -> void:
	if not _bgm_player.playing:
		return

	_fade_out_bgm(fade_duration)
	await get_tree().create_timer(fade_duration).timeout

	_bgm_player.stop()
	_current_bgm = ""


## 暂停背景音乐
func pause_bgm() -> void:
	_bgm_player.stream_paused = true


## 恢复背景音乐
func resume_bgm() -> void:
	_bgm_player.stream_paused = false


## 设置BGM音量
func set_bgm_volume(volume: float) -> void:
	_bgm_volume = clampf(volume, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index(BUS_BGM)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(_bgm_volume))
		AudioServer.set_bus_mute(bus_idx, _bgm_volume < 0.01)
	emit_signal("volume_changed", BUS_BGM, _bgm_volume)


## 获取BGM音量
func get_bgm_volume() -> float:
	return _bgm_volume


# ==================== SFX 相关 ====================
## 播放音效
func play_sfx(sfx_name: String, volume_scale: float = 1.0) -> void:
	var sfx_path := SFX_PATH + sfx_name + ".wav"

	# 尝试不同格式
	if not ResourceLoader.exists(sfx_path):
		sfx_path = SFX_PATH + sfx_name + ".ogg"

	if not ResourceLoader.exists(sfx_path):
		push_warning("[AudioManager] SFX文件不存在: %s" % sfx_name)
		return

	var stream := load(sfx_path) as AudioStream
	if stream == null:
		push_error("[AudioManager] 无法加载SFX: %s" % sfx_name)
		return

	var player := _get_available_sfx_player()
	if player == null:
		push_warning("[AudioManager] 没有可用的音效播放器")
		return

	player.stream = stream
	player.volume_db = linear_to_db(_sfx_volume * volume_scale)
	player.play()


## 播放UI音效
func play_ui_sound(sound_type: String) -> void:
	match sound_type:
		"click", "select":
			play_sfx("ui_click")
		"hover":
			play_sfx("ui_hover")
		"confirm":
			play_sfx("ui_confirm")
		"cancel":
			play_sfx("ui_cancel")
		"error":
			play_sfx("ui_error")
		_:
			pass


## 设置SFX音量
func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index(BUS_SFX)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(_sfx_volume))
		AudioServer.set_bus_mute(bus_idx, _sfx_volume < 0.01)
	emit_signal("volume_changed", BUS_SFX, _sfx_volume)


## 获取SFX音量
func get_sfx_volume() -> float:
	return _sfx_volume


# ==================== 通用方法 ====================
## 设置主音量
func set_master_volume(volume: float) -> void:
	var bus_idx := AudioServer.get_bus_index(BUS_MASTER)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
		AudioServer.set_bus_mute(bus_idx, volume < 0.01)
	emit_signal("volume_changed", BUS_MASTER, volume)


## 静音切换
func toggle_mute() -> bool:
	var bus_idx := AudioServer.get_bus_index(BUS_MASTER)
	if bus_idx >= 0:
		var is_muted := AudioServer.is_bus_mute(bus_idx)
		AudioServer.set_bus_mute(bus_idx, not is_muted)
		return not is_muted
	return false


# ==================== 私有方法 ====================
func _create_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null


func _fade_out_bgm(duration: float) -> void:
	if _bgm_tween:
		_bgm_tween.kill()

	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -40.0, duration)


func _fade_in_bgm(duration: float) -> void:
	if _bgm_tween:
		_bgm_tween.kill()

	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", 0.0, duration)


func _on_sfx_player_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
