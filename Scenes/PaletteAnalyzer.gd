extends RefCounted
class_name PaletteAnalyzer
## Extracts exact colors and automatically groups chromatic colors by hue.
## Colors with very low saturation are left ungrouped unless manually assigned.

static func create_Pallete(image : Image) -> PackedColorArray:
	var colors : PackedColorArray = []
	for x in image.get_width():
		for y in image.get_height():
			var pixel = quantize_color(image.get_pixel(x, y))
			if (pixel.a < 1):
				continue
			if (!colors.has(pixel)):
				colors.append(pixel)
			
	return colors

static func quantize_color(color: Color, step: int = 16) -> Color:
	return Color(
		roundi(color.r * 255.0 / step) * step / 255.0,
		roundi(color.g * 255.0 / step) * step / 255.0,
		roundi(color.b * 255.0 / step) * step / 255.0,
		1.0
	)
	
static func analyze(palette: PackedColorArray, hue_threshold: float = 0.075, max_families: int = 6) -> Dictionary:
	var colors: Array[Color] = []
	var color_keys: Array[int] = []
	var seen: Dictionary = {}

	for y in range(palette.size()):
		var c = palette[y]
		if c.a <= 0.0:
			continue
		var key: int = c.to_rgba32()
		if not seen.has(key):
			seen[key] = true
			colors.append(c)
			color_keys.append(key)

	# Create hue clusters. Low-saturation colors remain neutral (-1).
	var clusters: Array[Dictionary] = []
	var family_ids := PackedInt32Array()
	family_ids.resize(colors.size())
	for i in range(colors.size()):
		family_ids[i] = -1

	var chromatic_indices: Array[int] = []
	for i in range(colors.size()):
		if colors[i].s > 0.12:
			chromatic_indices.append(i)

	chromatic_indices.sort_custom(func(a: int, b: int) -> bool:
		return colors[a].h < colors[b].h
	)

	for color_index in chromatic_indices:
		var hue: float = colors[color_index].h
		var best_cluster := -1
		var best_distance := 999.0

		for cluster_index in range(clusters.size()):
			var center: float = float(clusters[cluster_index]["hue"])
			var distance := _hue_distance(hue, center)
			if distance < best_distance:
				best_distance = distance
				best_cluster = cluster_index

		if best_cluster >= 0 and best_distance <= hue_threshold:
			var cluster: Dictionary = clusters[best_cluster]
			cluster["indices"].append(color_index)
			cluster["hue_sum_x"] = float(cluster["hue_sum_x"]) + cos(hue * TAU)
			cluster["hue_sum_y"] = float(cluster["hue_sum_y"]) + sin(hue * TAU)
			cluster["hue"] = fposmod(atan2(float(cluster["hue_sum_y"]), float(cluster["hue_sum_x"])) / TAU, 1.0)
			clusters[best_cluster] = cluster
		else:
			clusters.append({
				"hue": hue,
				"indices": [color_index],
				"hue_sum_x": cos(hue * TAU),
				"hue_sum_y": sin(hue * TAU)
			})

	# Merge closest hue clusters until the requested maximum is reached.
	while clusters.size() > max_families:
		var merge_a := 0
		var merge_b := 1
		var closest := 999.0
		for a in range(clusters.size()):
			for b in range(a + 1, clusters.size()):
				var d := _hue_distance(float(clusters[a]["hue"]), float(clusters[b]["hue"]))
				if d < closest:
					closest = d
					merge_a = a
					merge_b = b

		var ca: Dictionary = clusters[merge_a]
		var cb: Dictionary = clusters[merge_b]
		var combined_indices: Array = ca["indices"] + cb["indices"]
		var sx = cos(float(ca["hue"]) * TAU) * ca["indices"].size() + cos(float(cb["hue"]) * TAU) * cb["indices"].size()
		var sy = sin(float(ca["hue"]) * TAU) * ca["indices"].size() + sin(float(cb["hue"]) * TAU) * cb["indices"].size()
		ca["indices"] = combined_indices
		ca["hue_sum_x"] = sx
		ca["hue_sum_y"] = sy
		ca["hue"] = fposmod(atan2(sy, sx) / TAU, 1.0)
		clusters[merge_a] = ca
		clusters.remove_at(merge_b)

	# Stable family IDs in ascending hue order.
	clusters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["hue"]) < float(b["hue"])
	)
	var family_hues := PackedFloat32Array()
	for family_index in range(clusters.size()):
		var cluster: Dictionary = clusters[family_index]
		family_hues.append(float(cluster["hue"]))
		for color_index in cluster["indices"]:
			family_ids[int(color_index)] = family_index

	return {
		"colors": colors,
		"color_keys": color_keys,
		"family_ids": family_ids,
		"family_hues": family_hues,
		"family_count": clusters.size()
	}


static func _hue_distance(a: float, b: float) -> float:
	var d := absf(a - b)
	return minf(d, 1.0 - d)
