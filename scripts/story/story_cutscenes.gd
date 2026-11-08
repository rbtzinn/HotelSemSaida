class_name StoryCutscenes
extends RefCounted
## Roteiro das cutscenes da história (tomadas no motor). Quem chama decide o momento;
## `Cutscene` cuida de tocar uma vez só.

## Ligada ao começar um jogo novo (solo ou dupla); o Saguão toca a abertura e a desliga.
const OPENING_PENDING := "cena.abertura.pendente"


## Abertura: o Saguão em 1923 e o mesmo percurso hoje. Termina nos olhos da personagem ativa.
static func opening(tree: SceneTree) -> Cutscene:
	var past := Era.Id.PAST_1923
	var today := Era.Id.PRESENT
	return Cutscene.play(tree, "abertura", [
		{"era": past, "fade": true, "time": 6.5, "caption": "Grand Hotel Aurora. Março de 1923.",
			"from": Vector3(10, 1.7, 10.1), "look_from": Vector3(10, 4.6, 6.5),
			"to": Vector3(10, 2.6, 8.4), "look_to": Vector3(10, 2.2, 3.4)},
		{"era": past, "time": 5.0, "caption": "Hóspedes chegam. Alguns nunca vão embora.",
			"from": Vector3(2.6, 2.8, 9.6), "look_from": Vector3(10, 4.2, 6.5),
			"to": Vector3(6.2, 3.6, 6.4), "look_to": Vector3(17, 1.2, 8)},
		{"era": today, "time": 6.5, "caption": "O mesmo hotel, cem anos depois.",
			"from": Vector3(10, 1.7, 10.1), "look_from": Vector3(10, 4.6, 6.5),
			"to": Vector3(10, 2.6, 8.4), "look_to": Vector3(10, 0.4, 7.0)},
		{"era": today, "fade": false, "time": 5.5, "caption": "Lia não lembra de ter entrado.",
			"from": Vector3(16.2, 1.7, 9.7), "look_from": Vector3(10, 0.6, 7.2),
			"to": Vector3(12.6, 1.4, 9.4), "look_to": Vector3(10, 1.4, 10.75)},
	])


## Primeira troca de época: a câmera sai dos olhos de uma, sobe pela sala e entra nos da outra.
static func first_switch(tree: SceneTree, from: FirstPersonMotor, to: FirstPersonMotor) -> Cutscene:
	var start := from.get_camera().global_transform
	var end := to.get_camera().global_transform
	var eye := end.origin
	var middle := (start.origin + end.origin) / 2.0 + Vector3(0, 2.6, 0)
	if middle.distance_to(eye) < 1.0:
		middle += Vector3(0, 0, 1.5)
	var above := Transform3D(Basis.looking_at(eye - middle, Vector3.UP), middle)
	return Cutscene.play(tree, "troca", [
		{"time": 2.6, "caption": "Mesmo lugar. Outro tempo.", "from_xform": start, "to_xform": above},
		{"time": 1.8, "from_xform": above, "to_xform": end},
	])


## Fim da Cozinha: Lia chega à manutenção; o relógio de ponto em 1923 e a ficha de Otília hoje.
static func kitchen_end(tree: SceneTree) -> Cutscene:
	return Cutscene.play(tree, "fim_cozinha", [
		{"era": Era.Id.PAST_1923, "fade": true, "time": 4.5, "caption": "Março de 1923. Cada entrada tem sua saída carimbada.",
			"from": Vector3(2.6, 1.7, 3.2), "look_from": Vector3(0.3, 1.5, 4.0),
			"to": Vector3(1.5, 1.6, 3.7), "look_to": Vector3(0.3, 1.5, 4.1)},
		{"era": Era.Id.PRESENT, "time": 5.0, "caption": "Otília, cozinheira. 1923. Entrou e não saiu.",
			"from": Vector3(1.6, 1.6, 5.6), "look_from": Vector3(0.3, 1.45, 4.7),
			"to": Vector3(1.0, 1.5, 5.0), "look_to": Vector3(0.3, 1.45, 4.7)},
	])


## Fim da Biblioteca: o dossiê de Caio hoje e, em 1923, a palavra que ficou pela metade.
static func library_end(tree: SceneTree) -> Cutscene:
	return Cutscene.play(tree, "fim_biblioteca", [
		{"era": Era.Id.PRESENT, "time": 5.0, "caption": "Dr. Caio Ferraz, médico. 1951. Ninguém o viu sair.",
			"from": Vector3(9.0, 2.0, 0.6), "look_from": Vector3(9, 1.05, -1.3),
			"to": Vector3(9.5, 1.6, -0.3), "look_to": Vector3(9, 1.05, -1.35)},
		{"era": Era.Id.PAST_1923, "time": 4.5, "caption": "Em 1923, alguém começou a escrever uma palavra e parou.",
			"from": Vector3(8.4, 1.7, -0.2), "look_from": Vector3(9, 1.05, -1.3),
			"to": Vector3(8.8, 1.45, -0.6), "look_to": Vector3(9, 1.05, -1.35)},
	])


