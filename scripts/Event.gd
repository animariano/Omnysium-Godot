extends Control

var evento_actual = null
var evento_terminado = false

var sprites_eventos = {
	"trampa": preload("res://assets/events/evento_trampa.png"),
	"equipo": preload("res://assets/events/evento_equipo.png"),
	"cofre":  preload("res://assets/events/evento_cofre.png"),
	"fuente": preload("res://assets/events/evento_fuente.png"),
	"cueva":  preload("res://assets/events/evento_cueva.png"),
	"estatua":    preload("res://assets/events/evento_estatua.png"),
	"hongos":     preload("res://assets/events/evento_hongos.png"),
	"mochila":    preload("res://assets/events/evento_mochila.png"),
	"vendedor":   preload("res://assets/events/evento_vendedor.png"),
	"pergamino":  preload("res://assets/events/evento_pergamino.png"),
	"restos":     preload("res://assets/events/evento_restos.png"),
	"alquimista": preload("res://assets/events/evento_alquimista.png"),
	"altar":      preload("res://assets/events/evento_altar.png"),
}
var texturas_dado = [
	preload("res://assets/dado1.png"),
	preload("res://assets/dado2.png"),
	preload("res://assets/dado3.png"),
	preload("res://assets/dado4.png"),
	preload("res://assets/dado5.png"),
	preload("res://assets/dado6.png"),
]

func _ready():
	$Background/ContinuarButton.pressed.connect(_on_continuar)
	$Background/ContinuarButton.visible = false
	$Background/DadoTexture.visible = false
	$Background/ResultadoLabel.visible = false

	evento_actual = GameManager.get_evento_aleatorio()

	if evento_actual == null:
		# No hay eventos disponibles, seguir directo
		log_evento("No hay eventos disponibles. Continuás tu camino...")
		$Background/ContinuarButton.visible = true
		return

	GameManager.marcar_evento_visto(evento_actual.id)
	$Background/EventImage.texture = sprites_eventos[evento_actual.id]
	$Background/EventTitle.text = evento_actual.nombre
	cargar_evento(evento_actual.id)

func cargar_evento(id: String):
	match id:
		"trampa":    cargar_trampa()
		"equipo":    cargar_equipo()
		"cofre":     cargar_cofre()
		"fuente":    cargar_fuente()
		"cueva":     cargar_cueva()
		"estatua":   cargar_estatua()
		"hongos":    cargar_hongos()
		"mochila":   cargar_mochila()
		"vendedor":  cargar_vendedor()
		"pergamino": cargar_pergamino()
		"restos":    cargar_restos()
		"alquimista":cargar_alquimista()
		"altar":     cargar_altar()

func log_evento(texto: String):
	$Background/EventLog.append_text("\n" + texto)

func mostrar_dado(resultado: int):
	$Background/DadoTexture.visible = true     
	$Background/ResultadoLabel.visible = true  
	$Background/DadoTexture.texture = texturas_dado[resultado - 1]
	$Background/ResultadoLabel.text = "Dado: %d" % resultado
	
func animar_dado(resultado: int):
	$Background/DadoTexture.visible = true
	$Background/ResultadoLabel.visible = true
	for i in range(12):
		var cara_random = randi() % 6
		$Background/DadoTexture.texture = texturas_dado[cara_random]
		await get_tree().create_timer(0.05).timeout
	mostrar_dado(resultado)

func limpiar_opciones():
	for child in $Background/OpcionesContainer.get_children():
		child.queue_free()

func agregar_boton(texto: String, callback: Callable):
	var btn = Button.new()
	btn.text = texto
	btn.pressed.connect(callback)
	$Background/OpcionesContainer.add_child(btn)

func terminar_evento():
	evento_terminado = true
	limpiar_opciones()
	$Background/ContinuarButton.visible = true

# ─── TRAMPA ──────────────────────────────────────────────────────
func cargar_trampa():
	log_evento("Te encontrás con una trampa oculta!")
	log_evento("Tirá el dado para esquivarla. Necesitás sacar 4 o menos.")
	agregar_boton("Tirar dado", _on_trampa_dado)

func _on_trampa_dado():
	limpiar_opciones()
	var resultado = randi() % 6 + 1
	#mostrar_dado(resultado)
	await animar_dado(resultado)
	if resultado <= 4:
		log_evento("[color=green]Esquivaste la trampa con éxito![/color]")
	else:
		GameManager.heroe.salud -= 2
		log_evento("[color=red]No lograste esquivar la trampa.[/color] Salud restante: %d" % GameManager.heroe.salud)
		if GameManager.heroe.salud <= 0:
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
			return
	terminar_evento()

