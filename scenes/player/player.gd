extends CharacterBody3D

# nodes references
@onready var velocity_label: Label = $HUD/debug/MarginContainer/VBoxContainer/velocity
@onready var cam_animation: AnimationPlayer = $headpivot/head/cam_animation
@onready var head: Node3D = $headpivot/head
@onready var headpivot: Node3D = $headpivot
@onready var ceiling_detector: RayCast3D = $ceiling_detector
@onready var slide_timer_label = $HUD/debug/MarginContainer/VBoxContainer/slide_timer
@onready var slide_speed_label = $HUD/debug/MarginContainer/VBoxContainer/slide_speed
@onready var g_normal_label: Label = $HUD/debug/MarginContainer/VBoxContainer/g_normal

# physics vars
var jump_vel: float = 4.5
var air_friction: float = 1.25
var floor_friction: float = 7.0
var last_velocity = Vector3.ZERO

# speed vars
var current_speed: float =0.0
var base_speed: float = 8.0
var speed_acceleration: float = 6.0

# headbob vars
var bob_freq: float = 2.0
var bob_amplitude: float = 0.04
var t_bob = 0.0

# fov vars
var default_fov: float = 83.0
var fov_change : float = 1.5

# slide vars
var sliding: bool = false
var slide_timer = 0.0
var slide_vector = Vector2.ZERO
var slide_speed = 1.0
var max_slide_speed = 17.25
var freelooking: bool = false

# crouching vars
var crouching_height = -0.75 # relative to base pos
var crouching_speed = 6.4
var crouching: bool = false

var cam_tilt_amount: float = 4.0
var mouse_sensitivity: float = 0.0017

func _ready() -> void:
	# initiating some stuff
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	default_fov = Globals.fov
	%Camera.fov = default_fov
	mouse_sensitivity = Globals.mouse_sensitivity
	current_speed = base_speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# freelooking
		if freelooking == true:
			headpivot.rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			headpivot.rotation.y = clamp(headpivot.rotation.y, deg_to_rad(-155), deg_to_rad(155))
		else:
			# lookin with mouse here
			rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
		# clamp the rotation so you can't flip your head down or up
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	# directional vector vars
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jump
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_vel
		cam_animation.play("jump")

	# crouch logic
	if Input.is_action_just_pressed("crouch"):
		#current_speed = crouching_speed
		$standing_coll.disabled = true
		$crouching_coll.disabled = false
		if velocity.length() >= 6.0 && input_dir != Vector2.ZERO:
			# start a slide
			slide_vector = input_dir
			sliding = true
			freelooking = true
			slide_timer = velocity.length() / 4.2
			slide_speed = clamp(velocity.length() * 1.6, 0, max_slide_speed)
		crouching = true
	if  ceiling_detector.is_colliding():
		slide_timer = 0
		sliding = false
		crouching = true
		$standing_coll.disabled = false
		$crouching_coll.disabled = true

	if crouching:
		head.position.y = lerp(head.position.y, crouching_height, delta * 10)

	# sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			freelooking = false
			crouching = false
			head.position.y = lerp(head.position.y, 0.0, delta * 10)
			%Camera.rotation.z = lerp(%Camera.rotation.z, deg_to_rad(0.0), delta * 10)

	# freelooking
	if sliding == true:
		freelooking = true
		if sliding:
			%Camera.rotation.z = lerp(%Camera.rotation.z, deg_to_rad(8.5), delta * 10)
		else: %Camera.rotation.z = lerp(%Camera.rotation.z, deg_to_rad(0.0), delta * 10)
	else :
		freelooking = false
		%Camera.rotation.z = lerp(%Camera.rotation.z, 0.0, delta * 10)
		headpivot.rotation.y = lerp(headpivot.rotation.y, 0.0, delta * 10)

	if Input.is_action_just_released("crouch"):
		sliding = false
		slide_timer = 0.0
		head.position.y = lerp(head.position.y, 0.0, delta * 10)
		%Camera.rotation.z = lerp(%Camera.rotation.z, deg_to_rad(0.0), delta * 10)
		current_speed = base_speed

	# ZQSD movements
	if is_on_floor() and !sliding or !is_on_floor():
		if direction:
			# floor acceleration
			velocity.x = lerp(velocity.x, direction.x * current_speed, delta * speed_acceleration)
			velocity.z = lerp(velocity.z, direction.z * current_speed, delta * speed_acceleration)
		else:
			# floor deceleration
			velocity.x = lerp(velocity.x, direction.x * current_speed, delta * floor_friction)
			velocity.z = lerp(velocity.z, direction.z * current_speed, delta * floor_friction)
	else:
		# air deceleration
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * air_friction)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * air_friction)

	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, clamp(velocity.y, -8.75, 8.75), slide_vector.y)).normalized()
		if direction:
			velocity.x = direction.x * (slide_timer + 0.25) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.25) * slide_speed

	# cam tilt
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		head.rotation.z = lerp(head.rotation.z, -input_dir.x, delta * 0.6)
	else:
		head.rotation.z = lerp(head.rotation.z, 0.0, delta * 3.0)
	head.rotation.z = clamp(head.rotation.z, deg_to_rad(-cam_tilt_amount), deg_to_rad(cam_tilt_amount))

	move_and_slide()
	velocity_label.text = "velocity.length() : " + str(velocity.length())
	slide_timer_label.text = "slide_timer : " + str(slide_timer)
	slide_speed_label.text = "slide_speed : " + str(slide_speed)
	g_normal_label.text = "g_normal : " + str($ground_normal.get_collision_normal())

	# camera landing animation
	if is_on_floor():
		if last_velocity.y < 0.0:
			cam_animation.play("land")
	last_velocity = velocity

	# headbob
	if is_on_floor():
		t_bob += delta * velocity.length()
	%Camera.transform.origin = headbob(t_bob)

	# fov changes
	var clamped_velocity: float = clamp(velocity.length(), 0.5, current_speed * 2)
	var target_fov: float = default_fov + fov_change * clamped_velocity
	%Camera.fov = lerp(%Camera.fov, target_fov, delta * 8.0)




		## sprint logic
		#if Input.is_action_pressed("sprint"):
			#sprinting = true
			#walking = false
			#current_speed = sprint_speed
			#Cam.rotation.z = deg_to_rad(Cam.rotation.y * freelook_tilt_amount)
		#else:
			#current_speed = walking_speed
			#walking = true
			#sprinting = false
