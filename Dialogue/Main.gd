# Exemplo de script para instanciar a DialogueBox e iniciar diálogo
# Anexe este script ao nó root da sua cena principal (ex: res://Main.tscn)
extends CanvasLayer

func _ready() -> void:
	# instanciar a UI de diálogo (expecting res://DialogueBox.tscn)
	var scene := ResourceLoader.load("res://Dialogue/DialogueBox.tscn")
	if scene:
		var dlg: Control = scene.instantiate()
		add_child(dlg)
		# iniciar diálogo
		var dm := get_node_or_null("/root/DialogueManager")
		if dm:
			dm.start("intro")
		else:
			push_warning("DialogueManager não encontrado. Lembre-se de registrar como Autoload.")
	else:
		push_warning("DialogueBox.tscn não encontrado em res://")
