extends Control

func _ready():
	$Background/MenuButton.pressed.connect(_on_menu)

func _on_menu():
	GameManager.reiniciar()
	SceneTransition.change_scene("res://scenes/MainMenu.tscn")
