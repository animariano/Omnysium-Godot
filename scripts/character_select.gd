
extends Control

func _ready():
	var hbox = $Background/HBoxContainer
	for personaje in GameManager.personajes_pool:
		var panel = crear_panel(personaje)
		hbox.add_child(panel)

func crear_panel(personaje: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 480)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)

	var img = TextureRect.new()
	img.texture = load("res://assets/characters/%s.png" % personaje.clase.to_lower())
	img.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_horizontal = Control.SIZE_FILL
	img.custom_minimum_size = Vector2(0, 220)

	var nombre = Label.new()
	nombre.text = personaje.nombre
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var stats = Label.new()
	stats.text = "Salud: %d | Ataque: %d" % [personaje.salud, personaje.ataque]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc = Label.new()
	desc.text = personaje.habilidad_especial + "\n" + personaje.habilidad_definitiva
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.size_flags_horizontal = Control.SIZE_FILL

	var btn = Button.new()
	btn.text = "Elegir"
	btn.size_flags_horizontal = Control.SIZE_FILL
	btn.pressed.connect(_on_elegir.bind(personaje))

	vbox.add_child(img)
	vbox.add_child(nombre)
	vbox.add_child(stats)
	vbox.add_child(desc)
	vbox.add_child(btn)
	panel.add_child(vbox)

	return panel

func _on_elegir(personaje: Dictionary):
	GameManager.heroe = {
		"nombre": personaje.nombre,
		"clase": personaje.clase,
		"salud": personaje.salud,
		"salud_maxima": personaje.salud,
		"ataque": personaje.ataque,
		"oro": 3,
		"habilidad_especial": personaje.habilidad_especial,
		"habilidad_definitiva": personaje.habilidad_definitiva,
		"escudo_fuego": false
	}
	GameManager.definitiva_cooldown = 0
	GameManager.cooldown_definitiva_base = personaje.cooldown_definitiva
	get_tree().change_scene_to_file("res://scenes/Combat.tscn")