#
	## sliding
	#if sliding:
		#slide_timer -= delta
		#if slide_timer <= 0:
			#sliding = false
			#freelooking = false
			#crouching = false
			#head.position.y = lerp(head.position.y, 0.0, delta * 10)
			#Cam.rotation.z = lerp(Cam.rotation.z, deg_to_rad(0.0), delta * 10)
#
	## freelooking
	#if Input.is_action_pressed("freelook") or sliding == true:
		#freelooking = true
		#if sliding:
			#Cam.rotation.z = lerp(Cam.rotation.z, deg_to_rad(8.5), delta * 10)
		#else: Cam.rotation.z = lerp(Cam.rotation.z, deg_to_rad(0.0), delta * 10)
	#else :
		#freelooking = false
		#Cam.rotation.z = lerp(Cam.rotation.z, 0.0, delta * 10)
		#headpivot.rotation.y = lerp(headpivot.rotation.y, 0.0, delta * 10)
#
	## handle jump
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#if sliding:
			#sliding = false
			#velocity.y = jump_velocity * clamp((slide_timer * slide_speed)/15.575, 0, 3)
			#velocity.x = velocity.x * (slide_timer * slide_speed)
			#velocity.z = velocity.z * (slide_timer * slide_speed)
		#else:
			#cam_animation.play("jump")
			#velocity.y = jump_velocity
#
	## Get the input direction and handle the movement/deceleration.
	#if is_on_floor():
		#direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * speed_accel_time)
	#else:
		#if input_dir != Vector2.ZERO:
			#direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_control)
#
	#if sliding:
		#direction = (transform.basis * Vector3(slide_vector.x, clamp(velocity.y, -8.75, 8.75), slide_vector.y)).normalized()
#
	#if direction:
		#velocity.x = direction.x * current_speed
		#velocity.z = direction.z * current_speed
		#if sliding:
			#velocity.x = direction.x * (slide_timer + 0.25) * slide_speed
			#velocity.z = direction.z * (slide_timer + 0.25) * slide_speed
	#else:
		#velocity.x = move_toward(velocity.x, 0, current_speed)
		#velocity.z = move_toward(velocity.z, 0, current_speed)
#
	## clamp velocity
	#velocity.x = clamp(velocity.x, -60.0, 60.0)
	#velocity.y = clamp(velocity.y, -60.0, 60.0)
	#velocity.z = clamp(velocity.z, -60.0, 60.0)
#
	## handle landing anim
	#if is_on_floor():
		#if last_velocity.y < 0.0:
			#cam_animation.play("land")
#
	#last_velocity = velocity
	#move_and_slide()
	## makes the cam tilt when going left or right
	#cam_tilt(input_dir.x, delta)
	## changes fov dues to speed
	#if is_on_floor(): fov_changes(delta)



func headbob(time) -> Vector3:
	var position: Vector3 = Vector3.ZERO
	position.y = sin(time * bob_freq) * bob_amplitude
	position.x = sin(time * bob_freq / 2) * bob_amplitude
	return position
