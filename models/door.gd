extends Node

@export var toggle: bool = true
@onready var Door: MeshInstance3D = $MeshInstance3d

func _ready():
	pass

func _physics_process(delta):
	
	if Input.is_action_just_pressed("door"):
		print("Door Toggle")
		if toggle:
			toggle = false
			self.visible = false
		else:
			toggle = true
			self.visible = true
