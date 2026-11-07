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
