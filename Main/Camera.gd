extends Camera2D

var alvo_zoom = 1.0
var velocidade_zoom = 0.1
var arrastando = false

func _unhandled_input(event):
	# Zoom com a roda do mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			alvo_zoom = clamp(alvo_zoom + velocidade_zoom, 0.5, 2.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			alvo_zoom = clamp(alvo_zoom - velocidade_zoom, 0.5, 2.0)
		
		# Arrastar com o botão do meio ou direito
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			arrastando = event.pressed

	# Movimento do Pan
	if event is InputEventMouseMotion and arrastando:
		position -= event.relative / zoom

func _process(delta):
	# Suaviza o zoom
	zoom = zoom.lerp(Vector2(alvo_zoom, alvo_zoom), delta * 10)