# ─── EQUIPO ───────────────────────────────────────────────────────
func cargar_equipo():
	log_evento("Encontraste equipo abandonado en el camino!")
	log_evento("Ganás +1 %s." % [GameManager.icono("espada")])
	log_evento("Ganás +1 %s max." % [GameManager.icono("corazon")])
	GameManager.heroe.ataque += 1
	GameManager.heroe.salud_maxima +=1
	terminar_evento()

# ─── COFRE ────────────────────────────────────────────────────────
func cargar_cofre():
	log_evento("Descubriste un cofre escondido lleno de oro!")
	var resultado = randi() % 6 + 1
	GameManager.heroe.oro += resultado
	resultado = resultado+3
	log_evento("[color=yellow]Encontrás oro en el cofre! Ganás %d %s.[/color]" % [resultado, GameManager.icono("moneda"),])
	terminar_evento()

# ─── FUENTE ───────────────────────────────────────────────────────
func cargar_fuente():
	log_evento("Descubriste una fuente con poderes curativos!")
	#GameManager.heroe.salud = min(GameManager.heroe.salud * 2, GameManager.heroe.salud_maxima)
	GameManager.heroe.salud = GameManager.heroe.salud_maxima
	log_evento("[color=green]Restauras completamente tu salud. Salud: %d[/color]" % GameManager.heroe.salud)
	terminar_evento()

# ─── CUEVA MISTERIOSA ─────────────────────────────────────────────
func cargar_cueva():
	log_evento("Entrás a una cueva misteriosa. Tres caminos te esperan:")
	agregar_boton("Sendero oscuro (riesgo/recompensa)", _on_cueva_oscuro)
	agregar_boton("Pasillo dorado (cofre de oro)", _on_cueva_dorado)
	agregar_boton("Túnel de vegetación (curación)", _on_cueva_vegetal)

func _on_cueva_oscuro():
	limpiar_opciones()
	
	log_evento("El sendero oscuro... Una roca cae desde el techo!")
	log_evento("Tirá el dado para esquivarla. Necesitás 3 o menos.")
	agregar_boton("Tirar dado", _on_cueva_oscuro_dado)

func _on_cueva_oscuro_dado():
	limpiar_opciones()
	await get_tree().process_frame
	var resultado = randi() % 6 + 1
	await animar_dado(resultado)

	if resultado <= 3:
		$Background/EventLog.clear() 
		log_evento("[color=green]Esquivaste la roca! Salís ileso.[/color]")
		agregar_boton("Continuar", func():
			limpiar_opciones()
			$Background/EventLog.clear()
			$Background/EventImage.texture = load("res://assets/events/evento_daga.png")
			log_evento("En el fondo del sendero encontrás un cuchillo algo extraño...")
			agregar_boton("Tomarlo", _on_cueva_tomar_cuchillo)
			agregar_boton("Dejarlo", _on_cueva_dejar_cuchillo)
		)
	else:
		GameManager.heroe.salud -= 3
		log_evento("[color=red]La roca te golpea! Perdés 3 de salud. Salud: %d[/color]" % GameManager.heroe.salud)
		if GameManager.heroe.salud <= 0:
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
			return
		agregar_boton("Continuar", func():
			limpiar_opciones()
			$Background/EventLog.clear()
			$Background/EventImage.texture = load("res://assets/events/evento_daga.png")
			log_evento("Dolorido por el golpe, llegás al fondo del sendero. Encontrás un cuchillo extraño...")
			agregar_boton("Tomarlo", _on_cueva_tomar_cuchillo)
			agregar_boton("Dejarlo", _on_cueva_dejar_cuchillo))

func _on_cueva_tomar_cuchillo():
	GameManager.heroe.salud_maxima += 2
	GameManager.heroe.ataque += 2
	$Background/EventLog.clear() 
	GameManager.comprar_item("daga_maldita")
	log_evento("[color=cyan]Lo tomás y te sentís más fuerte. +2 %s, +2 %s.[/color]" % [GameManager.icono("corazon"), GameManager.icono("espada")])
	log_evento("Pero con una sensación [color=red]extraña[/color].")
	terminar_evento()

func _on_cueva_dejar_cuchillo():
	log_evento("Te marchás sin tomarlo.")
	terminar_evento()

func _on_cueva_dorado():
	limpiar_opciones()
	$Background/EventLog.clear()
	$Background/EventImage.texture = load("res://assets/events/evento_cofre.png")
	log_evento("[color=yellow]Seguís la luz dorada y encontrás un cofre. Ganás 5 %s![/color]"%[GameManager.icono("moneda")])
	GameManager.heroe.oro += 5
	terminar_evento()

func _on_cueva_vegetal():
	limpiar_opciones()
	log_evento("[color=green]El túnel te lleva a una planta curativa. Recuperás 4 de salud.[/color]")
	GameManager.heroe.salud = min(GameManager.heroe.salud + 4, GameManager.heroe.salud_maxima)
	terminar_evento()
	
