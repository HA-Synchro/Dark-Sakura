extends Area3D
class_name SakuraEmber

@export var heal_amount: float = 15.0

var _player: Player = null
var _velocity: Vector3 = Vector3.ZERO
var _timer: float = 0.0
var _collected: bool = false

@onready var light: OmniLight3D = $OmniLight3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Initial random pop upwards
	_velocity = Vector3(randf_range(-1.5, 1.5), randf_range(2.0, 4.0), randf_range(-1.5, 1.5))
	
	# Despawn after 25 seconds
	var tree = get_tree()
	if tree:
		tree.create_timer(25.0).timeout.connect(func():
			if not _collected:
				queue_free()
		)

func _physics_process(delta: float) -> void:
	if _collected:
		return
	
	_timer += delta
	
	# Floating bob
	if mesh:
		mesh.rotation.y += delta * 3.0
		mesh.rotation.x += delta * 1.5
	if light:
		light.light_energy = 1.8 + sin(_timer * 6.0) * 0.6
	
	# Initial deceleration / gravity
	if _velocity.length_squared() > 0.05:
		global_position += _velocity * delta
		_velocity.y -= 7.0 * delta
		_velocity.x = move_toward(_velocity.x, 0.0, 3.0 * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, 3.0 * delta)
		if global_position.y < 0.3:
			global_position.y = 0.3
			_velocity = Vector3.ZERO
	
	# Magnetize to player if within range (4.5m)
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Player
	
	if _player and is_instance_valid(_player):
		var dist = global_position.distance_to(_player.global_position)
		if dist < 4.5:
			var dir = (_player.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
			var pull_speed = lerpf(12.0, 4.0, dist / 4.5)
			global_position += dir * pull_speed * delta

const SFX_EMBER = preload("res://Audio/SFX/ember_pickup.wav")

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if body is Player or body.is_in_group("player"):
		_collected = true
		var p = body as Player
		if p:
			p.heal(heal_amount)
		
		# Play audio
		var aud = AudioStreamPlayer.new()
		aud.stream = SFX_EMBER
		aud.volume_db = -4.0
		aud.pitch_scale = randf_range(0.95, 1.05)
		get_tree().root.add_child(aud)
		aud.play()
		aud.finished.connect(aud.queue_free)
		
		# Feedback pulse and quick shrink
		var tween := create_tween()
		if mesh:
			tween.tween_property(mesh, "scale", Vector3.ZERO, 0.15)
		if light:
			tween.parallel().tween_property(light, "light_energy", 4.0, 0.08)
			tween.tween_property(light, "light_energy", 0.0, 0.08)
		await tween.finished
		queue_free()
