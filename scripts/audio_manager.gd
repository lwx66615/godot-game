extends Node
class_name AudioManager

# 单例
static var instance: AudioManager

# 音效总线名称
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_AMBIENT := "Ambient"
const BUS_MUSIC := "Music"

# 音效定义
enum SoundType {
	GLOBAL,     # 全局音效（UI等）
	POSITION_2D # 2D位置音效（距离衰减）
}

# 音效配置
var sound_configs := {
	# 诡异音效
	"drag_knife": {
		"type": SoundType.POSITION_2D,
		"loop": true,
		"volume_db": 0.0,
		"max_distance": 500.0,
		"attenuation": 2.0  # 衰减系数
	},
	"knock_slow": {
		"type": SoundType.POSITION_2D,
		"loop": false,
		"volume_db": 5.0,
		"max_distance": 300.0,
		"attenuation": 1.5
	},
	"knock_medium": {
		"type": SoundType.POSITION_2D,
		"loop": false,
		"volume_db": 8.0,
		"max_distance": 300.0,
		"attenuation": 1.5
	},
	"knock_fast": {
		"type": SoundType.POSITION_2D,
		"loop": false,
		"volume_db": 12.0,
		"max_distance": 300.0,
		"attenuation": 1.0
	},
	"breach": {
		"type": SoundType.POSITION_2D,
		"loop": false,
		"volume_db": 15.0,
		"max_distance": 400.0,
		"attenuation": 1.0
	},
	"search_pace": {
		"type": SoundType.POSITION_2D,
		"loop": true,
		"volume_db": -5.0,
		"max_distance": 200.0,
		"attenuation": 2.0
	},

	# 玩家音效
	"footstep_walk": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": -10.0
	},
	"footstep_run": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": 0.0
	},
	"heartbeat_slow": {
		"type": SoundType.GLOBAL,
		"loop": true,
		"volume_db": -15.0
	},
	"heartbeat_fast": {
		"type": SoundType.GLOBAL,
		"loop": true,
		"volume_db": -5.0
	},
	"breath_normal": {
		"type": SoundType.GLOBAL,
		"loop": true,
		"volume_db": -20.0
	},
	"breath_stress": {
		"type": SoundType.GLOBAL,
		"loop": true,
		"volume_db": -10.0
	},

	# 环境音效
	"door_open": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": 0.0
	},
	"door_close": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": 0.0
	},
	"door_creak": {
		"type": SoundType.POSITION_2D,
		"loop": false,
		"volume_db": -5.0,
		"max_distance": 200.0,
		"attenuation": 2.0
	},
	"wind_day": {
		"type": SoundType.GLOBAL,
		"loop": true,
		"volume_db": -15.0
	},
	"wind_night": {
		"type": SoundType.GLOBAL,
		"loop": true,
		"volume_db": -10.0
	},
	"light_flicker": {
		"type": SoundType.POSITION_2D,
		"loop": false,
		"volume_db": -10.0,
		"max_distance": 150.0,
		"attenuation": 2.0
	},

	# UI音效
	"ui_prompt": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": -5.0
	},
	"ui_dialogue": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": 0.0
	},
	"ui_warning": {
		"type": SoundType.GLOBAL,
		"loop": false,
		"volume_db": 5.0
	}
}

# 正在播放的音效（用于停止和管理）
var active_sounds := {}  # sound_name -> player
var active_2d_sounds := []  # 正在播放的2D音效列表

# 音效资源路径
const AUDIO_PATH := "res://assets/audio/"

func _ready():
	instance = self

# ==================== 播放接口 ====================

# 播放全局音效
func play(sound_name: String) -> AudioStreamPlayer:
	if not sound_configs.has(sound_name):
		push_warning("音效未定义: %s" % sound_name)
		return null

	var config := sound_configs[sound_name]
	if config["type"] != SoundType.GLOBAL:
		push_warning("音效 %s 不是全局音效，请使用 play_2d" % sound_name)
		return null

	# 如果是循环音效且已在播放，不重复播放
	if config["loop"] and active_sounds.has(sound_name):
		return active_sounds[sound_name]

	var player := _create_global_player(sound_name, config)
	player.play()

	if config["loop"]:
		active_sounds[sound_name] = player

	return player

# 播放2D位置音效（距离衰减）
func play_2d(sound_name: String, position: Vector2) -> AudioStreamPlayer2D:
	if not sound_configs.has(sound_name):
		push_warning("音效未定义: %s" % sound_name)
		return null

	var config := sound_configs[sound_name]
	if config["type"] != SoundType.POSITION_2D:
		push_warning("音效 %s 不是2D音效，请使用 play" % sound_name)
		return null

	var player := _create_2d_player(sound_name, config)
	player.global_position = position
	player.play()

	active_2d_sounds.append(player)

	# 非循环音效播放完成后自动清理
	if not config["loop"]:
		player.finished.connect(_on_2d_sound_finished.bind(player))

	return player

# 停止音效
func stop(sound_name: String):
	if active_sounds.has(sound_name):
		var player := active_sounds[sound_name]
		player.stop()
		player.queue_free()
		active_sounds.erase(sound_name)

# 停止所有2D音效
func stop_all_2d():
	for player in active_2d_sounds:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	active_2d_sounds.clear()

# 停止所有音效
func stop_all():
	for sound_name in active_sounds.keys():
		stop(sound_name)
	stop_all_2d()

# ==================== 音效更新 ====================

