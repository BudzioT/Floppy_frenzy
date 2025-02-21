extends Control

@export var address: String = "127.0.0.1"
@export var port: int = 8910
@export var max_players: int = 6

var peer


func _ready() -> void:
	# Conecction called on both server and clients
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	
	# Client connections on clients
	multiplayer.connected_to_server.connect(_server_connected)
	multiplayer.connection_failed.connect(_server_connection_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

@rpc("any_peer", "call_local")	
func start_multi_game():
	var scene = load("res://scenes/test.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

# Send info of the given player uing rpc
@rpc("any_peer")
func send_player_info(id, player_name):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"id": id,
			"name": player_name
		}
	
	if multiplayer.is_server():
		for player_index in GameManager.players:
			send_player_info.rpc(player_index, GameManager.players[player_index].name)
	
# Called on server and client
func _player_connected(id: int):
	print("Player connected " + str(id))

# Server + Client
func _player_disconnected(id: int):
	print("Player disconnected " + str(id))
	
# Client
func _server_connected():
	print("Connected to the server")
	
	send_player_info.rpc_id(1, multiplayer.get_unique_id(), $VBoxContainer/HBoxContainer/NameInput.text)
	
# Client
func _server_connection_fail():
	print("Connection to server failed")

# Client
func _server_disconnected():
	print("Disconnected from the server")


func _on_host_button_button_down() -> void:
	# Create da peer as a server
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	if error != OK:
		print("Cannot host a server (" + str(error) + ")")
		return
	
	# Compress the data, use it as a player too - host wants to play after all
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	send_player_info(multiplayer.get_unique_id(), $VBoxContainer/HBoxContainer/NameInput.text)
	
	print("Waiting for players...")

func _on_join_button_button_down() -> void:
	# Create only da player
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		print("Couldn't connect to server (" + str(error) + ")")
		return
	
	# Connect him
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)	

func _on_start_button_button_down() -> void:
	start_multi_game.rpc()
