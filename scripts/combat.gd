extends Control

var salud_enemigo = 0
var salud_maxima_enemigo = 0 
var ataque_enemigo = 0
var turno_jugador = true
var especial_cooldown_turnos = 0
var ESPECIAL_COOLDOWN = 2 
var esperando_esquive = false
var dano_entrante = 0
var es_critico = false

#objetos usados
var manto_usado = false
var sangre_caliente_activa = false
var filo_creciente_bonus = 0
var idolo_ataque_bonus = 0
var tiene_dados_malditos = false

var sprites_enemigos = {
	"Goblin":          preload("res://assets/enemies/goblin.png"),
	"Pirata":          preload("res://assets/enemies/pirata.png"),
	"Orco":            preload("res://assets/enemies/orco.png"),
	"Ladron":          preload("res://assets/enemies/ladron.png"),
	"Vampiro":         preload("res://assets/enemies/vampiro.png"),
	"Elfo Oscuro":     preload("res://assets/enemies/elfo_oscuro.png"),
	"Hombre Lobo":     preload("res://assets/enemies/hombre_lobo.png"),
	"Lider Cultista":  preload("res://assets/enemies/lider_cultista.png"),
	"Demonio":         preload("res://assets/enemies/demonio.png"),
	"Dragon":          preload("res://assets/enemies/dragon.png")
}

