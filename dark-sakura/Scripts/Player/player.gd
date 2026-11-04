extends CharacterBody3D
class_name Player

signal health_changed(current: float, maximum: float)
signal player_died
signal player_dashed
signal player_jumped

@export_group("Movement Stats")
@export var walk_speed: float = 6.8
@export var sprint_speed: float = 9.8
@export var ground_accel: float = 14.0
@export var ground_friction: float = 11.0
@export var air_accel: float = 7.0
@export var air_friction: float = 0.5
@export var jump_velocity: float = 5.2

@export_group("Dash & Slide")
@export var dash_speed: float = 18.5
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.75
@export var slide_boost: float = 13.5
@export var slide_friction: float = 4.0

@export_group("Camera & Feel")
@export var mouse_sensitivity: float = 0.0022
@export var base_fov: float = 85.0
@export var sprint_fov: float = 93.0
@export var dash_fov: float = 102.0
@export var ads_fov: float = 65.0
@export var camera_tilt_amount: float = 0.035
@export var head_bob_speed: float = 12.0
@export var head_bob_intensity: float = 0.04

@export_group("Vitals")
@export var max_health: float = 100.0

# State variables
var current_health: float = 100.0
var is_invulnerable: bool = false
var is_dashing: bool = false
var can_dash: bool = true
var is_sliding: bool = false
var is_crouching: bool = false
var is_dead: bool = false

# Internal movement trackers
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _slide_dir: Vector3 = Vector3.ZERO
var _slide_speed: float = 0.0
var _head_bob_time: float = 0.0
var _cam_recoil: Vector2 = Vector2.ZERO
var _was_on_floor: bool = false

# Normal heights
const STAND_HEIGHT: float = 1.8
const CROUCH_HEIGHT: float = 0.95
const CAM_STAND_Y: float = 1.6
const CAM_CROUCH_Y: float = 0.85

const SFX_DASH = preload("res://Audio/SFX/player_dash.wav")
const SFX_STEP_SOUNDS: Array[AudioStream] = [
	preload("res://Audio/SFX/footstep_stone_01.wav"),
	preload("res://Audio/SFX/footstep_stone_02.wav"),
	preload("res://Audio/SFX/footstep_stone_03.wav"),
	preload("res://Audio/SFX/footstep_stone_04.wav"),
	preload("res://Audio/SFX/footstep_stone_05.wav"),
]
const SFX_HURT = preload("res://Audio/SFX/player_hurt.wav")
const SFX_HEARTBEAT = preload("res://Audio/SFX/heartbeat.wav")

# Juice trackers
var _trauma: float = 0.0
var _last_step_sign: float = 1.0
var _last_step_idx: int = -1
var _heartbeat_timer: float = 0.0

var _sfx_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _heartbeat_player: AudioStreamPlayer

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var pistol: Pistol = $Head/Camera3D/WeaponHolder/Pistol

