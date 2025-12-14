extends CharacterBody2D
class_name Player

const SPEED = 800.0
const JUMP_VELOCITY = -2000.0
var turnToLeft: bool = false
var jumpCounter: int = 0
var interacting: bool = false
var health_points: int = 50

# Parametros do recuo (knockback)
@export var knockback_strength: float = 300.0
@export var knockback_duration: float = 0.18
@export var knockback_friction: float = 8.0  # quanto maior, mais rápido para
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time_left: float = 0.0
var invulnerability_time_left: float = 0
var blink_timer: float = 0.0
var blink_state: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box_collision_shape_2d: CollisionShape2D = $HitBox/CollisionShape2D
@onready var hurt_box_collision_shape_2d: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var player_mesh: MeshInstance2D = $Mesh
@onready var original_color: Color = player_mesh.modulate
@onready var dm = get_node_or_null("/root/DialogueManager")

func _ready() -> void:
	if dm:
		dm.connect("dialogue_started", Callable(self, "_on_dialogue_started"))
		dm.connect("dialogue_ended", Callable(self, "_on_dialogue_ended"))

func _on_dialogue_started(_dialogue_id: String) -> void:
	interacting = true

func _on_dialogue_ended() -> void:
	await get_tree().create_timer(0.1).timeout
	interacting = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not interacting:
		animated_sprite_2d.play()
	
	hit_box_collision_shape_2d.disabled = not animated_sprite_2d.is_playing()
	
	if invulnerability_time_left > 0:
		blink_timer += delta
		if blink_timer >= 0.1:
			blink_timer -= 0.1
			blink_state = !blink_state

		if blink_state:
			player_mesh.modulate = original_color
		else:
			player_mesh.modulate = Color(1, 1, 1, 0.5)
	else:
		blink_timer = 0.0
		blink_state = false
		player_mesh.modulate = original_color

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * 6 * delta
	else:
		jumpCounter = 0

	if not interacting:
		if Input.is_action_just_pressed("ui_accept") and jumpCounter < 2:
			velocity.y = JUMP_VELOCITY
			jumpCounter += 1

		if Input.is_action_just_released("ui_accept") and not is_on_floor() and velocity.y < 0:
			velocity.y = get_gravity().y * delta

		if invulnerability_time_left > 0:
			invulnerability_time_left -= delta
		else:
			player_mesh.modulate = original_color
		hurt_box_collision_shape_2d.disabled = invulnerability_time_left > 0.0
		if knockback_time_left <= 0.0:
			var direction := Input.get_axis("ui_left", "ui_right") if not interacting else 0.0
			if direction:
				velocity.x = direction * SPEED
				
				if direction < 0:
					turnToLeft = true
				if direction > 0:
					turnToLeft = false
			
				if turnToLeft:
					animated_sprite_2d.flip_h = true
					animated_sprite_2d.position = Vector2(-82, animated_sprite_2d.position.y)
					hit_box_collision_shape_2d.position = Vector2(-82, hit_box_collision_shape_2d.position.y)
				else:
					animated_sprite_2d.flip_h = false
					animated_sprite_2d.position = Vector2(82, animated_sprite_2d.position.y)
					hit_box_collision_shape_2d.position = Vector2(82, hit_box_collision_shape_2d.position.y)
			else:
				velocity.x = 0
		else:
			knockback_time_left -= delta
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
			velocity.x = knockback_velocity.x

	move_and_slide()

func take_damage(damage: int, attacker: Node2D) -> void:
	health_points -= damage
	
	var dir := Vector2.ZERO
	if attacker != null and attacker is Node2D:
		# empurra na direção do personagem -> fora do atacante
		dir = (global_position - attacker.global_position).normalized()
	else:
		# fallback: empurra para trás baseado na velocidade/facing atual
		if velocity.x > 0:
			dir = Vector2.LEFT
		else:
			dir = Vector2.RIGHT

	# Aplica knockback
	knockback_velocity = dir * knockback_strength
	knockback_time_left = knockback_duration
	velocity.y = -1000
	
	invulnerability_time_left = knockback_duration + 1
	print("Player current hp: ", health_points)
