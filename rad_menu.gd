@tool
extends Control
class_name RadialMenu

## A quick and dirty radial menu. It uses custom drawing in a [code]_draw()[/code] function to produce its elements.[br]
## You can change what is shown by overriding [code]draw_sector_*[/code] and [code]draw_center_*[/code] methods of this function.[br]
## Each item is a child node of RadialMenu. The top and left anchors are used to position it in its sector.[br]
 
signal center_pressed
signal sector_pressed(idx:int)

#region Inspector Variables
@export var center_radius : float = 0.5 : ## Size of central element and hover hotspot as ratio with the max radius of the menu.
	set(val):
		center_radius = clamp(val, 0, 1)
		queue_redraw()
@export var sector_gap = deg_to_rad(3) :
	set(val):
		sector_gap = clamp(val, 0, PI * 0.5)
		queue_redraw()
@export var start_angle : float = 0 :  ## [b]WARNING:[/b]This doesn't work very well.
	set(val):
		start_angle = wrapf(val, -PI, PI)
		queue_redraw()
#endregion

#region Internal Variables
var center : Vector2  ## Coordinate of the center of the radial menu.
var max_radius : float
var proper_radius : float  ## Radius of the center in pixels, after accounting `center_radius`

var _sector_span : float  ## The angle of which each sector is wide.
var _hover_item : int = -1
var mouse_vector : Vector2
#endregion

func _init():
	child_entered_tree.connect(__on_child_changed)
	child_exiting_tree.connect(__on_child_changed)
	item_rect_changed.connect(__on_rect_changed)
	mouse_exited.connect(__on_mouse_exited)

func rearrange_children():
	for n in range(get_child_count()):
		var item : Control = get_child(n)
		var anchor := Vector2( item.anchor_left * item.size.x, item.anchor_top * item.size.y)
		item.position = get_sector_center(n) - anchor

func __on_child_changed(_node:Node):
	if get_child_count() == 0:
		_sector_span = TAU
	else:
		_sector_span = TAU / get_child_count()
	
	rearrange_children()
	queue_redraw()

func __on_rect_changed():
	center = get_rect().get_center()
	max_radius = size[size.min_axis_index()] * 0.5
	proper_radius = max_radius * center_radius
	rearrange_children()

func __on_mouse_exited():
	_hover_item = -2
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_vector = event.position - center
		var mouse_dist = mouse_vector.length()
		var mouse_angl = mouse_vector.angle()
		
		if mouse_dist < proper_radius:
			_hover_item = -1
		else:
			_hover_item = angle_to_idx(mouse_angl)  #FIXME for some reason this doesn't match up with start_angle every time.
		
		queue_redraw()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		if _hover_item == -1:
			center_pressed.emit()
			on_center_pressed()
		else:
			sector_pressed.emit(_hover_item)
			on_sector_pressed(_hover_item)


func _draw() -> void:
	draw_background()
	
	if _hover_item == -1:
		draw_center_hover()
	else:
		draw_center_normal()
	
	var n : int = -1
	for each in get_children():
		n += 1
		
		var ini_angle = n * _sector_span + sector_gap + start_angle
		var end_angle = ini_angle + _sector_span - sector_gap
		var mid_angle = ini_angle + _sector_span / 2
		if _hover_item == n:
			draw_sector_hover(n, ini_angle, mid_angle, end_angle)
		else:
			draw_sector_normal(n, ini_angle, mid_angle, end_angle)

#region Helper Functions
func get_sect_corners(ini_angle, end_angle) -> Dictionary:
	var ini_vect = Vector2.RIGHT.rotated(ini_angle)
	var end_vect = Vector2.RIGHT.rotated(end_angle)
	
	var ans = {
		"ini_inner": ini_vect + ini_vect * proper_radius + center,
		"ini_outer": ini_vect * max_radius + center,
		"end_inner": end_vect + end_vect * proper_radius + center,
		"end_outer": end_vect * max_radius + center,
		}
	
	# Allow user to get values as if it's an array.
	ans[0] = ans.ini_inner
	ans[1] = ans.ini_outer
	ans[2] = ans.end_inner
	ans[3] = ans.end_outer
	
	return ans

func get_sector_center(index:int) -> Vector2:
	var mid_angle = index * _sector_span + start_angle + 0.5 * _sector_span
	var mid_dist = (max_radius - proper_radius) * 0.5 + proper_radius
	var coord = Vector2.RIGHT.rotated(mid_angle) * mid_dist + center
	return coord

#endregion

#region Functions for Overriding
func draw_background():
	draw_circle(center, max_radius, Color(0.19, 0.286, 0.482, 1.0))

func draw_sector_normal(_idx, ini_angle, _mid_angle, end_angle):
	var corners = get_sect_corners(ini_angle, end_angle)
	draw_line(corners[0], corners[1], Color(0.265, 0.383, 0.622, 1.0), 8)
	draw_arc(center, max_radius - 6, ini_angle, end_angle, 12, Color(0.265, 0.383, 0.622, 1.0), 12)

func draw_sector_hover(_idx, ini_angle, _mid_angle, end_angle):
	var corners = get_sect_corners(ini_angle, end_angle)
	draw_line(corners[0], corners[1], Color(0.248, 0.386, 0.503, 1.0), 8)
	draw_arc(center, max_radius - 3, ini_angle, end_angle, 12, Color(0.248, 0.386, 0.503, 1.0), 6)

func draw_center_normal():
	draw_circle(center, proper_radius - 12, Color(0.265, 0.383, 0.622, 1.0))

func draw_center_hover():
	draw_circle(center, proper_radius, Color(0.248, 0.386, 0.503, 1.0))
	

## Override this function if you don't want to connect a signal.
func on_center_pressed():
	pass

## Override this function if you don't want to connect a signal.
func on_sector_pressed(_idx:int):
	pass

#endregion

#region Utility Functions
## Set size of the center element as a number of pixels. Note: not tested properly.
func set_center_radius(rad:int): #TODO: Test this properly.
	rad = clamp(rad, 0, max_radius)
	center_radius = inverse_lerp(0, max_radius, rad)

func angle_to_idx(angle:float) -> int:
	angle = wrapf( angle + start_angle, -PI, PI )
	if angle < 0:
		angle += TAU
	return floori( remap(angle, 0, TAU, 0, get_child_count()) )

func item_to_angle(item:Node) -> float:
	var index = get_children().find(item)
	if index > -1:
		var tau_angle = wrapf(_sector_span * index + start_angle, 0, TAU)
		var pi_angle = tau_angle
		if pi_angle > PI:
			pi_angle -= TAU
		return pi_angle
	else:
		return 0
#endregion
