@tool
extends Control
class_name RadialMenu

## A quick and dirty radial menu. It uses custom drawing in a [code]_draw()[/code] function to produce its elements.[br]
## You can change what is shown by overriding [code]draw_sector_*[/code] and [code]draw_center_*[/code] methods of this function.[br]
## You may had a child Control node with Anchor and Offset Preset set to Center, to make it display there.[br]
 
signal center_pressed
signal sector_pressed(idx:int)

@export var center_radius : float = 0.3 : ## Size of central element and hover hotspot as ratio with the max radius of the menu.
	set(val):
		center_radius = clamp(val, 0, 1)
		queue_redraw()
@export var sector_gap = deg_to_rad(1) :
	set(val):
		sector_gap = clamp(val, 0, PI * 0.5)
		queue_redraw()
@export var start_angle : float = 0 :
	set(val):
		start_angle = wrapf(val, -PI, PI)
		queue_redraw()
@export var items : Array[String] : 
	set(val):
		items = val
		if val.size() > 0:
			_sector_span = TAU / val.size()
		else:
			_sector_span = TAU
		queue_redraw()

var _sector_span : float  # The angle of which each sector is wide.

#region Utility Functions
## Set size of the center element as a number of pixels. Note: not tested properly.
func set_center_radius(rad:int): #TODO: Test this properly.
	var max_radius = size[size.min_axis_index()] * 0.5
	rad = clamp(rad, 0, max_radius)
	center_radius = inverse_lerp(0, max_radius, rad)

func angle_to_idx(angle:float) -> int:
	#TODO isn't there a purely mathematical way to do this?
	angle = wrapf( angle + start_angle, -PI, PI )
	if angle < 0:
		angle += TAU
	return floori( remap(angle, 0, TAU, 0, items.size()) )

func angle_to_item(angle:float) -> String:
	var index = angle_to_idx(angle)
	return items[index]

func item_to_angle(item:String) -> float:
	var index = items.find(item)
	if index >= 0:
		return wrapf(_sector_span * index + start_angle, 0, TAU)
	else:
		return -1
#endregion

var _hover_item : int = -1
var mouse_vector : Vector2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_vector = event.position - center
		var mouse_dist = mouse_vector.length()
		var mouse_angl = mouse_vector.angle()
		
		var center_elem_radius = radius * center_radius * 0.5
		
		if mouse_dist < center_elem_radius:
			_hover_item = -1
		else:
			_hover_item = angle_to_idx(mouse_angl)
		
		queue_redraw()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		if _hover_item < 0:
			center_pressed.emit()
			on_center_pressed()
		else:
			sector_pressed.emit(_hover_item)
			on_sector_pressed(_hover_item)

var center : Vector2  ## Coordinate of the center of the radial menu.
var radius : float

func _draw() -> void:
	center = get_rect().get_center()
	radius = size[size.min_axis_index()] * 0.5
	var font := SystemFont.new()
	var font_dist : float = ((1 - center_radius) * radius * 2) * 0.5 + center_radius
	
	var n : int = -1
	for each in items:
		n += 1
		
		if _hover_item < 0:
			draw_center_hover(radius * center_radius)
		else:
			draw_center_normal(radius * center_radius)
		
		var ini_angle = n * _sector_span + sector_gap + start_angle
		var end_angle = ini_angle + _sector_span - sector_gap
		var mid_angle = ini_angle + _sector_span / 2
		if _hover_item == n:
			draw_sector_hover(n, ini_angle, mid_angle, end_angle)
		else:
			draw_sector_normal(n, ini_angle, mid_angle, end_angle)
		
		var text_pos := Vector2.RIGHT.rotated(mid_angle) * font_dist + center - font.get_string_size(each) * 0.5
		draw_string(font, text_pos, each)


func draw_sector_normal(_idx, ini_angle, _mid_angle, end_angle):
	draw_arc(center, radius - 3, ini_angle, end_angle, 12, Color.RED, 6)

func draw_sector_hover(_idx, ini_angle, _mid_angle, end_angle):
	draw_arc(center, radius - 8, ini_angle, end_angle, 12, Color.SLATE_GRAY, 12)

func draw_center_normal(max_radius):
	draw_circle(center, max_radius * center_radius, Color.ORANGE)

func draw_center_hover(max_radius):
	draw_circle(center, max_radius * center_radius, Color.YELLOW)

## Override this function if you don't want to connect a signal.
func on_center_pressed():
	pass

## Override this function if you don't want to connect a signal.
func on_sector_pressed(_idx:int):
	pass
