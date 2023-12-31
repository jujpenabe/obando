extends Post
class_name Bridge

@onready var _bridge_sprite = %BridgeSprite
@onready var _scaffold_sprite = %ScaffoldSprite
@onready var _bridge_limit = %BridgeLimit
@onready var _bridge_limit2 = %BridgeLimit2
@onready var _bridge_floor = %BridgeFloor
@onready var _interaction_area_collision_shape = %InteractionAreaCollisionShape

# SFX
@onready var _build_sound1 = %BuildSound1

var _progress = 0
var _section = 40

# On timer timeout calculate the work of resources to produce every 5 seconds (add to a pool)
# based on the number of villagers in the pool and the type of them (A, B, C)
# according to the post type (A, B, C) some produce more than others

# On readt set the wood amount to 10
func _ready() -> void:
	_interaction_area.interact = Callable(self, "_on_interact")
	_interaction_area.a_order = Callable(self, "_on_a_order")
	_interaction_area.b_order = Callable(self, "_on_b_order")
	_interaction_area.c_order = Callable(self, "_on_c_order")

	_interaction_area.cancel_a_order = Callable(self, "_on_cancel_a_order")
	_interaction_area.cancel_b_order = Callable(self, "_on_cancel_b_order")
	_interaction_area.cancel_c_order = Callable(self, "_on_cancel_c_order")

	_interaction_area.stair = Callable(self, "_on_stair")
	_interaction_area.unfocus = Callable(self, "_on_unfocus")

	_label.text = _description_text
	_label.global_position = _interaction_area.global_position
	_label.global_position.y -= 32
	_label.global_position.x -= _label.size.x * 0.5
	# set the location of the sound to the bridge location
	_build_sound1.position = position

func _on_p_timer_timeout() -> void:
	_build()
	# wait 5 seconds and repeat

func _build() -> void:
	if _a_villagers.size() + _b_villagers.size() + _c_villagers.size() == 0:
		_stop_production()
		return
	# play the build sound is not playing or is finished
	if !_build_sound1.is_playing():
		_build_sound1.play()
	var work = 0

	if _a_villagers.size() > 0:
		for vill in _a_villagers:
			if vill.type == 0:
				work += 4
			if (vill.type + 1) % 3 == 0:
				work += 2
			if (vill.type + 2) % 3 == 0:
				work += 1
	if _b_villagers.size() > 0:
		for vill in _b_villagers:
			if vill.type == 0:
				work += 4
			if (vill.type + 1) % 3 == 0:
				work += 2
			if (vill.type + 2) % 3 == 0:
				work += 1
	if _c_villagers.size() > 0:
		for vill in _c_villagers:
			if vill.type == 0:
				work += 4
			if (vill.type + 1) % 3 == 0:
				work += 2
			if (vill.type + 2) % 3 == 0:
				work += 1
	_effort += work
	if _effort >= _max_effort:
		_effort = 0
		# consume resources
		_label.hide()
		if _resources > 0:
			_resources -= 1
			_progress += 1
			# if progres is odd build the scaffold
			if _progress % 2 == 1:
				_scaffold_sprite.region_rect = Rect2(_scaffold_sprite.region_rect.position, Vector2(_scaffold_sprite.region_rect.size.x + _section, _scaffold_sprite.region_rect.size.y))
				_scaffold_sprite.offset.x += _section * 0.5
				_bridge_limit2.position.x += _section * 0.5
				_bridge_floor.shape.set_b(Vector2(_bridge_floor.shape.get_b().x + 20, _bridge_floor.shape.get_b().y))
				_continue_villagers_work(_section * 0.05)
			# if progress is even build the bridge
			elif _progress % 2 == 0:
				_bridge_sprite.region_rect = Rect2(_bridge_sprite.region_rect.position, Vector2(_bridge_sprite.region_rect.size.x + _section, _bridge_sprite.region_rect.size.y))
				_bridge_sprite.offset.x += _section * 0.5
				_continue_villagers_work(_section * 0.1)
				# Move the scaffold left to the right
				# random 50% thath the sprite will move
				if (_progress > 1 && randi() % 2) || (_bridge_limit.position.x < _bridge_limit2.position.x - (_section * 6)):
					var _section_copy = _section
					# if the bridge limit2 position is less than the bridge limit position minus the section * 10
					if _bridge_limit.position.x < _bridge_limit2.position.x - (_section * 3):
						_section_copy *= 2
					_scaffold_sprite.region_rect = Rect2(_scaffold_sprite.region_rect.position, Vector2(_scaffold_sprite.region_rect.size.x - _section_copy, _scaffold_sprite.region_rect.size.y))
					_scaffold_sprite.offset.x += _section_copy * 0.5
					_bridge_limit.position.x += _section_copy * 0.5
					_interaction_area_collision_shape.position.x += (_section_copy * 0.5)
					_interaction_area_collision_shape.scale.x += (_section_copy * 0.05)
					_continue_villagers_work(_section_copy * 0.5)

					# move the sound position
					_build_sound1.position.x += _section
					# Move the villagers current far distnace to the right
				if (_bridge_limit2.position.x >= 520):
					# bridge is finished
					_bridge_limit2.position.x = 600
					_bridge_floor.shape.set_b(Vector2(600, _bridge_floor.shape.get_b().y))
					_bridge_sprite.region_rect = Rect2(_bridge_sprite.region_rect.position, Vector2(1152, _bridge_sprite.region_rect.size.y))
					_bridge_sprite.offset.x = 530
					#  banish the scaffold with a tween
					var tween = create_tween()
					tween.tween_property(_scaffold_sprite, "modulate", Color.TRANSPARENT, 5)
					tween.tween_callback(_scaffold_sprite.hide)
					_bridge_limit.disabled = true
					_bridge_limit2.disabled = true
					_stop_production()
					_remove_all_villagers()
					# disbale the interaction area
					_interaction_area.monitoring = false

			# print the work of resources produced
		_production_timer.wait_time = 4

func _stop_production() -> void:
	_production_timer.stop()
	_production_timer.wait_time = 10
	_production_timer.stop()
	_a_timer.stop()
	_b_timer.stop()
	_c_timer.stop()
	_effort = 0
	_can_cancel = true
	_build_sound1.stop()

func _continue_villagers_work(point: int) -> void:
	_offset += point
	for vill in _a_villagers:
		vill.set_far_distance(position.x + _offset)
	for vill in _b_villagers:
		vill.set_far_distance(position.x + _offset)
	for vill in _c_villagers:
		vill.set_far_distance(position.x + _offset)
	# set the new far distance to the villagers
