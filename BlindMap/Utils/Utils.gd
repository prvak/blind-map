class_name Utils extends Object


static func free_all_nodes(node: Node):
	var children = node.get_children()
	for child in children:
		node.remove_child(child)
		child.queue_free()


class Random extends Object:
	
	static func get_random_slice(array: Array, count: int) -> Array:
		if array.size() <= count: return array

		var remaining_indexes = {}
		for i in array.size():
			remaining_indexes[i] = true

		var result = []
		var remaining_items = count;
		while remaining_items > 0:
			var index = remaining_indexes.keys().pick_random()
			remaining_indexes.erase(index);
			remaining_items -= 1
			result.append(array[index])
		return result
