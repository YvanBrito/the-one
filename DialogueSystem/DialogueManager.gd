# res://DialogueManager.gd
extends Node

signal dialogue_started(dialogue_id)
signal dialogue_ended()
signal line_shown(line_data)

# Dicionário com todos os diálogos (carregado de JSON por padrão)
var dialogues: Dictionary = {}

# Estado do diálogo atual
var is_playing: bool = false
var current_dialogue_id: String = ""
var _queue: Array = []
var _waiting_for_choice: bool = false
var _last_line: Dictionary = {}
var dialog_box := ResourceLoader.load("res://DialogueSystem/DialogueBox.tscn")
var dlg: Control = null

# Arquivo padrão de diálogos (pode chamar load_from_file para outro path)
const DEFAULT_DIALOGUE_PATH: String = "res://DialogueSystem/dialogues.json"

func _ready() -> void:
	dlg = dialog_box.instantiate()
	call_deferred("_find_canvas")
	_load_default_dialogues()

func _find_canvas():
	var main = get_tree().get_current_scene()
	if not main:
		return

	var canvas = main.get_node_or_null("CanvasLayer")
	if canvas:
		canvas.add_child(dlg)
		return

	canvas = main.find_node("CanvasLayer", true, false)
	if canvas:
		canvas.add_child(dlg)
	else:
		print("CanvasLayer não encontrado na cena principal")

# --- Carregamento ---
func _load_default_dialogues() -> void:
	if FileAccess.file_exists(DEFAULT_DIALOGUE_PATH):
		var f: FileAccess = FileAccess.open(DEFAULT_DIALOGUE_PATH, FileAccess.READ)
		if f != null:
			var text: String = f.get_as_text()
			# parse_result tipado explicitamente para evitar inference warnings
			var parse_result: Variant = JSON.parse_string(text)
			if parse_result:
				var parsed_value: Variant = parse_result
				if typeof(parsed_value) == TYPE_DICTIONARY:
					dialogues = parsed_value
				else:
					push_warning("DialogueManager: JSON carregado mas o conteúdo não é um Dictionary.")
			else:
				push_warning("DialogueManager: erro ao parsear JSON: %s" % parse_result.error_string)
	else:
		# Não é obrigatório ter o arquivo; pode adicionar diálogos via add_dialogue()
		push_warning("DialogueManager: arquivo de diálogos não encontrado em %s" % DEFAULT_DIALOGUE_PATH)

# Carrega diálogos de outro arquivo (path absoluto/res://)
func load_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("DialogueManager: arquivo não encontrado: %s" % path)
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("DialogueManager: não conseguiu abrir %s" % path)
		return
	var text: String = f.get_as_text()
	var parse_result: Variant = JSON.parse_string(text)
	if parse_result.error == OK:
		var parsed_value: Variant = parse_result.result
		if typeof(parsed_value) == TYPE_DICTIONARY:
			dialogues = parsed_value
			return
	push_warning("DialogueManager: erro ao parsear JSON em %s: %s" % [path, parse_result.error_string])

# Permite adicionar diálogos via código
func add_dialogue(dialogue_id: String, content: Array) -> void:
	dialogues[dialogue_id] = content

# --- Controle do diálogo ---
func start(dialogue_id: String) -> void:
	dlg.visible = true
	if not dialogues.has(dialogue_id):
		push_warning("DialogueManager: diálogo não encontrado: %s" % dialogue_id)
		return
	current_dialogue_id = dialogue_id
	_queue = dialogues[dialogue_id].duplicate(true) # deep duplicate para evitar mutação do original
	is_playing = true
	_waiting_for_choice = false
	_last_line = {}
	emit_signal("dialogue_started", dialogue_id)
	_show_next_line()

func _show_next_line() -> void:
	if _queue.is_empty():
		_end_dialogue()
		return
	var line: Variant = _queue.pop_front()
	# guardar a última linha para o tratamento de choices (tipada explicitamente)
	if typeof(line) == TYPE_DICTIONARY:
		_last_line = line.duplicate(true) as Dictionary
	else:
		_last_line = line
	emit_signal("line_shown", line)
	# se a linha tem choices, colocamos o estado de espera
	if typeof(line) == TYPE_DICTIONARY and line.has("choices"):
		_waiting_for_choice = true

func next_line() -> void:
	# chamado pela UI quando o jogador avança (ex: pressionar ação)
	if not is_playing:
		return
	# se estivermos aguardando escolha, o avanço normal é ignorado
	if _waiting_for_choice:
		return
	_show_next_line()

func make_choice(choice_index: int) -> void:
	# chamado pela UI quando o jogador seleciona uma opção
	if not is_playing or not _waiting_for_choice:
		return
	_waiting_for_choice = false
	# valida a última linha e aplica o 'next' da escolha
	if _last_line and typeof(_last_line) == TYPE_DICTIONARY and _last_line.has("choices"):
		# anote explicitamente o tipo de 'choices' e 'choice' para evitar inference warnings
		var choices: Array = _last_line["choices"] as Array
		if choice_index >= 0 and choice_index < choices.size():
			var choice: Dictionary = choices[choice_index] as Dictionary
			# se a escolha aponta para outro diálogo por id
			if typeof(choice) == TYPE_DICTIONARY and choice.has("next"):
				var next_id: String = String(choice["next"])
				if dialogues.has(next_id):
					_queue = dialogues[next_id].duplicate(true)
					_show_next_line()
					return
	# se escolha inválida ou sem next definido -> encerrar diálogo
	_end_dialogue()

func _end_dialogue() -> void:
	is_playing = false
	current_dialogue_id = ""
	_queue.clear()
	_last_line = {}
	_waiting_for_choice = false
	emit_signal("dialogue_ended")

# --- Utilitários de consulta ---
func get_current_dialogue_id() -> String:
	return current_dialogue_id

func get_is_playing() -> bool:
	return is_playing

func get_last_line() -> Dictionary:
	return _last_line.duplicate(true) if typeof(_last_line) == TYPE_DICTIONARY else _last_line
