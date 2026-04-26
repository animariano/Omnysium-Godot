extends Node

@export_multiline var descripcion: String = ""
var panel = null
var touch_timer: Timer = null
var hide_timer: Timer = null
var hover_timer: Timer = null
var touch_pos: Vector2 = Vector2.ZERO
var mostrando: bool = false
var fue_long_press: bool = false

func _ready():
    panel = get_tree().get_first_node_in_group("tooltip_panel")
    var padre = get_parent()

    # Timers — siempre se crean
    touch_timer = Timer.new()
    touch_timer.wait_time = 0.5
    touch_timer.one_shot = true
    touch_timer.timeout.connect(_on_long_press)
    add_child(touch_timer)

    hide_timer = Timer.new()
    hide_timer.wait_time = 0.01
    hide_timer.one_shot = true
    hide_timer.timeout.connect(_on_hide_timeout)
    add_child(hide_timer)

    hover_timer = Timer.new()
    hover_timer.wait_time = 0.05
    hover_timer.one_shot = false
    hover_timer.timeout.connect(_on_hover_check)
    add_child(hover_timer)
    hover_timer.start()

    if padre is Control:
        if padre is Button or padre is TextureButton:
            padre.button_down.connect(_on_button_down)
            padre.button_up.connect(_on_button_up)
        else:
            padre.mouse_filter = Control.MOUSE_FILTER_STOP
            padre.gui_input.connect(_on_gui_input)

func _on_hover_check():
    var padre = get_parent()
    if not padre is Control:
        return
    if DisplayServer.is_touchscreen_available():
        return
    var mouse = padre.get_global_mouse_position()
    var rect = padre.get_global_rect()
    rect = rect.grow(4)  # ← margen de 4px alrededor del nodo
    if rect.has_point(mouse):
        hide_timer.stop()
        if not mostrando and descripcion != "" and panel != null:
            mostrando = true
            panel.mostrar(descripcion, padre.get_global_rect().get_center())
    else:
        if mostrando:
            if not hide_timer.is_stopped():
                return
            hide_timer.start()

func _on_hide_timeout():
    mostrando = false
    if panel:
        panel.ocultar_panel()

func _on_gui_input(event: InputEvent):
    if panel == null:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_pos = event.position
            touch_timer.start()
        else:
            touch_timer.stop()
    if event is InputEventScreenDrag:
        touch_timer.stop()
        if panel:
            panel.ocultar_panel()

func _on_long_press():
    fue_long_press = true
    GameManager.bloquear_accion = true
    mostrando = true
    if descripcion != "" and panel != null:
        var padre = get_parent()
        if padre is Control:
            var pos = padre.global_position + Vector2(padre.size.x / 2, 0)
            panel.mostrar(descripcion, pos)

func _on_button_down():
    fue_long_press = false
    touch_timer.start()

func _on_button_up():
    touch_timer.stop()
    if fue_long_press:
        # Fue long press — ocultar tooltip al soltar y bloquear acción
        await get_tree().process_frame
        await get_tree().process_frame
        GameManager.bloquear_accion = false
        mostrando = false
        if panel:
            panel.ocultar_panel()
    else:
        GameManager.bloquear_accion = false