# 更新2D音效位置（用于跟随移动的对象）
func update_2d_position(sound_name: String, new_position: Vector2):
	# 找到对应的循环2D音效并更新位置
	for player in active_2d_sounds:
		if is_instance_valid(player) and player.stream:
			# 通过检查是否是目标音效来更新位置
			# 这里需要额外的标识机制，暂时用简单方式
			player.global_position = new_position

# ==================== 音量控制 ====================

# 设置总线音量（0-100）
func set_bus_volume(bus_name: String, volume_percent: float):
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("音效总线不存在: %s" % bus_name)
		return

	# 转换为分贝（0% = -40dB, 100% = 0dB）
	var volume_db := linear_to_db(volume_percent / 100.0)
	AudioServer.set_bus_volume_db(bus_idx, volume_db)

# 获取总线音量
func get_bus_volume(bus_name: String) -> float:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 0.0

	var volume_db := AudioServer.get_bus_volume_db(bus_idx)
	return db_to_linear(volume_db) * 100.0

# ==================== 内部方法 ====================

# 创建全局音效播放器
func _create_global_player(sound_name: String, config: Dictionary) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()

	# 加载音效资源（如果存在）
	var stream := _load_sound(sound_name)
	if stream:
		player.stream = stream
	else:
		# 占位符：生成简单的蜂鸣声
		player.stream = _generate_placeholder_sound()

	player.volume_db = config["volume_db"]
	player.bus = BUS_SFX

	add_child(player)

	# 非循环音效播放完成后自动清理
	if not config["loop"]:
		player.finished.connect(_on_global_sound_finished.bind(player, sound_name))

	return player

# 创建2D音效播放器
func _create_2d_player(sound_name: String, config: Dictionary) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()

	# 加载音效资源（如果存在）
	var stream := _load_sound(sound_name)
	if stream:
		player.stream = stream
	else:
		# 占位符：生成简单的蜂鸣声
		player.stream = _generate_placeholder_sound()

	player.volume_db = config["volume_db"]
	player.max_distance = config["max_distance"]
	player.attenuation = config["attenuation"]
	player.bus = BUS_SFX

	# 添加到场景树（需要父节点）
	# 这里暂时添加到AudioManager，实际应该添加到合适的父节点
	get_tree().current_scene.add_child(player)

	return player

# 加载音效资源
func _load_sound(sound_name: String) -> AudioStream:
	# 尝试加载音效文件
	# 支持多种格式
	var extensions := [".wav", ".ogg", ".mp3"]

	for ext in extensions:
		var path := AUDIO_PATH + _get_sound_category(sound_name) + "/" + sound_name + ext
		if ResourceLoader.exists(path):
			return load(path)

	return null

# 根据音效名称判断分类
func _get_sound_category(sound_name: String) -> String:
	if sound_name.begins_with("drag") or sound_name.begins_with("knock") or \
	   sound_name.begins_with("breach") or sound_name.begins_with("search"):
		return "ghost"
	elif sound_name.begins_with("footstep") or sound_name.begins_with("heartbeat") or \
	     sound_name.begins_with("breath"):
		return "player"
	elif sound_name.begins_with("door") or sound_name.begins_with("wind") or \
	     sound_name.begins_with("light"):
		return "environment"
	else:
		return "ui"

# 生成占位符音效（简单的蜂鸣声）
func _generate_placeholder_sound() -> AudioStream:
	# 使用AudioStreamGenerator生成简单的蜂鸣声
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050  # 低采样率，减少CPU占用
	generator.buffer_length = 0.1  # 短缓冲

	# 注意：实际播放时需要填充音频数据
	# 这里只是创建一个空的占位符，实际音效需要外部资源
	return generator

# ==================== 回调 ====================

func _on_global_sound_finished(player: AudioStreamPlayer, sound_name: String):
	player.queue_free()
	if active_sounds.has(sound_name):
		active_sounds.erase(sound_name)

func _on_2d_sound_finished(player: AudioStreamPlayer2D):
	if active_2d_sounds.has(player):
		active_2d_sounds.erase(player)
	player.queue_free()

# ==================== 便捷方法 ====================

# 播放诡异拖刀声（持续播放，跟随诡异位置）
func start_ghost_drag_sound(ghost_position: Vector2) -> AudioStreamPlayer2D:
	return play_2d("drag_knife", ghost_position)

# 停止诡异拖刀声
func stop_ghost_drag_sound():
	# 找到并停止所有drag_knife音效
	for player in active_2d_sounds:
		if is_instance_valid(player):
			# 通过名称匹配（需要额外标识）
			player.stop()
			player.queue_free()
	active_2d_sounds.clear()

# 播放敲门声（根据阶段）
func play_knock_sound(stage: int, door_position: Vector2):
	match stage:
		1: play_2d("knock_slow", door_position)
		2: play_2d("knock_medium", door_position)
		3: play_2d("knock_fast", door_position)

# 播放破门声
func play_breach_sound(door_position: Vector2):
	play_2d("breach", door_position)

# 播放脚步声
func play_footstep(is_running: bool):
	if is_running:
		play("footstep_run")
	else:
		play("footstep_walk")

# 播放门开关声
func play_door_sound(is_open: bool):
	if is_open:
		play("door_open")
	else:
		play("door_close")

# 播放心跳声（根据诡异距离）
func start_heartbeat(ghost_distance: float):
	# 根据距离选择心跳节奏
	if ghost_distance < 100.0:
		play("heartbeat_fast")
	else:
		play("heartbeat_slow")

# 停止心跳声
func stop_heartbeat():
	stop("heartbeat_slow")
	stop("heartbeat_fast")