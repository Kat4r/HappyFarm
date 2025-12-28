extends TileMapLayer

# No topo do FarmGrid.gd
@export var sistema_tempo: CanvasModulate# <--- Arraste o nó CicloDiaNoite para cá

# --- Estados ---
enum Ferramenta { ENXADA, SEMENTE, MAO, COMPRAR }
enum Estado { GRAMA, ARADO, PLANTADO, BLOQUEADO }

# --- Configurações Iniciais ---
# ID do Source do seu Tileset (geralmente é 0 ou 1)
const SOURCE_ID = 0 
# Coordenada do tile de TERRA ARADA no seu Atlas
const TILE_TERRA_ARADA = Vector2i(2, 0) 
# Coordenada do tile de GRAMA (para resetar)
const TILE_GRAMA = Vector2i(0, 0) 

const TAMANHO_MAPA_TOTAL = 10 # O grid será 10x10
const CUSTO_TERRENO = 100     # Preço por bloco

var tamanho_atual = 3 # Começa 3x3

const CUSTO_EXPANSAO = 100
# --- Funções para a UI chamar ---
func selecionar_enxada():
	ferramenta_atual = Ferramenta.ENXADA
	print("Ferramenta: Enxada")

func selecionar_semente():
	ferramenta_atual = Ferramenta.SEMENTE
	print("Ferramenta: Semente")

func selecionar_mao():
	ferramenta_atual = Ferramenta.MAO
	print("Ferramenta: Mão/Colher")

# --- Variáveis de Sistema ---
# Dicionário que guarda o estado de cada célula
# Chave: Vector2i (coordenada) -> Valor: Dictionary (dados)
var dados_grade: Dictionary = {}
var ferramenta_atual = Ferramenta.MAO # Começamos com a "Mão" por padrão
@export var semente_atual: PlantData 
# Coordenadas visuais para o "Cubo Inicial" (Ajuste se necessário)
# Essas coordenadas costumam formar um quadrado visual bonito no isométrico
# Coordenadas que formam o "cubo" 3x3 centralizado no grid 10x10
var lotes_iniciais: Array[Vector2i] = [
	Vector2i(4, 3), Vector2i(5, 2), Vector2i(5, 6),
	Vector2i(4, 4), Vector2i(5, 4), Vector2i(5, 3),
	Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 4)
]


func _ready():
	gerar_mundo_completo()
	
	# Conectamos o sinal: toda vez que o minuto mudar no relógio, as plantas crescem
	if sistema_tempo:
		sistema_tempo.tempo_atualizado.connect(_ao_passar_minuto_no_jogo)



func gerar_mundo_completo():
	for x in range(TAMANHO_MAPA_TOTAL):
		for y in range(TAMANHO_MAPA_TOTAL):
			var cell = Vector2i(x, y)
			var estado_inicial = Estado.BLOQUEADO
			
			# ID do Tile: 0 é a grama normal, 1 é a grama escura (alternativa)
			var id_visual = 1 
			
			if cell in lotes_iniciais:
				estado_inicial = Estado.GRAMA
				id_visual = 0 # Grama clara para o cubo inicial
			
			dados_grade[cell] = {
				"estado": estado_inicial,
				"planta_ref": null,
				"progresso": 0
			}
			
			# set_cell(camada, coordenadas, source_id, atlas_coords, alternative_tile)
			# O último número (id_visual) define se é a grama clara ou escura
			set_cell(cell, SOURCE_ID, TILE_GRAMA, id_visual)

# Função chamada quando o jogador clica para comprar
func atualizar_visual_lote(cell: Vector2i):
	# Quando compra, forçamos o ID visual para 0 (Grama Clara)
	set_cell(cell, SOURCE_ID, TILE_GRAMA, 0)
	
	# Dica de Diretor: Podemos adicionar um efeito de som de moedas aqui!
	print("Lote em ", cell, " agora está iluminado e pronto para uso!")
				

func comprar_expansao():
	if GameManager.gastar_moedas(CUSTO_EXPANSAO):
		tamanho_atual += 1
		# Quando aumentamos o tamanho, precisamos preencher a "borda" nova
		expandir_tiles_visuais()
		print("Fazenda expandida para ", tamanho_atual, "x", tamanho_atual)
	else:
		print("Moedas insuficientes para expandir!")

func expandir_tiles_visuais():
	# Esta lógica preenche a nova coluna e a nova linha do quadrado
	for i in range(tamanho_atual):
		# Preenche a nova linha (X)
		_criar_tile_grama(Vector2i(i, tamanho_atual - 1))
		# Preenche a nova coluna (Y)
		_criar_tile_grama(Vector2i(tamanho_atual - 1, i))

func _criar_tile_grama(cell: Vector2i):
	if not dados_grade.has(cell):
		dados_grade[cell] = {
			"estado": Estado.GRAMA,
			"planta_ref": null,
			"progresso": 0
		}
		set_cell(cell, SOURCE_ID, TILE_GRAMA)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var cell_pos = local_to_map(mouse_pos)
			interagir(cell_pos)

