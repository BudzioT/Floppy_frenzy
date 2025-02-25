extends Node3D

@export var player_scene: PackedScene
@onready var spawnpoints = $SpawnLocations.get_children()

var cameras = []
var player_count: int = 0


func _ready() -> void:
	GameManager.connect("player_need_join", spawn_player)

func spawn_player(_device_id: int):
	if spawnpoints.size() < 1:
		return
	player_count += 1
	
	var player = player_scene.instantiate()
	if player.is_inside_tree():
		return
	add_child(player)
	player.global_position = spawnpoints[player_count - 1].global_position
