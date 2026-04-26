extends Control

func _ready():
	AudioManager.reproducir_musica("menu")
	$Background/PlayButton.pressed.connect(_on_play_pressed)
	$Background/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	GameManager.reiniciar()
	SceneTransition.change_scene("res://scenes/CharacterSelect.tscn")
func _on_quit_pressed():
	get_tree().quit()
