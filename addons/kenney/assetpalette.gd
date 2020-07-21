extends HBoxContainer
tool

var _file_dialog
var display_mode

var meshlibs = []
var mls = []

var item

enum { DISPLAY_LIST, DISPLAY_THUMBNAIL }

var position3D

func _show_file_dialog():
	_file_dialog.popup_centered_ratio()

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	_file_dialog = FileDialog.new()
	_file_dialog.mode = FileDialog.MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.connect("file_selected", self, "_on_FileDialog_file_selected")
	add_child(_file_dialog)
	
	display_mode = DISPLAY_THUMBNAIL
	
	set_process_input(true)
	
	_update_palette()

func _exit_tree():
	# Cleanup
	_file_dialog.queue_free()
	set_process_input(false)

func _set_display_mode(mode):
	if display_mode == mode:
		return
	
	if mode == DISPLAY_LIST:
		get_node("AssetLibrary/HBoxContainer/ModeList").pressed = true
		get_node("AssetLibrary/HBoxContainer/ModeThumbnail").pressed = false
	if mode == DISPLAY_THUMBNAIL:
		get_node("AssetLibrary/HBoxContainer/ModeList").pressed = false
		get_node("AssetLibrary/HBoxContainer/ModeThumbnail").pressed = true
		
	display_mode = mode
	
	_update_palette()
	
func _update_palette():
	var libraries = get_node("AssetLibrary/ItemList") as ItemList;
	var mlp = get_node("AssetLibrary/MeshLibraryPalette") as ItemList;
	var info = get_node("AssetLibrary/MeshLibraryPalette/InfoMessage");
	var icon_size = get_node("AssetLibrary/IconSize").value;
	
	info.hide()
	libraries.clear()
	
	for i in range(meshlibs.size()):
		libraries.add_item(meshlibs[i]);
	
	mlp.clear()
	
	if display_mode == DISPLAY_THUMBNAIL:
		mlp.max_columns = 0
		mlp.icon_mode = ItemList.ICON_MODE_TOP
		mlp.fixed_column_width = 64 * max(icon_size, 1.5)
	if display_mode == DISPLAY_LIST:
		mlp.max_columns = 1
		mlp.icon_mode = ItemList.ICON_MODE_LEFT
		mlp.fixed_column_width = 0
		
	mlp.fixed_icon_size = Vector2(64, 64);
	mlp.max_text_lines = 2;
	
	if mls.size() == 0:
		get_node("AssetLibrary/HBoxContainer/SearchBox").text = ''
		get_node("AssetLibrary/HBoxContainer/SearchBox").editable = false
		info.show()
		return
	
	var first = mls[0] as MeshLibrary;
	var list = first.get_item_list();
	
	for j in range(list.size()):
		
		var name = first.get_item_name(j)
		var preview = first.get_item_preview(j)
		if name == "":
			name = "#" + String(j)
		
		mlp.add_item("")
		
		if !preview == null:
			mlp.set_item_icon(j, preview)
			mlp.set_item_tooltip(j, name)
		
		if display_mode == DISPLAY_LIST:
			mlp.set_item_text(j, name)
		
		mlp.set_item_metadata(j, list[j])

func _on_FileDialog_file_selected(path: String):
	if meshlibs.find(path) == -1:
		meshlibs.append(path);
		mls.append(load(path));
		_update_palette()

func _on_InfoMessage_gui_input(ev:InputEventMouseButton):
	if ev is InputEventMouseButton:
		if ev.is_pressed() and ev.doubleclick:
			_show_file_dialog()

func _on_IconSize_value_changed(value):
	var mlp = get_node("AssetLibrary/MeshLibraryPalette") as ItemList
	mlp.icon_scale = value
	mlp.update()


func _on_ModeThumbnail_pressed():
	_set_display_mode(DISPLAY_THUMBNAIL)


func _on_ModeList_pressed():
	_set_display_mode(DISPLAY_LIST)

func get_drag_preview(i):
	var preview = Control.new()
	var sprite = Sprite.new()
	sprite.set_texture((mls[0] as MeshLibrary).get_item_preview(item))
	preview.add_child(sprite)
	return preview

func _on_MeshLibraryPalette_gui_input(ev:InputEventMouseButton):
	if ev is InputEventMouseButton:
		if ev.is_pressed():
			var mlp = get_node("AssetLibrary/MeshLibraryPalette") as ItemList
			item = mlp.get_item_at_position(ev.position)
			var preview = get_drag_preview(item)
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			self.call_deferred("force_drag", (mls[0] as MeshLibrary).get_item_mesh(item), preview)

func _notification(what):
	if what == EditorInterface.NOTIFICATION_DRAG_END:
		var ep = EditorPlugin.new()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		var scene = ep.get_editor_interface().get_edited_scene_root()
		
		if position3D != null:
			var mi = MeshInstance.new()
			mi.mesh = (mls[0] as MeshLibrary).get_item_mesh(item)
			mi.translate(position3D);
			mi.name = (mls[0] as MeshLibrary).get_item_name(item)
			scene.add_child(mi);
			mi.owner = scene;

func forward_canvas_gui_input(camera, ev):
	var position2D = ev.position
	
	var dropPlane = Plane(Vector3(0, 1, 0), 0)
	
	position3D = dropPlane.intersects_ray(
		camera.project_ray_origin(position2D),
		camera.project_ray_normal(position2D)
	)
