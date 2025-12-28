extends Control

# Referências específicas para cada painel
@export var painel_inventario: Control
@export var painel_loja: Control

@export var grid_inventario: GridContainer
@export var grid_loja: GridContainer
@export var label_moedas: Label

# Configuração de Itens (Simulando um banco de dados simples)
# No futuro, isso pode vir dos Resources (PlantData)
var dados_loja = {
	"trigo_semente": {"nome": "Semente de Trigo", "custo": 10, "icon": "res://assets/seeds_wheat.png"},
	"cenoura_semente": {"nome": "Semente de Cenoura", "custo": 15, "icon": "res://assets/seeds_carrot.png"} # Exemplo extra
}

var dados_venda = {
	"trigo_colhido": {"valor": 15},
	"cenoura_colhida": {"valor": 25}
}

var textura_cubo = preload("res://imagens/inventario_ui.png")

# -------------------------------------------------------------------------
# PASSO 1: O "BANCO DE IMAGENS" (Cadastre seus itens aqui)
# Mapeia o ID do Item (Texto) -> para a Imagem (Recurso Visual)
# -------------------------------------------------------------------------
var icones_itens = {
	"trigo_semente": preload("res://imagens/plantas/UI_semente_trigo.png"),
	"trigo_colhido": preload("res://imagens/plantas/UI_pronto_trigo.png"),
	# No futuro, basta adicionar novas linhas:
	# ex: "cenoura_semente": preload("res://assets/itens/saco_cenoura.png"),
}
# -------------------------------------------------------------------------

func _ready():
	# Forçamos a conexão e a atualização imediata
	if GameManager:
		GameManager.moedas_alteradas.connect(atualizar_moedas)
		GameManager.inventario_atualizado.connect(atualizar_inventario)
		
		# Chamada manual para garantir que o 50 apareça no segundo 1
		atualizar_moedas(GameManager.moedas)
		atualizar_inventario()
		configurar_loja_placeholders()
	
	painel_inventario.visible = false
	painel_loja.visible = false

# Criando botões de texto para a loja
func configurar_loja_placeholders():
	# Limpa antes de criar
	for child in grid_loja.get_children():
		child.queue_free()
	
	# Criar botão de COMPRAR TRIGO
	var btn_comprar = Button.new()
	btn_comprar.text = "Comprar Semente Trigo ($10)"
	btn_comprar.pressed.connect(func(): 
		if GameManager.gastar_moedas(10):
			GameManager.adicionar_ao_inventario("trigo_semente", 1)
			print("Comprou semente!")
	)
	grid_loja.add_child(btn_comprar)

# --- Acesso a UI ---
func _input(event):
	# TAB para o Inventário
	if event.is_action_pressed("ui_focus_next"):
		painel_inventario.visible = not painel_inventario.visible
		# Se abrir o inventário, fecha a loja
		if painel_inventario.visible:
			painel_loja.visible = false

	# Tecla P para a Loja
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		painel_loja.visible = not painel_loja.visible
		print("loja aberta")
		# Se abrir a loja, fecha o inventário
		if painel_loja.visible:
			painel_inventario.visible = false
			print("loja fechada")

# --- Atualizações Visuais ---
func  atualizar_moedas(valor: int):
	label_moedas.text = "Moedas: " + str(valor)

# Defina o total de slots que você quer (10 colunas x 3 linhas = 30)
const TOTAL_SLOTS = 30 