# ─── ESTATUA MALDITA ─────────────────────────────────────────────
func cargar_estatua():
	log_evento("Ante vos se alza una estatua con una expresión perturbadora.")
	log_evento("Algo en ella te invita a rezar... o a ignorarla.")
	agregar_boton("Rezar", _on_estatua_rezar)
	agregar_boton("Ignorar", _on_estatua_ignorar)

func _on_estatua_rezar():
	limpiar_opciones()
	log_evento("Te arrodillás ante la estatua y rezás...")
	agregar_boton("Tirar dado", func():
		limpiar_opciones()
		var resultado = randi() % 6 + 1
		await animar_dado(resultado)
		if resultado >= 4:
			GameManager.heroe.salud -= 2
			log_evento("[color=red]La estatua cobra su precio. Perdés 2 de salud. Salud: %d[/color]" % GameManager.heroe.salud)
			if GameManager.heroe.salud <= 0:
				await get_tree().create_timer(1.0).timeout
				get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
				return
		else:
			GameManager.heroe.oro += 2
			log_evento("[color=yellow]La estatua te bendice. Ganás 2 %s. Oro: %d[/color]" % [GameManager.icono("moneda"), GameManager.heroe.oro])
		terminar_evento()
	)

func _on_estatua_ignorar():
	log_evento("Pasás de largo sin prestarle atención.")
	terminar_evento()

# ─── HONGOS EXTRAÑOS ─────────────────────────────────────────────
func cargar_hongos():
	log_evento("Encontrás unos hongos de colores llamativos. Podrían ser comestibles... o no.")
	agregar_boton("Comer", _on_hongos_comer)
	agregar_boton("No comer", _on_hongos_no_comer)

func _on_hongos_comer():
	limpiar_opciones()
	log_evento("Te llevás un hongo a la boca...")
	agregar_boton("Tirar dado", func():
		limpiar_opciones()
		var resultado = randi() % 6 + 1
		await animar_dado(resultado)
		if resultado >= 4:
			GameManager.aplicar_efecto("heroe", "veneno", 3, 1)
			log_evento("[color=red]¡Los hongos eran venenosos! Quedás envenenado por 3 turnos.[/color]")
		else:
			GameManager.heroe.salud_maxima += 1
			GameManager.heroe.salud += 1
			log_evento("[color=green]Tenían propiedades curativas! Salud máxima +1. Salud: %d/%d[/color]" % [GameManager.heroe.salud, GameManager.heroe.salud_maxima])
		terminar_evento()
	)

func _on_hongos_no_comer():
	log_evento("Decidís no arriesgarte. Seguís tu camino.")
	terminar_evento()

# ─── MOCHILA OLVIDADA ────────────────────────────────────────────
func cargar_mochila():
	log_evento("Encontrás una mochila abandonada al costado del camino.")
	agregar_boton("Revisar", _on_mochila_revisar)
	agregar_boton("Ignorar", _on_mochila_ignorar)

func _on_mochila_revisar():
	limpiar_opciones()
	# Obtener item aleatorio no comprado y vendible
	var disponibles = GameManager.items_pool.filter(func(item):
		return not GameManager.items_comprados.has(item.id) and item.get("vendible", true)
	)
	if disponibles.is_empty():
		log_evento("La mochila está vacía. No había nada útil.")
		terminar_evento()
		return
	disponibles.shuffle()
	var item = disponibles[0]
	GameManager.comprar_item(item.id)
	# Aplicar efecto si tiene efecto inmediato
	_aplicar_efecto_item(item.id)
	log_evento("[color=cyan]Encontrás: [b]%s[/b]. %s[/color]" % [item.nombre, item.desc])
	terminar_evento()

func _on_mochila_ignorar():
	log_evento("Dejás la mochila donde está y seguís tu camino.")
	terminar_evento()

func _aplicar_efecto_item(item_id: String):
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

# ─── VENDEDOR AMBULANTE ──────────────────────────────────────────
func cargar_vendedor():
	log_evento("Un vendedor ambulante con una capa raída te ofrece sus mercancías.")
	agregar_boton("Comprar", _on_vendedor_comprar)
	agregar_boton("Robar", _on_vendedor_robar)

func _on_vendedor_comprar():
	limpiar_opciones()
	log_evento("El vendedor sonríe y abre su bolso...")
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/Market.tscn")

func _on_vendedor_robar():
	limpiar_opciones()
	log_evento("Aprovechás un descuido y le robás la bolsa.")
	GameManager.heroe.oro += 5
	log_evento("[color=yellow]Obtienes 5 %s." % [GameManager.icono("moneda"),])
	terminar_evento()

# ─── PERGAMINO ANTIGUO ───────────────────────────────────────────
func cargar_pergamino():
	log_evento("Encontrás un pergamino con runas antiguas. Al leerlo, sentís que algo cambia en vos.")
	agregar_boton("Tirar dado", _on_pergamino_dado)

