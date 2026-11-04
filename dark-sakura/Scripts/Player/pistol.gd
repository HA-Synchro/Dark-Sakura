extends Node3D
class_name Pistol

signal ammo_changed(current: int, maximum: int, reserve: int)
signal shot_fired
signal reloaded
signal hit_registered(is_headshot: bool)
signal melee_hit

@export_group("Pistol Attributes")
@export var damage_body: float = 35.0
@export var damage_head: float = 105.0
@export var fire_rate: float = 0.22  ## Minimum seconds between shots
@export var mag_capacity: int = 7
@export var max_reserve_ammo: int = 70
@export var range_distance: float = 100.0

@export_group("Handling & Feel")
@export var ads_fov: float = 65.0
@export var ads_speed: float = 14.0
@export var hip_pos: Vector3 = Vector3(0.14, -0.115, -0.21)
@export var ads_pos: Vector3 = Vector3(0.0, -0.088, -0.155)
@export var sway_amount: float = 0.002
@export var sway_max: float = 0.05
@export var sway_smooth: float = 12.0

@export_group("References")
@export var hit_effect_scene: PackedScene = preload("res://Scenes/Effects/hit_effect.tscn")

var current_ammo: int = 7
var reserve_ammo: int = 49
var can_shoot: bool = true
var is_reloading: bool = false
var is_aiming: bool = false
var is_meleeing: bool = false

var _mouse_input: Vector2 = Vector2.ZERO
var _current_sway: Vector2 = Vector2.ZERO
var _bob_timer: float = 0.0

# Procedural Recoil Spring Dynamics
var _target_recoil_pos: Vector3 = Vector3.ZERO
var _current_recoil_pos: Vector3 = Vector3.ZERO
var _target_recoil_rot: Vector3 = Vector3.ZERO
var _current_recoil_rot: Vector3 = Vector3.ZERO
var _current_base_pos: Vector3 = Vector3(0.14, -0.115, -0.21)
var _current_bob: Vector3 = Vector3.ZERO

const SFX_SHOOT = preload("res://Audio/SFX/gun_shoot.wav")
const SFX_EMPTY = preload("res://Audio/SFX/gun_empty.wav")
const SFX_RELOAD = preload("res://Audio/SFX/gun_reload.wav")
const SFX_HIT = preload("res://Audio/SFX/hit_normal.wav")
const SFX_HEADSHOT = preload("res://Audio/SFX/hit_headshot.wav")
const SFX_MELEE = preload("res://Audio/SFX/melee_hit.wav")

@onready var visuals: Node3D = $Visuals
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $RayCast3D
@onready var melee_raycast: RayCast3D = $MeleeRayCast3D
@onready var muzzle_flash: Node3D = $Visuals/MuzzleFlash
@onready var shoot_audio: AudioStreamPlayer = $Audio/ShootAudio
@onready var reload_audio: AudioStreamPlayer = $Audio/ReloadAudio
@onready var empty_audio: AudioStreamPlayer = $Audio/EmptyAudio
@onready var melee_audio: AudioStreamPlayer = $Audio/MeleeAudio
@onready var hit_audio: AudioStreamPlayer = $Audio/HitAudio

func _ready() -> void:
	current_ammo = mag_capacity
	_current_base_pos = hip_pos
	if muzzle_flash:
		muzzle_flash.visible = false
	
	# Wire up audio streams
	if shoot_audio:
		shoot_audio.stream = SFX_SHOOT
		shoot_audio.volume_db = 1.5
	if empty_audio:
		empty_audio.stream = SFX_EMPTY
		empty_audio.volume_db = -1.0
	if reload_audio:
		reload_audio.stream = SFX_RELOAD
		reload_audio.volume_db = 0.5
	if hit_audio:
		hit_audio.stream = SFX_HIT
	if melee_audio:
		melee_audio.stream = SFX_MELEE
	
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
	emit_signal("ammo_changed", current_ammo, mag_capacity, reserve_ammo)

func handle_mouse_input(event: InputEventMouseMotion) -> void:
	if not is_meleeing:
		_mouse_input = event.relative

func _process(delta: float) -> void:
	_update_recoil_springs(delta)
	_update_sway(delta)
	_update_ads(delta)
	_apply_composite_transform()

func _update_recoil_springs(delta: float) -> void:
	_target_recoil_pos = _target_recoil_pos.lerp(Vector3.ZERO, delta * 11.0)
	_current_recoil_pos = _current_recoil_pos.lerp(_target_recoil_pos, delta * 26.0)
	
	_target_recoil_rot = _target_recoil_rot.lerp(Vector3.ZERO, delta * 9.5)
	_current_recoil_rot = _current_recoil_rot.lerp(_target_recoil_rot, delta * 22.0)

