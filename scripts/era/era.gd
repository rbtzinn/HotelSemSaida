class_name Era
extends RefCounted
## As duas épocas do hotel e os dados de cada uma (personagem, ano, cor).

enum Id { PAST_1923, PRESENT }


static func other(era: Id) -> Id:
	return Id.PRESENT if era == Id.PAST_1923 else Id.PAST_1923


static func character_name(era: Id) -> String:
	return "Helena" if era == Id.PAST_1923 else "Lia"


static func year_label(era: Id) -> String:
	return "1923" if era == Id.PAST_1923 else "Hoje"


static func character_color(era: Id) -> Color:
	return Color("#6B1E2A") if era == Id.PAST_1923 else Color("#6E8596")
