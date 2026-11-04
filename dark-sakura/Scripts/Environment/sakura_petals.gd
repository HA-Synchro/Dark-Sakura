extends CPUParticles3D

## Dark Sakura Drifting Petals: automatically follows the player horizontally
@export var follow_player: bool = true
var _player: Node3D = null

func _ready() -> void:
	emitting = true
	if follow_player:
		_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Node3D
	else:
		# Fallback: search by name
		_player = get_node_or_null("/root/PrototypeGround/Player")

func _process(_delta: float) -> void:
	if not _player:
		_find_player()
		return
	# Smoothly follow player horizontally, keep fixed height
	global_position.x = _player.global_position.x
	global_position.z = _player.global_position.z
