extends CharacterBody2D


#TODO: fix animations with new platformer movement

const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const WALL_JUMP_COLL_DIST = 10

var anim_state  = "idle"
var is_jumping  = false
var jump_grace  = 0
var coyote_time = 0

# Please place all player children in the player scene (except cam)
@onready var anim_sprite = $AnimatedSprite2D

# =======================
# Basic functions
# =======================

func _physics_process(delta):
	move_check()
	jump_check(delta)

	anim_state_check()



# =======================
# Movement Handling
# =======================

func wall_check():
	var space_state = get_world_2d().direct_space_state
	for y in [0,12,24,36,48,60,72,84,96,108,120]:
		var query = PhysicsRayQueryParameters2D.create(position+Vector2(0,-y),
			position+Vector2(40 + WALL_JUMP_COLL_DIST,-y))
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result != {}:
			return -1
	for y in [0,12,24,36,48,60,72,84,96,108,120]:
		var query = PhysicsRayQueryParameters2D.create(position+Vector2(0,-y),
			position+Vector2(-40 - WALL_JUMP_COLL_DIST,-y))
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result != {}:
			return 1
	return 0

func jump_check(delta):
	# Landing
	if anim_state == "jump" and is_on_floor():
		anim_state = "idle"
		is_jumping = false
	
	# Allow buffering jump
	if Input.is_action_just_pressed("jump"):
		jump_grace = 6 # 6t/60tps = 100ms 
	elif jump_grace > 0:
		jump_grace -= 1
	
	# Add the gravity.
	if not is_on_floor():
		coyote_time -= 1
		velocity += get_gravity() * delta
	else:
		coyote_time = 6
	# Handle jump.
	var wall_side = wall_check()
	if wall_side and jump_grace > 0 and not is_on_floor():
		jump_grace = 0
		coyote_time = 0
		velocity.x += wall_side * 1500
		velocity.y = JUMP_VELOCITY
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
		
		if (anim_state != "jump"): anim_state = "walk"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if (anim_state != "jump"): anim_state = "idle"

	move_and_slide()


func anim_state_check():
	if is_jumping: anim_sprite.play("jump")
	else: anim_sprite.play(anim_state)
