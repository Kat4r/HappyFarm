extends Node

var moedas: int = 5000
var inventario: Dictionary = {} # { "trigo_semente": 5, "trigo_colhido": 2 }

signal moedas_alteradas(novo_valor)
signal inventario_atualizado

# Estrutura de uma entrega: { "id": 1, "valor": 150, "dia_chegada": 5 }
var entregas_pendentes: Array = []

func criar_pedido_entrega(valor_base: int, dias_demora: int):
	# Ex: Vende por 150, chega daqui 3 dias (Dia atual + 3)
	# Precisamos pegar o dia atual do TimeSystem (precisamos conectar os scripts depois)
	# Por enquanto vamos simular:
	var dia_pagamento = 0 # (Aqui pegaremos TimeSystem.dia_atual) + dias_demora
	
	var entrega = {
		"valor": int(valor_base * 1.5), # Bônus de 50% por esperar!
		"dias_para_receber": dias_demora
	}
	entregas_pendentes.append(entrega)
	print("Contrato fechado! Dinheiro chega em ", dias_demora, " dias.")

# Essa função será chamada pelo sinal 'mudou_dia' do TimeSystem
func processar_pagamentos_diarios():
	# Loop reverso para poder remover itens do array sem crashar
	for i in range(entregas_pendentes.size() - 1, -1, -1):
		var entrega = entregas_pendentes[i]
		entrega.dias_para_receber -= 1
		
		if entrega.dias_para_receber <= 0:
			adicionar_moedas(entrega.valor)
			print("PAGAMENTO RECEBIDO: +$", entrega.valor)
			entregas_pendentes.remove_at(i)

func adicionar_moedas(qtd):
	moedas += qtd
	moedas_alteradas.emit(moedas)

func gastar_moedas(qtd) -> bool:
	if moedas >= qtd:
		moedas -= qtd
		moedas_alteradas.emit(moedas)
		return true
	return false

func adicionar_ao_inventario(item_id: String, qtd: int):
	if inventario.has(item_id):
		inventario[item_id] += qtd
	else:
		inventario[item_id] = qtd
	inventario_atualizado.emit()


# Verifica se tem o item (para plantio)
func tem_item(item_id: String) -> bool:
	return inventario.has(item_id) and inventario[item_id] > 0

# Remove item (usado ao plantar ou vender)
func remover_do_inventario(item_id: String, qtd: int = 1):
	if tem_item(item_id):
		inventario[item_id] -= qtd
		if inventario[item_id] <= 0:
			inventario.erase(item_id) # Remove a chave se zerar
		inventario_atualizado.emit()
