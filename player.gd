extends CharacterBody2D

const SPEED = 800.0
const JUMP_VELOCITY = -2000.0
var turnToLeft: bool = false
var jumpCounter: int = 0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		animated_sprite_2d.play()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * 6 * delta
	else:
		jumpCounter = 0

	if Input.is_action_just_pressed("ui_accept") and jumpCounter < 2:
		velocity.y = JUMP_VELOCITY
		jumpCounter += 1

	if Input.is_action_just_released("ui_accept") and not is_on_floor() and velocity.y < 0:
		velocity.y = get_gravity().y * delta

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if direction < 0:
			turnToLeft = true
		if direction > 0:
			turnToLeft = false
	
		if turnToLeft:
			animated_sprite_2d.flip_h = true
			animated_sprite_2d.position = Vector2(-82, animated_sprite_2d.position.y)
		else:
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.position = Vector2(82, animated_sprite_2d.position.y)
	else:
		velocity.x = move_toward(velocity.x, 0, 2000*delta)

	move_and_slide()