# HUD References
@onready var hud: CanvasLayer = $HUD
@onready var health_bar: ProgressBar = $HUD/MarginContainer/VBoxBottomLeft/HealthBar
@onready var health_label: Label = $HUD/MarginContainer/VBoxBottomLeft/HealthLabel
@onready var ammo_label: Label = $HUD/MarginContainer/VBoxBottomRight/AmmoLabel
@onready var dash_bar: ProgressBar = $HUD/MarginContainer/VBoxBottomLeft/DashBar
@onready var crosshair_dot: Control = $HUD/Crosshair/CenterDot
@onready var hitmarker: Control = $HUD/Crosshair/Hitmarker
@onready var damage_rect: ColorRect = $HUD/DamageVignette
@onready var game_over_screen: Control = get_node_or_null("HUD/GameOverScreen")

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_health = max_health
	_update_hud_vitals()
	
	# Create juice audio players
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.volume_db = -6.0
	add_child(_footstep_player)
	
	_heartbeat_player = AudioStreamPlayer.new()
	_heartbeat_player.stream = SFX_HEARTBEAT
	_heartbeat_player.volume_db = -3.0
	add_child(_heartbeat_player)
	
	if pistol:
		if not pistol.ammo_changed.is_connected(_on_pistol_ammo_changed):
			pistol.ammo_changed.connect(_on_pistol_ammo_changed)
		if not pistol.shot_fired.is_connected(_on_pistol_shot_fired):
			pistol.shot_fired.connect(_on_pistol_shot_fired)
		if not pistol.hit_registered.is_connected(_on_pistol_hit_registered):
			pistol.hit_registered.connect(_on_pistol_hit_registered)
		if not pistol.melee_hit.is_connected(_on_pistol_melee_hit):
			pistol.melee_hit.connect(_on_pistol_melee_hit)
		# Trigger initial ammo HUD update
		_on_pistol_ammo_changed(pistol.current_ammo, pistol.mag_capacity, pistol.reserve_ammo)
	
	if hitmarker:
		hitmarker.modulate.a = 0.0
	if damage_rect:
		damage_rect.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		if (event is InputEventKey and event.pressed and (event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or _is_action_just_pressed("reload"):
			get_tree().reload_current_scene()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
			get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_event := event as InputEventMouseMotion
		# Yaw (Horizontal) rotates Player
		rotate_y(-mouse_event.relative.x * mouse_sensitivity)
		# Pitch (Vertical) rotates Head
		head.rotate_x(-mouse_event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))
		
		# Forward mouse motion to weapon for sway
		if pistol:
			pistol.handle_mouse_input(mouse_event)
	
	# Re-capture mouse on gameplay click if uncaptured and not paused
	if event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if is_dead:
		return
	
	_handle_combat_inputs()
	_update_camera_fov(delta)
	_update_camera_recoil(delta)
	_update_dash_hud(delta)
	
	# Low health heartbeat & vignette
	if current_health < 30.0 and not is_dead:
		_heartbeat_timer += delta
		if _heartbeat_timer >= 0.8:
			_heartbeat_timer = 0.0
			if _heartbeat_player:
				_heartbeat_player.play()
		if damage_rect:
			damage_rect.modulate.a = lerp(damage_rect.modulate.a, (sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5) * 0.45, delta * 8.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var on_floor := is_on_floor()
	
	# Coyote time & jump buffer
	if on_floor:
		_coyote_timer = 0.14
		if not _was_on_floor:
			_apply_landing_impact()
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		velocity += get_gravity() * delta
	
	_was_on_floor = on_floor
	
	# Dash cooldown
	if not can_dash:
		_dash_cooldown_timer -= delta
		if _dash_cooldown_timer <= 0.0:
			can_dash = true
	
	# Jump input buffer
	if _is_action_just_pressed("jump"):
		_jump_buffer_timer = 0.12
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)
	
	# Get input direction
	var move_dir := _get_input_direction()
	
	# Handle Dash execution
	if _is_action_just_pressed("dash") and can_dash and not is_dashing:
		_start_dash(move_dir)
	
	# Update Dash state
	if is_dashing:
		_dash_timer -= delta
		velocity.x = _dash_dir.x * dash_speed
		velocity.z = _dash_dir.z * dash_speed
		velocity.y = 0.0
		if _dash_timer <= 0.0:
			is_dashing = false
			is_invulnerable = false
		move_and_slide()
		return
	
	# Handle Slide & Crouch
	_handle_slide_and_crouch(move_dir, delta)
	
	# Jump execution
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		velocity.y = jump_velocity
		emit_signal("player_jumped")
		# If jumping during slide, preserve and boost momentum (Bunny Hop)
		if is_sliding:
			is_sliding = false
			velocity += _slide_dir * (slide_boost * 0.45)
	
	# Horizontal movement acceleration/friction
	if not is_sliding:
		_apply_standard_movement(move_dir, delta, on_floor)
	
	move_and_slide()
	
	# Camera tilt, head bob & weapon movement bob
	_update_view_effects(move_dir, delta, on_floor)

func _get_input_direction() -> Vector3:
	var input_x: float = 0.0
	var input_z: float = 0.0
	
	if _is_action_pressed("move_right"):
		input_x += 1.0
	if _is_action_pressed("move_left"):
		input_x -= 1.0
	if _is_action_pressed("move_back"):
		input_z += 1.0
	if _is_action_pressed("move_forward"):
		input_z -= 1.0
	
	var dir := (transform.basis * Vector3(input_x, 0, input_z)).normalized()
	return dir

func _apply_standard_movement(move_dir: Vector3, delta: float, on_floor: bool) -> void:
	var is_sprinting := Input.is_key_pressed(KEY_SHIFT) and not is_crouching
	var target_speed := sprint_speed if is_sprinting else walk_speed
	if is_crouching:
		target_speed = walk_speed * 0.55
	
	var target_vel := move_dir * target_speed
	var accel := ground_accel if on_floor else air_accel
	var friction := ground_friction if on_floor else air_friction
	
	if move_dir.length_squared() > 0.001:
		velocity.x = lerp(velocity.x, target_vel.x, accel * delta)
		velocity.z = lerp(velocity.z, target_vel.z, accel * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

func _start_dash(move_dir: Vector3) -> void:
	is_dashing = true
	can_dash = false
	is_invulnerable = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	
	# Dash towards movement input, or straight forward if neutral
	if move_dir.length_squared() > 0.001:
		_dash_dir = move_dir
	else:
		_dash_dir = -transform.basis.z.normalized()
	
	if _sfx_player:
		_sfx_player.stream = SFX_DASH
		_sfx_player.pitch_scale = randf_range(0.95, 1.05)
		_sfx_player.play()
	add_trauma(0.18)
	
	emit_signal("player_dashed")

func _handle_slide_and_crouch(move_dir: Vector3, delta: float) -> void:
	var slide_pressed := _is_action_pressed("slide")
	var horizontal_vel := Vector2(velocity.x, velocity.z)
	
	# Start slide if running and slide pressed on floor
	if slide_pressed and is_on_floor() and not is_sliding:
		if horizontal_vel.length() > (walk_speed * 0.75):
			is_sliding = true
			_slide_dir = velocity.normalized()
			if _slide_dir.length_squared() < 0.1:
				_slide_dir = -transform.basis.z.normalized()
			_slide_speed = maxf(horizontal_vel.length() + 3.0, slide_boost)
	
	# Execute sliding physics
	if is_sliding:
		if not slide_pressed or not is_on_floor() or _slide_speed < (walk_speed * 0.4):
			is_sliding = false
		else:
			_slide_speed = maxf(0.0, _slide_speed - (slide_friction * delta))
			velocity.x = _slide_dir.x * _slide_speed
			velocity.z = _slide_dir.z * _slide_speed
	
	# Crouch / Slide Camera and Collision height adjustments
	is_crouching = slide_pressed
	var target_cam_y := CAM_CROUCH_Y if (is_crouching or is_sliding) else CAM_STAND_Y
	head.position.y = lerp(head.position.y, target_cam_y, delta * 12.0)
	
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var cap := collision_shape.shape as CapsuleShape3D
		var target_height := CROUCH_HEIGHT if (is_crouching or is_sliding) else STAND_HEIGHT
		cap.height = lerp(cap.height, target_height, delta * 12.0)

func _update_view_effects(move_dir: Vector3, delta: float, on_floor: bool) -> void:
	# Camera Roll (Strafe Banking)
	var local_vel := transform.basis.inverse() * velocity
	var target_roll := -local_vel.x * (camera_tilt_amount * 0.15)
	camera.rotation.z = lerp_angle(camera.rotation.z, deg_to_rad(target_roll), delta * 10.0)
	
	# Head Bobbing & Footsteps
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if on_floor and horiz_speed > 0.5 and not is_sliding:
		_head_bob_time += delta * (horiz_speed * 1.8)
		var bob_offset := sin(_head_bob_time) * (head_bob_intensity * (horiz_speed / sprint_speed))
		camera.position.y = lerp(camera.position.y, bob_offset, delta * 14.0)
		
		# Footstep detection at zero crossings
		var cur_sign: float = 1.0 if sin(_head_bob_time) >= 0.0 else -1.0
		if cur_sign != _last_step_sign:
			_last_step_sign = cur_sign
			if on_floor:
				_play_footstep(0.94, 1.06)
	else:
		camera.position.y = lerp(camera.position.y, 0.0, delta * 14.0)
	
	# Forward bob to pistol
	if pistol:
		var speed_ratio := horiz_speed / sprint_speed
		pistol.apply_movement_bob(speed_ratio, delta)

func _play_footstep(pitch_min: float = 0.94, pitch_max: float = 1.06) -> void:
	if not _footstep_player or SFX_STEP_SOUNDS.is_empty():
		return
	var idx := randi() % SFX_STEP_SOUNDS.size()
	if idx == _last_step_idx and SFX_STEP_SOUNDS.size() > 1:
		idx = (idx + 1) % SFX_STEP_SOUNDS.size()
	_last_step_idx = idx
	_footstep_player.stream = SFX_STEP_SOUNDS[idx]
	_footstep_player.pitch_scale = randf_range(pitch_min, pitch_max)
	_footstep_player.play()

func _apply_landing_impact() -> void:
	camera.position.y -= 0.08
	add_trauma(0.12)
	_play_footstep(0.82, 0.92)

func _handle_combat_inputs() -> void:
	if not pistol:
		return
	
	# Shoot (Left Click)
	if _is_action_just_pressed("shoot"):
		pistol.trigger_shoot()
	
	# Aim Down Sights (Right Click Hold)
	pistol.is_aiming = _is_action_pressed("ads")
	
	# Reload (R)
	if _is_action_just_pressed("reload"):
		pistol.trigger_reload()
	
	# Melee / Kick (F)
	if _is_action_just_pressed("melee"):
		pistol.trigger_melee()
		# Add a physical forward kick screen shake
		_cam_recoil.x -= deg_to_rad(2.5)
		add_trauma(0.25)

func _update_camera_fov(delta: float) -> void:
	var target_fov := base_fov
	if pistol and pistol.is_aiming:
		target_fov = ads_fov
	elif is_dashing:
		target_fov = dash_fov
	elif Input.is_key_pressed(KEY_SHIFT) and Vector2(velocity.x, velocity.z).length() > (walk_speed * 1.1):
		target_fov = sprint_fov
	
	camera.fov = lerp(camera.fov, target_fov, delta * 12.0)

func _update_camera_recoil(delta: float) -> void:
	# Recover camera recoil smoothly
	_cam_recoil = _cam_recoil.lerp(Vector2.ZERO, delta * 16.0)
	
	# Trauma Screen Shake
	var shake_offset := Vector3.ZERO
	var shake_rot_z := 0.0
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 2.2)
		var shake := _trauma * _trauma
		shake_offset.x = randf_range(-1.0, 1.0) * shake * 0.04
		shake_offset.y = randf_range(-1.0, 1.0) * shake * 0.04
		shake_rot_z = deg_to_rad(randf_range(-1.0, 1.0) * shake * 2.5)
	
	camera.position.x = shake_offset.x
	camera.rotation.x = _cam_recoil.x
	camera.rotation.y = _cam_recoil.y
	camera.rotation.z += shake_rot_z

func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)

