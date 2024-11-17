extends CharacterBody2D


#TODO: fix animations with new platformer movement

const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const WALL_JUMP_COLL_DIST = 10

var anim_state  = "idle"
var is_jumping  = false
var jump_grace  = 0
var coyote_time = 0
var can_climb = false

# Please place all player children in the player scene (except cam)
@onready var anim_sprite = $AnimatedSprite2D

# =======================
# Basic functions
# =======================

func _physics_process(delta):
	apply_gravity(delta)
	move_check()
	jump_check()

	anim_state_check()



# =======================
# Movement Handling
# =======================

#TODO: climbing

func wall_grip_left() -> float:
	var scaled_trigger_strength = clamp((Input.get_action_raw_strength("grab_left")-.1)/.7,0,1)
	return (2-scaled_trigger_strength)*scaled_trigger_strength
func wall_grip_right() -> float:
	var scaled_trigger_strength = clamp((Input.get_action_raw_strength("grab_right")-.1)/.7,0,1)
	return (2-scaled_trigger_strength)*scaled_trigger_strength

func apply_gravity(delta):
	# Add the gravity.
	if not is_on_floor():
		coyote_time -= 1
		velocity += get_gravity() * delta
		var wall_side = wall_check(2)
		var wgl=wall_grip_left()
		var wgr=wall_grip_right()
		if (wgl or wgr) and wall_side:
			anim_state = "grab"
		can_climb = wgl == 1. or wgr == 1.
		
		if velocity.y >= 0:
			# sqrt*4 is the same as 16th root, pow(
			if wall_side == 1:
				velocity.y *= pow(1 - wgl,1./16.)
			elif wall_side == -1:
				velocity.y *= pow(1 - wgr,1./16.)
	else:
		coyote_time = 6

func wall_check(dist):
	var space_state = get_world_2d().direct_space_state
	for y in [0,12,24,36,48,60,72,84,96,108,120]:
		var query = PhysicsRayQueryParameters2D.create(position+Vector2(0,-y),
			position+Vector2(40 + dist,-y))
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result != {}:
			return -1
	for y in [0,12,24,36,48,60,72,84,96,108,120]:
		var query = PhysicsRayQueryParameters2D.create(position+Vector2(0,-y),
			position+Vector2(-40 - dist,-y))
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result != {}:
			return 1
	return 0

func jump_check():
	# Landing
	if anim_state == "jump" and is_on_floor():
		anim_state = "idle"
		is_jumping = false
	
	# Allow buffering jump
	if Input.is_action_just_pressed("jump"):
		jump_grace = 6 # 6t/60tps = 100ms 
	elif jump_grace > 0:
		jump_grace -= 1

	# Handle jump.
	var wall_side = wall_check(WALL_JUMP_COLL_DIST)
	if wall_side and jump_grace > 0 and not is_on_floor():
		jump_grace = 0
		coyote_time = 0
		velocity.x += wall_side * 1500
		velocity.y = JUMP_VELOCITY
		anim_state = "jump"
		is_jumping = true
	if coyote_time > 0 and jump_grace > 0:
		jump_grace = 0
		coyote_time = 0
		velocity.y = JUMP_VELOCITY
		anim_state = "jump"
		is_jumping = true

func move_check():
	# Get the input direction and handle the movement/deceleration.
	#NOTE: if the player is accelerated faster than the max movement speed,
	#NOTE: the player pressing a direction will cause them to suddenly decelerate
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x += .2 * direction * SPEED
		velocity.x = sign(velocity.x)*min(abs(velocity.x), SPEED)
		
		if velocity.x > 0: anim_sprite.flip_h = false
		else: if velocity.x < 0: anim_sprite.flip_h = true
		
		if (anim_state != "jump" and anim_state != "grab"): anim_state = "walk"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if (anim_state != "jump" and anim_state != "grab"): anim_state = "idle"

	move_and_slide()


func anim_state_check():
	if is_jumping: anim_sprite.play("jump")
	else: anim_sprite.play(anim_state)