## Fim das Caldeiras: a lanterna de Tomás e a subida pelos canos rumo ao Saguão.
static func boilers_end(tree: SceneTree) -> Cutscene:
	var box := Vector3(3.80, 0.99, 9.03)
	return Cutscene.play(tree, "fim_caldeiras", [
		{"era": Era.Id.PRESENT, "time": 4.5, "caption": "Tomás Reis, explorador. 2003. A lanterna apagou antes da saída.",
			"from": box + Vector3(1.6, 0.6, 0.2), "look_from": box,
			"to": box + Vector3(0.8, 0.3, 0.1), "look_to": box + Vector3(0, -0.05, 0)},
		{"era": Era.Id.PRESENT, "time": 4.5, "caption": "Antes de sumir, ele voltou ao Saguão.",
			"from": box + Vector3(0.9, 0.4, 0.1), "look_from": box + Vector3(-0.2, 3.0, -0.5),
			"to": box + Vector3(0.9, 3.4, 0.1), "look_to": box + Vector3(-0.2, 5.5, -0.5)},
	])


## Bolsa de Marta, no fundo do poço: a bolsa e a correia que sobe até a soleira.
static func marta_bag(tree: SceneTree) -> Cutscene:
	var bag := Vector3(15.72, -1.70, 0.57)
	var sill := Vector3(16.05, 0.03, 2.17)
	return Cutscene.play(tree, "bolsa_marta", [
		{"era": Era.Id.PRESENT, "time": 4.0, "caption": "Marta Siqueira, fotógrafa. 1979.",
			"from": bag + Vector3(0.9, 0.9, 1.0), "look_from": bag,
			"to": bag + Vector3(0.6, 0.5, 0.7), "look_to": bag},
		# Sobe pelo vão do poço (z < 2) antes de recuar para o Saguão, sem atravessar o piso
		{"era": Era.Id.PRESENT, "time": 3.0, "caption": "A última chapa ficou no poço. Ela não.",
			"from": bag + Vector3(0.7, 0.6, 0.8), "look_from": bag + Vector3(-0.2, 0.4, 0.4),
			"to": Vector3(16.3, 0.7, 1.4), "look_to": sill},
		{"era": Era.Id.PRESENT, "time": 2.5,
			"from": Vector3(16.3, 0.7, 1.4), "look_from": sill,
			"to": sill + Vector3(0.25, 1.5, 1.9), "look_to": sill + Vector3(0, -0.3, -0.4)},
	])


## Final, parte 1: depois do clarão, a entrada mostra o Saguão de novo.
static func exit_return(tree: SceneTree) -> Cutscene:
	return Cutscene.play(tree, "final_saida", [
		{"era": Era.Id.PRESENT, "time": 5.0, "caption": "Do outro lado da porta, o Saguão. De novo.",
			"from": Vector3(10, 2.6, 7.4), "look_from": Vector3(10, 1.4, 10.75),
			"to": Vector3(10, 1.65, 9.55), "look_to": Vector3(10, 1.5, 3.5)},
	])


## Final, parte 2: Helena em 1923, diante da porta giratória que treme com três batidas.
static func knocks(tree: SceneTree) -> Cutscene:
	var shots: Array = [
		{"era": Era.Id.PAST_1923, "fade": true, "time": 3.0, "caption": "1923. Diante da porta giratória, Helena espera.",
			"from": Vector3(10, 1.6, 7.6), "look_from": Vector3(10, 1.5, 10.7),
			"to": Vector3(10, 1.6, 8.6), "look_to": Vector3(10, 1.5, 10.7)},
	]
	for i in 3:
		var jolt := Vector3(0.03 if i % 2 == 0 else -0.03, 0.02, 0.04)
		shots.append({"time": 0.18, "caption": "Alguém bate do outro lado." if i == 0 else "",
			"from": Vector3(10, 1.6, 8.6) + jolt, "look_from": Vector3(10, 1.5, 10.7),
			"to": Vector3(10, 1.6, 8.6), "look_to": Vector3(10, 1.5, 10.7)})
		shots.append({"time": 0.7, "from": Vector3(10, 1.6, 8.6), "look_from": Vector3(10, 1.5, 10.7),
			"to": Vector3(10, 1.6, 8.62), "look_to": Vector3(10, 1.5, 10.7)})
	shots.append({"time": 1.5, "from": Vector3(10, 1.6, 8.62), "look_from": Vector3(10, 1.5, 10.7),
		"to": Vector3(10, 1.6, 8.8), "look_to": Vector3(10, 1.5, 10.7)})
	return Cutscene.play(tree, "final_batidas", shots)


## Quartos: o diário de Helena. A escrivaninha em 1923 e, hoje, a mala onde ele sobreviveu.
static func helena_diary(tree: SceneTree) -> Cutscene:
	var desk := GuestFloorRoom3D.DESK
	var trunk := GuestFloorRoom3D.TRUNK + Vector3(0, 0.45, 0)
	return Cutscene.play(tree, "fim_quartos", [
		{"era": Era.Id.PAST_1923, "fade": true, "time": 5.0, "caption": "Helena. Quarto 207, março de 1923.",
			"from": desk + Vector3(1.6, 0.8, -1.4), "look_from": desk,
			"to": desk + Vector3(0.9, 0.5, -0.6), "look_to": desk + Vector3(0, -0.05, 0.1)},
		{"era": Era.Id.PRESENT, "time": 5.0, "caption": "Ela escrevia que ia embora. Todas as noites.",
			"from": trunk + Vector3(-1.2, 0.9, -1.0), "look_from": trunk,
			"to": trunk + Vector3(-0.6, 0.5, -0.5), "look_to": trunk},
	])
