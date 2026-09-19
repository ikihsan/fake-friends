class_name FFHandbookPage
extends Resource

@export var page_id: String = ""
@export var title: String = ""
@export_enum("person", "plan", "map") var kind: String = "person"
## Stable entry IDs map to initial prose. Saves contain overrides, not resource mutations.
@export var entries: Dictionary = {}
