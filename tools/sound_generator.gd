@tool
extends EditorScript
class_name SoundGenerator

## 音效占位符生成工具
## 在 Godot 编辑器中运行：File -> Run (或 Ctrl+Shift+X)
## 会在 assets/audio/ 目录下生成占位符音效文件
##
## 注意：这些是简单的程序化音效，仅用于测试
## 正式版本需要替换为专业音效资源

const AUDIO_PATH := "res://assets/audio/"

# 音效定义
const SOUNDS := {
	# ============ 诡异音效 ============
	"ghost/drag_knife": {
		"frequency": 80.0,
		"duration": 0.5,
		"waveform": "sawtooth",
		"volume": 0.3,
		"description": "拖刀声 - 低频锯齿波"
	},
	"ghost/knock_slow": {
		"frequency": 200.0,
		"duration": 0.15,
		"waveform": "square",
		"volume": 0.5,
		"description": "敲门声(慢) - 低沉撞击"
	},
	"ghost/knock_medium": {
		"frequency": 250.0,
		"duration": 0.12,
		"waveform": "square",
		"volume": 0.6,
		"description": "敲门声(中) - 中等撞击"
	},
	"ghost/knock_fast": {
		"frequency": 300.0,
		"duration": 0.1,
		"waveform": "square",
		"volume": 0.7,
		"description": "敲门声(快) - 急促撞击"
	},
	"ghost/breach": {
		"frequency": 150.0,
		"duration": 0.3,
		"waveform": "noise",
		"volume": 0.8,
		"description": "破门声 - 噪音冲击"
	},
	"ghost/search_pace": {
		"frequency": 100.0,
		"duration": 0.2,
		"waveform": "sine",
		"volume": 0.2,
		"description": "搜索徘徊声 - 低频正弦波"
	},

	# ============ 玩家音效 ============
	"player/footstep_walk": {
		"frequency": 400.0,
		"duration": 0.08,
		"waveform": "noise",
		"volume": 0.3,
		"description": "脚步声(走) - 轻微噪音"
	},
	"player/footstep_run": {
		"frequency": 400.0,
		"duration": 0.1,
		"waveform": "noise",
		"volume": 0.5,
		"description": "脚步声(跑) - 较重噪音"
	},
	"player/heartbeat_slow": {
		"frequency": 60.0,
		"duration": 0.3,
		"waveform": "sine",
		"volume": 0.4,
		"description": "心跳声(慢) - 低频脉冲"
	},
	"player/heartbeat_fast": {
		"frequency": 80.0,
		"duration": 0.2,
		"waveform": "sine",
		"volume": 0.5,
		"description": "心跳声(快) - 高频脉冲"
	},
	"player/breath_normal": {
		"frequency": 300.0,
		"duration": 0.5,
		"waveform": "noise",
		"volume": 0.15,
		"description": "呼吸声(正常) - 轻微噪音"
	},
	"player/breath_stress": {
		"frequency": 350.0,
		"duration": 0.3,
		"waveform": "noise",
		"volume": 0.25,
		"description": "呼吸声(紧张) - 较重噪音"
	},

	# ============ 环境音效 ============
	"environment/door_open": {
		"frequency": 300.0,
		"duration": 0.2,
		"waveform": "sawtooth",
		"volume": 0.4,
		"description": "开门声 - 锯齿波"
	},
	"environment/door_close": {
		"frequency": 250.0,
		"duration": 0.15,
		"waveform": "sawtooth",
		"volume": 0.5,
		"description": "关门声 - 锯齿波"
	},
	"environment/door_creak": {
		"frequency": 500.0,
		"duration": 0.4,
		"waveform": "sine",
		"volume": 0.3,
		"description": "门吱呀声 - 正弦波"
	},
	"environment/wind_day": {
		"frequency": 200.0,
		"duration": 1.0,
		"waveform": "noise",
		"volume": 0.2,
		"description": "风声(白天) - 低频噪音"
	},
	"environment/wind_night": {
		"frequency": 150.0,
		"duration": 1.0,
		"waveform": "noise",
		"volume": 0.25,
		"description": "风声(夜晚) - 更低频噪音"
	},
	"environment/light_flicker": {
		"frequency": 1000.0,
		"duration": 0.05,
		"waveform": "square",
		"volume": 0.2,
		"description": "灯光闪烁 - 高频脉冲"
	},

	# ============ UI音效 ============
	"ui/ui_prompt": {
		"frequency": 600.0,
		"duration": 0.1,
		"waveform": "sine",
		"volume": 0.3,
		"description": "UI提示 - 短促正弦波"
	},
	"ui/ui_dialogue": {
		"frequency": 500.0,
		"duration": 0.08,
		"waveform": "sine",
		"volume": 0.25,
		"description": "UI对话 - 轻柔正弦波"
	},
	"ui/ui_warning": {
		"frequency": 800.0,
		"duration": 0.15,
		"waveform": "square",
		"volume": 0.4,
		"description": "UI警告 - 急促方波"
	},
}

