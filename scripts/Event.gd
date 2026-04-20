extends Control

var evento_actual = null
var evento_terminado = false

var sprites_eventos = {
    "trampa": preload("res://assets/events/evento_trampa.png"),
    "equipo": preload("res://assets/events/evento_equipo.png"),
    "cofre":  preload("res://assets/events/evento_cofre.png"),
    "fuente": preload("res://assets/events/evento_fuente.png"),
    "cueva":  preload("res://assets/events/evento_cueva.png"),
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
    log_evento("Ganás +1 de ataque.")
    log_evento("Ganás +1 de salud máxima.")
    GameManager.heroe.ataque += 1
    GameManager.heroe.salud_maxima +=1
    terminar_evento()

# ─── COFRE ────────────────────────────────────────────────────────
func cargar_cofre():
    log_evento("Descubriste un cofre escondido lleno de oro!")
    var resultado = randi() % 6 + 1
    GameManager.heroe.oro += resultado
    resultado = resultado+3
    log_evento("[color=yellow]Encontrás oro en el cofre! Ganás %d de oro. Oro: %d[/color]" % [resultado, GameManager.heroe.oro])
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
    GameManager.heroe.salud += 2
    GameManager.heroe.ataque += 2
    $Background/EventLog.clear() 
    GameManager.comprar_item("daga_maldita")
    log_evento("[color=cyan]Lo tomás y te sentís más fuerte. +2 salud, +2 ataque.[/color]")
    log_evento("Pero con una sensación [color=red]extraña[/color].")
    terminar_evento()

func _on_cueva_dejar_cuchillo():
    log_evento("Te marchás sin tomarlo.")
    terminar_evento()

func _on_cueva_dorado():
    limpiar_opciones()
    log_evento("[color=yellow]Seguís la luz dorada y encontrás un cofre. Ganás 10 de oro![/color]")
    GameManager.heroe.oro += 10
    terminar_evento()

func _on_cueva_vegetal():
    limpiar_opciones()
    log_evento("[color=green]El túnel te lleva a una planta curativa. Recuperás 4 de salud.[/color]")
    GameManager.heroe.salud = min(GameManager.heroe.salud + 4, GameManager.heroe.salud_maxima)
    terminar_evento()

# ─── CONTINUAR ────────────────────────────────────────────────────
func _on_continuar():
    get_tree().change_scene_to_file("res://scenes/Combat.tscn")
