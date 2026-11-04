extends EnemyBase
class_name EnemyAberration

signal boss_died

var _is_performing_slam: bool = false
var _slam_cooldown: float = 0.0

@onready var weakpoint_light: OmniLight3D = get_node_or_null("Weakpoint/OmniLight3D")

func _on_ready_setup() -> void:
	enemy_name = "The Root Executioner"
	max_health = 450.0
	current_health = 450.0
	move_speed = 3.8
	attack_damage = 35.0
	attack_range = 4.6
	attack_cooldown = 1.6
	detection_radius = 32.0
	drop_embers = 5
	ammo_drop_chance = 1.0
	ammo_drop_count = 2

func _physics_process(delta: float) -> void:
	if _slam_cooldown > 0.0:
		_slam_cooldown -= delta
	
	if weakpoint_light:
		weakpoint_light.light_energy = 2.0 + sin(Time.get_ticks_msec() * 0.006) * 1.0
	
	super._physics_process(delta)

func _tick_chase(delta: float) -> void:
	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# Decide between Ground Slam (close) or Lunge (mid-range 5-11m)
	if dist <= attack_range and _attack_timer <= 0.0:
		_start_ground_slam()
		return
	elif dist > 5.0 and dist < 11.0 and _attack_timer <= 0.0 and randf() < 0.45:
		_start_lunge_attack()
		return
	
	_rotate_towards_player(delta * 4.5)
	var move_dir = (player.global_position - global_position)
	move_dir.y = 0.0
	move_dir = move_dir.normalized()
	
	# Fast walk if player is far
	var is_sprinting = dist > 9.0
	var speed = 6.4 if is_sprinting else move_speed
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	play_anim("walk_fast" if is_sprinting else "walk_limp", 0.25, true)

func _start_ground_slam() -> void:
	current_state = State.ATTACK
	_is_performing_slam = true
	velocity = Vector3.ZERO
	play_anim("attack_ground", 0.15, false)
	
	var tree = get_tree()
	if tree:
		# Windup before impact
		await tree.create_timer(0.55).timeout
		if current_state == State.ATTACK:
			_execute_slam_impact()
		await tree.create_timer(0.55).timeout
		_is_performing_slam = false
		_on_attack_finished()

func _execute_slam_impact() -> void:
	if not player or not is_instance_valid(player):
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range + 3.2:
		# Ground shockwave: deals full damage if on floor, reduced if mid-air
		var dmg = attack_damage if player.is_on_floor() else attack_damage * 0.4
		player.take_damage(dmg, global_position, Vector3.UP)

func _start_lunge_attack() -> void:
	current_state = State.ATTACK
	velocity = Vector3.ZERO
	play_anim("attack_lunge", 0.15, false)
	
	# Burst forward towards player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * 8.5
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.5).timeout
		if current_state == State.ATTACK:
			_execute_attack_hit()
		await tree.create_timer(0.7).timeout
		_on_attack_finished()

func _on_hit_reaction(is_headshot: bool) -> void:
	# Heavy stagger on headshot or knee hit
	if is_headshot or current_health < max_health * 0.35:
		current_state = State.STAGGER
		_stagger_timer = 1.8
		play_anim("knee_hit_recover", 0.15, false)

func on_weakpoint_hit(amount: float, hit_point: Vector3, hit_normal: Vector3) -> void:
	# Weakpoint hit: 2.5x damage and instant stagger!
	take_damage(amount * 2.5, hit_point, hit_normal, true)
	current_state = State.STAGGER
	_stagger_timer = 2.0
	play_anim("knee_hit_recover", 0.12, false)

func _die(is_headshot: bool) -> void:
	super._die(is_headshot)
	emit_signal("boss_died")
