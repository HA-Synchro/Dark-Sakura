extends Area3D

@onready var parent_enemy: EnemyAberration = get_parent() as EnemyAberration

func take_damage(amount: float, hit_point: Vector3, hit_normal: Vector3, _is_headshot: bool = false) -> void:
	if parent_enemy and is_instance_valid(parent_enemy):
		parent_enemy.on_weakpoint_hit(amount, hit_point, hit_normal)