func _run() -> void:
	print("=== 开始生成音效占位符 ===")

	var generated_count := 0
	var failed_count := 0

	for sound_path: String in SOUNDS.keys():
		var config: Dictionary = SOUNDS[sound_path]
		var full_path: String = AUDIO_PATH + sound_path + ".wav"

		# 检查文件是否已存在
		if ResourceLoader.exists(full_path):
			print("  [跳过] %s (已存在)" % sound_path)
			continue

		# 生成音效数据
		var audio_data := _generate_audio_data(config)
		if audio_data == null:
			print("  [失败] %s" % sound_path)
			failed_count += 1
			continue

		# 保存为 WAV 文件
		var save_result := _save_wav(full_path, audio_data, config)
		if save_result == OK:
			print("  [成功] %s - %s" % [sound_path, config.get("description", "")])
			generated_count += 1
		else:
			print("  [失败] %s (保存错误)" % sound_path)
			failed_count += 1

	print("\n=== 生成完成 ===")
	print("成功: %d, 失败: %d" % [generated_count, failed_count])
	print("\n注意: 这些是简单的程序化音效占位符")
	print("正式版本需要替换为专业音效资源")

# 生成音频数据
func _generate_audio_data(config: Dictionary) -> PackedByteArray:
	var frequency: float = config.get("frequency", 440.0)
	var duration: float = config.get("duration", 0.1)
	var waveform: String = config.get("waveform", "sine")
	var volume: float = config.get("volume", 0.5)

	var sample_rate: int = 22050  # 标准采样率
	var num_samples: int = int(duration * sample_rate)

	var samples: PackedByteArray = PackedByteArray()
	samples.resize(num_samples * 2)  # 16位样本 = 2字节

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

		# 应用音量和淡入淡出
		var envelope: float = 1.0
		var fade_samples: int = mini(num_samples / 10, 100)  # 淡入淡出

		if i < fade_samples:
			envelope = float(i) / float(fade_samples)  # 淡入
		elif i > num_samples - fade_samples:
			envelope = float(num_samples - i) / float(fade_samples)  # 淡出

		sample_value *= volume * envelope

		# 转换为16位整数
		var int_value: int = int(sample_value * 32767.0)
		int_value = clampi(int_value, -32768, 32767)

		# 小端序存储
		samples.set(i * 2, int_value & 0xFF)
		samples.set(i * 2 + 1, (int_value >> 8) & 0xFF)

	return samples

# 保存为 WAV 文件
func _save_wav(path: String, samples: PackedByteArray, config: Dictionary) -> int:
	var sample_rate: int = 22050
	var num_channels: int = 1  # 单声道
	var bits_per_sample: int = 16

	var data_size: int = samples.size()
	var file_size: int = 36 + data_size

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_CREATE

	# WAV 文件头
	file.store_string("RIFF")
	file.store_32(file_size)
	file.store_string("WAVE")

	# fmt 子块
	file.store_string("fmt ")
	file.store_32(16)  # fmt 块大小
	file.store_16(1)   # 音频格式 (1 = PCM)
	file.store_16(num_channels)
	file.store_32(sample_rate)
	file.store_32(sample_rate * num_channels * bits_per_sample / 8)  # 字节率
	file.store_16(num_channels * bits_per_sample / 8)  # 块对齐
	file.store_16(bits_per_sample)

	# data 子块
	file.store_string("data")
	file.store_32(data_size)
	file.store_buffer(samples)

	file.close()

	return OK
