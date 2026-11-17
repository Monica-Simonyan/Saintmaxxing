extends Node
## Looping background music and menu click sound (Autoload: Audio).

const MUSIC: AudioStream = preload("res://assets/audio/exploration.wav")
const CLICK: AudioStream = preload("res://assets/audio/menu_click.wav")

var _music_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.stream = MUSIC
	_music_player.finished.connect(_music_player.play)
	add_child(_music_player)
	_music_player.play()

	_click_player = AudioStreamPlayer.new()
	_click_player.stream = CLICK
	add_child(_click_player)

	get_tree().node_added.connect(_on_node_added)


# Audio runs while paused, so the music is halted explicitly and resumes in place.
func _process(_delta: float) -> void:
	_music_player.stream_paused = get_tree().paused


func play_click() -> void:
	_click_player.play()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play_click)
