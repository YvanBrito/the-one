extends Camera2D

# Camera script for a 2D platformer (Godot 4).
# Attach this to a Camera2D node and set `target_path` to your Player node.
# Features:
# - configurable smoothing
# - configurable deadzone (center box where camera doesn't move)
# - horizontal lookahead while the player runs
# - optional camera limits (uses Camera2D's built-in limit_* properties)

@export var target_path: NodePath

# Smoothing
@export var use_smoothing: bool = true
@export var smooth_speed: float = 8.0  # higher = snappier (per second)

# Deadzone (size of the center rectangle in pixels)
@export var deadzone_size: Vector2 = Vector2(100, 64)

# Lookahead
@export var enable_lookahead: bool = true
@export var lookahead_distance: float = 80.0       # max horizontal lookahead in pixels
@export var lookahead_speed: float = 6.0           # how fast lookahead interpolates
@export var lookahead_activate_speed: float = 10.0 # min target speed (px/s) to enable lookahead

# Vertical follow tweak (small offset to keep player slightly above center)
@export var vertical_offset: float = -16.0

# Optional limits — if enable_limits is true the exported limits will be applied to this Camera2D
@export var enable_limits: bool = false
@export var limit_left_export: int = 0
@export var limit_top_export: int = 0
@export var limit_right_export: int = 0
@export var limit_bottom_export: int = 0

# Internal
var target: Node2D = null
var prev_target_pos: Vector2 = Vector2.ZERO
var lookahead: Vector2 = Vector2.ZERO

func _ready() -> void:
	if enable_limits:
		limit_left  = int(limit_left_export)
		limit_top   = int(limit_top_export)
		limit_right = int(limit_right_export)
		limit_bottom= int(limit_bottom_export)

	if target_path != NodePath(""):
		var maybe_target = get_node_or_null(target_path)
		if maybe_target:
			target = maybe_target as Node2D
			prev_target_pos = target.global_position

func _physics_process(delta: float) -> void:
	if not target:
		# try to find target if path set but node wasn't available at _ready
		if target_path != NodePath(""):
			var maybe = get_node_or_null(target_path)
			if maybe:
				target = maybe as Node2D
				prev_target_pos = target.global_position
			else:
				return
		else:
			return

	if delta <= 0.0:
		return

	var target_pos: Vector2 = target.global_position
	# approx target velocity (px/s)
	var velocity: Vector2 = (target_pos - prev_target_pos) / delta

	# Determine lookahead target based on horizontal velocity
	var lookahead_target: Vector2 = Vector2.ZERO
	if enable_lookahead and abs(velocity.x) >= lookahead_activate_speed:
		lookahead_target.x = sign(velocity.x) * lookahead_distance

	# Smoothly interpolate lookahead
	lookahead = lookahead.lerp(lookahead_target, clamp(lookahead_speed * delta, 0.0, 1.0))

	# Desired camera target position (player + lookahead + small vertical offset)
	var desired_cam_pos: Vector2 = target_pos + lookahead + Vector2(0, vertical_offset)

	# Deadzone handling: only move camera if desired position is outside a centered rectangle
	var cam_pos: Vector2 = global_position
	var dz_half := deadzone_size * 0.5
	var dz_min := cam_pos - dz_half
	var dz_max := cam_pos + dz_half

	if desired_cam_pos.x > dz_max.x:
		cam_pos.x = desired_cam_pos.x - dz_half.x
	elif desired_cam_pos.x < dz_min.x:
		cam_pos.x = desired_cam_pos.x + dz_half.x
	# vertical:
	if desired_cam_pos.y > dz_max.y:
		cam_pos.y = desired_cam_pos.y - dz_half.y
	elif desired_cam_pos.y < dz_min.y:
		cam_pos.y = desired_cam_pos.y + dz_half.y

	# Apply smoothing or snap
	if use_smoothing:
		global_position = global_position.lerp(cam_pos, clamp(smooth_speed * delta, 0.0, 1.0))
	else:
		global_position = cam_pos

	# Camera2D has its own built-in clamping via limit_* properties; since we set them (if enabled)
	# the engine will respect them for the visible region.

	prev_target_pos = target_pos