func _update_sway(delta: float) -> void:
	var target_sway_x = clamp(-_mouse_input.x * sway_amount, -sway_max, sway_max)
	var target_sway_y = clamp(-_mouse_input.y * sway_amount, -sway_max, sway_max)
	
	_current_sway.x = lerp(_current_sway.x, target_sway_x, delta * sway_smooth)
	_current_sway.y = lerp(_current_sway.y, target_sway_y, delta * sway_smooth)
	_mouse_input = Vector2.ZERO

func _update_ads(delta: float) -> void:
	var target_pos := ads_pos if is_aiming else hip_pos
	_current_base_pos = _current_base_pos.lerp(target_pos, delta * ads_speed)

func apply_movement_bob(speed_ratio: float, delta: float) -> void:
	if is_aiming or is_reloading or is_meleeing:
		_current_bob = _current_bob.lerp(Vector3.ZERO, delta * 10.0)
		return
	
	if speed_ratio > 0.1:
		_bob_timer += delta * (speed_ratio * 10.0)
		var bob_x: float = sin(_bob_timer * 0.5) * 0.007
		var bob_y: float = absf(cos(_bob_timer)) * 0.01
		_current_bob = _current_bob.lerp(Vector3(bob_x, -bob_y, 0.0), delta * 12.0)
	else:
		_bob_timer = 0.0
		_current_bob = _current_bob.lerp(Vector3.ZERO, delta * 12.0)

func _apply_composite_transform() -> void:
	if not visuals:
		return
	if is_reloading or is_meleeing:
		return
	
	visuals.position = _current_base_pos + _current_bob + _current_recoil_pos
	visuals.rotation = Vector3(
		_current_recoil_rot.x + _current_sway.y,
		_current_recoil_rot.y + _current_sway.x,
		_current_recoil_rot.z
	)

func _apply_shot_recoil() -> void:
	if not is_aiming:
		# Violent hip-fire hand-cannon kick
		_target_recoil_pos.z += 0.095
		_target_recoil_pos.y += 0.036
		_target_recoil_pos.x += randf_range(-0.012, 0.012)
		_target_recoil_rot.x += deg_to_rad(randf_range(24.0, 30.0))
		_target_recoil_rot.y += deg_to_rad(randf_range(-3.5, 3.5))
		_target_recoil_rot.z += deg_to_rad(randf_range(-6.0, -2.5))
	else:
		# Tight, punchy ADS recoil
		_target_recoil_pos.z += 0.065
		_target_recoil_pos.y += 0.02
		_target_recoil_rot.x += deg_to_rad(16.0)
		_target_recoil_rot.y += deg_to_rad(randf_range(-1.5, 1.5))
		_target_recoil_rot.z += deg_to_rad(randf_range(-2.0, -1.0))

func trigger_shoot() -> void:
	if not can_shoot or is_reloading or is_meleeing:
		return
	
	if current_ammo <= 0:
		_play_audio(empty_audio)
		if reserve_ammo > 0:
			trigger_reload()
		return
	
	current_ammo -= 1
	can_shoot = false
	emit_signal("ammo_changed", current_ammo, mag_capacity, reserve_ammo)
	
	# 1. Fire hitscan raycast FIRST from camera center through crosshair before recoil kicks
	_fire_raycast()
	
	# 2. Audio & visual effects
	_play_audio(shoot_audio)
	_burst_muzzle_flash()
	
	# 3. Apply procedural weapon recoil and kick camera
	_apply_shot_recoil()
	emit_signal("shot_fired")
	
	if anim_player:
		anim_player.stop()
		anim_player.play("shoot")
	
	# Reset cooldown
	if is_inside_tree() and get_tree():
		await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	
	if not is_reloading and not is_meleeing and anim_player and not anim_player.is_playing():
		anim_player.play("idle")

func _fire_raycast() -> void:
	# Hitscan directly through camera center (aligned with screen crosshair)
	var cam: Camera3D = get_viewport().get_camera_3d() if get_viewport() else null
	var ray_origin: Vector3
	var ray_dir: Vector3
	
	if cam:
		ray_origin = cam.global_position
		ray_dir = -cam.global_transform.basis.z.normalized()
	elif raycast:
		raycast.force_raycast_update()
		ray_origin = raycast.global_position
		ray_dir = -raycast.global_transform.basis.z.normalized()
	else:
		return
	
	var space_state := get_world_3d().direct_space_state
	if not space_state:
		return
	
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_dir * 120.0,
		7 # layers 1: environment, 2: enemies, 3: props
	)
	
	# Exclude player character body from collision
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node:
		query.exclude = [player_node.get_rid()]
	
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return
	
	var collider: Object = result.collider
	var hit_point: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	
	# Spawn impact effect on hit surface
	_spawn_impact(hit_point, hit_normal)
	
	# Check for headshot
	var is_headshot := false
	if collider is Node:
		var node_name: String = String(collider.name).to_lower()
		if "head" in node_name:
			is_headshot = true
	
	var final_damage := damage_head if is_headshot else damage_body
	
	# Apply damage to target
	if collider and collider.has_method("take_damage"):
		collider.take_damage(final_damage, hit_point, hit_normal, is_headshot)
		emit_signal("hit_registered", is_headshot)
		if is_headshot:
			_play_audio_stream(SFX_HEADSHOT)
			_apply_hitstop(0.035)
		else:
			_play_audio(hit_audio)
	elif collider and collider.has_method("hit"):
		collider.hit(final_damage)
		emit_signal("hit_registered", is_headshot)
		if is_headshot:
			_play_audio_stream(SFX_HEADSHOT)
			_apply_hitstop(0.035)
		else:
			_play_audio(hit_audio)
	
	# Physics impulse for RigidBody3D objects
	if collider is RigidBody3D:
		collider.apply_impulse(ray_dir * 8.0, hit_point - (collider as RigidBody3D).global_position)

