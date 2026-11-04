extends Area3D

signal seal_collected(seal_name: String)

@export var seal_name: String = "Seal of Petals"
@export var glow_color: Color = Color(1.0, 0.2, 0.6, 1.0)

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var _timer: float = 0.0
var _is_collected: bool = false

func _enter_tree() -> void:
	add_to_group("seals")

func _ready() -> void:
	add_to_group("seals")
	body_entered.connect(_on_body_entered)
	if light:
		light.light_color = glow_color

func _process(delta: float) -> void:
	if _is_collected:
		return
	_timer += delta
	# Floating bob and spin
	if mesh:
		mesh.rotation.y += delta * 1.8
		mesh.position.y = 1.0 + (sin(_timer * 3.0) * 0.15)
	if light:
		light.light_energy = 2.0 + (sin(_timer * 4.0) * 0.6)

func _on_body_entered(body: Node3D) -> void:
	if _is_collected:
		return
	if body is Player or body.is_in_group("player"):
		_is_collected = true
		emit_signal("seal_collected", seal_name)
		
		# Feedback pulse and disappear
		var tween := create_tween()
		if mesh:
			tween.tween_property(mesh, "scale", Vector3.ZERO, 0.25)
		if light:
			tween.parallel().tween_property(light, "light_energy", 6.0, 0.15)
			tween.tween_property(light, "light_energy", 0.0, 0.15)
		await tween.finished
		queue_free()
