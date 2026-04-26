extends PanelContainer

func _ready():
	add_to_group("tooltip_panel")
	visible = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← ignorar mouse
	# También aplicarlo a todos los hijos
	for hijo in get_children():
		if hijo is Control:
			hijo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for nieto in hijo.get_children():
				if nieto is Control:
					nieto.mouse_filter = Control.MOUSE_FILTER_IGNORE

func mostrar(texto: String, pos: Vector2):
	$MarginContainer/TooltipLabel.text = texto
	visible = false
	global_position = Vector2(-9999, -9999)
	visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport = get_viewport_rect().size
	var s = get_combined_minimum_size()
	var x = clamp(pos.x - s.x / 2, 10, viewport.x - s.x - 10)
	var y = clamp(pos.y - s.y - 20, 10, viewport.y - s.y - 10)
	global_position = Vector2(x, y)

func ocultar_panel():
	visible = false