# --- Lógica de Interação ---
func interagir(cell: Vector2i):
	var dados = dados_grade.get(cell)
	
	match ferramenta_atual:
		Ferramenta.ENXADA:
			# ALTERAÇÃO AQUI: Removemos o "dados == null"
			# Agora ele SÓ ara se a célula já existir no dicionário E for Grama.
			if dados != null and dados.estado == Estado.GRAMA:
				arar_terra(cell)
			else:
				print("Não é possível arar fora da fazenda!", cell)
				
				
		Ferramenta.SEMENTE:
			# Só planta se o terreno estiver arado e vazio
			if dados != null and dados.estado == Estado.ARADO:
				plantar_semente(cell)
				
		Ferramenta.MAO:
			if dados.progresso >= 480: # 8 horas de jogo passaram
				colher_planta(cell)
			else:
				print("Ainda faltam ", 480 - dados.progresso, " minutos de jogo para colher.")
			
		Ferramenta.COMPRAR:
			if dados.estado == Estado.BLOQUEADO:
				if GameManager.gastar_moedas(CUSTO_TERRENO):
					dados.estado = Estado.GRAMA
					atualizar_visual_lote(cell) # Feedback visual
					print("Você comprou o lote: ", cell)
					
					
				else:
					print("Moedas insuficientes! Você precisa de 100.")

# --- Ações ---
func arar_terra(cell: Vector2i):
	print("Arando terra em: ", cell)
	# Cria a entrada no dicionário
	dados_grade[cell] = {
		"estado": Estado.ARADO,
		"planta_ref": null,
		"progresso": 0
	}
	# Atualiza visual para Terra Arada (Layer 0 é o chão)
	set_cell(cell, SOURCE_ID, TILE_TERRA_ARADA)

# --- Plantação ---
func plantar_semente(cell: Vector2i):
	# --- 1 - Verifica se o horário é liberado para o plantio ---
	if sistema_tempo.e_horario_proibido():
		print("Está muito escuro para plantar! Espere amanhecer (06:00).")
		# Feedback visual opcional: Tocar som de erro ou piscar tela
		return
		
	# 2. Verifica estoque
	if not GameManager.tem_item("trigo_semente"):
		print("Sem sementes!")
		return
		
	# 3. Verifica se o Resource está carregado
	if semente_atual == null:
		print("Erro: Resource da semente não configurado.")
		return

	# 4. Se chegou aqui, é porque TEM semente. Então consome 1 unidade.
	GameManager.remover_do_inventario("trigo_semente", 1)
	
	# 5. Lógica de plantio (Visual e Dados)
	var dados = dados_grade[cell]
	dados.estado = Estado.PLANTADO
	dados.planta_ref = semente_atual
	dados.progresso = 0
	
	atualizar_visual_planta(cell, dados)
	print("Plantou 1 trigo. Restam: ", GameManager.inventario.get("trigo_semente", 0))

# --- Colher Plantio ---
func colher_planta(cell: Vector2i):
	var dados = dados_grade[cell]
	print("Colhendo ", dados.planta_ref.nome_exibicao)
	
	# --- Lógica de Recompensa ATUALIZADA ---
	# Adiciona o item 'trigo_colhido' ao inventário
	# No futuro, o ID do item colhido pode vir de dentro do PlantData
	GameManager.adicionar_ao_inventario("trigo_colhido", 1)
	
	# Resetando para o Estado Inicial (Grama)
	dados.estado = Estado.GRAMA
	dados.planta_ref = null
	dados.progresso = 0
	set_cell(cell, SOURCE_ID, TILE_GRAMA)

func selecionar_modo_compra():
	ferramenta_atual = Ferramenta.COMPRAR
	print("Modo de compra ativado. Clique em um terreno bloqueado.")
	

# Esta função roda toda vez que o relógio do jogo muda (ex: de 06:00 para 06:01)
func _ao_passar_minuto_no_jogo(dia, hora, minuto):
	for cell in dados_grade.keys():
		var dados = dados_grade[cell]
		
		if dados.estado == Estado.PLANTADO:
			# Aumenta o progresso em 1 minuto
			dados.progresso += 1
			
			# 8 horas = 480 minutos. 
			# Se você quiser que o trigo cresça em estágios visuais:
			# Estágio 1: 0-160 min | Estágio 2: 161-320 min | Estágio 3 (Colheita): 321-480 min
			
			# Só atualizamos o visual se mudar o estágio para não pesar o jogo
			atualizar_visual_planta(cell, dados)

# --- Atualização Visual ---
func atualizar_visual_planta(cell: Vector2i, dados: Dictionary):
	var coord_atlas = dados.planta_ref.get_atlas_coord_por_estagio(dados.progresso)
	# Nota: Aqui estamos substituindo o tile. 
	# Num sistema mais avançado, usaríamos uma segunda TileMapLayer só para plantas "acima" da terra.
	set_cell(cell, SOURCE_ID, coord_atlas)


func _on_btn_enxada_pressed() -> void:
	selecionar_enxada()


func _on_btn_semente_pressed() -> void:
	selecionar_semente()


func _on_btn_mao_pressed() -> void:
	selecionar_mao()


func _on_btn_expandir_pressed() -> void:
	selecionar_modo_compra()
