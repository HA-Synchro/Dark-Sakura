extends Area3D
class_name AmmoEmber

@export var ammo_amount: int = 7

var _player: Player = null
var _velocity: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var _collected: bool = false

@onready var light: OmniLight3D = $OmniLight3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

const SFX_AMMO = preload("res://Audio/SFX/ammo_pickup.wav")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Initial random pop upwards with slight spread
	_velocity = Vector3(randf_range(-1.8, 1.8), randf_range(2.5, 4.2), randf_range(-1.8, 1.8))
	
	# Despawn after 30 seconds
	var tree = get_tree()
	if tree:
		tree.create_timer(30.0).timeout.connect(func():
			if not _collected:
				queue_free()
		)

func _physics_process(delta: float) -> void:
	if _collected:
		return
	
	_timer += delta
	
	# Floating bob and double-axis rotation for crystal shard feel
	if mesh:
		mesh.rotation.y += delta * 4.0
		mesh.rotation.z += delta * 2.2
	if light:
		light.light_energy = 2.2 + sin(_timer * 7.0) * 0.7
	
	# Initial deceleration / gravity
	if _velocity.length_squared() > 0.05:
		global_position += _velocity * delta
		_velocity.y -= 7.5 * delta
		_velocity.x = move_toward(_velocity.x, 0.0, 3.2 * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, 3.2 * delta)
		if global_position.y < 0.35:
			global_position.y = 0.35
			_velocity = Vector3.ZERO
	
	# Magnetize to player if within range (5.0m)
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Player
	
	if _player and is_instance_valid(_player):
		var dist = global_position.distance_to(_player.global_position)
		if dist < 5.0:
			var dir = (_player.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
			var pull_speed = lerpf(14.0, 5.0, dist / 5.0)
			global_position += dir * pull_speed * delta

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if body is Player or body.is_in_group("player"):
		_collected = true
		var p = body as Player
		if p and p.pistol:
			p.pistol.add_ammo(ammo_amount)
		
		# Play audio
		var aud = AudioStreamPlayer.new()
		aud.stream = SFX_AMMO
		aud.volume_db = -3.0
		aud.pitch_scale = randf_range(0.96, 1.04)
		get_tree().root.add_child(aud)
		aud.play()
		aud.finished.connect(aud.queue_free)
		
		# Feedback pulse and quick shrink
		var tween := create_tween()
		if mesh:
			tween.tween_property(mesh, "scale", Vector3.ZERO, 0.15)
		if light:
			tween.parallel().tween_property(light, "light_energy", 0.0, 0.15)
		await tween.finished
		queue_free()
