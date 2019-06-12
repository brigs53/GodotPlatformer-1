#This is a simple state machine within the Player.gd. Read the comments for more information on how to use this. Note the PlayerState variables.
#As of June 11th, 2019 at 5:11 PM, the states included are Idle, GroundMove, and AirMove. Each function contains comments that describe what
#each function does. I'll readd walljumping, crouching, and many other animations soon.

extends Character

const utilEngine = preload("res://Scripts/Utils.gd")

export var runSpeed1 : float = 220
export var jumpHeight1 : float = 40
export var jumpTime1 : float = 0.3

#Saves the current state of the player and the state that the player will do next (updates after each frame).
export var PlayerState_Prev = ""
export var PlayerState = ""
export var PlayerState_Next = "Idle"
#
var onFloor = is_on_floor()
#var onFloor = true
export var canIdle := true
export var canFall := true
##
export var fastFallSpeed := 600.0
##
var velocity1 := Vector2()
##Acceleration/strafing
export var groundMvmtTime := {
	accel = 0.2,
	decel = 0.1,
	turn = 0.3
}
export var airMvmtTime := {
	accel = 0.4,
	decel = 0.2,
	turn = 0.5
}
#
export var wallJumpSpeed := 500.0
export var wallSlide := {
	maxSpeed = 600,
	accelTime = 0.5
}
#export var wallSlideSpeed := 
export var accelTimeG := 0.2
export var decelTimeG := 0.1
export var turnTimeG := 0.1
export var accelTimeA := 0.2
export var decelTimeA := 0.4
export var turnTimeA := 0.1
#
#
#export var cancels := {
#	"Idle": false,
#	"Fall": false,
#	"Attack": false,
#	"Jump": false
#}
#
##Child nodes
##onready var animP : AnimationPlayer = $AnimationPlayer
##onready var sprite : Sprite = $Sprite
#
var gravity := 0.0
#
var onWall := false
var move = 0.0

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#States are being updated every frame. _physics_process(delta) checks every frame of what state the player is in.
func _physics_process(delta):
	PlayerState_Prev = PlayerState
	PlayerState = PlayerState_Next
	
	
	#print(PlayerState)
	move_mechanics(delta)
	#print(is_on_floor())
	#print(velocity.x)
	
#If the player is idle, then run the idle_state(delta) function.
	if PlayerState == "Idle":
		idle_state(delta)
#If the player is moving on the ground, then run the GroundMove_state(delta) function.
	elif PlayerState == "GroundMove":
		GroundMove_state(delta)
#If the player is moving in the air, then run the AirMove_state(delta) function.
	elif PlayerState == "AirMove":
		AirMove_state(delta)
		
	#elif PlayerState == "jump":
	#	jump_state(delta)
	#elif PlayerState == "jumpMove":
	#	jumpMove_state(delta)
	#elif PlayerState == "fall":
	#	fall_state(delta)
	#elif PlayerState == "runJump":
	#	runJump_state(delta)
	#elif PlayerState == "
	
	#Restart key is "r"
	if(Input.is_action_pressed("restart")):
		get_tree().reload_current_scene()
	#Quit/Exit key is "esc"
	if(Input.is_action_pressed("quit")):
		get_tree().quit()


func playAnim(animName: String, fall:=true, idle:=true):
	animP.play(animName)
	#canIdle = idle
	#canFall = fall

#Responsible for the idle state and transitions from the idle state.
#Note: Because being in an "idle" state means that the player must be grounded in place, moving will always be on the ground after an input.
func idle_state(delta):
	#Move right --> Trigger state change (Idle --> GroundMove). _physics_process(delta) will check updated state and choose next function.
	if Input.is_action_pressed("ui_right"):
		sprite.flip_h = false
		PlayerState_Next = "GroundMove"
	#Move left --> Trigger state change (Idle --> GroundMove). _physics_process(delta) will check updated state and choose next function.
	elif Input.is_action_pressed("ui_left"):
		sprite.flip_h = true
		PlayerState_Next = "GroundMove"
	#Pressing jump --> Trigger state change (Idle --> AirMove). _physics_process(delta) will check updated state and choose next function.
	elif Input.is_action_pressed("jump"):
		velocity.y = Utils.jumpVelocity(gravity,jumpTime)
		PlayerState_Next = "AirMove"
	#If no input is detected, then play the Idle animation. _physics_process(delta) will keep running the function idle_state(delta).
	else: playAnim("idle")

