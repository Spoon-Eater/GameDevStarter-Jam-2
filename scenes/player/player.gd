extends CharacterBody3D

# nodes references
@onready var velocity_label: Label = $HUD/debug/MarginContainer/velocity

# physics vars
var speed: float = 8.0
var speed_acceleration: float = 6.0
var jump_vel: float = 4.5
var air_friction: float = 1.25
var floor_friction: float = 7.0

# headbob vars
var bob_freq: float = 2.0
var bob_amplitude: float = 0.04
var t_bob = 0.0

var mouse_sensitivity: float = 0.0017

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_sensitivity = Globals.mouse_sensitivity

func _unhandled_input(event: InputEvent) -> void:
	# look w/ mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		%Camera.rotate_x(-event.relative.y * mouse_sensitivity)
		%Camera.rotation.x = clampf(%Camera.rotation.x, -deg_to_rad(90), deg_to_rad(90 ))

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jump
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_vel

	# ZQSD movements
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			# floor acceleration
			velocity.x = lerp(velocity.x, direction.x * speed, delta * speed_acceleration)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * speed_acceleration)
		else:
			# floor deceleration
			velocity.x = lerp(velocity.x, direction.x * speed, delta * floor_friction)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * floor_friction)
	else:
		# air deceleration
		velocity.x = lerp(velocity.x, direction.x * speed, delta * air_friction)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * air_friction)

	move_and_slide()
	velocity_label.text = str(velocity.length())

# headbob
	if is_on_floor():
		t_bob += delta * velocity.length()
	%Camera.transform.origin = headbob(t_bob)

func headbob(time) -> Vector3:
	var position: Vector3 = Vector3.ZERO
	position.y = sin(time * bob_freq) * bob_amplitude
	position.x = sin(time * bob_freq / 2) * bob_amplitude
	return position
