extends Node2D

@onready var jump_effect = load("res://air_jump.tscn")

func _ready() -> void:
	$Player.air_jump.connect(spawn_jump_effect)
 
func spawn_jump_effect(effect_position: Vector2, effect_rotation: float) -> void:
	var new_effect = jump_effect.instantiate()
	new_effect.position = effect_position
	new_effect.rotation = effect_rotation
	add_child.call_deferred(new_effect)
