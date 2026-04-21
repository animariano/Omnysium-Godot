extends Node

func _ready():
	var tema = load("res://assets/ui/tema.tres")
	get_tree().root.theme = tema

# Iconos UI globales
var icono_corazon = preload("res://assets/ui/icono_corazon.png")
var icono_moneda = preload("res://assets/ui/icono_moneda.png")
var icono_espada = preload("res://assets/ui/icono_espada.png")

func icono(nombre: String) -> String:
	match nombre:
		"corazon": return "[img=20x20]res://assets/ui/icono_corazon.png[/img]"
		"moneda":  return "[img=20x20]res://assets/ui/icono_moneda.png[/img]"
		"espada":  return "[img=20x20]res://assets/ui/icono_espada.png[/img]"
	return ""

# Datos del héroe (equivalente a tu struct Heroe)
var heroe = {
	"nombre": "",
	"clase": "",
	"salud": 0,
	"salud_maxima": 0, 
	"ataque": 0,
	"oro": 0,
	"habilidad_especial": "",
	"habilidad_definitiva": "",
	"escudo_fuego": false  # para el Mago
}

var personajes_pool = [
	{
		"nombre": "Paladín", "clase": "Paladin",
		"salud": 8, "ataque": 4,
		"habilidad_especial": "Curar (Recupera 4 de salud)",
		"habilidad_definitiva": "Golpe Sanador (Ataca y sana la misma cantidad)",
		"cooldown_definitiva": 2
	},
	{
		"nombre": "Mago", "clase": "Mago",
		"salud": 6, "ataque": 1,
		"habilidad_especial": "Bola de Fuego (Daño directo = ataque/2)",
		"habilidad_definitiva": "Escudo de Fuego (Devuelve 2 de daño)",
		"cooldown_definitiva": 3
	},
	{
		"nombre": "Berserker", "clase": "Berserker",
		"salud": 6, "ataque": 4,
		"habilidad_especial": "Cabezazo (Doble daño, mitad de salud)",
		"habilidad_definitiva": "Arremetida Suicida (Triple daño, quedás a 1)",
		"cooldown_definitiva": 2
	},
	# ← agregar personajes nuevos acá
]

# Lista de enemigos (equivalente a tu array en jugar.cpp)
var enemigos = [
	{"nombre": "Goblin",         "salud": 4,  "ataque": 2},
	{"nombre": "Pirata",         "salud": 5,  "ataque": 2},
	{"nombre": "Orco",           "salud": 6,  "ataque": 3},
	{"nombre": "Ladron",         "salud": 8,  "ataque": 5},
	{"nombre": "Vampiro",        "salud": 15, "ataque": 5},
	{"nombre": "Elfo Oscuro",    "salud": 15, "ataque": 5},
	{"nombre": "Hombre Lobo",    "salud": 17, "ataque": 6},
	{"nombre": "Lider Cultista", "salud": 20, "ataque": 7},
	{"nombre": "Demonio",        "salud": 25, "ataque": 8},
	{"nombre": "Dragon",         "salud": 30, "ataque": 10}
]

var enemigo_actual_index = 0
var habilidad_especial_usada = 0
var definitiva_cooldown = 0
var contador_mercado = 0
var cooldown_definitiva_base = 3
var especial_cooldown = 0
var cooldown_especial_base = 2  # cada 2 combates

func reiniciar():
	efectos_heroe = []
	efectos_enemigo = []
	eventos_vistos = []
	items_comprados = []
	enemigo_actual_index = 0
	habilidad_especial_usada = false
	definitiva_cooldown = 0 
	especial_cooldown = 0
	contador_mercado = 0
	heroe = {"nombre":"","clase":"","salud":0,"ataque":0,"oro":0,
			 "habilidad_especial":"","habilidad_definitiva":"","escudo_fuego":false}

func enemigo_actual():
	return enemigos[enemigo_actual_index]

func siguiente_enemigo():
	enemigo_actual_index += 1
	habilidad_especial_usada = false
	
	# Pool completo de items del mercado
