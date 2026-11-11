@tool
extends EditorPlugin

const AUTOLOAD := "HitFeel"


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD, "res://addons/gameshipkit_game_feel/hit_feel.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD)
