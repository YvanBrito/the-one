class_name HurtBox
extends Area2D

@export var owner_is_enemy: bool = true

func _init() -> void:
	collision_layer = 0
	collision_mask = 2

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null or hitbox.owner == null:
		return

	if hitbox.owner == owner:
		return
	
	if owner_is_enemy and hitbox.owner.is_in_group("Enemy"):
		return
	
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage, hitbox.owner)
