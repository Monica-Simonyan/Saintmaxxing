extends Control

const UNICORN_TEXTURE: Texture2D = preload("res://assets/unicorn_hair.png")

@onready var play_button: Button = $CenterContainer/MarginContainer/PlayButton
@onready var unicorn: TextureRect = $PortraitTexture

var _starting: bool = false


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	unicorn.texture = UNICORN_TEXTURE
	unicorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unicorn.stretch_mode = TextureRect.STRETCH_SCALE
	unicorn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	UnicornPose.apply(unicorn, get_viewport_rect().size.x, 0.0)


func _on_play_pressed() -> void:
	if _starting:
		return
	_starting = true
	play_button.disabled = true
	SceneTransition.change_scene(GameState.UNICORN_MONOLOGUE_SCENE, 0.2)
