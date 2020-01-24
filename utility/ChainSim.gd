extends Node


var colour_bonus_values = [0, 2, 4, 8, 16]
var group_bonus_values = [0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]

func chain_power_equation(x):
	if x > 1:
		return floor( pow( 2, 1.36*x+1-0.2* pow (x, (1.5))))
	else:
		return 0


func board_fill_percent(b:Array):
	var max_capacity = len(b) * len(b[0])
	var capacity = 0.0
	for i in range(len(b)):
		for j in range(len(b[0])):
			if b[i][j] != 0:
				capacity += 1.0
	
	return capacity / max_capacity
	

func get_group_sizes(b:Array, new_pieces=[]):
	var board = b.duplicate(true)
	
	var board_size = Vector2(len(board[0]), len(board))
	
	if new_pieces:
		for piece in new_pieces:
			board[piece[1]][piece[0]] = piece[2]
	
	fall_puyos(board)
	
	var groups = [0]
	
	var matches = find_matches(board)
	
	for group in matches:
		while len(group) > len(groups):
			groups.append(0)
		groups[len(group) - 1] += 1
	
	return groups
	

func get_potential_matches(b:Array, pop_goal, new_pieces:Array):
	var board = b.duplicate(true)
	var new_pieces_copy = new_pieces.duplicate(true)
	
	var board_size = Vector2(len(b[0]), len(b))
	
	var potential_pops = []
	
	var i = 0
	while i < len(new_pieces_copy):
		var piece = new_pieces_copy[i]
		if piece[0] >= 0 && piece[0] <= 5 && piece[1] >= 0:
			board[floor(piece[1])][piece[0]] = piece[2]
			new_pieces_copy.remove(i)
		elif piece[0] < 0 || piece[0] > 5:
			new_pieces_copy.remove(i)
		else:
			i += 1
	
	fall_puyos(board)
	i = 0
	while i < len(new_pieces_copy):
		var piece = new_pieces_copy[i]
		board[floor(piece[1]) + 1][piece[0]] = piece[2]
		new_pieces_copy.remove(i)
	
	fall_puyos(board)
	
	
	var matches = find_matches(board)
	
	for group in matches:
		if len(group) >= pop_goal:
			for piece in group:
				potential_pops.append([piece[1], piece[2]])
	
	return potential_pops
	
	
# Returns the final board state its chain number score and garbage clear amount
func get_final_board(b:Array, pop_goal, new_pieces=[]): 
	var board = b.duplicate(true)
	
	var board_size = Vector2(len(b[0]), len(b))
	
	if new_pieces:
		for piece in new_pieces:
			board[piece[1]][piece[0]] = piece[2]
	
	var chain = 0
	
	var score = 0
		
	var finished = false
	
	var garbage_clear_count = 0
	
	while !finished:
		fall_puyos(board)
		
		var matches = find_matches(board)
		
		var has_match = false
		
		chain += 1
		
		var puyo_count = 0
		var score_multiplier = 1
		
		var colours = []
		
		for group in matches:
			if len(group) >= pop_goal:
				has_match = true
				score_multiplier += group_bonus_values[min(len(group), len(group_bonus_values) - 1)]
				
				if !group[0][0] in colours:
					colours.append(group[0][0])
				
				for p in group:
					puyo_count += 1
					set_colour(board, board_size, p[1], p[2], 0)
					if get_colour(board, board_size, p[1] + 1, p[2]) == -1:
						set_colour(board, board_size, p[1] + 1, p[2], 0)
						garbage_clear_count += 1
					if get_colour(board, board_size, p[1] - 1, p[2]) == -1:
						set_colour(board, board_size, p[1] - 1, p[2], 0)
						garbage_clear_count += 1
					if get_colour(board, board_size, p[1], p[2] + 1) == -1:
						set_colour(board, board_size, p[1], p[2] + 1, 0)
						garbage_clear_count += 1
					if get_colour(board, board_size, p[1], p[2] - 1) == -1:
						set_colour(board, board_size, p[1], p[2] - 1, 0)
						garbage_clear_count += 1
		
		score_multiplier += colour_bonus_values[len(colours)]
		score_multiplier += chain_power_equation(chain)
		score_multiplier = clamp(score_multiplier, 1, 999)
		
		score += (puyo_count * 10) * score_multiplier
		
		if !has_match:
			finished = true
			
	return [board, chain, score, garbage_clear_count]
		
	


func fall_puyos(b:Array):
	var final_board = []
		
	var puyo_in_columns = [] # list of puyos in each column, bottom first
	
	var board_size = Vector2(len(b[0]), len(b))
	
	for x in range(board_size.x):
		var column = []
		for y in range(board_size.y - 1, -1, -1):
			if b[y][x] != 0:
				column.append(b[y][x])
		puyo_in_columns.append(column)
	
	for y in range(board_size.y - 1, -1, -1):
		for x in range(board_size.x):
			if len(puyo_in_columns[x]) < board_size.y - 1 - y + 1:
				b[y][x] = 0
			else:
				b[y][x] = puyo_in_columns[x][board_size.y - 1 - y]
	
func find_piece_in_group(piece, group):
	for i in range(len(group) - 1, -1, -1):
		if group[i][1] == piece[1] && group[i][2] == piece[2]:
			return true
	return false
	
func find_matches(b:Array):
	var board_size = Vector2(len(b[0]), len(b))
	
	var matches = []
	
	for y in range(1, board_size.y):
		for x in range(board_size.x):
			if get_colour(b, board_size, x, y) > 0:
				var has_match = false
				
				var group = 0
				
				while group < len(matches):
					if matches[group][0][0] == b[y][x]:
						for piece in matches[group]:
							if (piece[1] == x && piece[2] + 1 == y) || (piece[1] + 1 == x && piece[2] == y):
								if !has_match:
									matches[group].append([get_colour(b, board_size, x, y), x, y])
									has_match = true
								else:
									for g in range(group - 1, -1, -1):
										if find_piece_in_group([get_colour(b, board_size, x, y), x, y], matches[g]):
											matches[group] += matches[g]
											matches.remove(g)
											break
								break
					group += 1
				if !has_match:
					matches.append([[get_colour(b, board_size, x, y), x, y]])

	return matches
				
func get_board_heights(b:Array):
	var board_size = Vector2(len(b[0]), len(b))
	var heights = []
	for i in range(len(b[0])):
		var height = 0
		while !is_solid(b, board_size, i, height):
			height += 1
		heights.append(height)
	return heights

class LandSort:
	static func sort(a, b):
		if a[1] < b[1]:
			return true
		return false

func get_land_locations(heights:Array, puyos:Array):#puyo: [x, y, c]
	var heights_copy = heights.duplicate()
	var final_position = []
	puyos.sort_custom(LandSort, 'sort')
	for puyo in puyos:
		puyo[1] = heights_copy[puyo[0]]
		final_position.append(puyo)
		heights_copy[puyo[0]] -= 1
	
	return final_position




func get_colour(b, board_size, x, y):
	if x < 0 || x > board_size.x - 1 || y > board_size.y - 1 || y < 0:
		return 0
	else:
		return b[floor(y)][x]


func set_colour(b, board_size, x, y, colour):
	if x >= 0 && x < board_size.x && y < board_size.y && y >= 0:
		 b[floor(y)][x] = colour

func is_solid(b, board_size, x, y):
	if x < 0 || x > board_size.x - 1 || y > board_size.y - 1 || y < 0:
		return false
	elif y < 0:
		return false
	elif b[floor(y)][x] != 0:
		return true
	return false