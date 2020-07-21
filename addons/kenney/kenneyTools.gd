extends EditorPlugin
tool

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var dock

func forward_spatial_gui_input(camera, event):
	if dock != null:
		dock.forward_canvas_gui_input(camera, event)
	return false
	
func handles(object):
	return true

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	dock = preload("res://addons/kenney/main.tscn").instance()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, dock)
	
	add_tool_menu_item("kenney - fbx setup", self, "callback")
	add_tool_menu_item("kenney - fbx process", self, "callback_do")

func _exit_tree():
	remove_tool_menu_item("kenney - fbx setup")
	remove_tool_menu_item("kenney - fbx process")
	remove_control_from_docks(dock)
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, dock)
	dock.queue_free()
	
func disable_plugin():
	_exit_tree()
	
func create_node(scene_root, name) -> void:
	if scene_root.get_node(name) == null:
		var n = Node.new()
		n.set_name(name)
		scene_root.add_child(n)
		n.owner = scene_root
	 
func add_node(scene_root, node: MeshInstance, parent) -> void:
	if scene_root != null:
		var mi = node.duplicate()
		
		if parent != null:
			parent.add_child(mi)
			mi.owner = scene_root
		else:
			var container = scene_root.get_node("Meshes")
			container.add_child(mi);
		
		mi.owner = scene_root
	
func walk(scene_root, children, parent):
	for i in range(children.size()):
		var child = children[i];
		
		var mi = StaticBody.new()
		mi.rotation = child.rotation
		mi.transform = child.transform
		mi.translation = child.translation
		mi.scale = child.scale
		mi.name = child.get_name()
		
		if parent == null:
			scene_root.get_node("Meshes").add_child(mi)
			mi.owner = scene_root
		else:
			parent.add_child(mi)
			mi.owner = scene_root
		
		if child.get_class() == 'MeshInstance':
			var mesh = MeshInstance.new()
			mesh.mesh = child.mesh
			mesh.name = mi.name
			mi.add_child(mesh)
			var dup = mesh.duplicate()
			dup.create_convex_collision()
			var shape = dup.get_child(0).get_child(0).duplicate()
			mi.add_child(shape)
			shape.owner = scene_root
			dup.free()
			
			mesh.owner = scene_root
				
		if child.get_children().size() != 0:
			walk(scene_root, child.get_children(), mi)

func callback(ud):
	var scene_root = get_tree().get_edited_scene_root();
	
	create_node(scene_root, "Meshes")
	create_node(scene_root, "Objects")
	
func callback_do(ud):
	var scene_root = get_tree().get_edited_scene_root();
	
	var child_count = scene_root.get_node("Objects").get_child_count();
	var children = scene_root.get_node("Objects").get_children()
	
	walk(scene_root, children, null)
	
	var mesh_child_count = scene_root.get_node("Meshes").get_child_count();
	var mesh_children = scene_root.get_node("Meshes").get_children()
	
	for i in range(mesh_child_count):
		mesh_children[i].remove_and_skip()
	
	var objs = scene_root.get_node("Objects")
	scene_root.remove_child(objs)
	objs.free()
		
	scene_root.get_node("Meshes").remove_and_skip()
	
func get_plugin_name():
	return "MeshLibrary Tool"
	
func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
