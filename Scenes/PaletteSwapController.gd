extends Node
class_name PaletteSwapController
## Attach to a Sprite2D. Assign PaletteSwap.gdshader as its ShaderMaterial shader.
## Builds a 2-row palette texture: row 0 = original colors, row 1 = generated colors.

@export_range(0.01, 0.25, 0.005) var hue_threshold: float = 0.075
@export_range(1, 12, 1) var max_families: int = 6
@export_range(1, 512, 1) var max_unique_colors: int = 256

var _source_colors: Array[Color] = []
var _color_keys: Array[int] = []
var _family_ids := PackedInt32Array()
var _base_family_hues := PackedFloat32Array()
var _current_family_hues := PackedFloat32Array()
var _palette_image: Image
var _palette_texture: ImageTexture


func analyze_and_build(palette : PackedColorArray) -> void:
	var result := PaletteAnalyzer.analyze(palette, hue_threshold, max_families)
	_source_colors = result["colors"]
	_color_keys = result["color_keys"]
	_family_ids = result["family_ids"]
	_base_family_hues = result["family_hues"]
	_current_family_hues = _base_family_hues.duplicate()

func get_family_count() -> int:
	return _base_family_hues.size()


func get_family_hue_degrees(family_id: int) -> float:
	if family_id < 0 or family_id >= _current_family_hues.size():
		return 0.0
	return _current_family_hues[family_id] * 360.0

## Set one automatically discovered family to a new hue (degrees, 0..360).
## Original per-color saturation, value and alpha are preserved.
func set_family_hue(family_id: int, hue_degrees: float) -> void:
	if family_id < 0 or family_id >= _current_family_hues.size():
		push_warning("PaletteSwapController: Invalid family ID %d." % family_id)
		return
	_current_family_hues[family_id] = fposmod(hue_degrees, 360.0) / 360.0
	_apply_current_palette()


## Reset all families to their original hues.
func reset_palette() -> void:
	_current_family_hues = _base_family_hues.duplicate()
	_apply_current_palette()


## Returns a copy of the detected colors and their assigned family IDs for UI/debugging.
func get_palette_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in range(_source_colors.size()):
		entries.append({
			"color": _source_colors[i],
			"hex": "#" + _source_colors[i].to_html(false).to_upper(),
			"family_id": _family_ids[i]
		})
	return entries

func get_row_colors() -> PackedColorArray:
	var cols : PackedColorArray = []
	for i in range(_source_colors.size()):
		cols.append(_recolored_color(i))
	return cols

func _apply_current_palette() -> void:
	if _palette_image == null or _palette_texture == null:
		return
	for i in range(_source_colors.size()):
		_palette_image.set_pixel(i, 1, _recolored_color(i))
	_palette_texture.update(_palette_image)


func _recolored_color(index: int) -> Color:
	var source: Color = _source_colors[index]
	var family_id: int = _family_ids[index]
	if family_id < 0 or family_id >= _current_family_hues.size():
		return source
	# Hue rotation preserves each color's saturation, value (shade), and alpha.
	return Color.from_hsv(_current_family_hues[family_id], source.s, source.v, source.a)
