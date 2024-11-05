extends CharacterBody2D


const SPEED = 400.0
const JUMP_VELOCITY = -600.0

var anim_state = "idle"
var is_jumping = false

@onready var anim_sprite = $AnimatedSprite2D

# =======================
# Basic functions
# =======================

func _physics_process(delta):
	jump_check(delta)
	move_check()

	anim_state_check()



# =======================
# Movement Handling
# =======================

func jump_check(delta):
	# Landing
	if anim_state == "jump" and is_on_floor():
		anim_state = "idle"
		is_jumping = false
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
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
	# var last_collision = get_last_slide_collision()
	# if last_collision != null:
	# 	print(last_collision.get_normal())


func anim_state_check():
	if is_jumping: anim_sprite.play("jump")
	else: anim_sprite.play(anim_state)
