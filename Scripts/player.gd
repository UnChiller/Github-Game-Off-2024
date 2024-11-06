extends CharacterBody2D


const SPEED = 400.0
const JUMP_VELOCITY = -600.0

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
	jump_check(delta)
	move_check()
	
	#var last_collision = get_last_slide_collision()
	#if last_collision != null:
	#	print(last_collision.get_normal())

	anim_state_check()



# =======================
# Movement Handling
# =======================

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
	if coyote_time > 0 and jump_grace > 0:
		coyote_time = 0
		velocity.y = JUMP_VELOCITY
		anim_state = "jump"
		is_jumping = true


func move_check():
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		if (anim_state != "jump"): anim_state = "walk"
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if (anim_state != "jump"): anim_state = "idle"

	move_and_slide()


func anim_state_check():
	if is_jumping: anim_sprite.play("jump")
	else: anim_sprite.play(anim_state)
