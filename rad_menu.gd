@tool
extends Container
class_name RadialMenu

## This is the new one after refactoring.
## A quick and dirty radial menu. It uses custom drawing in a [code]_draw()[/code] function to produce its elements.[br]
## You can change what is shown by overriding [code]draw_sector_*[/code] and [code]draw_center_*[/code] methods of this function.[br]
## You may had a child Control node with Anchor and Offset Preset set to Center, to make it display there.[br]



signal center_pressed
signal sector_pressed(idx:int)

#region Inspector Variables
@export var center_radius : float = 0.5 : ## Size of central element and hover hotspot as ratio with the max radius of the menu.
	set(val):
		center_radius = clamp(val, 0, 1)
		central_radius = max_radius * center_radius
		queue_redraw()
@export var sector_margin = deg_to_rad(3) : ## Visual separation between sectors.
	set(val):
		sector_margin = clamp(val, 0, PI * 0.5)
		queue_redraw()
@export var start_angle : float = 0 :
	set(val):
		start_angle = wrapf(val, -PI, PI)
		queue_sort()
		queue_redraw()
@export var centered_sector : bool : ## Each sector's angle will be the center of the sector.
	set(val):
		centered_sector = val
		queue_sort()
		queue_redraw()
#endregion

#region Internal Variables
var center : Vector2  ## Local coordinate of the center of the radial menu.
var max_radius : float
var mouse_position : Vector2

var _sector_span : float = TAU  ## The angle of which each sector is wide.
var central_radius : float  ## The proper radius of central element.
var _hover_item : int = -2
var _start_offset : float :  ## The start_angle accounting for offsets.
	set(val):
		_start_offset = wrapf(val, -PI, PI)
#endregion

#region Environmental Response
func _init() -> void:
	mouse_exited.connect(__on_mouse_exited)
	item_rect_changed.connect(__on_rect_changed)
	minimum_size_changed.connect(__on_rect_changed)
	sort_children.connect(__on_sort_children)

func __on_mouse_exited():
	_hover_item = -2
	queue_redraw()

func __on_rect_changed():
	reset_size()
	var rect = get_rect()
	max_radius = rect.size[rect.size.min_axis_index()] * 0.5
	center = rect.size * 0.5
	central_radius = max_radius * center_radius

func __on_sort_children():
	_sector_span = TAU / max(1, get_child_count())
	set_start_offset()
	
	for n in range(get_child_count()):
		var item : Control = get_child(n)
		var item_offset := item.position
		match item.size_flags_horizontal:
			SIZE_SHRINK_CENTER, SIZE_EXPAND, SIZE_FILL, SIZE_EXPAND_FILL:
				item_offset.x = item.size.x * 0.5
			SIZE_SHRINK_BEGIN:
				item_offset.x = item.size.x
			SIZE_SHRINK_END:
				item_offset.x = 0
		match item.size_flags_vertical:
			SIZE_SHRINK_CENTER, SIZE_EXPAND, SIZE_FILL, SIZE_EXPAND_FILL:
				item_offset.y = item.size.y * 0.5
			SIZE_SHRINK_BEGIN:
				item_offset.y = item.size.y
			SIZE_SHRINK_END:
				item_offset.y = 0
				
		item.position = get_sector_center(n) - item_offset
#endregion

#region Helper Functions
## Get the coordinate from an angle around the center.
func point_at_angle(angle:float, length:float=1.0) -> Vector2 :
	return center + Vector2.RIGHT.rotated(angle) * length

## Get angle around the center from a coordinate.
func angle_at_point(coord:Vector2) -> float:
	return (coord - center).angle()

## Set the center element radius by a distance, rather than a ratio.
func set_central_radius(rad:float):
	if not is_zero_approx(max_radius):
		center_radius = rad / max_radius

## The "band" is the thickness between `central_radius` and `max_radius`.
## Return a distance along that thickness. Optionally get a radius.
func inverse_lerp_band(ratio:float, as_radius:=false) -> float:
	var distance = (max_radius - central_radius) * ratio
	if as_radius:
		return distance + central_radius
	else:
		return distance

