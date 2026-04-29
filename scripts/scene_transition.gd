extends Node

func change_scene(target: String) -> void:
	AudioManager.reproducir("transition2",-5.0)
	$AnimationPlayer.play("dissolve")
	await $AnimationPlayer.animation_finished

	get_tree().change_scene_to_file(target)

	$AnimationPlayer.play_backwards("dissolve")
