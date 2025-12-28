extends Sprite2D

# Referência ao TileMap para fazermos os cálculos de conversão
@export var tilemap_ref: TileMapLayer

# Velocidade da suavização (quanto maior, mais rápido o cursor segue o mouse)
@export var velocidade_lerp: float = 20.0

# Cores de feedback
var cor_valida = Color(1, 1, 1, 0.8) # Branco levemente transparente
var cor_invalida = Color(1, 0.3, 0.3, 0.8) # Vermelho avermelhado

func _process(delta):
	if tilemap_ref == null:
		return
		
	# 1. Pega a posição do mouse relativa ao mundo
	var mouse_pos = get_global_mouse_position()
	
	# 2. Converte essa posição para a Célula da Grade (Grid Coordinate)
	# O Godot faz a matemática isométrica automaticamente aqui se o TileSet estiver configurado
	var cell_pos = tilemap_ref.local_to_map(tilemap_ref.to_local(mouse_pos))
	
	# 3. Converte a Célula de volta para Posição de Tela (para centralizar o sprite)
	var target_pos = tilemap_ref.map_to_local(cell_pos)
	
	# 4. Movimento Suave (Lerp)
	# Movemos a posição atual em direção ao alvo
	global_position = global_position.lerp(target_pos, velocidade_lerp * delta)
	
	# 5. Feedback Visual
	atualizar_cor_feedback(cell_pos)

func atualizar_cor_feedback(cell: Vector2i):
	var dados = tilemap_ref.get("dados_grade")
	# Pegamos a ferramenta atual diretamente do script da fazenda
	var ferramenta = tilemap_ref.get("ferramenta_atual")
	
	if dados == null: return

	# Lógica de cor baseada na semente
	# Verificamos se a ferramenta é SEMENTE (que é o índice 1 no nosso Enum)
	if ferramenta == 1: # 1 corresponde a Ferramenta.SEMENTE
		if not GameManager.tem_item("trigo_semente"):
			modulate = Color(1, 0, 0, 0.8) # Vermelho (Sem sementes)
			return

	if dados.has(cell):
		modulate = cor_valida
	else:
		modulate = cor_invalida
