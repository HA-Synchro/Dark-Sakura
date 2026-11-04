extends Node3D

@onready var particles: CPUParticles3D = $CPUParticles3D
@onready var light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	if particles:
		particles.emitting = true
	# Fade light and free after particles finish
	var tween := create_tween()
	if light:
		tween.tween_property(light, "light_energy", 0.0, 0.25)
	await get_tree().create_timer(0.4).timeout
	queue_free()
