extends CanvasLayer
class_name PauseMenu

const SFX_HOVER = preload("res://Audio/SFX/gun_empty.wav")
const SFX_SELECT = preload("res://Audio/SFX/seal_pickup.wav")
const SFX_PAUSE = preload("res://Audio/SFX/ember_pickup.wav")

const SCENE_MENU = "res://Scenes/UI/main_menu.tscn"

@onready var root_control: Control = $MainControl
@onready var btn_resume: Button = $MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnResume
@onready var btn_guide: Button = $MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnGuide
@onready var btn_settings: Button = $MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnSettings
@onready var btn_retry: Button = $MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnRetry
@onready var btn_quit: Button = $MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnQuit
@onready var modal_guide: PanelContainer = get_node_or_null("ModalLayer/ModalCenter/ModalGuide")
@onready var modal_settings: PanelContainer = get_node_or_null("ModalLayer/ModalCenter/ModalSettings")

var _sfx_hover: AudioStreamPlayer
var _sfx_select: AudioStreamPlayer
var _sfx_pause: AudioStreamPlayer
var _is_paused: bool = false
var _button_raw_labels: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10 # Below PSXPostProcess (layer 15) so PSX dithering and pixelation are applied!
	visible = false
	
	_setup_audio()
	_style_buttons()
	_setup_guide_modal()
	_setup_settings_modal()
	
	_connect_button(btn_resume, _on_resume_pressed)
	_connect_button(btn_guide, _on_guide_pressed)
	_connect_button(btn_settings, _on_settings_pressed)
	_connect_button(btn_retry, _on_retry_pressed)
	_connect_button(btn_quit, _on_quit_pressed)

func _setup_audio() -> void:
	_sfx_hover = AudioStreamPlayer.new()
	_sfx_hover.stream = SFX_HOVER
	_sfx_hover.volume_db = -4.0
	_sfx_hover.pitch_scale = 1.35
	_sfx_hover.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_hover)
	
	_sfx_select = AudioStreamPlayer.new()
	_sfx_select.stream = SFX_SELECT
	_sfx_select.volume_db = 1.0
	_sfx_select.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_select)
	
	_sfx_pause = AudioStreamPlayer.new()
	_sfx_pause.stream = SFX_PAUSE
	_sfx_pause.volume_db = 0.5
	_sfx_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_pause)

func _strip_indicator(text: String) -> String:
	if text.begins_with("▶  ") or text.begins_with("•  "):
		return text.substr(3)
	elif text.begins_with("▶ ") or text.begins_with("• "):
		return text.substr(2)
	elif text.begins_with("▶") or text.begins_with("•"):
		return text.substr(1).strip_edges()
	return text

func _style_button(btn: Button, font_size: int = 19) -> void:
	if not btn:
		return
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.015, 0.035, 0.9)
	style_normal.border_color = Color(0.55, 0.12, 0.28, 0.75)
	style_normal.border_width_left = 5
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left = 2
	style_normal.corner_radius_top_right = 2
	style_normal.corner_radius_bottom_right = 2
	style_normal.corner_radius_bottom_left = 2
	style_normal.content_margin_left = 18
	style_normal.content_margin_right = 18
	style_normal.content_margin_top = 10
	style_normal.content_margin_bottom = 10

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.04, 0.14, 0.95)
	style_hover.border_color = Color(1.0, 0.18, 0.44, 1.0)
	style_hover.border_width_left = 8
	style_hover.border_width_top = 1
	style_hover.border_width_right = 1
	style_hover.border_width_bottom = 1
	style_hover.corner_radius_top_left = 2
	style_hover.corner_radius_top_right = 2
	style_hover.corner_radius_bottom_right = 2
	style_hover.corner_radius_bottom_left = 2
	style_hover.content_margin_left = 22
	style_hover.content_margin_right = 18
	style_hover.content_margin_top = 10
	style_hover.content_margin_bottom = 10
	style_hover.shadow_color = Color(1.0, 0.15, 0.42, 0.45)
	style_hover.shadow_size = 8

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.85, 0.16, 0.45, 1.0)
	style_pressed.border_color = Color(1.0, 1.0, 1.0, 1.0)
	style_pressed.border_width_left = 8
	style_pressed.border_width_top = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_bottom = 2
	style_pressed.content_margin_left = 22
	style_pressed.content_margin_right = 18
	style_pressed.content_margin_top = 10
	style_pressed.content_margin_bottom = 10

	var style_focus = style_hover.duplicate()

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	btn.add_theme_color_override("font_color", Color(0.9, 0.84, 0.87, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.0, 0.05, 1.0))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _style_buttons() -> void:
	for btn in [btn_resume, btn_guide, btn_settings, btn_retry, btn_quit]:
		_style_button(btn, 19)