var sprites_heroes = {
	"Paladin":   preload("res://assets/characters/paladin.png"),
	"Mago":      preload("res://assets/characters/mago.png"),
	"Berserker": preload("res://assets/characters/berserker.png")
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
	
	# Conectar botones — ajustá las rutas a tu jerarquía real
	$Background/ActionButtons/AtacarButton.pressed.connect(_on_atacar)
	$Background/ActionButtons/EspecialButton.pressed.connect(_on_especial)
	$Background/ActionButtons/DefinitivaButton.pressed.connect(_on_definitiva)
	$Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton.pressed.connect(_on_esquivar)
	
	$Background/HeroePanel/VBoxContainer/BarraSaludHeroe.max_value = GameManager.heroe.salud_maxima
	$Background/EnemigoPanel/VBoxContainer/BarraSaludEnemigo.max_value = salud_maxima_enemigo

	# El botón de esquive empieza oculto
	$Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton.visible = false
	$Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton/AlertaAnim.visible = false
	var alerta = $Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton/AlertaAnim
	alerta.visible = false
	# Animacion golpe escondida
	$Background/HeroePanel/VBoxContainer/HeroeImage/HeroeHitAnim.animation_finished.connect(
	func(): $Background/HeroePanel/VBoxContainer/HeroeImage/HeroeHitAnim.visible = false)
	$Background/EnemigoPanel/VBoxContainer/EnemigoImage/EnemigoHitAnim.animation_finished.connect(
	func(): $Background/EnemigoPanel/VBoxContainer/EnemigoImage/EnemigoHitAnim.visible = false)

	var enemigo = GameManager.enemigo_actual()
	salud_enemigo = enemigo.salud
	salud_maxima_enemigo = enemigo.salud
	ataque_enemigo = enemigo.ataque
	manto_usado = false
	sangre_caliente_activa = false
	filo_creciente_bonus = 0
	idolo_ataque_bonus = 0
	tiene_dados_malditos = GameManager.items_comprados.has("dados_malditos")

	actualizar_ui()
	cargar_inventario() 
	configurar_botones_accion()
	log_combate("Te topas con [b]" + enemigo.nombre + "[/b]! Salud: " + str(enemigo.salud) + " | Ataque: " + str(enemigo.ataque))

func actualizar_ui():
	var h = GameManager.heroe
	var enemigo = GameManager.enemigo_actual()

	$Background/HeroePanel/VBoxContainer/HeroeImage.texture = sprites_heroes[h.clase]
	$Background/HeroePanel/VBoxContainer/HeroeNameLabel.text = h.nombre
	$Background/HeroePanel/VBoxContainer/HeroeStatsLabel.text = " %s %d    %s %d" % [
		GameManager.icono("espada"),
		h.ataque,
		GameManager.icono("moneda"),
		h.oro
	]	
	$Background/HeroePanel/VBoxContainer/BarraSaludHeroe.max_value = h.salud_maxima
	#$Background/HeroePanel/VBoxContainer/BarraSaludHeroe.value = h.salud   probando
	$Background/HeroePanel/VBoxContainer/BarraSaludHeroe.set_target(h.salud)
	$Background/HeroePanel/VBoxContainer/SaludLabel.text = "%d/%d" % [h.salud, h.salud_maxima]

	$Background/EnemigoPanel/VBoxContainer/EnemigoImage.texture = sprites_enemigos[enemigo.nombre]
	$Background/EnemigoPanel/VBoxContainer/EnemigoNameLabel.text = enemigo.nombre
	$Background/EnemigoPanel/VBoxContainer/EnemigoStatsLabel.text = "%s %d" % [GameManager.icono("espada"), ataque_enemigo]
	$Background/EnemigoPanel/VBoxContainer/BarraSaludEnemigo.max_value = enemigo.salud  # salud inicial
	$Background/EnemigoPanel/VBoxContainer/BarraSaludEnemigo.max_value = salud_maxima_enemigo
	#$Background/EnemigoPanel/VBoxContainer/BarraSaludEnemigo.value = salud_enemigo probando
	$Background/EnemigoPanel/VBoxContainer/BarraSaludEnemigo.set_target(salud_enemigo)
	$Background/EnemigoPanel/VBoxContainer/SaludLabel.text = "%d/%d" % [salud_enemigo, salud_maxima_enemigo]

	$Background/TurnoLabel.text = "[color=green]Tu turno![/color]" if turno_jugador else "[color=red]Turno del enemigo[/color]"

	# Botones de acción solo activos en turno del jugador y sin esquive pendiente
	var puede_actuar = turno_jugador and not esperando_esquive
	$Background/ActionButtons/AtacarButton.disabled = not puede_actuar
	$Background/ActionButtons/EspecialButton.disabled = not puede_actuar or especial_cooldown_turnos > 0
	$Background/ActionButtons/DefinitivaButton.disabled = not puede_actuar or GameManager.definitiva_cooldown > 0
func log_combate(texto: String):
	$Background/CombatLog.append_text("\n" + texto)

func mostrar_dado(resultado: int):
	$Background/CenterArea/DadoPanel/VBoxContainer/DadoTexture.texture = texturas_dado[resultado - 1]
	$Background/CenterArea/DadoPanel/VBoxContainer/ResultadoLabel.text = "Dado: %d" % resultado
	
func animar_dado(resultado: int):
	# Muestra caras aleatorias por 600ms antes del resultado final
	for i in range(12):
		var cara_random = randi() % 6
		$Background/CenterArea/DadoPanel/VBoxContainer/DadoTexture.texture = texturas_dado[cara_random]
		await get_tree().create_timer(0.05).timeout
	# Muestra el resultado final
	mostrar_dado(resultado)

# ─── TURNO DEL JUGADOR ───────────────────────────────────────────

func _on_atacar():
	var h = GameManager.heroe
	turno_jugador = false
	actualizar_ui()

	var ataque_efectivo = h.ataque

	# Amuleto Berserk
	if GameManager.items_comprados.has("amuleto_berserk") and h.salud <= 2:
		ataque_efectivo += 3
		log_combate("[color=red]¡Amuleto Berserk activado! +3 ataque.[/color]")

	# Filo Creciente
	if GameManager.items_comprados.has("filo_creciente"):
		filo_creciente_bonus += 1
		ataque_efectivo += filo_creciente_bonus
		log_combate("[color=orange]Filo Creciente: +%d ataque acumulativo.[/color]" % filo_creciente_bonus)

	# Debilidad
	if GameManager.tiene_efecto("heroe", "debilidad"):
		ataque_efectivo = max(1, ataque_efectivo / 2)
		log_combate("[color=gray]⬇ Debilidad: ataque reducido al 50%.[/color]")

	# Sangre Caliente
	var multiplicador = 1
	if sangre_caliente_activa:
		multiplicador = 2
		sangre_caliente_activa = false
		log_combate("[color=orange]¡Sangre Caliente! Daño doble.[/color]")

	if h.clase == "Mago":
		var dado_dano = tirar_dado()
		await animar_dado(dado_dano)
		var dano_total = ataque_efectivo * dado_dano * multiplicador

		# Vulnerabilidad enemigo
		if GameManager.tiene_efecto("enemigo", "vulnerabilidad"):
			dano_total = int(dano_total * 1.5)
			log_combate("[color=orange]💢 Enemigo vulnerable: +50% daño.[/color]")
			
		log_combate("Dado de daño: [b]%d[/b]. Daño potencial: %d" % [dado_dano, dano_total])
		await get_tree().create_timer(0.8).timeout

		if GameManager.heroe.salud <= 0:
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
			return

		var dado_acierto = tirar_dado()
		await animar_dado(dado_acierto)
		var umbral_ataque = 4 if GameManager.items_comprados.has("guantes_precision") else 3

		if tiene_dados_malditos or dado_acierto <= umbral_ataque:
			animar_golpe("enemigo")
			salud_enemigo -= dano_total
			log_combate("[color=green]¡Ataque exitoso! Hiciste %d de daño.[/color]" % dano_total)
			if GameManager.items_comprados.has("colmillo_vampirico"):
				GameManager.heroe.salud = min(GameManager.heroe.salud + 1, h.salud_maxima)
				log_combate("[color=green]Colmillo Vampírico: +1 salud.[/color]")
			if dado_acierto == 6 and GameManager.items_comprados.has("anillo_critico"):
				salud_enemigo -= dano_total
				log_combate("[color=yellow]¡Anillo Crítico! Daño doble.[/color]")
		else:
			log_combate("[color=gray]¡Ataque fallido![/color]")
			if GameManager.items_comprados.has("sangre_caliente"):
				sangre_caliente_activa = true
	else:
		var cantidad_ataques = 2 if GameManager.items_comprados.has("mascara_frenetica") else 1
		for _i in range(cantidad_ataques):
			var resultado = tirar_dado()
			await animar_dado(resultado)

			if GameManager.heroe.salud <= 0:
				await get_tree().create_timer(1.0).timeout
				get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
				return

			var umbral_ataque = 4 if GameManager.items_comprados.has("guantes_precision") else 3
			if tiene_dados_malditos or resultado <= umbral_ataque:
				var dano_final = ataque_efectivo * multiplicador
				
				# Vulnerabilidad — 50% más de daño (Paladín/Berserker)
				if GameManager.tiene_efecto("enemigo", "vulnerabilidad"):
					dano_final = int(dano_final * 1.5)
					log_combate("[color=orange]💢 Enemigo vulnerable: +50% daño.[/color]")
					
				animar_golpe("enemigo")   
				salud_enemigo -= dano_final
				log_combate("[color=green]¡Ataque exitoso! Hiciste %d de daño.[/color]" % dano_final)

				if GameManager.items_comprados.has("colmillo_vampirico"):
					GameManager.heroe.salud = min(GameManager.heroe.salud + 1, GameManager.heroe.salud_maxima)
					log_combate("[color=green]Colmillo Vampírico: +1 salud.[/color]")
				if resultado == 6 and GameManager.items_comprados.has("anillo_critico"):
					animar_golpe("enemigo")
					salud_enemigo -= dano_final
					log_combate("[color=yellow]¡Anillo Crítico! Daño doble.[/color]")
			else:
				log_combate("[color=gray]¡Ataque fallido![/color]")
				if GameManager.items_comprados.has("sangre_caliente"):
					sangre_caliente_activa = true

			await get_tree().create_timer(0.5).timeout

	actualizar_ui()
	await get_tree().create_timer(0.8).timeout
	chequear_muerte_enemigo()

func _on_especial():
	if especial_cooldown_turnos > 0:
		return
	especial_cooldown_turnos = ESPECIAL_COOLDOWN
	turno_jugador = false
	# Efecto visual — se apaga skill
	$Background/ActionButtons/EspecialButton.modulate = Color(0.3, 0.3, 0.3)
	var h = GameManager.heroe
	match h.clase:
		"Paladin":
			GameManager.heroe.salud = min(h.salud + 3, h.salud_maxima)
			log_combate("[color=cyan]Usaste Curar. Tu salud: %d[/color]" % GameManager.heroe.salud)
		"Mago":
			var dano = max(1, h.ataque / 2)
			salud_enemigo -= dano
			animar_golpe("enemigo")
			log_combate("[color=cyan]Bola de Fuego! Hiciste %d de daño directo.[/color]" % dano)
		"Berserker":
			var dano = h.ataque * 2
			salud_enemigo -= dano
			animar_golpe("enemigo")
			GameManager.heroe.salud = max(1, h.salud / 2)
			log_combate("[color=cyan]Cabezazo! Hiciste %d de daño. Tu salud: %d[/color]" % [dano, GameManager.heroe.salud])

	actualizar_ui()
	await get_tree().create_timer(0.8).timeout
	chequear_muerte_enemigo()

func _on_definitiva():
	if GameManager.definitiva_cooldown > 0:
		return
	GameManager.definitiva_cooldown = GameManager.cooldown_definitiva_base # disponible cada 3 combates
	turno_jugador = false
	var h = GameManager.heroe

	# Efecto visual inmediato
	$Background/ActionButtons/DefinitivaButton.modulate = Color(0.3, 0.3, 0.3)
	$Background/ActionButtons/DefinitivaButton.tooltip_text = h.habilidad_definitiva + "\n⏳ Disponible en 3 combates"

	match h.clase:
		"Paladin":
			animar_golpe("enemigo") 
			salud_enemigo -= h.ataque
			GameManager.heroe.salud = min(h.salud + h.ataque, h.salud_maxima)
			log_combate("[color=yellow]Golpe Sanador! Daño: %d. Tu salud: %d[/color]" % [h.ataque, GameManager.heroe.salud])
		"Mago":
			GameManager.heroe.escudo_fuego = true
			log_combate("[color=yellow]Escudo de Fuego activado![/color]")
		"Berserker":
			var dano = h.ataque * 3
			animar_golpe("enemigo") 
			salud_enemigo -= dano
			GameManager.heroe.salud = 1
			log_combate("[color=yellow]Arremetida Suicida! Daño: %d. Quedás a 1 de salud.[/color]" % dano)

	actualizar_ui()
	await get_tree().create_timer(0.8).timeout
	chequear_muerte_enemigo()

# ─── TURNO DEL ENEMIGO ───────────────────────────────────────────

func turno_enemigo():
	turno_jugador = false
	actualizar_ui()
	await get_tree().create_timer(0.8).timeout

	# Sanguijuela — inicio turno enemigo
	if GameManager.items_comprados.has("sanguijuela"):
		salud_enemigo -= 1
		animar_golpe("enemigo") 
		GameManager.heroe.salud = min(GameManager.heroe.salud + 1, GameManager.heroe.salud_maxima)
		log_combate("[color=green]Sanguijuela: enemigo -1 salud, vos +1 salud.[/color]")
		actualizar_ui()
		if salud_enemigo <= 0:
			await get_tree().create_timer(1.0).timeout
			chequear_muerte_enemigo()
			return
	# Aturdido — enemigo pierde el turno
	if GameManager.tiene_efecto("enemigo", "aturdido"):
			log_combate("[color=yellow]💫 El enemigo está aturdido y pierde su turno.[/color]")
			GameManager.reducir_duracion("enemigo")
			actualizar_efectos_ui()
			await get_tree().create_timer(1.0).timeout
			iniciar_turno_jugador()
			return

	await procesar_efectos_enemigo()
	if not is_inside_tree():
		return

	var enemigo = GameManager.enemigo_actual()
	var dado_enemigo = randi() % 6 + 1
	await animar_dado(dado_enemigo)

	var roba_oro = ["Pirata", "Ladron"]
	var critico_en_6 = ["Goblin", "Orco", "Hombre Lobo", "Elfo Oscuro"]

	if dado_enemigo == 6 and enemigo.nombre in roba_oro:
		log_combate("[color=yellow]¡El %s te robó todo el oro![/color]" % enemigo.nombre)
		GameManager.heroe.oro = 0
		actualizar_ui()
		await get_tree().create_timer(1.0).timeout
		iniciar_turno_jugador()
		return

	if dado_enemigo == 6 and enemigo.nombre in critico_en_6:
		dano_entrante = enemigo.ataque * 2
		es_critico = true
		log_combate("[color=red]¡%s lanza un golpe crítico! Daño potencial: %d.[/color]" % [enemigo.nombre, dano_entrante])
	else:
		dano_entrante = enemigo.ataque
		es_critico = false
		log_combate("[color=white]%s va a atacarte (daño: %d).[/color]" % [enemigo.nombre, dano_entrante])

	# Máscara Frenética — no podés esquivar
	if GameManager.items_comprados.has("mascara_frenetica"):
		log_combate("[color=gray]La Máscara Frenética te impide esquivar.[/color]")
		aplicar_dano_entrante()
		actualizar_ui()
		await get_tree().create_timer(0.5).timeout
		if GameManager.heroe.salud <= 0:
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
			return
		if salud_enemigo <= 0:
			chequear_muerte_enemigo()
			return
		iniciar_turno_jugador()
		return

	# Mostrar botón de esquive
	esperando_esquive = true
	$Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton.visible = true
	$Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton.text = "¡Esquivar!"
	var alerta = $Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton/AlertaAnim
	alerta.visible = true
	alerta.play("alerta") 

	actualizar_ui()

func _on_esquivar():
	if not esperando_esquive:
		return
	esperando_esquive = false
	$Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton.visible = false

	var alerta = $Background/CenterArea/DadoPanel/VBoxContainer/TirarDadoButton/AlertaAnim
	alerta.stop()
	alerta.visible = false
	
	var resultado = randi() % 6 + 1
	await animar_dado(resultado)

	var umbral_esquive = 4 if GameManager.items_comprados.has("botas_agiles") else 3

	if tiene_dados_malditos or resultado <= umbral_esquive:
		log_combate("[color=green]¡Esquivaste el ataque![/color]")
		# Calavera Burlona — enemigo recibe 1 daño si falla
		if GameManager.items_comprados.has("calavera_burlona"):
			salud_enemigo -= 1
			animar_golpe("enemigo") 
			log_combate("[color=green]Calavera Burlona: el enemigo recibe 1 de daño.[/color]")
	else:
		aplicar_dano_entrante()

	actualizar_ui()
	await get_tree().create_timer(0.5).timeout

	if GameManager.heroe.salud <= 0:
		log_combate("[color=red][b]¡Has muerto![/b][/color]")
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
		return

	if salud_enemigo <= 0:
		await get_tree().create_timer(1.0).timeout
		chequear_muerte_enemigo()
		return

	iniciar_turno_jugador()

func aplicar_dano_entrante():
	var dano_final = dano_entrante
	
	# Vulnerabilidad — recibe más daño
	if GameManager.tiene_efecto("heroe", "vulnerabilidad"):
		dano_final = int(dano_final * 1.5)
		log_combate("[color=red]💢 Vulnerabilidad: +50% daño recibido.[/color]")
		
	# Manto Protector — primer ataque del combate ignorado
	if GameManager.items_comprados.has("manto_protector") and not manto_usado:
		manto_usado = true
		log_combate("[color=cyan]¡Manto Protector absorbió el ataque![/color]")
		return

	# Placas — reducen daño en 1
	if GameManager.items_comprados.has("placas"):
		dano_final = max(0, dano_final - 1)
		log_combate("[color=cyan]Placas: daño reducido en 1.[/color]")
	animar_golpe("heroe")
	GameManager.heroe.salud -= dano_final
	log_combate("[color=red]Recibiste %d de daño. Tu salud: %d[/color]" % [dano_final, GameManager.heroe.salud])

	# Escudo de Fuego
	if GameManager.heroe.escudo_fuego:
		animar_golpe("enemigo") 
		salud_enemigo -= 2
		log_combate("[color=cyan]Escudo de Fuego devolvió 2 de daño![/color]")

	# Tablilla de Alma — reivís con 1 si morís
	if GameManager.heroe.salud <= 0 and GameManager.items_comprados.has("tablilla_alma"):
		GameManager.heroe.salud = 1
		GameManager.items_comprados.erase("tablilla_alma")
		cargar_inventario()  # actualizar el inventario visual
		log_combate("[color=yellow]¡La Tablilla de Alma te salvó! Reivís con 1 de salud.[/color]")

func iniciar_turno_jugador():
	if especial_cooldown_turnos > 0:
		especial_cooldown_turnos -= 1

	if especial_cooldown_turnos == 0:
		$Background/ActionButtons/EspecialButton.modulate = Color(1, 1, 1)

	turno_jugador = true
	# Aturdido — pierde el turno
	if GameManager.tiene_efecto("heroe", "aturdido"):
		log_combate("[color=yellow]💫 Estás aturdido y perdés el turno.[/color]")
		GameManager.reducir_duracion("heroe")
		actualizar_efectos_ui()
		await get_tree().create_timer(1.0).timeout
		turno_enemigo()
		return

	await procesar_efectos_heroe()
	if not is_inside_tree():
		return

	# Piedra de Regeneración (item)
	if GameManager.items_comprados.has("piedra_regen"):
		GameManager.heroe.salud = min(GameManager.heroe.salud + 1, GameManager.heroe.salud_maxima)
		log_combate("[color=green]Piedra de Regeneración: +1 salud.[/color]")

	# Ídolo del Abismo
	if GameManager.items_comprados.has("idolo_abismo"):
		GameManager.heroe.ataque += 1
		GameManager.heroe.salud -= 1
		log_combate("[color=orange]Ídolo del Abismo: +1 ataque, -1 salud.[/color]")
		if GameManager.heroe.salud <= 0:
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
			return

	# Runa de Poder Maldito
	if GameManager.items_comprados.has("runa_poder"):
		GameManager.heroe.salud -= 1
		animar_golpe("Heroe")
		log_combate("[color=red]Runa de Poder: -1 salud.[/color]")
		if GameManager.heroe.salud <= 0:
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
			return

	#turno_jugador = true
	actualizar_ui()

# ─── FIN DE COMBATE ──────────────────────────────────────────────

func chequear_muerte_enemigo():
	if salud_enemigo <= 0:
		log_combate("[b]¡Venciste al %s! Ganaste 3 %s.[/b]" % [GameManager.enemigo_actual().nombre, GameManager.icono("moneda")])
		GameManager.heroe.oro += 3
		await get_tree().create_timer(1.5).timeout
		siguiente_combate()
		return
	turno_enemigo()

func siguiente_combate():
	GameManager.contador_mercado += 1
	GameManager.enemigo_actual_index += 1

	# Reducir cooldown de definitiva
	if GameManager.definitiva_cooldown > 0:
		GameManager.definitiva_cooldown -= 1

	if GameManager.enemigo_actual_index >= GameManager.enemigos.size():
		get_tree().change_scene_to_file("res://scenes/Victory.tscn")
		return

	if GameManager.contador_mercado % 2 == 0:
		get_tree().change_scene_to_file("res://scenes/Market.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Event.tscn")
		
func cargar_inventario():
	var grid = $Background/CenterArea/InventarioPanel/InventarioGrid
	for child in grid.get_children():
		child.queue_free()

	if GameManager.items_comprados.is_empty():
		var label = Label.new()
		label.text = "Sin items"
		grid.add_child(label)
		return

	for item_id in GameManager.items_comprados:
		var item_data = GameManager.items_pool.filter(func(i): return i.id == item_id)
		if item_data.is_empty():
			continue
		var textura = load("res://assets/items/" + item_data[0].sprite)
		var img = TextureRect.new()
		img.texture = textura
		img.custom_minimum_size = Vector2(60, 60)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.tooltip_text = item_data[0].nombre + "\n" + item_data[0].desc
		grid.add_child(img)
		
func tirar_dado() -> int:
	if tiene_dados_malditos:
		var resultado = randi() % 6 + 1
		mostrar_dado(resultado)
		if resultado == 6:
			log_combate("[color=red]¡Los Dados Malditos sacaron 6! Perdés toda la salud.[/color]")
			GameManager.heroe.salud = 0
			actualizar_ui()
		return resultado
	return randi() % 6 + 1

func configurar_botones_accion():
	var h = GameManager.heroe
	var btn_atacar    = $Background/ActionButtons/AtacarButton
	var btn_especial  = $Background/ActionButtons/EspecialButton
	var btn_definitiva = $Background/ActionButtons/DefinitivaButton

	btn_atacar.texture_normal    = load("res://assets/skills/ataque_%s.png" % h.clase.to_lower())
	btn_especial.texture_normal  = load("res://assets/skills/especial_%s.png" % h.clase.to_lower())
	btn_definitiva.texture_normal = load("res://assets/skills/definitiva_%s.png" % h.clase.to_lower())

	btn_atacar.tooltip_text    = "Atacar\nTirás el dado. 1-3 acierta."
	btn_especial.tooltip_text  = h.habilidad_especial
	
	# Tooltip muestra si algun skill esta en cd
	if GameManager.definitiva_cooldown > 0:
		btn_definitiva.tooltip_text = h.habilidad_definitiva + "\n⏳ Disponible en %d combate/s" % GameManager.definitiva_cooldown
		btn_definitiva.modulate = Color(0.3, 0.3, 0.3)  # gris oscuro
	else:
		btn_definitiva.tooltip_text = h.habilidad_definitiva + "\n(Cooldown: 3 combates)"
		btn_definitiva.modulate = Color(1, 1, 1)  # color normal
		
	if GameManager.especial_cooldown > 0:
		btn_especial.tooltip_text = h.habilidad_especial + "\n⏳ Disponible en %d turnos/s" % GameManager.especial_cooldown
		btn_especial.modulate = Color(0.3, 0.3, 0.3)
	else:
		btn_especial.tooltip_text = h.habilidad_especial + "\n(Cooldown: %d turno/s)" % GameManager.cooldown_especial_base
		btn_especial.modulate = Color(1, 1, 1)    


func procesar_efectos_heroe():
	var h = GameManager.heroe

	# Veneno
	if GameManager.tiene_efecto("heroe", "veneno"):
		var dano = GameManager.get_valor_efecto("heroe", "veneno")
		GameManager.heroe.salud -= dano
		log_combate("[color=purple]☠ Veneno: perdés %d de salud.[/color]" % dano)
		if GameManager.heroe.salud <= 0:
			if GameManager.items_comprados.has("tablilla_alma"):
				GameManager.heroe.salud = 1
				GameManager.items_comprados.erase("tablilla_alma")
				cargar_inventario()
				log_combate("[color=yellow]¡La Tablilla de Alma te salvó![/color]")
			else:
				actualizar_ui()
				await get_tree().create_timer(1.0).timeout
				get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
				return

	# Regeneración
	if GameManager.tiene_efecto("heroe", "regeneracion"):
		var cura = GameManager.get_valor_efecto("heroe", "regeneracion")
		GameManager.heroe.salud = min(h.salud + cura, h.salud_maxima)
		log_combate("[color=green]💚 Regeneración: recuperás %d de salud.[/color]" % cura)

	GameManager.reducir_duracion("heroe")
	actualizar_ui()
	actualizar_efectos_ui()

func procesar_efectos_enemigo():
	# Veneno
	if GameManager.tiene_efecto("enemigo", "veneno"):
		var dano = GameManager.get_valor_efecto("enemigo", "veneno")
		salud_enemigo -= dano
		log_combate("[color=purple]☠ Veneno: el enemigo pierde %d de salud.[/color]" % dano)
		if salud_enemigo <= 0:
			GameManager.reducir_duracion("enemigo")
			actualizar_ui()
			chequear_muerte_enemigo()
			return

	# Regeneración enemigo
	if GameManager.tiene_efecto("enemigo", "regeneracion"):
		var cura = GameManager.get_valor_efecto("enemigo", "regeneracion")
		salud_enemigo = min(salud_enemigo + cura, salud_maxima_enemigo)
		log_combate("[color=green]💚 El enemigo se regenera %d de salud.[/color]" % cura)

	GameManager.reducir_duracion("enemigo")
	actualizar_ui()
	actualizar_efectos_ui()
	
var sprites_efectos = {
	"veneno":         preload("res://assets/effects/efecto_veneno.png"),
	"vulnerabilidad": preload("res://assets/effects/efecto_vulnerabilidad.png"),
	"debilidad":      preload("res://assets/effects/efecto_debilidad.png"),
	"regeneracion":   preload("res://assets/effects/efecto_regeneracion.png"),
	"aturdido":       preload("res://assets/effects/efecto_aturdido.png"),
}

func actualizar_efectos_ui():
	_actualizar_efectos_container(
		$Background/HeroePanel/VBoxContainer/HeroeEfectosContainer,
		GameManager.efectos_heroe
	)
	_actualizar_efectos_container(
		$Background/EnemigoPanel/VBoxContainer/EnemigoEfectosContainer,
		GameManager.efectos_enemigo
	)

func _actualizar_efectos_container(container: HBoxContainer, efectos: Array):
	for child in container.get_children():
		child.queue_free()
	for efecto in efectos:
		var img = TextureRect.new()
		img.texture = sprites_efectos.get(efecto.id)
		img.custom_minimum_size = Vector2(32, 32)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_STOP
		img.tooltip_text = "%s (%d turnos)" % [efecto.id.capitalize(), efecto.duracion]
		container.add_child(img)

func animar_golpe(objetivo: String):
	if objetivo == "heroe":
		var anim = $Background/HeroePanel/VBoxContainer/HeroeImage/HeroeHitAnim
		anim.visible = true
		anim.play("hit")
	else:
		var anim = $Background/EnemigoPanel/VBoxContainer/EnemigoImage/EnemigoHitAnim
		anim.visible = true
		anim.play("hit")
