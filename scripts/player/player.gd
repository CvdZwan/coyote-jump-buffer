extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 8.5
const BUFFER_TIME = 0.2  # Duration to allow buffered jumps
const COYOTE_TIME = 0.1  # Duration for coyote jump
var has_buffered_jump = false
var since_buffered_jump_timer = 0
var state = "idle"  # Initial state
var previous_state = "idle"  # Track the previous state
var just_jumped = false
var fall_window_timer = 0.0  # Timer for coyote jump window

func _physics_process(delta):
	# Debugging output
	

	$StateLabel.text = "State: " + state
	
	handle_default_movement(delta)
	handle_buffered_jump(delta)
	handle_coyote_jump(delta)
	handle_camera()
	manage_states() # Non-optimal code, just for this tutorial, use a proper state machine instead
	
	move_and_slide()

func manage_states():
	# Update state based on character conditions
	if is_on_floor():
		if velocity.x != 0 or velocity.z != 0:
			state = "Move"
		else:
			state = "Idle"
	else:
		if velocity.y > 0:
			state = "Jump"
		else:
			state = "Fall"

func handle_camera():
	var camera_position = $camera_controller.position
	camera_position.x = lerp(camera_position.x, position.x, 0.08)
	camera_position.y = lerp(camera_position.y, position.y, 0.08)
	$camera_controller.position = camera_position
	
func handle_coyote_jump(delta):	
	# Coyote jump logic (handled inside _physics_process now)
	if not is_on_floor():
		# Decrease the fall window timer while falling
		fall_window_timer -= delta
	else:	
		# Reset the fall window timer when on the ground
		fall_window_timer = COYOTE_TIME
		just_jumped = false

	# If in fall state and within the coyote time, allow jump
	if Input.is_action_just_pressed("ui_accept") and state == 'Fall' and not just_jumped and fall_window_timer > 0:
		velocity.y = JUMP_VELOCITY  # Perform the jump
		just_jumped = true  # Mark that we just jumped
		state = "Jump"  # Set state to jump
	
func handle_buffered_jump(delta):	
	# Handle input and set buffered jump
	if Input.is_action_just_pressed("ui_accept") and not is_on_floor():
		has_buffered_jump = true
		since_buffered_jump_timer = 0  # Reset the buffer timer whenever jump is pressed
	
	# Buffer jump logic
	if has_buffered_jump:
		since_buffered_jump_timer += delta
		if since_buffered_jump_timer >= BUFFER_TIME:
			since_buffered_jump_timer = 0
			has_buffered_jump = false  # Clear buffer after time passes
	
	if has_buffered_jump and is_on_floor():	
		velocity.y = JUMP_VELOCITY
		state = "Jump"  # Set state to jump if buffered jump is triggered
		has_buffered_jump = false  # Reset the buffer after a successful jump
		since_buffered_jump_timer = 0  # Reset the timer after jump

func handle_default_movement(delta):
	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle normal jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle movement.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		# Move the character at constant speed in the input direction
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Stop the character immediately when no input is detected
		velocity.x = 0
		velocity.z = 0