func _burst_muzzle_flash() -> void:
	if not muzzle_flash:
		return
	muzzle_flash.visible = true
	muzzle_flash.rotation.z = randf_range(0, TAU)
	var flash_light = muzzle_flash.get_node_or_null("FlashLight") as OmniLight3D
	if flash_light:
		flash_light.light_energy = 4.5
		var tween = create_tween()
		tween.tween_property(flash_light, "light_energy", 0.0, 0.05)
	
	# Hide after 50ms
	var t = get_tree().create_timer(0.05)
	t.timeout.connect(func(): if muzzle_flash: muzzle_flash.visible = false)

func _apply_hitstop(duration: float = 0.035) -> void:
	Engine.time_scale = 0.05
	var tree = get_tree()
	if tree:
		await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _play_audio_stream(stream: AudioStream) -> void:
	if hit_audio:
		hit_audio.stream = stream
		hit_audio.pitch_scale = randf_range(0.96, 1.04)
		hit_audio.play()

func _spawn_impact(point: Vector3, normal: Vector3) -> void:
	if not hit_effect_scene:
		return
	var tree := get_tree()
	if not tree:
		return
	
	var effect := hit_effect_scene.instantiate() as Node3D
	tree.root.add_child(effect)
	effect.global_position = point + (normal * 0.02)
	# Align local -Z with surface normal so sparks burst outward
	if absf(normal.dot(Vector3.UP)) < 0.99:
		effect.look_at(point + normal, Vector3.UP)
	else:
		effect.look_at(point + normal, Vector3.FORWARD)

func trigger_reload() -> void:
	if is_reloading or is_meleeing or current_ammo == mag_capacity or reserve_ammo <= 0:
		return
	
	is_reloading = true
	can_shoot = false
	
	_play_audio(reload_audio)
	
	if anim_player:
		anim_player.play("reload")
		await anim_player.animation_finished
	elif get_tree():
		await get_tree().create_timer(1.2).timeout
	
	var needed := mag_capacity - current_ammo
	var reload_amount := mini(needed, reserve_ammo)
	current_ammo += reload_amount
	reserve_ammo -= reload_amount
	
	is_reloading = false
	can_shoot = true
	
	emit_signal("ammo_changed", current_ammo, mag_capacity, reserve_ammo)
	emit_signal("reloaded")
	
	if anim_player:
		anim_player.play("idle")

func trigger_melee() -> void:
	if is_meleeing:
		return
	
	is_meleeing = true
	can_shoot = false
	
	_play_audio(melee_audio)
	
	if anim_player:
		anim_player.play("melee")
	
	# Check melee raycast after windup
	if get_tree():
		await get_tree().create_timer(0.12).timeout
	_check_melee_hit()
	
	if anim_player:
		await anim_player.animation_finished
	elif get_tree():
		await get_tree().create_timer(0.25).timeout
	
	is_meleeing = false
	can_shoot = true
	
	if anim_player and not is_reloading:
		anim_player.play("idle")

func _check_melee_hit() -> void:
	if not melee_raycast:
		return
	
	melee_raycast.force_raycast_update()
	if not melee_raycast.is_colliding():
		return
	
	var collider := melee_raycast.get_collider()
	var hit_point := melee_raycast.get_collision_point()
	var hit_normal := melee_raycast.get_collision_normal()
	
	_spawn_impact(hit_point, hit_normal)
	
	var kick_damage: float = 40.0
	if collider and collider.has_method("take_damage"):
		collider.take_damage(kick_damage, hit_point, hit_normal, false)
		emit_signal("melee_hit")
	
	if collider is RigidBody3D:
		var knockback := -melee_raycast.global_transform.basis.z.normalized() * 16.0
		collider.apply_central_impulse(knockback)
	elif collider is CharacterBody3D and "velocity" in collider:
		collider.velocity += -melee_raycast.global_transform.basis.z.normalized() * 14.0

func add_ammo(amount: int) -> void:
	reserve_ammo = mini(reserve_ammo + amount, max_reserve_ammo)
	emit_signal("ammo_changed", current_ammo, mag_capacity, reserve_ammo)

func _play_audio(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.pitch_scale = randf_range(0.95, 1.05)
		player.play()
