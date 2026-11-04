extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _unhandled_input(event: InputEvent) -> void:
	# Press F1 to toggle PSX post-processing on/off for easy comparison
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			visible = not visible
