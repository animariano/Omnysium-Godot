extends Control

var items_ofrecidos = []

var sprites_items = {
	"pocion_salud":       preload("res://assets/items/pocion_salud.png"),
	"espada_hierro":      preload("res://assets/items/espada_hierro.png"),
	"armadura_cuero":     preload("res://assets/items/armadura_cuero.png"),
	"espada_acero":       preload("res://assets/items/espada_acero.png"),
	"armadura_placas":    preload("res://assets/items/armadura_placas.png"),
	"botas_agiles":       preload("res://assets/items/botas_agiles.png"),
	"guantes_precision":  preload("res://assets/items/guantes_precision.png"),
	"manto_protector":    preload("res://assets/items/manto_protector.png"),
	"piedra_salud":       preload("res://assets/items/piedra_salud.png"),
	"piedra_regen":       preload("res://assets/items/piedra_regen.png"),
	"colmillo_vampirico": preload("res://assets/items/colmillo_vampirico.png"),
	"calavera_burlona":   preload("res://assets/items/calavera_burlona.png"),
	"sanguijuela":        preload("res://assets/items/sanguijuela.png"),
	"placas":             preload("res://assets/items/placas.png"),
	"anillo_critico":     preload("res://assets/items/anillo_critico.png"),
	"amuleto_berserk":    preload("res://assets/items/amuleto_berserk.png"),
	"dados_malditos":     preload("res://assets/items/dados_malditos.png"),
	"runa_poder":         preload("res://assets/items/runa_poder.png"),
	"tablilla_alma":      preload("res://assets/items/tablilla_alma.png"),
	"mascara_frenetica":  preload("res://assets/items/mascara_frenetica.png"),
	"corazon_cristal":    preload("res://assets/items/corazon_cristal.png"),
	"idolo_abismo":       preload("res://assets/items/idolo_abismo.png"),
	"filo_creciente":     preload("res://assets/items/filo_creciente.png"),
	"sangre_caliente":    preload("res://assets/items/sangre_caliente.png"),
}

var slots = []

func _ready():
	$Background/SalirButton.pressed.connect(_on_salir)
	
	slots = [
		$Background/ItemsContainer/ItemSlot1,
		$Background/ItemsContainer/ItemSlot2,
		$Background/ItemsContainer/ItemSlot3,
	]

	items_ofrecidos = GameManager.get_items_disponibles(3)
	actualizar_oro()
	cargar_items()

func actualizar_oro():
	$Background/OroLabel.text = "Oro: %d" % GameManager.heroe.oro

func cargar_items():
	for i in range(slots.size()):
		var slot = slots[i]
		if i >= items_ofrecidos.size():
			slot.visible = false
			continue

		var item = items_ofrecidos[i]
		var vbox = slot.get_node("VBoxContainer")

		vbox.get_node("ItemImage").texture = sprites_items[item.id]
		vbox.get_node("ItemName").text = item.nombre
		vbox.get_node("ItemDesc").text = item.desc
		vbox.get_node("ItemCosto").text = "Costo: %d 🪙" % item.costo

		var btn = vbox.get_node("ComprarButton")
		btn.text = "Comprar"
		btn.disabled = GameManager.heroe.oro < item.costo
		btn.pressed.connect(_on_comprar.bind(i))

func _on_comprar(indice: int):
	var item = items_ofrecidos[indice]
	if GameManager.heroe.oro < item.costo:
		return

	GameManager.heroe.oro -= item.costo
	GameManager.comprar_item(item.id)
	aplicar_efecto(item.id)
	actualizar_oro()

	# Deshabilitar el botón y marcar como comprado
	var btn = slots[indice].get_node("VBoxContainer/ComprarButton")
	btn.text = "Comprado"
	btn.disabled = true

	# Actualizar botones restantes por si ya no alcanza el oro
	for i in range(slots.size()):
		if i != indice and i < items_ofrecidos.size():
			var b = slots[i].get_node("VBoxContainer/ComprarButton")
			if not b.disabled:
				b.disabled = GameManager.heroe.oro < items_ofrecidos[i].costo

func aplicar_efecto(item_id: String):
	var h = GameManager.heroe
	match item_id:
		"pocion_salud":
			GameManager.heroe.salud = min(h.salud + 2, h.salud_maxima)
		"espada_hierro":
			GameManager.heroe.ataque += 1
		"armadura_cuero":
			GameManager.heroe.salud_maxima += 2
			GameManager.heroe.salud += 2
		"espada_acero":
			GameManager.heroe.ataque += 2
		"armadura_placas":
			GameManager.heroe.salud_maxima += 4
			GameManager.heroe.salud += 4
		"piedra_salud":
			GameManager.heroe.salud_maxima += 2
			GameManager.heroe.salud += 2
		"corazon_cristal":
			GameManager.heroe.salud_maxima = 3
			GameManager.heroe.salud = min(h.salud, 3)
			GameManager.heroe.ataque *= 2
		"runa_poder":
			GameManager.heroe.ataque += 4
		_:
			# Items pasivos — solo se registran como comprados,
			# su efecto se aplica en Combat.gd
			pass

func _on_salir():
	get_tree().change_scene_to_file("res://scenes/Event.tscn")
