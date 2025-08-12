@tool
extends CenterContainer

# here's a basic crosshair system i implemented look at the code
# if you want to know how it's made but you can just click the node
# and modify it's propreties in the inspector it very straightforward

@export_group("Crosshair Dot")
@export var dot_radius: float
@export var dot_color: Color = Color.WHITE
@export_group("Crosshair Outline")
@export var dot_outline: bool = true
# BE AWARE make sure dot_outline_radius is greater than dot_radius
# else it won't appear
@export var dot_outline_radius: float
@export var dot_outline_color: Color = Color.BLACK

func _ready():
	queue_redraw()

func _draw():
	if dot_outline == true:
		draw_circle(Vector2(0, 0), dot_outline_radius, dot_outline_color)
	draw_circle(Vector2(0, 0), dot_radius, dot_color)