func _on_pergamino_dado():
	limpiar_opciones()
	var resultado = randi() % 6 + 1
	await animar_dado(resultado)
	if resultado <= 3:
		GameManager.heroe.salud_maxima += 1
		GameManager.heroe.salud += 1
		GameManager.heroe.ataque += 1
		log_evento("[color=green]Las runas te empoderan! Salud máxima +1, Ataque +1.[/color]")
	else:
		log_evento("[color=gray]Las runas se desvanecen sin efecto. No pasa nada.[/color]")
	terminar_evento()

# ─── RESTOS DE AVENTURERO ────────────────────────────────────────
func cargar_restos():
	log_evento("Encontrás los restos de un aventurero caído. Su bolsa aún tiene algo dentro.")
	log_evento("[color=red]Advertencia: registrar los restos podría ser peligroso.[/color]")
	agregar_boton("Registrar restos", _on_restos_registrar)
	agregar_boton("Ignorar", _on_restos_ignorar)

func _on_restos_registrar():
	limpiar_opciones()
	var oro_encontrado = randi() % 4 + 1  # 1 a 4 de oro
	GameManager.heroe.oro += oro_encontrado
	GameManager.aplicar_efecto("heroe", "veneno", 3, 1)
	log_evento("[color=yellow]Encontrás %d %s en la bolsa.[/color]" % [oro_encontrado, GameManager.icono("moneda")])
	log_evento("[color=red]Pero algo te infecta. Quedás envenenado por 3 turnos.[/color]")
	terminar_evento()

func _on_restos_ignorar():
	log_evento("Dejás los restos en paz y seguís tu camino.")
	terminar_evento()

# ─── ALQUIMISTA ──────────────────────────────────────────────────
func cargar_alquimista():
	log_evento("Un alquimista excéntrico te ofrece una pócima de aspecto dudoso.")
	log_evento("'¡Solo 50% de chances de morir!' — dice con una sonrisa.")
	agregar_boton("Tomar pócima", _on_alquimista_tomar)
	agregar_boton("Rechazar", _on_alquimista_rechazar)

func _on_alquimista_tomar():
	limpiar_opciones()
	log_evento("Tomás la pócima de un sorbo...")
	agregar_boton("Tirar dado", func():
		limpiar_opciones()
		var resultado = randi() % 6 + 1
		await animar_dado(resultado)
		if resultado >= 4:
			GameManager.aplicar_efecto("heroe", "veneno", 3, 1)
			log_evento("[color=red]La pócima era tóxica! Quedás envenenado por 3 turnos.[/color]")
		else:
			GameManager.heroe.salud_maxima += 2
			GameManager.heroe.salud += 2
			log_evento("[color=green]La pócima funciona! Salud máxima +2. Salud: %d/%d[/color]" % [GameManager.heroe.salud, GameManager.heroe.salud_maxima])
		terminar_evento()
	)

func _on_alquimista_rechazar():
	log_evento("Rechazás la oferta. El alquimista se encoge de hombros y sigue su camino.")
	terminar_evento()

# ─── ALTAR ANTIGUO ───────────────────────────────────────────────
func cargar_altar():
	log_evento("Encontrás un altar de piedra cubierto de símbolos. Emana un poder oscuro.")
	log_evento("Podés sacrificar salud para obtener más poder. Se puede usar varias veces.")
	_mostrar_opciones_altar()

func _mostrar_opciones_altar():
	limpiar_opciones()
	var h = GameManager.heroe
	if h.salud <= 2:
		log_evento("[color=red]Estás demasiado débil para seguir sacrificando.[/color]")
		terminar_evento()
		return
	agregar_boton("Sacrificar (-2 salud, +1 ataque)", _on_altar_sacrificar)
	agregar_boton("Alejarse", _on_altar_alejarse)

func _on_altar_sacrificar():
	var h = GameManager.heroe
	if h.salud <= 2:
		log_evento("[color=red]No tenés suficiente salud para sacrificar.[/color]")
		terminar_evento()
		return
	GameManager.heroe.salud -= 2
	GameManager.heroe.ataque += 1
	log_evento("[color=red]El altar absorbe tu vitalidad.[/color]")
	log_evento("[color=orange]Salud: %d | Ataque: %d[/color]" % [GameManager.heroe.salud, GameManager.heroe.ataque])
	# Ofrecer usar de nuevo
	await get_tree().process_frame
	_mostrar_opciones_altar()

func _on_altar_alejarse():
	log_evento("Te alejás del altar. Sentís el poder corriendo por tus venas.")
	terminar_evento()

# ─── CONTINUAR ────────────────────────────────────────────────────
func _on_continuar():
	get_tree().change_scene_to_file("res://scenes/Combat.tscn")
