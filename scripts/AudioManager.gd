extends Node

var sonidos = {}
var musica_actual: AudioStreamPlayer = null
var musicas_combate = []

func _ready():
	sonidos = {
		# Efectos
		"ataque_fallo":    preload("res://assets/audio/ataque_fallo.mp3"),
		"aturdido":        preload("res://assets/audio/aturdido.mp3"),
		"bloqueo":         preload("res://assets/audio/bloqueo.mp3"),
		"debuff":          preload("res://assets/audio/debuff.mp3"),
		"debuff2":         preload("res://assets/audio/debuff2.mp3"),
		"escudo_fuego":    preload("res://assets/audio/escudo_fuego.mp3"),
		"golpe_asesino":   preload("res://assets/audio/golpe_asesino.mp3"),
		"golpe_berserker": preload("res://assets/audio/golpe_berserker.mp3"),
		"golpe_espada":    preload("res://assets/audio/golpe_espada.mp3"),
		"golpe_mago":      preload("res://assets/audio/golpe_mago.mp3"),
		"humano_dano":     preload("res://assets/audio/humano_dano.mp3"),
		"item":            preload("res://assets/audio/item.mp3"),
		"oro":             preload("res://assets/audio/oro.mp3"),
		"pocion":          preload("res://assets/audio/pocion.mp3"),
		"rugido":          preload("res://assets/audio/rugido.mp3"),
		"runa":            preload("res://assets/audio/runa.mp3"),
		"transition":      preload("res://assets/audio/transition.mp3"),
		"transition2":      preload("res://assets/audio/transition2.mp3"),
		"curacion":      preload("res://assets/audio/curacion.mp3"),
		"sangre":      preload("res://assets/audio/blood.mp3"),

		
		# Músicas de escena
		"menu":            preload("res://assets/audio/menu.mp3"),
		"character_select":preload("res://assets/audio/character_select.mp3"),
		"mercado_entrar":  preload("res://assets/audio/mercado_entrar.mp3"),
		"bosque":          preload("res://assets/audio/bosque.mp3"),
		"ciudad":          preload("res://assets/audio/ciudad.mp3"),
		"cueva":           preload("res://assets/audio/cueva.mp3"),
		"lugar_siniestro": preload("res://assets/audio/lugar_siniestro.mp3"),
		"noche":           preload("res://assets/audio/noche.mp3"),
	}

	# Pool de músicas de combate
	musicas_combate = [
		preload("res://assets/audio/combate.mp3"),
		preload("res://assets/audio/combate2.mp3"),
		preload("res://assets/audio/combate3.mp3"),
		preload("res://assets/audio/combate4.mp3"),
	]

func reproducir(nombre: String, volumen_db: float = 0.0):
	if not sonidos.has(nombre):
		print("Sonido no encontrado: ", nombre)
		return
	var player = AudioStreamPlayer.new()
	player.stream = sonidos[nombre]
	player.volume_db = volumen_db
	player.autoplay = true
	add_child(player)
	player.finished.connect(func(): player.queue_free())

func reproducir_musica(nombre: String, volumen_db: float = -10.0):
	detener_musica()
	if not sonidos.has(nombre):
		print("Música no encontrada: ", nombre)
		return
	musica_actual = AudioStreamPlayer.new()
	musica_actual.stream = sonidos[nombre]
	musica_actual.volume_db = volumen_db
	musica_actual.stream.loop = true
	musica_actual.autoplay = true
	add_child(musica_actual)

func reproducir_musica_combate(volumen_db: float = -10.0):
	detener_musica()
	var lista = musicas_combate.duplicate()
	lista.shuffle()
	musica_actual = AudioStreamPlayer.new()
	musica_actual.stream = lista[0]
	musica_actual.volume_db = volumen_db
	musica_actual.autoplay = true
	add_child(musica_actual)
	# Al terminar, reproducir otra aleatoria
	musica_actual.finished.connect(_siguiente_combate.bind(volumen_db))

func _siguiente_combate(volumen_db: float):
	if musica_actual == null:
		return
	reproducir_musica_combate(volumen_db)

func detener_musica():
	if musica_actual != null:
		musica_actual.stop()
		musica_actual.queue_free()
		musica_actual = null
