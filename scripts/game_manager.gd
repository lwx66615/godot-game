extends Node
class_name GameManager

# 单例
static var instance: GameManager

# 时间系统 - 行动驱动
enum TimePeriod { MORNING, NOON, EVENING, NIGHT }

# 当前天数
var current_day := 1

# 当前时间（分钟，从0:00开始）
# 游戏从第1天早晨6:00开始
var current_time := 360  # 6:00 = 360分钟

# 时段边界（分钟）
const MORNING_START := 360   # 6:00
const NOON_START := 600      # 10:00
const EVENING_START := 840   # 14:00
const NIGHT_START := 1020    # 17:00
const DAY_END := 1440        # 24:00

# 时间消耗常量（分钟）
const TIME_MOVE_ROOM := 5        # 移动到相邻房间
const TIME_SEARCH := 15          # 搜刮/翻找
const TIME_DIALOGUE_BASE := 10   # 对话基础时间
const TIME_DIALOGUE_PER_LINE := 5 # 每段对话额外时间
const TIME_REST := 30            # 休息
const TIME_USE_ITEM := 5         # 使用物品
const TIME_READ := 10            # 阅读日记/笔记
const TIME_HIDE := 3             # 进入躲藏

# 信号
signal time_changed(new_time: int)
signal period_changed(new_period: int, old_period: int)
signal day_changed(new_day: int)

func _ready():
	instance = self
	process_mode = Node.PROCESS_MODE_PAUSABLE

# 注意：移除了 _process 中的自动时间流逝
# 时间现在由玩家行动驱动

# ==================== 时间消耗 ====================

# 消耗时间（核心方法）
func consume_time(minutes: int) -> void:
	if minutes <= 0:
		return

	var old_period := get_current_period()
	var old_day := current_day

	# 更新时间
	current_time += minutes

	# 检查是否跨天
	while current_time >= DAY_END:
		current_time -= DAY_END
		current_day += 1
		day_changed.emit(current_day)

	# 检查时段变化
	var new_period := get_current_period()
	if new_period != old_period:
		period_changed.emit(new_period, old_period)

	# 发送时间变化信号
	time_changed.emit(current_time)

# ==================== 时间查询 ====================

# 获取当前时段
func get_current_period() -> int:
	if current_time >= NIGHT_START:
		return TimePeriod.NIGHT
	elif current_time >= EVENING_START:
		return TimePeriod.EVENING
	elif current_time >= NOON_START:
		return TimePeriod.NOON
	else:
		return TimePeriod.MORNING

# 获取时段名称
func get_period_name() -> String:
	match get_current_period():
		TimePeriod.MORNING:
			return "早晨"
		TimePeriod.NOON:
			return "中午"
		TimePeriod.EVENING:
			return "傍晚"
		TimePeriod.NIGHT:
			return "夜晚"
		_:
			return "未知"

# 获取时间字符串（如"09:30"）
func get_time_string() -> String:
	var hours := current_time / 60
	var minutes := current_time % 60
	return "%02d:%02d" % [hours, minutes]

# 获取时段进度（0-1）
func get_period_progress() -> float:
	var period_start := _get_period_start(get_current_period())
	var period_end := _get_period_end(get_current_period())
	var period_duration := period_end - period_start
	var elapsed := current_time - period_start
	return float(elapsed) / float(period_duration)

# 获取时段开始时间
func _get_period_start(period: int) -> int:
	match period:
		TimePeriod.MORNING:
			return MORNING_START
		TimePeriod.NOON:
			return NOON_START
		TimePeriod.EVENING:
			return EVENING_START
		TimePeriod.NIGHT:
			return NIGHT_START
		_:
			return MORNING_START

# 获取时段结束时间
func _get_period_end(period: int) -> int:
	match period:
		TimePeriod.MORNING:
			return NOON_START
		TimePeriod.NOON:
			return EVENING_START
		TimePeriod.EVENING:
			return NIGHT_START
		TimePeriod.NIGHT:
			return DAY_END
		_:
			return DAY_END

# 是否是夜晚
func is_night() -> bool:
	return get_current_period() == TimePeriod.NIGHT

# 是否是白天
func is_daytime() -> bool:
	return get_current_period() != TimePeriod.NIGHT

# ==================== 调试方法 ====================

# 跳过指定分钟（用于调试）
func skip_time(minutes: int) -> void:
	consume_time(minutes)

# 跳过到下一时段（用于调试）
func skip_to_next_period() -> void:
	var current_period := get_current_period()
	var period_end := _get_period_end(current_period)
	var time_to_skip := period_end - current_time
	if time_to_skip > 0:
		consume_time(time_to_skip)

# 跳过到夜晚（用于调试）
func skip_to_night() -> void:
	while get_current_period() != TimePeriod.NIGHT:
		skip_to_next_period()

# 设置时间速度（保留接口，但不再使用）
func set_time_speed(_speed: float) -> void:
	pass  # 行动驱动模式下不使用时间速度

# 跳过当前时段（保留接口，兼容旧代码）
func skip_period() -> void:
	skip_to_next_period()
