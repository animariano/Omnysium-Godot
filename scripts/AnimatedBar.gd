extends ProgressBar

var target_value: float
var speed := 6.0

func _ready():
	target_value = value

func set_target(v: float):
	target_value = clamp(v, min_value, max_value)

func _process(delta):
	value = lerp(value, target_value, delta * speed)

	if abs(value - target_value) < 0.2:
		value = target_value