## Returns the coordinates of corners with names "ini_inner", "end_outer", etc. but can also be accessed like an array with 4 elements.
func get_sector_corners(ini_angle, end_angle) -> Dictionary:  #TODO: Refactoring
	var ini_vect = Vector2.RIGHT.rotated(ini_angle)
	var end_vect = Vector2.RIGHT.rotated(end_angle)
	
	var ans = {
		"ini_inner": ini_vect + ini_vect * central_radius + center,
		"ini_outer": ini_vect * max_radius + center,
		"end_inner": end_vect + end_vect * central_radius + center,
		"end_outer": end_vect * max_radius + center,
		}
	
	# Allow user to get values as if it's an array.
	ans[0] = ans.ini_inner
	ans[1] = ans.ini_outer
	ans[2] = ans.end_inner
	ans[3] = ans.end_outer
	
	return ans

## Get the coordinate of the point in the center of a sector.
func get_sector_center(index:int) -> Vector2:
	var mid_angle = idx_to_middle_angle(index)
	var mid_dist = inverse_lerp_band(0.5, true)
	return point_at_angle(mid_angle, mid_dist)
#endregion

#region Utility Functions

func set_start_offset():
	if centered_sector:
		_start_offset = start_angle - _sector_span * 0.5
	else:
		_start_offset = start_angle

func angle_to_idx(angle:float) -> int:
	angle = wrapf( angle - _start_offset, 0, TAU )
	var idx = floori( remap(angle, 0, TAU, 0, get_child_count()) )
	return idx

func idx_to_start_angle(index:int, with_gap:bool=false) -> float:
	if index > -1:
		var tau_angle = index * _sector_span + _start_offset
		if with_gap:
			tau_angle += sector_margin
		var pi_angle = tau_angle
		if pi_angle > PI:
			pi_angle -= TAU
		return pi_angle
	else:
		return -2

func idx_to_middle_angle(index:int) -> float:
	return idx_to_start_angle(index, false) + _sector_span * 0.5

func idx_to_stop_angle(index:int, with_gap:bool=false) -> float:
	var ini_angle = idx_to_start_angle(index, false)
	if with_gap:
		ini_angle -= sector_margin
	return ini_angle + _sector_span

func item_to_angle(item:Node) -> float:
	var index = get_children().find(item)
	return idx_to_start_angle(index)
#endregion

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		
		if (mouse_position - center).length() < central_radius:
			_hover_item = -1
		else:
			_hover_item = angle_to_idx(angle_at_point(mouse_position))
			
		queue_redraw()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_echo():
		if event.is_released():
			if _hover_item == -1:
				center_pressed.emit()
				on_center_pressed()
			else:
				sector_pressed.emit(_hover_item)
				on_sector_pressed(_hover_item)
		queue_redraw()

#region Draw Functions
func _draw() -> void:
	draw_background()
	
	if _hover_item == -1:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			draw_center_pressing()
		else:
			draw_center_hover()
	else:
		draw_center_normal()
	
	for n in range(get_child_count()):
		var ini = idx_to_start_angle(n, true)
		var mid = idx_to_middle_angle(n)
		var end = idx_to_stop_angle(n, true)
		if _hover_item == n:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				draw_sector_pressing(n, ini, mid, end)
			else:
				draw_sector_hover(n, ini, mid, end)
		else:
			draw_sector_normal(n, ini, mid, end)

func draw_background():
	draw_circle(center, inverse_lerp_band(0.5, true), Color.DARK_SLATE_GRAY, false, 20)

func draw_center_normal():
	draw_circle(center, central_radius * 0.85, Color.DIM_GRAY)
func draw_center_hover():
	draw_circle(center, central_radius * 1.0, Color.WEB_GRAY)
func draw_center_pressing():
	draw_circle(center, central_radius * 0.7, Color.DARK_SEA_GREEN)

@warning_ignore("unused_parameter")
func draw_sector_normal(index:int, start:float, middle:float, stop:float):
	draw_circle(get_sector_center(index), inverse_lerp_band(0.4, false), Color.DIM_GRAY)
@warning_ignore("unused_parameter")
func draw_sector_hover(index:int, start:float, middle:float, stop:float):
	draw_circle(get_sector_center(index), inverse_lerp_band(0.5, false), Color.WEB_GRAY)
@warning_ignore("unused_parameter")
func draw_sector_pressing(index:int, start:float, middle:float, stop:float):
	draw_circle(get_sector_center(index), inverse_lerp_band(0.25, false), Color.DARK_SEA_GREEN)

#endregion


#region Functions to Override
## Override this function if you don't want to connect a signal.
func on_center_pressed():
	pass

## Override this function if you don't want to connect a signal.
@warning_ignore("unused_parameter")
func on_sector_pressed(idx:int):
	pass
#endregion
