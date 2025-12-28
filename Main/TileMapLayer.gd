extends TileMapLayer

# Vamos definir que cada tile tem 16x16 ou 32x32 pixels
var tile_size = Vector2i(32, 32)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = local_to_map(mouse_pos) # Converte clique em coordenada da grade
			interagir_com_terreno(tile_pos)

func interagir_com_terreno(pos: Vector2i):
	# Aqui verificamos se o tile é grama (para arar) ou terra (para plantar)
	print("Interagindo com a célula: ", pos)
	# Lógica de plantio virá aqui
