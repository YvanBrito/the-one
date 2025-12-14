class_name Enemy
extends CharacterBody2D

var health_points: int = 50

func take_damage(damage: int, _attacker: Node2D) -> void:
	health_points -= damage
	print("Enemy current hp: ", health_points)
	if health_points <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * 6 * delta

	move_and_slide()
