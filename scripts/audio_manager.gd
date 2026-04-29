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
var sound_configs = {
	# 诡异音效
	"drag_knife": {
		"type": 1,  # POSITION_2D
		"loop": true,
		"volume_db": 0.0,
		"max_distance": 500.0,
		"attenuation": 2.0
	},
	"knock_slow": {
		"type": 1,  # POSITION_2D
		"loop": false,
		"volume_db": 5.0,
		"max_distance": 300.0,
		"attenuation": 1.5
	},
	"knock_medium": {
		"type": 1,  # POSITION_2D
		"loop": false,
		"volume_db": 8.0,
		"max_distance": 300.0,
		"attenuation": 1.5
	},
	"knock_fast": {
		"type": 1,  # POSITION_2D
		"loop": false,
		"volume_db": 12.0,
		"max_distance": 300.0,
		"attenuation": 1.0
	},
	"breach": {
		"type": 1,  # POSITION_2D
		"loop": false,
		"volume_db": 15.0,
		"max_distance": 400.0,
		"attenuation": 1.0
	},
	"search_pace": {
		"type": 1,  # POSITION_2D
		"loop": true,
		"volume_db": -5.0,
		"max_distance": 200.0,
		"attenuation": 2.0
	},

	# 玩家音效
	"footstep_walk": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": -10.0
	},
	"footstep_run": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": 0.0
	},
	"heartbeat_slow": {
		"type": 0,  # GLOBAL
		"loop": true,
		"volume_db": -15.0
	},
	"heartbeat_fast": {
		"type": 0,  # GLOBAL
		"loop": true,
		"volume_db": -5.0
	},
	"breath_normal": {
		"type": 0,  # GLOBAL
		"loop": true,
		"volume_db": -20.0
	},
	"breath_stress": {
		"type": 0,  # GLOBAL
		"loop": true,
		"volume_db": -10.0
	},

	# 环境音效
	"door_open": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": 0.0
	},
	"door_close": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": 0.0
	},
	"door_creak": {
		"type": 1,  # POSITION_2D
		"loop": false,
		"volume_db": -5.0,
		"max_distance": 200.0,
		"attenuation": 2.0
	},
	"wind_day": {
		"type": 0,  # GLOBAL
		"loop": true,
		"volume_db": -15.0
	},
	"wind_night": {
		"type": 0,  # GLOBAL
		"loop": true,
		"volume_db": -10.0
	},
	"light_flicker": {
		"type": 1,  # POSITION_2D
		"loop": false,
		"volume_db": -10.0,
		"max_distance": 150.0,
		"attenuation": 2.0
	},

	# UI音效
	"ui_prompt": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": -5.0
	},
	"ui_dialogue": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": 0.0
	},
	"ui_warning": {
		"type": 0,  # GLOBAL
		"loop": false,
		"volume_db": 5.0
	}
}

# 正在播放的音效（用于停止和管理）
var active_sounds := {}  # sound_name -> player
var active_2d_sounds := []  # 正在播放的2D音效列表

# 音效资源路径
const AUDIO_PATH := "res://assets/audio/"

# 占位符音效缓存
var placeholder_cache := {}  # sound_name -> AudioStreamWAV

# 占位符音效配置
const PLACEHOLDER_CONFIGS := {
	# 诡异音效
	"drag_knife": {"freq": 80.0, "duration": 0.5, "wave": "sawtooth", "volume": 0.3},
	"knock_slow": {"freq": 200.0, "duration": 0.15, "wave": "square", "volume": 0.5},
	"knock_medium": {"freq": 250.0, "duration": 0.12, "wave": "square", "volume": 0.6},
	"knock_fast": {"freq": 300.0, "duration": 0.1, "wave": "square", "volume": 0.7},
	"breach": {"freq": 150.0, "duration": 0.3, "wave": "noise", "volume": 0.8},
	"search_pace": {"freq": 100.0, "duration": 0.2, "wave": "sine", "volume": 0.2},

	# 玩家音效
	"footstep_walk": {"freq": 400.0, "duration": 0.08, "wave": "noise", "volume": 0.3},
	"footstep_run": {"freq": 400.0, "duration": 0.1, "wave": "noise", "volume": 0.5},
	"heartbeat_slow": {"freq": 60.0, "duration": 0.3, "wave": "sine", "volume": 0.4},
	"heartbeat_fast": {"freq": 80.0, "duration": 0.2, "wave": "sine", "volume": 0.5},
	"breath_normal": {"freq": 300.0, "duration": 0.5, "wave": "noise", "volume": 0.15},
	"breath_stress": {"freq": 350.0, "duration": 0.3, "wave": "noise", "volume": 0.25},

	# 环境音效
	"door_open": {"freq": 300.0, "duration": 0.2, "wave": "sawtooth", "volume": 0.4},
	"door_close": {"freq": 250.0, "duration": 0.15, "wave": "sawtooth", "volume": 0.5},
	"door_creak": {"freq": 500.0, "duration": 0.4, "wave": "sine", "volume": 0.3},
	"wind_day": {"freq": 200.0, "duration": 1.0, "wave": "noise", "volume": 0.2},
	"wind_night": {"freq": 150.0, "duration": 1.0, "wave": "noise", "volume": 0.25},
	"light_flicker": {"freq": 1000.0, "duration": 0.05, "wave": "square", "volume": 0.2},

	# UI音效
	"ui_prompt": {"freq": 600.0, "duration": 0.1, "wave": "sine", "volume": 0.3},
	"ui_dialogue": {"freq": 500.0, "duration": 0.08, "wave": "sine", "volume": 0.25},
	"ui_warning": {"freq": 800.0, "duration": 0.15, "wave": "square", "volume": 0.4},
}

