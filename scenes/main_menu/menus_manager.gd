extends Node

func _ready() -> void:
	%main.show()
	%options.hide()

func _on_back_pressed() -> void:
	%main.show()
	%options.hide()

func _on_option_pressed() -> void:
	%main.hide()
	%options.show()
