extends Control

func _ready():
	$Background/MenuButton.pressed.connect(_on_menu)

func _on_menu():
	GameManager.reiniciar()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