func _ready():
	instance = self

# ==================== 播放接口 ====================

# 播放全局音效
func play(sound_name: String) -> AudioStreamPlayer:
	if not sound_configs.has(sound_name):
		push_warning("音效未定义: %s" % sound_name)
		return null

	var config : Dictionary = sound_configs[sound_name]
	if config["type"] != 0:  # GLOBAL
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

	var config : Dictionary = sound_configs[sound_name]
	if config["type"] != 1:  # POSITION_2D
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
		var player : AudioStreamPlayer = active_sounds[sound_name]
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

	# 加载音效资源（如果存在）或生成占位符
	player.stream = _load_sound(sound_name)

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

	# 加载音效资源（如果存在）或生成占位符
	player.stream = _load_sound(sound_name)

	player.volume_db = config["volume_db"]
	player.max_distance = config["max_distance"]
	player.attenuation = config["attenuation"]
	player.bus = BUS_SFX

	# 添加到场景树
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(player)
	else:
		add_child(player)

	return player

# 加载音效资源
func _load_sound(sound_name: String) -> AudioStream:
	# 尝试加载音效文件
	# 支持多种格式
	var extensions := [".wav", ".ogg", ".mp3"]

	for ext in extensions:
		var path : String = AUDIO_PATH + _get_sound_category(sound_name) + "/" + sound_name + ext
		if ResourceLoader.exists(path):
			return load(path)

	# 没有找到外部资源，生成占位符音效
	return _generate_placeholder_sound(sound_name)

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

# 生成占位符音效（程序化生成的简单音效）
func _generate_placeholder_sound(sound_name: String) -> AudioStreamWAV:
	# 检查缓存
	if placeholder_cache.has(sound_name):
		return placeholder_cache[sound_name]

	# 获取配置
	var config: Dictionary = PLACEHOLDER_CONFIGS.get(sound_name, {
		"freq": 440.0,
		"duration": 0.1,
		"wave": "sine",
		"volume": 0.5
	})

	var frequency: float = config.freq
	var duration: float = config.duration
	var waveform: String = config.wave
	var volume: float = config.volume

	# 生成音频数据
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var samples := PackedByteArray()
	samples.resize(num_samples * 2)  # 16位样本

	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var sample_value: float = 0.0

		# 生成波形
		match waveform:
			"sine":
				sample_value = sin(2.0 * PI * frequency * t)
			"square":
				sample_value = 1.0 if sin(2.0 * PI * frequency * t) > 0.0 else -1.0
			"sawtooth":
				sample_value = 2.0 * fmod(t * frequency, 1.0) - 1.0
			"noise":
				sample_value = randf_range(-1.0, 1.0)
			_:
				sample_value = sin(2.0 * PI * frequency * t)

		# 应用音量和淡入淡出
		var envelope: float = 1.0
		var fade_samples: int = mini(num_samples / 10, 100)

		if i < fade_samples:
			envelope = float(i) / float(fade_samples)
		elif i > num_samples - fade_samples:
			envelope = float(num_samples - i) / float(fade_samples)

		sample_value *= volume * envelope

		# 转换为16位整数（小端序）
		var int_value: int = clampi(int(sample_value * 32767.0), -32768, 32767)
		samples.set(i * 2, int_value & 0xFF)
		samples.set(i * 2 + 1, (int_value >> 8) & 0xFF)

	# 创建 AudioStreamWAV
	var stream := AudioStreamWAV.new()
	stream.data = samples
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false

	# 缓存
	placeholder_cache[sound_name] = stream

	return stream

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
