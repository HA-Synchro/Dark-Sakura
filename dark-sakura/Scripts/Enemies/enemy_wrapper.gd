extends EnemyBase
class_name EnemyWrapper

var _has_screamed: bool = false
var _is_screaming: bool = false

func _on_ready_setup() -> void:
	enemy_name = "The Weeping Maiden"
	max_health = 120.0
	current_health = 120.0
	move_speed = 8.4 # Frantic fast sprint
	attack_damage = 25.0
	attack_range = 3.0
	attack_cooldown = 1.4
	detection_radius = 25.0
	drop_embers = 2
	ammo_drop_chance = 0.35
	ammo_drop_count = 1

func _alert_enemy() -> void:
	if not _has_screamed:
		_trigger_scream_sequence()
	else:
		current_state = State.CHASE

func _trigger_scream_sequence() -> void:
	_has_screamed = true
	_is_screaming = true
	current_state = State.ALERT
	velocity = Vector3.ZERO
	play_anim("scream", 0.15, false)
	
	# Disorient player screen with blood vignette
	if player and is_instance_valid(player) and player.has_method("trigger_scream_disorientation"):
		player.trigger_scream_disorientation()
	
	var tree = get_tree()
	if tree:
		await tree.create_timer(1.2).timeout
		_is_screaming = false
		current_state = State.CHASE

func _start_attack() -> void:
	current_state = State.ATTACK
	velocity = Vector3.ZERO
	play_anim("attack", 0.12, false)
	
	# Deal damage midway through lunge
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.45).timeout
		if current_state == State.ATTACK:
			_execute_attack_hit()
		await tree.create_timer(0.6).timeout
		_on_attack_finished()

func _on_hit_reaction(is_headshot: bool) -> void:
	# Heavy stagger on headshot or kick
	current_state = State.STAGGER
	_stagger_timer = 1.4 if is_headshot else 0.8
	play_anim("stagger", 0.1, false)
