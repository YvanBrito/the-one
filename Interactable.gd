extends Area2D

var ready_to_interact: bool = false
@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var dm = get_node_or_null("/root/DialogueManager")

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and ready_to_interact:
		dm.start("find_angel")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		ready_to_interact = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		ready_to_interact = false