func atualizar_inventario():
	# Limpa slots antigos
	for child in grid_inventario.get_children():
		child.queue_free()
	
	var lista_itens = GameManager.inventario.keys()
	
	for i in range(TOTAL_SLOTS):
		var btn = Button.new()
		# --- NOVO: TROCAR COR DA FONTE PARA PRETO ---
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.add_theme_color_override("font_hover_color", Color.BLACK) # Garante que continue preto ao passar o mouse
		btn.add_theme_color_override("font_pressed_color", Color.BLACK)
		btn.add_theme_color_override("font_disabled_color", Color.BLACK)
		# --------------------------------------------
		
		# --- APLICA O FUNDO (SEU CUBO 64x64) ---
		var style = StyleBoxTexture.new()
		style.texture = textura_cubo # Sua variável do cubo carregada lá em cima
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("disabled", style)
		btn.add_theme_stylebox_override("focus", style)
		btn.custom_minimum_size = Vector2(64, 64)
		# ---------------------------------------

		# Se existe um item neste slot:
		if i < lista_itens.size():
			var item_id = lista_itens[i]
			var qtd = GameManager.inventario[item_id]
			
			# -----------------------------------------------------------------
			# PASSO 2: APLICA O ÍCONE (A ARTE DO ITEM)
			# Verifica se temos uma arte cadastrada para esse ID
			if icones_itens.has(item_id):
				btn.icon = icones_itens[item_id]
				btn.expand_icon = true # Permite redimensionar
				
				# Ajuste Fino: Centraliza o ícone dentro do cubo
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				
				# Dica Pro: Se o ícone ficar muito grande e cobrir o cubo todo, 
				# você precisará editar a imagem do ícone para ter bordas transparentes
				# ou usar um MarginContainer (mas o jeito da imagem é mais fácil).
			# -----------------------------------------------------------------

			# Texto da quantidade (Fica no cantinho ou embaixo)
			# Se você tirar o texto do nome, o visual fica mais limpo, mostrando só o numero
			btn.text = str(qtd) 
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP # Joga o texto pro fundo se quiser
			
			# Lógica de clique (Venda, etc)
			if item_id == "trigo_colhido":
				btn.pressed.connect(func(): _vender_item(item_id))
		
		else:
			# Slot Vazio (Sem ícone, sem texto, desabilitado)
			btn.text = ""
			btn.disabled = true 

		grid_inventario.add_child(btn)

func _vender_item(item_id):
	GameManager.remover_do_inventario(item_id, 1)
	GameManager.adicionar_moedas(15)
	# O sinal do GameManager vai chamar atualizar_inventario automaticamente

func criar_slot_inventario(item_id: String, qtd: int):
	var btn = Button.new()
	btn.text = str(qtd) # Mostra a quantidade no texto (provisório até ter ícones)
	btn.custom_minimum_size = Vector2(40, 40) # Tamanho do slot
	
	# Tenta carregar ícone se existir (lógica simplificada)
	# Se quiser usar os ícones reais, carregue a textura aqui baseado no item_id
	
	# Conecta o clique para VENDA ou SELEÇÃO
	btn.pressed.connect(func(): _on_item_inventario_clicado(item_id))
	grid_inventario.add_child(btn)

# --- Lógica da Loja ---

func configurar_loja():
	# Cria os botões de compra fixos
	for item_id in dados_loja.keys():
		var info = dados_loja[item_id]
		var btn = Button.new()
		btn.text = info.nome + "\n$" + str(info.custo)
		btn.custom_minimum_size = Vector2(80, 60)
		
		btn.pressed.connect(func(): _comprar_item(item_id, info.custo))
		grid_loja.add_child(btn)

func _comprar_item(item_id: String, custo: int):
	if GameManager.gastar_moedas(custo):
		GameManager.adicionar_ao_inventario(item_id, 1)
		print("Comprou: ", item_id)
	else:
		print("Moedas insuficientes!")

# --- Lógica de Interação com Inventário ---

func _on_item_inventario_clicado(item_id: String):
	# Se for um item colhido -> VENDER
	if item_id in dados_venda:
		var valor = dados_venda[item_id].valor
		GameManager.remover_do_inventario(item_id, 1)
		GameManager.adicionar_moedas(valor)
		print("Vendeu ", item_id, " por ", valor)
	
	# Se for semente -> SELECIONAR PARA PLANTAR (Opcional, mas útil)
	elif "semente" in item_id:
		print("Semente selecionada: ", item_id)
		# Aqui você poderia notificar o FarmGrid qual semente usar
		# Ex: FarmGrid.selecionar_semente_especifica(item_id)