func _on_pistol_shot_fired() -> void:
	# Add snappy camera recoil kick & screen trauma (Juicy hand-cannon power)
	_cam_recoil.x += deg_to_rad(randf_range(3.2, 4.2))
	_cam_recoil.y += deg_to_rad(randf_range(-0.4, 0.4))
	add_trauma(0.32)
	camera.fov = minf(camera.fov + 2.4, 115.0)

func _on_pistol_ammo_changed(current: int, maximum: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d  [%d]" % [current, maximum, reserve]

func _on_pistol_hit_registered(is_headshot: bool) -> void:
	if hitmarker:
		hitmarker.modulate = Color(1.0, 0.2, 0.3) if is_headshot else Color(1.0, 1.0, 1.0)
		hitmarker.scale = Vector2(1.5, 1.5) if is_headshot else Vector2(1.0, 1.0)
		hitmarker.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(hitmarker, "modulate:a", 0.0, 0.2)

func _on_pistol_melee_hit() -> void:
	_cam_recoil.x += deg_to_rad(1.5)

func _update_dash_hud(delta: float) -> void:
	if dash_bar:
		var fill := 1.0
		if not can_dash:
			fill = 1.0 - clampf(_dash_cooldown_timer / dash_cooldown, 0.0, 1.0)
		dash_bar.value = fill * 100.0

func _update_hud_vitals() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if health_label:
		health_label.text = "%d HP" % int(current_health)

func take_damage(amount: float, _hit_point: Vector3 = Vector3.ZERO, _hit_normal: Vector3 = Vector3.ZERO, _is_headshot: bool = false) -> void:
	if is_invulnerable or is_dead:
		return
	
	current_health = maxf(0.0, current_health - amount)
	_update_hud_vitals()
	
	# Hurt audio and trauma shake
	if _sfx_player:
		_sfx_player.stream = SFX_HURT
		_sfx_player.pitch_scale = randf_range(0.95, 1.05)
		_sfx_player.play()
	add_trauma(0.55)
	
	# Damage flash
	if damage_rect:
		damage_rect.modulate.a = 0.75
		var tween := create_tween()
		tween.tween_property(damage_rect, "modulate:a", 0.0, 0.35)
	
	# Recoil shake on damage
	_cam_recoil.x += deg_to_rad(randf_range(-2.0, 2.0))
	_cam_recoil.y += deg_to_rad(randf_range(-2.0, 2.0))
	
	if current_health <= 0.0:
		_die()

func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	_update_hud_vitals()

func trigger_scream_disorientation() -> void:
	if damage_rect and not is_dead:
		var tween := create_tween()
		tween.tween_property(damage_rect, "modulate:a", 0.5, 0.15)
		tween.tween_property(damage_rect, "modulate:a", 0.0, 0.8)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	emit_signal("player_died")
	# Fall sideways camera effect
	var tween := create_tween()
	tween.tween_property(camera, "rotation:z", deg_to_rad(75.0), 0.6)
	tween.parallel().tween_property(head, "position:y", 0.3, 0.6)
	
	# PSX Game Over Screen Fade
	if game_over_screen:
		game_over_screen.visible = true
		game_over_screen.modulate.a = 0.0
		tween.tween_interval(0.3)
		tween.tween_property(game_over_screen, "modulate:a", 1.0, 0.8)

# Helper input checker that falls back to standard keyboard keys if action isn't mapped
func _is_action_pressed(action_name: String) -> bool:
	if InputMap.has_action(action_name) and Input.is_action_pressed(action_name):
		return true
	match action_name:
		"move_forward": return Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
		"move_back": return Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
		"move_left": return Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
		"move_right": return Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
		"jump": return Input.is_key_pressed(KEY_SPACE)
		"dash": return Input.is_key_pressed(KEY_SHIFT)
		"slide": return Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C)
		"shoot": return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		"ads": return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		"reload": return Input.is_key_pressed(KEY_R)
		"melee": return Input.is_key_pressed(KEY_F)
	return false

func _is_action_just_pressed(action_name: String) -> bool:
	if InputMap.has_action(action_name) and Input.is_action_just_pressed(action_name):
		return true
	return false