var items_pool = [
	{"id": "pocion_salud",      "nombre": "Poción de Salud",       "desc": "Salud +2",                                          "costo": 2,  "sprite": "pocion_salud.png"},
	{"id": "espada_hierro",     "nombre": "Espada de Hierro",       "desc": "Ataque +1",                                         "costo": 3,  "sprite": "espada_hierro.png"},
	{"id": "armadura_cuero",    "nombre": "Armadura de Cuero",      "desc": "Salud máxima +2",                                   "costo": 3,  "sprite": "armadura_cuero.png"},
	{"id": "espada_acero",      "nombre": "Espada de Acero",        "desc": "Ataque +2",                                         "costo": 4,  "sprite": "espada_acero.png"},
	{"id": "armadura_placas",   "nombre": "Armadura de Placas",     "desc": "Salud máxima +4",                                   "costo": 4,  "sprite": "armadura_placas.png"},
	{"id": "botas_agiles",      "nombre": "Botas Ágiles",           "desc": "Prob. de esquivar +1 (esquivás con 1-4)",            "costo": 5,  "sprite": "botas_agiles.png"},
	{"id": "guantes_precision", "nombre": "Guantes de Precisión",   "desc": "Prob. de atacar +1 (acertás con 1-4)",              "costo": 5,  "sprite": "guantes_precision.png"},
	{"id": "manto_protector",   "nombre": "Manto Protector",        "desc": "Inmune al primer ataque por combate",               "costo": 7,  "sprite": "manto_protector.png"},
	{"id": "piedra_salud",      "nombre": "Piedra de Salud",        "desc": "Salud máxima +2",                                   "costo": 3,  "sprite": "piedra_salud.png"},
	{"id": "piedra_regen",      "nombre": "Piedra de Regeneración", "desc": "Regeneración +1 al inicio de cada turno",           "costo": 6,  "sprite": "piedra_regen.png"},
	{"id": "colmillo_vampirico","nombre": "Colmillo Vampírico",     "desc": "Te curás 1 por cada ataque exitoso",                "costo": 6,  "sprite": "colmillo_vampirico.png"},
	{"id": "calavera_burlona",  "nombre": "Calavera Burlona",       "desc": "El enemigo recibe 1 de daño si falla",              "costo": 6,  "sprite": "calavera_burlona.png"},
	{"id": "sanguijuela",       "nombre": "Sanguijuela",            "desc": "Al inicio del turno enemigo, él pierde 1 y vos ganás 1", "costo": 7, "sprite": "sanguijuela.png"},
	{"id": "placas",            "nombre": "Placas",                 "desc": "Todo daño recibido se reduce en 1",                 "costo": 6,  "sprite": "placas.png"},
	{"id": "anillo_critico",    "nombre": "Anillo Crítico",         "desc": "Si al atacar sacás 6, hacés daño doble",            "costo": 8,  "sprite": "anillo_critico.png"},
	{"id": "amuleto_berserk",   "nombre": "Amuleto Berserk",        "desc": "Con 2 o menos de salud, +3 ataque",                 "costo": 5,  "sprite": "amuleto_berserk.png"},
	{"id": "dados_malditos",    "nombre": "Dados Malditos",         "desc": "Acertás siempre. Si sacás 6, perdés toda la salud", "costo": 5,  "sprite": "dados_malditos.png"},
	{"id": "runa_poder",        "nombre": "Runa de Poder Maldito",  "desc": "Ataque +4. Perdés 1 de salud por turno",            "costo": 5,  "sprite": "runa_poder.png"},
	{"id": "tablilla_alma",     "nombre": "Tablilla de Alma",       "desc": "Revivís con 1 de salud al morir. Uso único",         "costo": 10, "sprite": "tablilla_alma.png"},
	{"id": "mascara_frenetica", "nombre": "Máscara Frenética",      "desc": "Atacás dos veces por turno, pero no podés esquivar","costo": 8,  "sprite": "mascara_frenetica.png"},
	{"id": "corazon_cristal",   "nombre": "Corazón de Cristal",     "desc": "Salud máxima baja a 3, ataque se duplica",          "costo": 5,  "sprite": "corazon_cristal.png"},
	{"id": "idolo_abismo",      "nombre": "Ídolo del Abismo",       "desc": "+1 ataque permanente por turno, pero perdés 1 salud","costo": 6, "sprite": "idolo_abismo.png"},
	{"id": "filo_creciente",    "nombre": "Filo Creciente",         "desc": "Cada turno que atacás, +1 ataque acumulativo",      "costo": 7,  "sprite": "filo_creciente.png"},
	{"id": "sangre_caliente",   "nombre": "Sangre Caliente",        "desc": "Si fallás un ataque, el siguiente hace daño doble", "costo": 6,  "sprite": "sangre_caliente.png"},
	#{"id": "daga_maldita", "nombre": "Daga Maldita", "desc": "+2 salud, +2 ataque. Encontrada en la cueva.", "costo": 0, "sprite": "daga_maldita.png"},
	{"id": "daga_maldita", "nombre": "Daga Maldita", "desc": "+2 salud, +2 ataque.", "costo": 0, "sprite": "daga_maldita.png", "vendible": false},
]

