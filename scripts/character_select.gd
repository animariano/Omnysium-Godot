extends Control

func _ready():
	AudioManager.reproducir_musica("character_select", -20.0)
	var vbox = $Background/ScrollContainer/VBoxContainer
	for personaje in GameManager.personajes_pool:
		var fila = crear_fila(personaje)
		vbox.add_child(fila)

func crear_fila(personaje: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 160)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Imagen del personaje ──
	var img = TextureRect.new()
	img.texture = load("res://assets/characters/%s.png" % personaje.clase.to_lower())
	img.custom_minimum_size = Vector2(140, 140)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# ── Stats ──
	var stats_vbox = VBoxContainer.new()
	stats_vbox.custom_minimum_size = Vector2(220, 0)
	stats_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_vbox.add_theme_constant_override("separation", 6)

	var nombre_label = Label.new()
	nombre_label.text = personaje.nombre
	nombre_label.add_theme_font_size_override("font_size", 24)

	var stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_label.text = " %s %d    %s %d" % [
		GameManager.icono("corazon"),
		personaje.salud,
		GameManager.icono("espada"),
		personaje.ataque
	]

	stats_vbox.add_child(nombre_label)
	stats_vbox.add_child(stats_label)

	# ── Icono ataque ──
	var icono_ataque = crear_icono(
		"res://assets/skills/ataque_%s.png" % personaje.clase.to_lower(),
        "Ataque\nTirás el dado. 1-3 acierta."
	)

	# ── Skill 1 ──
	var icono_especial = crear_icono(
		"res://assets/skills/especial_%s.png" % personaje.clase.to_lower(),
		personaje.habilidad_especial
	)

	# ── Skill 2 ──
	var icono_definitiva = crear_icono(
		"res://assets/skills/definitiva_%s.png" % personaje.clase.to_lower(),
		personaje.habilidad_definitiva + "\n(Cooldown: %d combates)" % personaje.cooldown_definitiva
	)

	# ── Botón elegir ──
	var btn = Button.new()
	btn.text = "Elegir"
	btn.custom_minimum_size = Vector2(120, 50)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_elegir.bind(personaje))

	# ── Spacer para empujar botón a la derecha ──
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(img)
	hbox.add_child(stats_vbox)
	hbox.add_child(icono_ataque)
	hbox.add_child(icono_especial)
	hbox.add_child(icono_definitiva)
	hbox.add_child(spacer)
	hbox.add_child(btn)
	panel.add_child(hbox)
	return panel

func crear_icono(ruta: String, descripcion: String) -> TextureRect:
	var img = TextureRect.new()
	img.texture = load(ruta)
	img.custom_minimum_size = Vector2(80, 80)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tip = load("res://scripts/Tooltip.gd").new()
	tip.descripcion = descripcion
	img.add_child(tip)
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	return img

func _on_elegir(personaje: Dictionary):
	GameManager.heroe = {
		"nombre": personaje.nombre,
		"clase": personaje.clase,
		"salud": personaje.salud,
		"salud_maxima": personaje.salud,
		"ataque": personaje.ataque,
		"oro": 0,
		"habilidad_especial": personaje.habilidad_especial,
		"habilidad_definitiva": personaje.habilidad_definitiva,
	}
	GameManager.definitiva_cooldown = 0
	GameManager.cooldown_definitiva_base = personaje.cooldown_definitiva
	SceneTransition.change_scene("res://scenes/Combat.tscn")

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var panel = get_tree().get_first_node_in_group("tooltip_panel")
		if panel:
			panel.ocultar_panel()
	elif event is InputEventScreenTouch and event.pressed:
		var panel = get_tree().get_first_node_in_group("tooltip_panel")
		if panel:
			panel.ocultar_panel()
