extends CharacterBody3D
class_name EnemyBase

signal enemy_died(enemy: EnemyBase)
signal enemy_damaged(current_hp: float, max_hp: float)

enum State { IDLE, ALERT, CHASE, ATTACK, STAGGER, DEAD }

@export_group("Stats")
@export var enemy_name: String = "Enemy"
@export var max_health: float = 100.0
@export var move_speed: float = 4.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.2
@export var detection_radius: float = 18.0
@export var drop_embers: int = 1
@export var ammo_drop_chance: float = 0.25
@export var ammo_drop_count: int = 1

@export_group("References")
@export var ember_scene: PackedScene = preload("res://Scenes/Gameplay/sakura_ember.tscn")
@export var ammo_scene: PackedScene = preload("res://Scenes/Gameplay/ammo_ember.tscn")
@export var hit_effect_scene: PackedScene = preload("res://Scenes/Effects/hit_effect.tscn")

var current_health: float
var current_state: State = State.IDLE
var player: Player = null

var _attack_timer: float = 0.0
var _stagger_timer: float = 0.0
var _anim_player: AnimationPlayer = null
var _current_anim: String = ""
var _is_dying: bool = false
var _mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("enemies")
	_on_ready_setup()
	current_health = max_health
	_anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_collect_meshes(self)
	_find_player()
	_on_ready_setup()

func _on_ready_setup() -> void:
	pass

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_mesh_instances.append(node)
	for c in node.get_children():
		_collect_meshes(c)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Player

func play_anim(anim_name: String, blend_time: float = 0.2, loop: bool = false) -> void:
	if not _anim_player:
		return
	if not _anim_player.has_animation(anim_name):
		return
	if _current_anim == anim_name and _anim_player.is_playing():
		return
	
	_current_anim = anim_name
	var anim = _anim_player.get_animation(anim_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	_anim_player.play(anim_name, blend_time)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	# Gravity
	if not is_on_floor():
		velocity.y -= 14.0 * delta
	
	# Attack timer
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	# Search player if lost
	if not player or not is_instance_valid(player):
		_find_player()
	
	# State machine tick
	_process_state(delta)
	
	move_and_slide()

func _process_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_tick_idle(delta)
		State.ALERT:
			_tick_alert(delta)
		State.CHASE:
			_tick_chase(delta)
		State.ATTACK:
			_tick_attack(delta)
		State.STAGGER:
			_tick_stagger(delta)

func _tick_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	play_anim("idle", 0.25, true)
	
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= detection_radius:
			_alert_enemy()

func _alert_enemy() -> void:
	current_state = State.CHASE

func _tick_alert(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	_rotate_towards_player(delta * 8.0)

func _tick_chase(delta: float) -> void:
	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return
	
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range and _attack_timer <= 0.0:
		_start_attack()
		return
	
	_rotate_towards_player(delta * 6.0)
	var move_dir = (player.global_position - global_position)
	move_dir.y = 0.0
	move_dir = move_dir.normalized()
	
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed
	play_anim("run" if _anim_player and _anim_player.has_animation("run") else "walk", 0.2, true)

func _start_attack() -> void:
	current_state = State.ATTACK
	velocity.x = 0.0
	velocity.z = 0.0
	play_anim("attack", 0.15, false)

func _tick_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	_rotate_towards_player(delta * 4.0)

func _execute_attack_hit() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range + 0.8:
			player.take_damage(attack_damage, global_position, Vector3.UP)

func _on_attack_finished() -> void:
	_attack_timer = attack_cooldown
	current_state = State.CHASE

func _tick_stagger(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		current_state = State.CHASE

func _rotate_towards_player(rate: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var target_dir = player.global_position - global_position
	target_dir.y = 0.0
	if target_dir.length_squared() > 0.01:
		var target_angle = atan2(target_dir.x, target_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rate)

func take_damage(amount: float, hit_point: Vector3, hit_normal: Vector3, is_headshot: bool = false) -> void:
	if current_state == State.DEAD or _is_dying:
		return
	
	var final_dmg = amount * 1.5 if is_headshot else amount
	current_health -= final_dmg
	emit_signal("enemy_damaged", current_health, max_health)
	
	# Spawn impact effect
	if hit_effect_scene and is_inside_tree() and get_tree():
		var eff = hit_effect_scene.instantiate() as Node3D
		get_tree().root.add_child(eff)
		eff.global_position = hit_point + (hit_normal * 0.05)
	
	# Flash red/white
	_flash_damage()
	
	if current_health <= 0.0:
		_die(is_headshot)
	else:
		_on_hit_reaction(is_headshot)

func _on_hit_reaction(is_headshot: bool) -> void:
	if current_state != State.ATTACK:
		current_state = State.STAGGER
		_stagger_timer = 0.6 if not is_headshot else 1.2
		if _anim_player and _anim_player.has_animation("stagger"):
			play_anim("stagger", 0.1, false)
		elif _anim_player and _anim_player.has_animation("hit_reaction"):
			play_anim("hit_reaction", 0.1, false)

func _flash_damage() -> void:
	for m in _mesh_instances:
		var mat = m.get_surface_override_material(0)
		if not mat:
			var orig = m.get_active_material(0)
			if orig:
				mat = orig.duplicate()
				m.set_surface_override_material(0, mat)
		if mat is StandardMaterial3D:
			mat.albedo_color = Color(1.5, 0.4, 0.6, 1.0) # Bright pink/red flash
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _die(is_headshot: bool) -> void:
	_is_dying = true
	current_state = State.DEAD
	emit_signal("enemy_died", self)
	
	# Disable collisions
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	
	# Spawn Sakura Embers
	_spawn_embers()
	
	# Play death animation
	if _anim_player and _anim_player.has_animation("death"):
		play_anim("death", 0.1, false)
	elif _anim_player and _anim_player.has_animation("fall_forward"):
		play_anim("fall_forward", 0.1, false)
	
	# Fade out & free after 2.5s
	if is_inside_tree() and get_tree():
		var timer = get_tree().create_timer(2.5)
		timer.timeout.connect(func():
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
			await tween.finished
			queue_free()
		)

func _spawn_embers() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var tree = get_tree()
	
	# 1. Health Embers (Pink)
	if ember_scene:
		for i in range(drop_embers):
			var ember = ember_scene.instantiate() as Area3D
			tree.root.add_child(ember)
			ember.global_position = global_position + Vector3(randf_range(-0.35, 0.35), 0.6, randf_range(-0.35, 0.35))
	
	# 2. Rare Ammo Embers (Purple)
	if ammo_scene:
		var roll_chance := ammo_drop_chance
		# Dynamic pity: boost drop chance if player reserve ammo is critical (<= 14)
		if player and player.pistol and player.pistol.reserve_ammo <= 14:
			roll_chance = minf(1.0, roll_chance + 0.25)
		
		if randf() <= roll_chance:
			for i in range(ammo_drop_count):
				var ammo_ember = ammo_scene.instantiate() as Area3D
				tree.root.add_child(ammo_ember)
				ammo_ember.global_position = global_position + Vector3(randf_range(-0.4, 0.4), 0.8, randf_range(-0.4, 0.4))