#Responsible for ground movement and transitions from any state involving ground movement.
#For more info on the "move" variable, check the function move_mechanics(delta).
func GroundMove_state(delta):
	#Moving on the ground will play the "run" animation.
	playAnim("run")
	
	#Moving right on the ground. If "move" is less than 1, then accelerate (right) until it reaches 1.
	if Input.is_action_pressed("ui_right"):
		if (move <= 1): move += Input.get_action_strength("ui_right")
		else: move = 1
	#Moving left on the ground. If "move" is more than -1, then accelerate (left) until it reaches -1.
	elif Input.is_action_pressed("ui_left"):
		if (move >= -1): move -= Input.get_action_strength("ui_left")
		else: move = -1
	#Jumping (w/ or w/o moving) --> Trigger state change (GroundMove --> AirMove).
	if Input.is_action_pressed("jump"):
		velocity.y = Utils.jumpVelocity(gravity,jumpTime)
		PlayerState_Next = "AirMove"
	
	#Speed decelerates to 0 when "ui_right" released. Triggers (GroundMove --> Idle) because player is grounded and isn't moving.
	if Input.is_action_just_released("ui_right"):
		move = 0
		PlayerState_Next = "Idle"
		#Speed decelerates to 0 when "ui_left" released. Triggers (GroundMove --> Idle) because player is grounded and isn't moving.
	elif Input.is_action_just_released("ui_left"):
		move = 0
		PlayerState_Next = "Idle"
		
#Responsible for air movement and transitions from any state involving air movement.
func AirMove_state(delta):
	#print("AirMove")
	
	#If the velocity is less than 0, the player must be jumping because he is moving upwards.
	#This "if" statement will be changed once "wall sliding" is reimplemented.
	if velocity.y < 0:
		playAnim("jump")
	#If the velocity is greater than 0, the player must be falling because he is moving downwards.
	elif velocity.y > 0:
		playAnim("fall")

	#Moving right in the air. If "move" is less than 1, then accelerate (right) until it reaches 1.
	if Input.is_action_pressed("ui_right"):
		sprite.flip_h = false
		if (move <= 1): move += Input.get_action_strength("ui_right")
		else: move = 1
	#Moving left in the air. If "move" is more than -1, then accelerate (left) until it reaches -1.
	elif Input.is_action_pressed("ui_left"):
		sprite.flip_h = true
		if (move >= -1): move -= Input.get_action_strength("ui_left")
		else: move = -1
	
	#Speed decelerates to 0 when "ui_right" released. No state change yet.
	if Input.is_action_just_released("ui_right"):
		move = 0
		#Speed decelerates to 0 when "ui_left" released. No state change yet.
	elif Input.is_action_just_released("ui_left"):
		move = 0
	#Checks if the player is on the ground. If yes, then trigger state change (AirMove --> Idle)
	#This means that if the player lands on the ground while moving, the states will change from AirMove --> Move --> GroundMove.
	#There will be one frame where the player will be in an idle state. However, because this game runs at 60 fps, the player will be idle for
	#only 1/60 of a second, thus would be mostly unnoticable. We can easily fix this if needed.
	if(is_on_floor() == true):
		PlayerState_Next = "Idle"
		

