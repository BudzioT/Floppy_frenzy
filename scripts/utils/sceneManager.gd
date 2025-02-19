extends Node3D

@export var player_scene: PackedScene


func _ready() -> void:
	var index: int = 0
	for player in GameManager.players:
		var current_player = player_scene.instantiate()
		add_child(current_player)
		
		for spawn in get_tree().get_nodes_in_group("SpawnLocations"):
			if spawn.name == ("Spawn" + str(index)):
				print("HIT")
				current_player.global_transform.origin = spawn.global_transform.origin
		index += 1
