extends Control

@export var type_speed: float = 0.02 # segundos por caractere

var _is_typing: bool = false
var _skip: bool = false

@onready var portrait: TextureRect = $Portrait
@onready var speaker_label: Label = $VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $VBox/Text
@onready var choices_container: VBoxContainer = $VBox/Choices
@onready var dm = get_node_or_null("/root/DialogueManager")

func _ready() -> void:
	if dm:
		dm.connect("line_shown", Callable(self, "_on_line_shown"))
		dm.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

# Recebe a linha (Dictionary) do DialogueManager
func _on_line_shown(line: Dictionary) -> void:
	_show_speaker(line.get("speaker", ""))
	_show_portrait(line.get("portrait", ""))
	_clear_choices()
	# Inicia typing e aguarda até terminar antes de criar as choices (melhor UX)
	await _start_typing(line.get("text", ""))
	if line.has("choices"):
		_create_choice_buttons(line["choices"])

func _show_speaker(speaker_name: String) -> void:
	speaker_label.text = speaker_name

func _show_portrait(path: String) -> void:
	if path == "" or path == null:
		portrait.texture = null
		return
	if ResourceLoader.exists(path):
		portrait.texture = load(path)
	else:
		portrait.texture = null

func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

func _create_choice_buttons(choices: Array) -> void:
	_clear_choices()
	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = choices[i].get("text", "...")
		# Conecta o sinal e anexa o índice usando Callable.bind()
		btn.pressed.connect(Callable(self, "_on_choice_pressed").bind(i))
		choices_container.add_child(btn)

func _on_choice_pressed(index: int) -> void:
	if dm:
		dm.make_choice(index)

# Inicia a corrotina de typing e espera até ela acabar
func _start_typing(text: String) -> void:
	if _is_typing:
		_skip = true
		return
	_is_typing = true
	_skip = false
	text_label.text = ""
	await _type_text(text)

# Corrotina que escreve letra a letra
func _type_text(text: String) -> void:
	var text_len := text.length()
	var i := 0
	while i < text_len:
		if _skip:
			text_label.bbcode_text = text
			break
		text_label.bbcode_text = text.substr(0, i + 1)
		i += 1
		await get_tree().create_timer(type_speed).timeout
	_is_typing = false

# Usa a action "ui_accept" (padrão: Enter / Espaço). Recomendo manter essa action no InputMap.
func _unhandled_input(_event: InputEvent) -> void:
	# Se a ação foi pressionada
	if Input.is_action_just_pressed("ui_accept"):
		if _is_typing:
			_skip = true
		else:
			if dm:
				dm.next_line()

func _on_dialogue_ended() -> void:
	visible = false
