extends Node

func quit() -> void:
	get_tree().quit()

func play() -> void:
	get_tree().change_scene_to_file("res://scenes/testlevel/test_level.tscn")

func _on_sensitivity_value_changed(value: float) -> void:
	Globals.mouse_sensitivity = value/100
