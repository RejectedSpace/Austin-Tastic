extends Node2D

class_name Attack

var attack_name: String
var anim_name: String
var startup_time: float
var attack_time: float
var lag_time: float

@warning_ignore("shadowed_variable")
static func create(attack_name: String, anim_name: String, startup_time: float, attack_time: float, lag_time:float) -> Attack:
	var instance = Attack.new()
	
	instance.attack_name = attack_name
	instance.anim_name = anim_name
	instance.startup_time = startup_time
	instance.attack_time = attack_time
	instance.lag_time = lag_time
	
	return instance

func get_attack_name() -> String:
	return attack_name

func get_anim_name() -> String:
	return anim_name

func get_startup_time() -> float:
	return startup_time

func get_attack_time() -> float:
	return attack_time

func get_lag_time() -> float:
	return lag_time