# Items ya comprados (no vuelven a aparecer)
var items_comprados: Array = []

func get_items_disponibles(cantidad: int) -> Array:
	var disponibles = items_pool.filter(func(item):
		return not items_comprados.has(item.id) and item.get("vendible", true)
	)
	disponibles.shuffle()
	return disponibles.slice(0, cantidad)

func comprar_item(item_id: String):
	items_comprados.append(item_id)

var eventos_pool = [
	{"id": "trampa",    "nombre": "Trampa Oculta",    "sprite": "evento_trampa.png"},
	{"id": "equipo",    "nombre": "Equipo Abandonado", "sprite": "evento_equipo.png"},
	{"id": "cofre",     "nombre": "Cofre del Tesoro",  "sprite": "evento_cofre.png"},
	{"id": "fuente",    "nombre": "Fuente de Salud",   "sprite": "evento_fuente.png"},
	{"id": "cueva",     "nombre": "Cueva Misteriosa",  "sprite": "evento_cueva.png"},
]

var eventos_vistos: Array = []

var efectos_heroe: Array = []
var efectos_enemigo: Array = []

func get_evento_aleatorio():
	var disponibles = eventos_pool.filter(func(e):
		return not eventos_vistos.has(e.id)
	)
	if disponibles.is_empty():
		return null
	disponibles.shuffle()
	return disponibles[0]

func marcar_evento_visto(evento_id: String):
	eventos_vistos.append(evento_id)

func aplicar_efecto(objetivo: String, id: String, duracion: int, valor: int = 0):
	var lista = efectos_heroe if objetivo == "heroe" else efectos_enemigo
	# Si ya existe el efecto, refresca la duración
	for e in lista:
		if e.id == id:
			e.duracion = duracion
			e.valor = valor
			return
	lista.append({"id": id, "duracion": duracion, "valor": valor})

func tiene_efecto(objetivo: String, id: String) -> bool:
	var lista = efectos_heroe if objetivo == "heroe" else efectos_enemigo
	return lista.any(func(e): return e.id == id)

func reducir_duracion(objetivo: String):
	var lista = efectos_heroe if objetivo == "heroe" else efectos_enemigo
	for e in lista:
		e.duracion -= 1
	if objetivo == "heroe":
		efectos_heroe = efectos_heroe.filter(func(e): return e.duracion > 0)
	else:
		efectos_enemigo = efectos_enemigo.filter(func(e): return e.duracion > 0)

func get_valor_efecto(objetivo: String, id: String) -> int:
	var lista = efectos_heroe if objetivo == "heroe" else efectos_enemigo
	for e in lista:
		if e.id == id:
			return e.valor
	return 0
