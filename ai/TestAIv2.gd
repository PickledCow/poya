extends Node

export var mode = 1

var lr = -1

var input_repeat = 0
var drop_delay = 20

var target_column = -1
var target_column_height = 0

var top_score = 0

var highest_score = 0

var cant_make_smaller = true

var target_rotation = 0


var best_position = [] # x, y, size

var recieved_garbage = false
var recalculated = false
var recalculation_start_frame = 0

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

func score_group(group_sizes, pop_goal):
	var score = 0
	score -= group_sizes[0] * 0.5
	for i in range(1, min(pop_goal - 1, len(group_sizes))):
		score += group_sizes[i] * (i + 1)
	
	for i in range(pop_goal - 1, len(group_sizes)):
		score -= group_sizes[i]
	
	return score


func score_group_zone(group_sizes, pop_goal):
	var score = 0
	
	for i in range(1, min(pop_goal - 2, len(group_sizes))):
		score += group_sizes[i] * i * 20
	
	for i in range(pop_goal - 1, len(group_sizes)):
		if group_sizes[i]:
			score += (150 + 50 / (i * group_sizes[i]))
	
	return score




const PUYO_OFFSETS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

func get_input(frame, board, pop_goal, current_puyo, puyo_queue:Array, garbage_queue, incoming_garbage, board_heights, colour_count, in_zone):
	var inputs = []
	
	var pieces = current_puyo.slave_puyo_static.duplicate(true) + [[Vector2(0,0), 0]]
	
	if get_parent().state == 0:
		
		var rotation_order = [0,1,2,3]
		if current_puyo.type == 4:
			rotation_order = range(1, colour_count + 1)
		rotation_order.shuffle()
		
		var column_order = [5,0,4,1]
		column_order.shuffle()
		var death_columns = [3, 2]
		death_columns.shuffle()
		column_order += death_columns
		
		
	
		if !in_zone && !recieved_garbage && incoming_garbage + garbage_queue > 0:
			recieved_garbage = true
			recalculation_start_frame = frame
			
			if garbage_queue > 0:
				highest_score = 0
			else:
				highest_score = 360
		
		if frame == 0:
			
			target_column = -1
			target_column_height = 0
			
			target_rotation = 0
			
			if current_puyo.type == 4:
				target_rotation = 1
			
			top_score = 0
			
			cant_make_smaller = true
			
			recalculated = false
			recieved_garbage = false
			recalculation_start_frame = 0
			
			if in_zone:
				highest_score = -INF
			
			if ChainSim.board_fill_percent(board) < 0.7:
				highest_score = 360
			elif ChainSim.board_fill_percent(board) < 0.8:
				highest_score = 40
			else:
				highest_score = 0
		if (frame < 6 && !recieved_garbage) || (frame < 6 && in_zone):
			# Build up board
			for rotation in rotation_order:
				var pieces_copy = pieces.duplicate(true)
				var can_place = true
				
				if current_puyo.type < 4:
					for piece in pieces_copy:
						piece[0] = piece[0].rotated(rotation * TAU * 0.25).round()
						if (column_order[frame] == 0 && piece[0].x == -1) || (column_order[frame] == 5 && piece[0].x == 1) || (board_heights[column_order[frame] + piece[0].x]) < 2:
							can_place = false 
							break
				elif current_puyo.type == 4 && column_order[frame] == 5:
					can_place = false
						
						
				if can_place:
					var drop_puyos = []
					for piece in pieces_copy:
						var formatted_piece = [column_order[frame] + piece[0].x, 1 + piece[0].y]
						if current_puyo.type < 4:
							if piece[1] == 0:
								formatted_piece.append(current_puyo.c1)
							else:
								formatted_piece.append(current_puyo.c2)
						else:
							formatted_piece.append(rotation)
							
						drop_puyos.append(formatted_piece)
						
					if ChainSim.board_fill_percent(board) < 0.6 && garbage_queue + incoming_garbage == 0 && !in_zone:
						var current_score = score_group(ChainSim.get_group_sizes(board, drop_puyos), pop_goal)
						var final_board = ChainSim.get_final_board(board, pop_goal, drop_puyos)
						if ChainSim.board_fill_percent(final_board[0]) == 0:
							current_score = 9999999999999
						
						if final_board[0][1][2] == 0 && final_board[0][1][3] == 0:
							if (current_score > top_score) || (current_score == top_score && get_parent().board_heights[column_order[frame]] > get_parent().board_heights[target_column]):
								top_score = current_score
								target_column = column_order[frame]
								target_rotation = rotation
					elif in_zone:
						var current_score = score_group_zone(ChainSim.get_group_sizes(board, drop_puyos), pop_goal)
						var final_board = ChainSim.get_final_board(board, pop_goal, drop_puyos)
						if ChainSim.board_fill_percent(final_board[0]) == 0:
							current_score += 9999999999999
						
						if final_board[0][1][2] == 0 && final_board[0][1][3] == 0:
							if (current_score > top_score):
								top_score = current_score
								target_column = column_order[frame]
								target_rotation = rotation
					
					
					else:
						var final_board = ChainSim.get_final_board(board, pop_goal, drop_puyos)
						var score = final_board[2]
						if ChainSim.board_fill_percent(final_board[0]) == 0:
							score += 5000
						score += final_board[3] * 50
						if final_board[0][1][2] == 0 && final_board[0][1][3] == 0 && score > highest_score:
							cant_make_smaller = false
							highest_score = score
							target_column = column_order[frame]
							target_rotation = rotation

		elif cant_make_smaller && frame < 12 && !recieved_garbage && !in_zone:
			for rotation in rotation_order:
				var pieces_copy = pieces.duplicate(true)
				var can_place = true
				for piece in pieces_copy:
					piece[0] = piece[0].rotated(rotation * TAU * 0.25).round()
					if (column_order[frame - 6] == 0 && piece[0].x == -1) || (column_order[frame - 6] == 5 && piece[0].x == 1) || (board_heights[column_order[frame - 6] + piece[0].x]) < 2:
						can_place = false 
						break
					
				if can_place:
					var drop_puyos = []
					for piece in pieces_copy:
						var formatted_piece = [column_order[frame - 6] + piece[0].x, 1 + piece[0].y]
						if piece[1] == 0:
							formatted_piece.append(current_puyo.c1)
						else:
							formatted_piece.append(current_puyo.c2)
						drop_puyos.append(formatted_piece)
						
					var current_score = score_group(ChainSim.get_group_sizes(board, drop_puyos), pop_goal)
					var final_board = ChainSim.get_final_board(board, pop_goal, drop_puyos)
					
					if ChainSim.board_fill_percent(final_board[0]) == 0:
						current_score = 9999999999999
					if final_board[0][1][2] == 0 && final_board[0][1][3] == 0:
						if (current_score > top_score) || (current_score == top_score && get_parent().board_heights[column_order[frame - 6]] > get_parent().board_heights[target_column]):
							top_score = current_score
							target_column = column_order[frame - 6]
							target_rotation = rotation
		
		else:
			
			if recieved_garbage && !recalculated && !in_zone:
				for rotation in rotation_order:
					var pieces_copy = pieces.duplicate(true)
					var can_place = true
					if current_puyo.type < 4:
						for piece in pieces_copy:
							piece[0] = piece[0].rotated(rotation * TAU * 0.25).round()
							if (column_order[frame - recalculation_start_frame] == 0 && piece[0].x == -1) || (column_order[frame - recalculation_start_frame] == 5 && piece[0].x == 1) || (board_heights[column_order[frame - recalculation_start_frame] + piece[0].x]) < 2:
								can_place = false 
								break
					elif current_puyo.type == 4 && column_order[frame - recalculation_start_frame] == 5:
						can_place = false
					
					if can_place:
						var drop_puyos = []
						for piece in pieces_copy:
							var formatted_piece = [column_order[frame - recalculation_start_frame] + piece[0].x, 1 + piece[0].y]
							if piece[1] == 0:
								formatted_piece.append(current_puyo.c1)
							else:
								formatted_piece.append(current_puyo.c2)
							drop_puyos.append(formatted_piece)
						
						var final_board = ChainSim.get_final_board(board, pop_goal, drop_puyos)
						var score = final_board[2]
						if ChainSim.board_fill_percent(final_board[0]) == 0:
							score += 5000
						if ChainSim.board_fill_percent(board) > 0.8:
							score += 360
						if final_board[0][1][2] == 0 && final_board[0][1][3] == 0:
							if score > highest_score:
								cant_make_smaller = false
								highest_score = score
								target_column = column_order[frame - recalculation_start_frame]
								target_rotation = rotation

				if frame - recalculation_start_frame >= 5:
					recalculated = true
			
			
			
			if (recieved_garbage && recalculated) || !recieved_garbage || in_zone:
				if current_puyo.position.x < target_column:
					drop_delay = 0#20
					if input_repeat == 0:
						inputs.append('r')
				if current_puyo.position.x > target_column:
					drop_delay = 0#20
					if input_repeat == 0:
						inputs.append('l')
				if (current_puyo.type < 4 && current_puyo.rotation != target_rotation) || (current_puyo.type == 4 && current_puyo.c1 != target_rotation):
					drop_delay = 0#20
					if input_repeat == 0:
						inputs.append('cw')
				if current_puyo.position.x == target_column && (current_puyo.type < 4 && current_puyo.rotation == target_rotation) || (current_puyo.type == 4 && current_puyo.c1 == target_rotation):
					if drop_delay > 0:
						drop_delay -= 1
					else:
						inputs.append('d')
				elif frame > 40:
					inputs.append('d')

			
		input_repeat += 1
		
		input_repeat = input_repeat % 2#6
		
		
	return inputs

