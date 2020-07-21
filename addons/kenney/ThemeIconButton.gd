extends Button
tool

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(String) var theme_icon = ""
export(String) var theme_control = "EditorIcons"

func _enter_tree():
	icon = get_icon(theme_icon, theme_control)

# Called when the node enters the scene tree for the first time.
func _ready():
	icon = get_icon(theme_icon, theme_control)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