#Responsible for general movement of the character for both air and ground.
func move_mechanics(delta):
	gravity = Utils.jumpGravity(jumpHeight, jumpTime)
	velocity.y += gravity*delta
	var moveTimes = groundMvmtTime if onFloor else airMvmtTime
	var accelX : float
	#Calculates acceleration and moving forward
	if velocity.x * move >  0:
		accelX = runSpeed1/moveTimes.accel
	#Stopping
	elif move == 0:
		accelX = runSpeed1/moveTimes.decel
	#Turning around
	else:
		accelX = runSpeed1/moveTimes.turn
	#How fast player wants to go based on input
	var targetSpeed = move*runSpeed1
	velocity.x = Utils.moveTowards(velocity.x, targetSpeed, accelX*delta)
	#velocity.y = min(velocity.y, fastFallSpeed)	
	# -y is up, +y is down
	
	velocity = move_and_slide(velocity, Vector2(0, -1))
	#print(onFloor)
	
#else:
#		move = 0
#		if canIdle and onFloor:
#			playAnim("idle")

	

	#var move = 0

	#velocity.y += gravity*delta
#
	
#
#	#Just touched wall
#	var touchedWall = is_on_wall()
#	if !onWall and touchedWall:
#		onWall = true
#		if !onFloor:
#			velocity.y = min(velocity.y, 0.0)
#	#Just left wall
#	elif onWall and !touchedWall:
#		canFall = true
#	onWall = touchedWall
#
#	if onWall and velocity.y > 0:
#		gravity = wallSlide.maxSpeed/wallSlide.accelTime
#		velocity.y = min(wallSlide.maxSpeed, velocity.y)
#		playAnim("wall slide")
#		canFall = false
#	else:
#		gravity = Utils.jumpGravity(jumpHeight, jumpTime)#2*jumpHeight/(jumpTime*jumpTime)
		
	#movement
	#if Input.is_action_pressed("ui_right"):
		#Use 1 for non-analog input
		#move += Input.get_action_strength("ui_right")
		#PlayerState_Next = "idle"
		#sprite.flip_h = velocity.x < 0
		#sprite.flip_h = false
		#if onFloor:
			#playAnim("run")
	#elif Input.is_action_pressed("ui_left"):
		#Use 1 for non-analog input
		#move -= Input.get_action_strength("ui_left")
		#sprite.flip_h = velocity.x < 0
		#sprite.flip_h = true
		#if onFloor:
			#playAnim("run")
#	else:
#		move = 0
#		if canIdle and onFloor:
#			playAnim("idle")
#
#	if Input.is_action_just_pressed("jump"):
#		#Ground jump
#		if onFloor:
#			velocity.y = Utils.jumpVelocity(gravity,jumpTime)#-2*jumpHeight/jumpTime
#			print(velocity.y)
#			playAnim("jump")
#		#Wall jump
#		elif onWall:
#			canFall = false
#			playAnim("flip")
#		gravity = Utils.jumpGravity(jumpHeight,jumpTime)
#		velocity.y = Utils.jumpVelocity(gravity,jumpTime)#-2*jumpHeight/jumpTime
#
#	#falling animation
#	if !onFloor and !onWall:
#		if Input.is_action_just_released("jump"):
#			velocity.y = max(velocity.y*0.5, 0)
#		elif Input.is_action_just_pressed("ui_down"):
#			velocity.y = fastFallSpeed
#		if canFall and velocity.y > 0:
#			playAnim("fall")
#
#	#attack animations
#	if Input.is_action_just_pressed("light attack") and canFall:
#		#animation runs on a different frame system than the script
#		#I set the canFall value in animation and it kept getting cancelled 
#		#do state checks in script, not animation, as they are faster here (constant vs variable update)
#		#canFall = false
#		#canIdle = false
#		playAnim("slash 1", false, false)
#		#print("Can idle is now ", canIdle)
#
#
#	#movement calculations
	
#
#
##func _on_AnimationPlayer_animation_finished(anim_name):
##	canIdle = true
##	canFall = true
#
##play animation and reset vars