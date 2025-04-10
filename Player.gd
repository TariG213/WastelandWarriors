extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Smg12/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

var bulletScene = preload("res://Bullet.tscn")
var bulletSpawn 		

var health = 100

var SPEED = 5.0
var JUMP_VELOCITY

var ammo : int = 5
var maxAmmo : int = 28
var player_health = 100

var max_stamina = 100 
var stamina = 100
var stamina_drain = 20.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func shoot ():
	if ammo >= 0:
		var bullet = bulletScene.instantiate()
		get_node("/root/testWorld").add_child(bullet)
		bullet.global_transform = bulletSpawn.global_transform
		bullet.scale = Vector3(0.1, 0.1, 0.1)
		ammo -= 1 

func reload():
	ammo = maxAmmo
	print("Relaoded")



func _ready():
	bulletSpawn = get_node("Camera3D/Llewlac/Smg12/bulletSpawn")
	if not is_multiplayer_authority(): return
	else:
		print("Error: bulletSpawn is null!")

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	bulletSpawn = get_node("Camera3D/bulletSpawn")
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if Input.is_action_just_pressed("reload"):
		reload()


		
	if Input.is_action_pressed("player_run") and stamina > 0:
		SPEED = 10.0
		stamina -= stamina_drain * delta
	else:
		SPEED = 5.0
		if stamina < max_stamina:
			stamina += stamina_drain * delta 
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()


@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
		
		# Test comment



func reduce_health(amount):
	player_health -= 1
	health_changed.emit(health)
	if player_health < 0:
		get_tree().change_scene_to_file("res://lose.tscn")
			# The player dies. 
			# Go back to the main menu. This can be changed to any scene in the future.
