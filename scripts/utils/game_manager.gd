extends Node

const MAX_PLAYERS: int = 4
var players = []

signal player_need_join(device_id: int)


func _ready() -> void:
	pass

func add_players(device_id: int) -> bool:
	if players.size() < MAX_PLAYERS:
		if not players.any(func(player): return player.device_id == device_id):
			players.append({ "device_id": device_id })
			return true
	return false
	
func _input(event: InputEvent) -> void:
	var device_id: int
	
	if event is InputEventKey:
		device_id = -1
	elif event is InputEventJoypadButton:
		device_id = event.device
	else:
		return
	
	if add_players(device_id):
			emit_signal("player_need_join", device_id)
