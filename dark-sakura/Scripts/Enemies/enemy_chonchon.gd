extends EnemyBase
class_name EnemyChonchon

var _hover_timer: float = 0.0
var _is_diving: bool = false

func _on_ready_setup() -> void:
	enemy_name = "The Petal-Veiled"
	max_health = 50.0
	current_health = 50.0
	move_speed = 6.4
	attack_damage = 16.0
	attack_range = 2.8
	attack_cooldown = 1.0
	detection_radius = 24.0
	drop_embers = 1
	ammo_drop_chance = 0.22
	ammo_drop_count = 1

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		# Fall to ground on death
		if not is_on_floor():
			velocity.y -= 12.0 * delta
		move_and_slide()
		return
	
	_hover_timer += delta * 4.0
	
	# Attack timer
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	# Search player
	if not player or not is_instance_valid(player):
		_find_player()
	
	_process_state(delta)
	
	# Hovering floating elevation
	if current_state != State.DEAD and not _is_diving:
		var target_y = 1.5 + sin(_hover_timer) * 0.3
		velocity.y = (target_y - position.y) * 4.0
	
	move_and_slide()

func _start_attack() -> void:
	current_state = State.ATTACK
	_is_diving = true
	play_anim("attack", 0.12, false)
	
	# Quick dive burst towards player
	if player and is_instance_valid(player):
		var dive_dir = (player.global_position + Vector3(0, 0.5, 0) - global_position).normalized()
		velocity = dive_dir * 10.0
	
	# Deal damage midway through attack animation
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.4).timeout
		if current_state == State.ATTACK:
			_execute_attack_hit()
		await tree.create_timer(0.6).timeout
		_is_diving = false
		_on_attack_finished()

func _on_hit_reaction(is_headshot: bool) -> void:
	_is_diving = false
	current_state = State.STAGGER
	_stagger_timer = 0.4
	velocity = -velocity.normalized() * 4.0 # Knockback
	play_anim("hit_reaction", 0.1, false)
