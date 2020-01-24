extends Node

export var mode = 1

var lr = -1

var input_repeat = 0
var drop_delay = 20

var target_column = -1
var target_column_height = 0

var column_order = [5,0,4,1,3,2]

var best_position = [] # x, y, size

func find_lowest_index(array):
	var index = 0
	var lowest = 0
	lowest = array[0]
	for i in [5,0,4,1,2,3]:
		if array[i] > lowest:
			lowest = array[i]
			index = i
	
	return index
	
func find_greatest_index(array):
	var index = 0
	var greatest = 0
	greatest = array[0]
	for i in [0,5,1,4,2,3]:
		if array[i] < greatest && array[i] != 0:
			greatest = array[i]
			index = i
	
	return index

func get_input(frame):
	var inputs = []
	
	if get_parent().state == 0:
		if mode == 0:
			
			var target_column = 2
			
			if get_parent().garbage_queue + get_parent().incoming_garbage > 0:
				target_column = find_greatest_index(get_parent().board_heights)
			else:
				target_column = find_lowest_index(get_parent().board_heights)
			
			if get_parent().current_puyo.position.x < target_column:
				drop_delay = 20
				if input_repeat == 0:
					inputs.append('r')
			elif get_parent().current_puyo.position.x > target_column:
				drop_delay = 20
				if input_repeat == 0:
					inputs.append('l')
			else:
				if drop_delay > 0:
					drop_delay -= 1
				else:
					inputs.append('d')

		
		elif mode == 1:
			
			var target_column = 2
			if get_parent().board_heights[5] > 1:
				target_column = 5
			elif get_parent().board_heights[4] > 1:
				target_column = 4
			elif get_parent().board_heights[3] > 1:
				target_column = 3
			elif get_parent().board_heights[0] > 1:
				target_column = 0
			elif get_parent().board_heights[1] > 1:
				target_column = 1
			
			
			if get_parent().current_puyo.position.x < target_column:
				drop_delay = 20
				if input_repeat == 0:
					inputs.append('r')
			elif get_parent().current_puyo.position.x > target_column:
				drop_delay = 20
				if input_repeat == 0:
					inputs.append('l')
			else:
				if drop_delay > 0:
					drop_delay -= 1
				else:
					inputs.append('d')
	
		elif mode == 2:
			for i in ['l', 'r', 'd', 'cw', 'ccw']:
				if randi() % 8 == 0:
					inputs.append(i)
		
		elif mode == 3:
			if get_parent().current_puyo.position.x == 0:
				lr = 1
			elif get_parent().current_puyo.position.x == 5:
				lr = -1
			
			if input_repeat == 0:
					
				if lr == 1:
					inputs.append('r')
					inputs.append('cw')
				else:
					inputs.append('l')
					inputs.append('ccw')
				
			inputs.append('d')
		
		elif mode == 4: # greed
			if frame == 0:
				target_column = -1
				target_column_height = 0
			if frame < 6:
				if get_parent().current_puyo.c1 == get_parent().get_colour(column_order[frame], get_parent().board_heights[column_order[frame]]):
					if frame < 4:
						if get_parent().board_heights[column_order[frame]] > target_column_height:
							target_column = column_order[frame]
							target_column_height = get_parent().board_heights[column_order[frame]]
					else:
						if get_parent().board_heights[column_order[frame]] - 2 > target_column_height:
							target_column = column_order[frame]
							target_column_height = get_parent().board_heights[column_order[frame]]
							
						
			else:
				if target_column == -1 || get_parent().board_heights[target_column] == 0:
					target_column = find_lowest_index(get_parent().board_heights)
				
				if get_parent().current_puyo.position.x < target_column:
					drop_delay = 20
					if input_repeat == 0:
						inputs.append('r')
				elif get_parent().current_puyo.position.x > target_column:
					drop_delay = 20
					if input_repeat == 0:
						inputs.append('l')
				else:
					if drop_delay > 0:
						drop_delay -= 1
					else:
						inputs.append('d')
	
			
		input_repeat += 1
		
		input_repeat = input_repeat % 6
		
		
	return inputs