func _connect_button(btn: Button, callback: Callable) -> void:
	if not btn:
		return
	if callback.is_valid():
		btn.pressed.connect(callback)
	btn.mouse_entered.connect(_on_button_hovered.bind(btn))
	btn.focus_entered.connect(_on_button_hovered.bind(btn))
	btn.mouse_exited.connect(_on_button_unhovered.bind(btn))
	btn.focus_exited.connect(_on_button_unhovered.bind(btn))

func _on_button_hovered(btn: Button) -> void:
	if not btn:
		return
	if _sfx_hover:
		_sfx_hover.pitch_scale = randf_range(1.3, 1.45)
		_sfx_hover.play()
	
	var clean = _strip_indicator(btn.text)
	if not clean.is_empty():
		btn.text = "▶  " + clean
	
	var tween := create_tween()
	tween.tween_property(btn, "position:x", 12.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(btn: Button) -> void:
	if not btn:
		return
	var clean = _strip_indicator(btn.text)
	if not clean.is_empty():
		btn.text = "•  " + clean
	
	var tween := create_tween()
	tween.tween_property(btn, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if _is_paused:
			if modal_guide and modal_guide.visible:
				modal_guide.visible = false
				btn_guide.grab_focus()
				get_viewport().set_input_as_handled()
			elif modal_settings and modal_settings.visible:
				modal_settings.visible = false
				btn_settings.grab_focus()
				get_viewport().set_input_as_handled()
			else:
				close_pause_menu()
				get_viewport().set_input_as_handled()
		else:
			# Check if player is alive before allowing pause
			var player = get_tree().get_first_node_in_group("player")
			if player and "is_dead" in player and player.is_dead:
				return
			var dm = get_tree().root.find_child("Dungeon", true, false)
			if dm and "is_victory" in dm and dm.is_victory:
				return
			open_pause_menu()
			get_viewport().set_input_as_handled()

func open_pause_menu() -> void:
	_is_paused = true
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_sfx_pause.pitch_scale = 0.95
	_sfx_pause.play()
	
	if modal_guide:
		modal_guide.visible = false
	if modal_settings:
		modal_settings.visible = false
	
	if root_control:
		root_control.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(root_control, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if btn_resume:
		btn_resume.grab_focus()

func close_pause_menu() -> void:
	_is_paused = false
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_sfx_hover.pitch_scale = 1.15
	_sfx_hover.play()

# --- Button Handlers ---

func _on_resume_pressed() -> void:
	_sfx_select.play()
	close_pause_menu()

func _on_guide_pressed() -> void:
	_sfx_select.play()
	if modal_guide:
		modal_guide.visible = true
		modal_guide.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(modal_guide, "modulate:a", 1.0, 0.18)
	if modal_settings:
		modal_settings.visible = false

func _on_settings_pressed() -> void:
	_sfx_select.play()
	if modal_settings:
		modal_settings.visible = true
		modal_settings.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(modal_settings, "modulate:a", 1.0, 0.18)
	if modal_guide:
		modal_guide.visible = false

func _on_retry_pressed() -> void:
	_sfx_select.play()
	close_pause_menu()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	_sfx_select.play()
	close_pause_menu()
	get_tree().change_scene_to_file(SCENE_MENU)

# --- Modals ---

func _setup_guide_modal() -> void:
	if not modal_guide:
		return
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.012, 0.03, 0.98)
	panel_style.border_color = Color(1.0, 0.22, 0.48, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
	panel_style.shadow_size = 16
	modal_guide.add_theme_stylebox_override("panel", panel_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	modal_guide.add_child(vbox)
	
	var title := Label.new()
	title.text = "ARCHIVAL SURVIVAL NOTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.65, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.02, 0.08, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)
	
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 3)
	div.color = Color(1.0, 0.2, 0.45, 0.85)
	vbox.add_child(div)
	
	var content := RichTextLabel.new()
	content.bbcode_enabled = true
	content.fit_content = true
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.text = """[b][color=#FF457E]▸ KINETIC ARENA MOVEMENT[/color][/b]
  [color=#FFE066][b]W A S D[/b][/color]   [color=#F4ECF0]Sprint across stone corridors (6.5 m/s)[/color]
  [color=#FFE066][b]SHIFT[/b][/color]     [color=#F4ECF0]Dash / Dodge burst with temporary invulnerability[/color]
  [color=#FFE066][b]CTRL[/b][/color]      [color=#F4ECF0]Low slide under lunges while maintaining speed[/color]
  [color=#FFE066][b]SPACE[/b][/color]     [color=#F4ECF0]Jump / Bunnyhop across ground shockwaves[/color]

[b][color=#FF457E]▸ WEAPON: SAKURA-9 SERVICE CANNON[/color][/b]
  [color=#FFE066][b]LMB[/b][/color]       [color=#F4ECF0]Heavy .308 caliber gunshot (Aim for the head!)[/color]
  [color=#FFE066][b]RMB[/b][/color]       [color=#F4ECF0]Aim Down Sights for pinpoint reticle precision[/color]
  [color=#FFE066][b]R[/b][/color]         [color=#F4ECF0]Tactical / Empty Reload (7-round magazine)[/color]
  [color=#FFE066][b]F[/b][/color]         [color=#F4ECF0]Boot Kick Melee (Knocks back & interrupts windups)[/color]

[b][color=#FF457E]▸ HARVEST & EXPEDITION OBJECTIVE[/color][/b]
  [color=#FF77AA][b]Pink Embers[/b][/color]     [color=#F4ECF0]Restore +15 Health ticks on fallen foes[/color]
  [color=#D070FF][b]Purple Crystals[/b][/color] [color=#F4ECF0]Rare Ammo drops (+7 bullets with low-ammo pity)[/color]
  [color=#FFE066][b]The Seals[/b][/color]       [color=#F4ECF0]Break West & East Seals to shatter the Great Gate, then purge the Root Executioner in the Bloom Sanctum![/color]"""
	content.add_theme_font_size_override("normal_font_size", 16)
	content.add_theme_font_size_override("bold_font_size", 17)
	content.add_theme_constant_override("line_separation", 4)
	vbox.add_child(content)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)
	
	var close_btn := Button.new()
	close_btn.text = "•  RETURN TO PAUSE MENU"
	close_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		_sfx_hover.play()
		modal_guide.visible = false
		btn_guide.grab_focus()
	)
	_connect_button(close_btn, func(): pass)
	vbox.add_child(close_btn)

func _setup_settings_modal() -> void:
	if not modal_settings:
		return
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.012, 0.03, 0.98)
	panel_style.border_color = Color(1.0, 0.22, 0.48, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
	panel_style.shadow_size = 16
	modal_settings.add_theme_stylebox_override("panel", panel_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	modal_settings.add_child(vbox)
	
	var title := Label.new()
	title.text = "SETTINGS & SYSTEM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.65, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.02, 0.08, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)
	
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 3)
	div.color = Color(1.0, 0.2, 0.45, 0.85)
	vbox.add_child(div)
	
	# Master Volume Slider
	var vol_box := VBoxContainer.new()
	var vol_lbl := Label.new()
	vol_lbl.text = "MASTER VOLUME: 100%"
	vol_lbl.add_theme_font_size_override("font_size", 17)
	vol_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.92, 1.0))
	vol_box.add_child(vol_lbl)
	
	var vol_slider := HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = 1.0
	vol_slider.value_changed.connect(func(val: float):
		AudioServer.set_bus_volume_db(0, linear_to_db(val) if val > 0.01 else -80.0)
		vol_lbl.text = "MASTER VOLUME: %d%%" % int(val * 100.0)
	)
	vol_box.add_child(vol_slider)
	vbox.add_child(vol_box)
	
	# Fullscreen Toggle Button
	var fs_btn := Button.new()
	fs_btn.text = "•  DISPLAY MODE: FULLSCREEN"
	fs_btn.pressed.connect(func():
		_sfx_hover.play()
		var mode = DisplayServer.window_get_mode()
		var label := ""
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			label = "DISPLAY MODE: WINDOWED"
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			label = "DISPLAY MODE: FULLSCREEN"
		fs_btn.text = "▶  " + label
	)
	_style_button(fs_btn, 18)
	_connect_button(fs_btn, func(): pass)
	vbox.add_child(fs_btn)
	
	# PSX Post-Processing Toggle
	var psx_btn := Button.new()
	psx_btn.text = "•  PSX SHADER PIPELINE: ENABLED"
	psx_btn.pressed.connect(func():
		_sfx_hover.play()
		var pp = get_tree().root.find_child("PSXPostProcess", true, false)
		if pp:
			pp.visible = not pp.visible
			var state = "ENABLED" if pp.visible else "DISABLED"
			psx_btn.text = "▶  PSX SHADER PIPELINE: " + state
	)
	_style_button(psx_btn, 18)
	_connect_button(psx_btn, func(): pass)
	vbox.add_child(psx_btn)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)
	
	# Return Button
	var close_btn := Button.new()
	close_btn.text = "•  RETURN TO PAUSE MENU"
	close_btn.pressed.connect(func():
		_sfx_hover.play()
		modal_settings.visible = false
		btn_settings.grab_focus()
	)
	_style_button(close_btn, 19)
	close_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_connect_button(close_btn, func(): pass)
	vbox.add_child(close_btn)
