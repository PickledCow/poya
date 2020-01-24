extends Control

var frame_texture = preload("res://win_field_puyo_d4444.png")

var started = false

export var is_cpu = false

var board_width = 400

export var player = 1
onready var player_string = str(player)
export var colour_count = 4

var board = []
var board_heights = []

var win_lose = -2 # 0: playing, 1: win, -1:lose, -2:notstarted

var state = 0

var score = 0
var score_increase = 0

var current_chain = 1
var chain_completed = false

var current_chain_burst = 1 # Bonus for when you do actual chains in burst 

var puyo_count = 0
var puyo_value = 0
var score_multiplier = 1


var colour_bonus_values = [0, 2, 4, 8, 16]
var group_bonus_values = [0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]

var frame_number = 0


var spinning_x_frame = 0
var spinning_x_animation_duration = 1

var popping_animation_timer = 0
var popping_animation_duration = 30

var chain_text_timer = 0
var chain_text_duration = 40

var potential_pops = []
var potential_pop_flash_timer = 0
var potential_pop_flash_duration = 1

func initalise_board():
	for i in get_parent().board_size.y:
		var row = []
		for j in get_parent().board_size.x:
			row.append(0)
		board.append(row)
	
	board_heights = [13, 13, 13, 13, 13, 13]
	
	garbage_columns.shuffle()


class ActivePuyo:
	var position = Vector2(2, 0)
	var rotation = 0
	var c1 = 0
	var c2 = 0
	
	var slave_puyos = []
	var slave_puyo_static = [] # Default arrangement of slave puyos
	
	var type = 0 # 0: normal, 1: |., 2: *_, 3: swirl, 4: colour changing
	
	var centre = Vector2(1, 0) # Offset from master to centre in swirl puyo
	
	# Sprite for non-standard puyo sprites
	var sprite
	
	var last_position = Vector2(2, 0)
	var grounded = false
	var ground_timer = 32
	var locked = false
	
	var floor_kicks = 8
	
	var rotation_animation_timer = 0
	var double_rotation = false
	
	var movement_animation_timer = 0
	
var current_puyo
var puyo_queue = []
var colour_counter = 0
const PUYO_OFFSETS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

const SWIRL_CENTRE_OFFSETS = [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 0)]
const SWIRL_ROTATION_OFFSETS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

var garbage_queue = 0
var incoming_garbage = 0
var drop_garbage = false

var attack_power = 0
var attack_remainder = 0

var puyo_type_counter = 0
export var puyo_type_order = [0, 1, 4, 1, 3, 2, 1, 4, 0, 1, 3, 0, 4, 2, 0, 3]

var garbage_columns = [0, 1, 2, 3, 4, 5]

const GARBAGE_GRAVITY = [0.0087890625, 0.00927734375, 0.0078125, 0.01025390625, 0.00830078125, 0.009765625]

func create_new_puyo():
	current_puyo = ActivePuyo.new()
	current_puyo.c1 = puyo_queue[0][0]#get_parent().cp[colour_count - 3][colour_counter]
	#colour_counter += 1
	
	current_puyo.type = puyo_queue[0][2]#puyo_type_order[puyo_type_counter]
	#puyo_type_counter += 1
	
	current_puyo.c2 = puyo_queue[0][1]#get_parent().cp[colour_count - 3][colour_counter]
	#colour_counter += 1
	
	if current_puyo.type == 0 || current_puyo.type == 2:
		current_puyo.slave_puyos.append([Vector2(0, -1), 1])
		if current_puyo.type == 2:
			current_puyo.slave_puyos.append([Vector2(1, 0), 0])
			
	elif current_puyo.type == 1:
		current_puyo.slave_puyos.append([Vector2(0, -1), 0])
		current_puyo.slave_puyos.append([Vector2(1, 0), 1])
	
	elif current_puyo.type == 3:
		current_puyo.slave_puyos.append([Vector2(0, -1), 0])
		current_puyo.slave_puyos.append([Vector2(1, -1), 1])
		current_puyo.slave_puyos.append([Vector2(1, 0), 1])
		
	elif current_puyo.type == 4:
		current_puyo.slave_puyos.append([Vector2(0, -1), 0])
		current_puyo.slave_puyos.append([Vector2(1, -1), 0])
		current_puyo.slave_puyos.append([Vector2(1, 0), 0])
	
	current_puyo.slave_puyo_static = current_puyo.slave_puyos.duplicate(true) 
	
	puyo_queue[0] = puyo_queue[1]
	var new_puyo = []
	new_puyo.append(get_parent().cp[colour_count - 3][colour_counter])
	colour_counter += 1
	
	if puyo_type_order[puyo_type_counter] != 4:
		# No double swirl
		if !(puyo_type_order[puyo_type_counter] == 3 && get_parent().cp[colour_count - 3][colour_counter] == get_parent().cp[colour_count - 3][colour_counter-1]):
			new_puyo.append(get_parent().cp[colour_count - 3][colour_counter])
		else:
			var possible_colours = []
			for i in range(1,colour_count+1):
				if i != get_parent().cp[colour_count - 3][colour_counter]:
					possible_colours.append(i)
			possible_colours.shuffle()
			
			new_puyo.append(possible_colours[0])
			
		colour_counter += 1
	else:
		new_puyo.append(get_parent().cp[colour_count - 3][colour_counter])
	
	new_puyo.append(puyo_type_order[puyo_type_counter])
	puyo_type_counter += 1
	puyo_queue[1] = new_puyo
	

	
	if colour_counter >= 254:
		colour_counter -= 256
	if puyo_type_counter >= len(puyo_type_order) - 2:
		puyo_type_counter -= len(puyo_type_order)

func initalise_queue():
	for i in range(2):
		var new_puyo = []
		new_puyo.append(get_parent().cp[colour_count - 3][colour_counter])
		colour_counter += 1
		
		if puyo_type_order[puyo_type_counter] != 4:
			# No double swirl
			if !(puyo_type_order[puyo_type_counter] == 3 && get_parent().cp[colour_count - 3][colour_counter] == get_parent().cp[colour_count - 3][colour_counter-1]):
				new_puyo.append(get_parent().cp[colour_count - 3][colour_counter])
			else:
				new_puyo.append(randi()%colour_count + 1)
				
			colour_counter += 1
		else:
			var possible_colours = []
			for i in range(1,colour_count+1):
				if i != get_parent().cp[colour_count - 3][colour_counter]:
					possible_colours.append(i)
			possible_colours.shuffle()
			
			new_puyo.append(possible_colours[0])
			
		
		new_puyo.append(puyo_type_order[puyo_type_counter])
		puyo_type_counter += 1
		puyo_queue.append(new_puyo)

var falling_puyos = []

class FallingPuyo:
	var position = Vector2(0,0)
	var colour = 0
	var velocity = 1/16.0
	const TERMINAL_VELOCITY = 0.5
	var gravity = 0.01171875
	
	var grounded = false
	var animation = 16

func create_falling_puyo(position, colour, gravity=0):
	var falling_puyo = FallingPuyo.new()
	falling_puyo.position = position
	falling_puyo.colour = colour
	
	if gravity != 0:
		falling_puyo.gravity = gravity
	
	falling_puyos.append(falling_puyo)

var in_zone = false
var zone_timer = 20
var zone_meter = 0
var zone_goal = 7
export var starting_zone_meter = 0
var burst_garbage = 0


func chain_power_equation(chain, in_zone):
	if !in_zone:
		if chain > 1:
			return floor( pow( 2, 1.36*chain+1-0.2* pow (chain, (1.5))))
		else:
			return 1
	else:
		return floor(4 + chain * 3)


func reset():
	started = true
	
	win_lose = 0
	puyo_type_counter = 0
	board = []
	board_heights = []
	
	win_lose = 0 # 0: playing, 1: win, -1:lose
	
	state = 0
	
	score = 0
	score_increase = 0
	
	current_chain = 1
	chain_completed = false
	
	current_chain_burst = 1
	
	puyo_count = 0
	puyo_value = 0
	score_multiplier = 1
	
	
	frame_number = 0


	spinning_x_frame = 0
	spinning_x_animation_duration = 1

	popping_animation_timer = 0
	popping_animation_duration = 30

	chain_text_timer = 0
	chain_text_duration = 40

	potential_pops = []
	potential_pop_flash_timer = 0
	potential_pop_flash_duration = 1

	current_puyo = null
	puyo_queue = []
	colour_counter = 0

	garbage_queue = 0
	incoming_garbage = 0
	drop_garbage = false

	attack_power = 0
	attack_remainder = 0

	puyo_type_counter = 0

	garbage_columns = [0, 1, 2, 3, 4, 5]

	falling_puyos = []

	in_zone = false
	zone_timer = 20
	zone_meter = starting_zone_meter
	burst_garbage = 0
	
	initalise_board()
	initalise_queue()
	
	update_board_height()


func _ready():
	pass
	#reset()
	
	
	if false:
		if player == 2:
			board = [
			[ 0, 0, 0, 4, 0, 0],
			[ 0, 0, 2, 3, 3, 2],
			[ 0, 0, 1, 3, 3, 2],
			[ 0, 3, 4, 4, 2, 5],
			[ 1, 4, 1, 4, 5, 5],
			[ 4, 2, 1, 2, 4, 4],
			[ 4, 2, 1, 5, 3, 4],
			[ 4, 1, 2, 4, 2, 3],
			[ 2, 1, 1, 3, 1, 3],
			[ 3, 3, 3, 2, 3, 2],
			[ 2, 1, 2, 1, 3, 2],
			[ 2, 2, 1, 2, 2, 1],
			[ 1, 1, 2, 3, 3, 1]
		]
	
	if false:
		board = [
		[ 0, 0, 0, 0, 0, 0],
		[ 0, 0, 0, 0, 0, 0],
		[ 0, 0, 0, 0, 0, 0],
		[ 0, 0, 0, 0, 0, 0],
		[ 0, 0, 0, 0, 0, 0],
		[ 0, 0, 0, 0, 0, 0],
		[ 1, 2, 0, 5, 1, 4],
		[ 1, 2, 0, 5, 1, 4],
		[ 1, 2, 0, 5, 1, 4],
		[ 3, 3, 0, 3, 3, 3],
		[ 1, 2,-1, 5, 1, 4],
		[ 1, 2,-1, 5, 1, 4],
		[ 1, 2,-1, 5, 1, 4]
		]
	
		
	
	if false:	
		set_colour(0, 12, 1)
		set_colour(1, 12, 1)
		set_colour(1, 10, 1)
		set_colour(2, 11, 1)
		set_colour(1, 11, 2)
		set_colour(0, 11, 2)
		set_colour(0, 10, 2)
		set_colour(2, 12, 2)
		set_colour(3, 12, 2)
		set_colour(3, 11, 2)
		set_colour(2, 10, 2)
		set_colour(4, 12, 3)
		set_colour(4, 11, 3)
		set_colour(3, 10, 3)
		set_colour(3, 9, 3)
		set_colour(5, 12, 4)
		set_colour(4, 10, 4)
		set_colour(4, 9, 4)
		set_colour(4, 8, 4)
		set_colour(4, 7, 2)
		set_colour(4, 6, 2)
		set_colour(4, 5, 2)
		set_colour(5, 11, 2)
		set_colour(0, 9, 3)
		set_colour(0, 8, 3)
		set_colour(0, 7, 3)
		set_colour(0, 6, 2)
		set_colour(0, 5, 2)
		set_colour(0, 4, 2)
		set_colour(0, 3, 3)
		set_colour(0, 2, 2)
	
	
	if player == 1:
		$Timer.rect_position = Vector2(300, 400)
		$ZoneProgress.rect_position = Vector2(600, 130)
		$BurstMeter/BarUnder.visible = true
		$BurstMeter/BarUnder_p2.visible = false
		$BurstMeter/Gague1.rect_position = Vector2(464,0)
		$BurstMeter/Gague2.rect_position = Vector2(464,0)
		$BurstMeter/Gague3.rect_position = Vector2(464,0)
		
	else:
		$Timer.rect_position = Vector2(-300, 400)
		$ZoneProgress.rect_position = Vector2(-264, 130)
		$BurstMeter/BarUnder.visible = false
		$BurstMeter/BarUnder_p2.visible = true
		$BurstMeter/Gague1.rect_position = Vector2(-96,0)
		$BurstMeter/Gague2.rect_position = Vector2(-96,0)
		$BurstMeter/Gague3.rect_position = Vector2(-96,0)
		
	
	
	
func is_solid(x, y):
	if x < 0 || x > get_parent().board_size.x - 1 || y > get_parent().board_size.y - 1:
		return true
	elif y < 0:
		return false
	elif board[floor(y)][x] != 0:
		return true
	return false

func get_colour(x, y):
	if x < 0 || x > get_parent().board_size.x - 1 || y > get_parent().board_size.y - 1 || y < 0:
		return 0
	else:
		return board[floor(y)][x]

func set_colour(x, y, colour):
	if x >= 0 && x < get_parent().board_size.x && y < get_parent().board_size.y && y >= 0:
		 board[floor(y)][x] = colour


var matches = []
var has_pops = false
var popping_puyos = []

func _physics_process(delta):
	if win_lose == 0:
		if current_puyo && win_lose == 0:
			state = 0
			current_puyo.last_position = current_puyo.position
			
			inputs = []
			
			
			if !current_puyo.locked:
				if !is_cpu:
					get_player_input()
				else:
					inputs = get_node('ai').get_input(frame_number, board.duplicate(true), get_parent().pop_goal, current_puyo, puyo_queue, garbage_queue, incoming_garbage, board_heights, colour_count, in_zone)
				move_piece_lr()
				rotate_piece()
				
			current_puyo.movement_animation_timer -= sign(current_puyo.movement_animation_timer)
			current_puyo.rotation_animation_timer -= sign(current_puyo.rotation_animation_timer)
			
			var puyo_global = [[current_puyo.position.x, current_puyo.position.y, current_puyo.c1]]
			for puyo in current_puyo.slave_puyos:
				var colour = current_puyo.c2
				if puyo[1] == 0:
					colour = current_puyo.c1
				puyo_global.append([current_puyo.position.x + puyo[0].x, current_puyo.position.y + puyo[0].y, colour])
			
			potential_pops = ChainSim.get_potential_matches(board, get_parent().pop_goal, puyo_global)
			
			fall_piece()
			
			land_piece()
			
			frame_number += 1
			
			
		if !current_puyo || win_lose == 1:
			state = 1
			fall_and_land_falling_puyos()
			if len(falling_puyos) == 0:
				if popping_animation_timer == 0 && !has_pops:
					state = 2
					update_board_height()
					
					puyo_count = 0
					
					matches = ChainSim.find_matches(board)#find_groups()
					
					var colours = []
					
					
					var group_bonus = 0
					
					for group in matches:
						if len(group) >= get_parent().pop_goal:
							if !(group[0][0] in colours):
								colours.append(group[0][0])
							
							has_pops = true
							popping_animation_timer = popping_animation_duration
							
							group_bonus += group_bonus_values[min(len(group), len(group_bonus_values) - 1)]
			
							for piece in group:
								puyo_count += 1
								popping_puyos.append([piece[1], piece[2]])
								if get_colour(piece[1], piece[2] - 1) == -1:
									popping_puyos.append([piece[1], piece[2] - 1])
								if get_colour(piece[1], piece[2] + 1) == -1:
									popping_puyos.append([piece[1], piece[2] + 1])
								if get_colour(piece[1] + 1, piece[2]) == -1:
									popping_puyos.append([piece[1] + 1, piece[2]])
								if get_colour(piece[1] - 1, piece[2]) == -1:
									popping_puyos.append([piece[1] - 1, piece[2]])
							
					
					# Increase score
					
					puyo_value = (10 * puyo_count)		
					
					var colour_bonus = colour_bonus_values[len(colours) - 1]
					var group_and_colour_bonus = colour_bonus + group_bonus
					
					if in_zone:
						group_and_colour_bonus *= 0.5
					
					score_multiplier = (chain_power_equation(current_chain, in_zone) + group_and_colour_bonus)
					
					if current_chain_burst > 1:
						score_multiplier *= 1.5
					score_multiplier = clamp(floor(score_multiplier), 1, 999)
					score_increase = puyo_value * score_multiplier
					score += score_increase
						
			
				
				elif popping_animation_timer == 0 && has_pops:
					
					get_node("Se/" + str(min(current_chain, 7))).play()
					
					
					for piece in popping_puyos:
						# Remove piece
						set_colour(piece[0], piece[1], 0)
		
					popping_puyos = []
					
				
					var np = float(score_increase) / get_parent().target_points + attack_remainder
					var nc = int(floor(np))
					attack_remainder = np - nc
					
					var counter = false
					
					if !in_zone:
						
						if garbage_queue > 0:
							get_parent().counter(player)
							zone_meter += 1
							garbage_queue -= nc
							if incoming_garbage > 0:
								incoming_garbage += garbage_queue
								garbage_queue = 0
								if incoming_garbage <= 0:
									attack_power = -incoming_garbage
									incoming_garbage = 0
									counter = true
							elif garbage_queue <= 0:
								attack_power = -garbage_queue
								counter = true
						elif incoming_garbage > 0:
							get_parent().counter(player)
							zone_meter += 1
							incoming_garbage -= nc
							if incoming_garbage <= 0:
								attack_power = -incoming_garbage
								incoming_garbage = 0
								counter = true
						else:
							attack_power += nc
						
						
						if counter:
							pass
							#$Character/Chants/counter.play()
						else:
							pass
							#get_node("Character/Chants/" + str(current_chain)).play()

						if attack_power > 0:
							get_parent().send_garbage(attack_power, player)
						attack_power = 0
						
					else:
						burst_garbage += nc
		
		
					var peaks = find_lowest_pop(matches)
					
					
					
					
					state = 3
					current_chain += 1
					if in_zone:
						current_chain_burst += 1
					# Convert everything above popped to falling puyos
					cascade_puyos(peaks)
					
					has_pops = false
					
					if get_parent().continuous_offsetting:
						drop_garbage = false
				
				# WIP: better chain alignments
				elif popping_animation_timer == 20:
					
					var chain_text = str(current_chain).replace('0', 'O')
					$Chain.bbcode_text = '[center]' + chain_text + '[i]-Chain'
					if current_chain_burst > 1:
						$Chain.bbcode_text += ' ×1.5'
					$Chain.visible = true
					
				#	print(Vector2(popping_puyos[len(popping_puyos) / 2][0], popping_puyos[len(popping_puyos) / 2][1]))
				
					var chain_position = Vector2(0, 0)
					for p in popping_puyos:
						chain_position += Vector2(p[0], p[1])
					chain_position /= len(popping_puyos)
					chain_position.x *= 64
					chain_position.y *= 60
					
					$Chain.rect_position = chain_position + Vector2(-200, -80) 
					
					chain_text_timer = chain_text_duration
					
				
				
				if popping_animation_timer == 0 && !has_pops && len(falling_puyos) == 0:
					puyo_value = 0
					score_increase = 0
					score_multiplier = 1
					current_chain_burst = 1
					if !in_zone:
						current_chain = 1
					
					
					
					if garbage_queue && drop_garbage && !in_zone:
						var max_falled = false
						if garbage_queue >= 30:
							#$Character/Chants/heavydamage.play()
							max_falled = true
						elif garbage_queue > 6:
							#$Character/Chants/lightdamage.play()
							pass
						
						for i in range(min(garbage_queue / 6, 5)):
							if max_falled:
								for j in range(6):
									create_falling_puyo(Vector2(j, -i), -1, GARBAGE_GRAVITY[j])
							else:
								for j in range(6):
									create_falling_puyo(Vector2(j, -i), -1)
						
						if !max_falled:
							for i in range(garbage_queue % 6):
								create_falling_puyo(Vector2(garbage_columns[0], -garbage_queue / 6), -1)
								garbage_columns.pop_front()
								if len(garbage_columns) == 0:
									garbage_columns = [0,1,2,3,4,5]
									garbage_columns.shuffle()
								
						garbage_queue -= 30
						
						
						
						
						garbage_queue = max(garbage_queue, 0)
						
						drop_garbage = false
					
					else:
						get_parent().lock_garbage(player)
						update_board_height()
						
						if is_solid(2, 1) || is_solid(3,1):
							win_lose = -1
						elif get_parent().is_opponent_lost(player):
							win_lose = 1
						else:
							if zone_timer <= 0 && in_zone:
								exit_zone()
								
							elif zone_meter >= zone_goal && !in_zone:
								enter_zone()
							
							create_new_puyo()
							
							
						frame_number = 0
		
				if popping_animation_timer:
					popping_animation_timer -= 1
			
		if chain_text_timer <= 0:
			$Chain.visible = false
		chain_text_timer -= 1
		
		if in_zone:
			zone_timer -= 1/60.0
		

func enter_zone():
	current_chain_burst = 1
	in_zone = true
	$Se/enterzone.play()
	$ZoneAnimations/ZoneEnterExit.play('enter')
	$BurstMeter/ZoneAnimation.play('gague_enter')

func exit_zone():
	in_zone = false
	zone_timer = 20
	zone_meter = starting_zone_meter
	current_chain = 1
	
	$BurstMeter/ZoneAnimation.play('gague_exit')
	
	
	if garbage_queue > 0:
		get_parent().counter(player)
		zone_meter += 1
		garbage_queue -= burst_garbage
		if incoming_garbage > 0:
			incoming_garbage += garbage_queue
			garbage_queue = 0
			if incoming_garbage <= 0:
				attack_power = -incoming_garbage
				incoming_garbage = 0
		elif garbage_queue <= 0:
			attack_power = -garbage_queue
	elif incoming_garbage > 0:
		get_parent().counter(player)
		zone_meter += 1
		incoming_garbage -= burst_garbage
		if incoming_garbage <= 0:
			attack_power = -incoming_garbage
			incoming_garbage = 0
	else:
		attack_power += burst_garbage
		
				
	if attack_power > 0:
		get_parent().send_garbage(attack_power, player)
		get_parent().lock_garbage(player)
	
	burst_garbage = 0

var input_timer = 0
var inputs = []
var DAS = 8
var ARR = 2


func get_player_input():
	
	if input_timer < 0:
		input_timer = 0
	
	if Input.is_action_just_pressed("left" + player_string):
		inputs.append('l')
		
		input_timer = DAS
	
	elif Input.is_action_pressed("left" + player_string) && input_timer == 0:
		inputs.append('l')
		input_timer = ARR
			
	if Input.is_action_just_pressed("right" + player_string):
		inputs.append('r')
		input_timer = DAS
	
	elif Input.is_action_pressed("right" + player_string) && input_timer == 0:
		inputs.append('r')
		input_timer = ARR
	
	input_timer -= 1
	
	
	if Input.is_action_just_pressed("ccw" + player_string):
		inputs.append('ccw')
	if Input.is_action_just_pressed("cw" + player_string):
		inputs.append('cw')

	
	if Input.is_action_pressed('down' + player_string):
		inputs.append('d')


func move_piece_lr():
	#  && fmod(current_puyo.position.y, 1.0) > 0.5)
	if 'l' in inputs:
		var can_move = true
		for p in current_puyo.slave_puyos + [[Vector2(0,0),0]]:
			if is_solid(current_puyo.position.x + p[0].x - 1, current_puyo.position.y + p[0].y) || (is_solid(current_puyo.position.x + p[0].x - 1, current_puyo.position.y + p[0].y + 1) && fmod(current_puyo.position.y, 1.0) >= 0.5):
				can_move = false
		if can_move:
			current_puyo.position.x -= 1
			current_puyo.movement_animation_timer = -4
			$Se/move.play()
			
	if 'r' in inputs:
		var can_move = true
		for p in current_puyo.slave_puyos + [[Vector2(0,0),0]]:
			if is_solid(current_puyo.position.x + p[0].x + 1, current_puyo.position.y + p[0].y) || (is_solid(current_puyo.position.x + p[0].x + 1, current_puyo.position.y + p[0].y + 1) && fmod(current_puyo.position.y, 1.0) >= 0.5):
				can_move = false
		if can_move:
			current_puyo.position.x += 1
			current_puyo.movement_animation_timer = 4
			$Se/move.play()
	
	
			
# TODO: Impliment double rotation when placing blocks is done

func dr(rotated):
	if rotation_timer < 0:
		rotated = 2
		current_puyo.position.y -= 1
		rotation_timer = 0
		current_puyo.double_rotation = true
	# Start double rotate timer
	else:
		rotation_timer = -dr_window
		$Se/rotate.stop()
		# We didn't rotate, reset timer to 0 if we just started the timer
		if current_puyo.rotation_animation_timer == -8:
			current_puyo.rotation_animation_timer = 0

func has_slave(vector):
	for p in current_puyo.slave_puyos:
		if vector == p[0]:
			return true
	return false


var rotation_timer = 0
var dr_window = 40
	
func rotate_piece():
	# WIP? Something is wrong with climbing, fix
	if 'ccw' in inputs:
		
		if current_puyo.type < 3:
			
			var rotated = 0
			if is_solid(current_puyo.position.x - 1, floor(current_puyo.position.y - 0.5)) && has_slave(Vector2(0, -1)):
				if !is_solid(current_puyo.position.x + 1, floor(current_puyo.position.y - 0.5)):
					rotated = 1
					current_puyo.position.x += 1
					current_puyo.movement_animation_timer = 4
				
				elif current_puyo.type == 0:
					if rotation_timer < 0:
						rotated = 2
						rotation_timer = 0
						current_puyo.double_rotation = true
						current_puyo.position.y -= 1
					# Start double rotate timer
					else:
						rotated = 0
						rotation_timer = -dr_window
				else:
					rotated = 0
					
			elif is_solid(current_puyo.position.x + 1, floor(current_puyo.position.y - 0.5) + 1) && has_slave(Vector2(0, 1)):
				if !is_solid(current_puyo.position.x - 1, floor(current_puyo.position.y - 0.5) + 1):
					rotated = 1
					current_puyo.position.x -= 1
					current_puyo.movement_animation_timer = -4
					
				elif current_puyo.type == 0:
					if rotation_timer < 0:
						rotated = 2
						rotation_timer = 0
						current_puyo.double_rotation = true
						current_puyo.position.y += 1
					# Start double rotate timer
					else:
						rotated = 0
						rotation_timer = -dr_window
				else:
					rotated = 0
					
			elif (is_solid(current_puyo.position.x, floor(current_puyo.position.y - 0.0000001) + 2) && has_slave(Vector2(-1, 0))):
				rotated = 1
				current_puyo.position.y = floor(current_puyo.position.y - 0.0000001)
			else:
				rotated = 1
			
			
			if rotated == 1:
				current_puyo.rotation -= 1
				current_puyo.rotation_animation_timer = -8
				for p in current_puyo.slave_puyos:
					p[0] = p[0].rotated(-TAU/4).round()
				$Se/rotate.play()
			elif rotated == 2:
				current_puyo.rotation -= 2
				current_puyo.rotation_animation_timer = -8
				for p in current_puyo.slave_puyos:
					p[0] = -p[0].round()
				$Se/rotate.play()
				
		elif current_puyo.type == 3:
			current_puyo.position -= SWIRL_ROTATION_OFFSETS[(current_puyo.rotation - 1 + 4) % 4]
			for i in range(3):
				current_puyo.slave_puyos[i][0] += -SWIRL_ROTATION_OFFSETS[(current_puyo.rotation + i + 4) % 4] + SWIRL_ROTATION_OFFSETS[(current_puyo.rotation - 1 + 4) % 4]
			$Se/rotate.play()
			current_puyo.rotation -= 1
			current_puyo.rotation_animation_timer = -8
		
		# BIg bllob
		else:
			current_puyo.c1 = (current_puyo.c1 - 1 + colour_count - 1) % colour_count + 1
		
	if 'cw' in inputs:
		
		if current_puyo.type < 3:
			var rotated = 0
			if is_solid(current_puyo.position.x + 1, floor(current_puyo.position.y - 0.5)) && has_slave(Vector2(0, -1)):
				if !is_solid(current_puyo.position.x - 1, floor(current_puyo.position.y - 0.5)):
					rotated = 1
					current_puyo.position.x -= 1
					current_puyo.movement_animation_timer = -4
				
				elif current_puyo.type == 0:
					if rotation_timer > 0:
						rotated = 2
						rotation_timer = 0
						current_puyo.double_rotation = true
						current_puyo.position.y -= 1
					# Start double rotate timer
					else:
						rotated = 0
						rotation_timer = dr_window
				else:
					rotated = 0
					
			elif is_solid(current_puyo.position.x - 1, floor(current_puyo.position.y - 0.5) + 1) && has_slave(Vector2(0, 1)):
				if !is_solid(current_puyo.position.x + 1, floor(current_puyo.position.y - 0.5) + 1):
					rotated = 1
					current_puyo.position.x += 1
					current_puyo.movement_animation_timer = 4
					
				elif current_puyo.type == 0:
					if rotation_timer > 0:
						rotated = 2
						rotation_timer = 0
						current_puyo.double_rotation = true
						current_puyo.position.y += 1
					# Start double rotate timer
					else:
						rotated = 0
						rotation_timer = dr_window
				else:
					rotated = 0
					
			elif is_solid(current_puyo.position.x, floor(current_puyo.position.y - 0.0000001) + 2) && has_slave(Vector2(1, 0)):
				rotated = 1
				current_puyo.position.y = floor(current_puyo.position.y - 0.0000001)
			else:
				rotated = 1
			
			
			if rotated == 1:
				current_puyo.rotation += 1
				current_puyo.rotation_animation_timer = 8
				for p in current_puyo.slave_puyos:
					p[0] = p[0].rotated(TAU/4).round()
				$Se/rotate.play()
			elif rotated == 2:
				current_puyo.rotation += 2
				current_puyo.rotation_animation_timer = 8
				for p in current_puyo.slave_puyos:
					p[0] = -p[0].round()
				$Se/rotate.play()
			
		elif current_puyo.type == 3:
			current_puyo.position += SWIRL_ROTATION_OFFSETS[current_puyo.rotation]
			for i in range(3):
				current_puyo.slave_puyos[i][0] += SWIRL_ROTATION_OFFSETS[(current_puyo.rotation + i + 1) % 4] - SWIRL_ROTATION_OFFSETS[current_puyo.rotation]
			$Se/rotate.play()
			current_puyo.rotation += 1
			current_puyo.rotation_animation_timer = 8
	
		else:
			current_puyo.c1 = (current_puyo.c1 + 1 + colour_count - 1) % colour_count + 1
	
	current_puyo.rotation = (current_puyo.rotation + 4) % 4
	
	rotation_timer -= sign(rotation_timer)
	
	

var fall_speed = 0.03125
var softdrop_speed = 0.5

func fall_piece():
	current_puyo.position.y += fall_speed
	if 'd' in inputs:
		current_puyo.position.y += softdrop_speed - fall_speed
func land_piece():
	# If we are clipping with the piece below, nudge back up
	var landed = false
	
	for p in current_puyo.slave_puyos + [[Vector2(0, 0), 0]]:
		if is_solid(current_puyo.position.x + p[0].x, floor(current_puyo.position.y + 1) + p[0].y):
			landed = true
			break
	
	if landed:
		current_puyo.position.y = floor(current_puyo.position.y)
		current_puyo.grounded = true
		current_puyo.ground_timer -= 1
		if 'd' in inputs || current_puyo.floor_kicks <= 0:
			current_puyo.ground_timer = 0
		if 'd' in inputs:
			$Se/down.play()
	else:
		current_puyo.grounded = false
	
		
	if current_puyo.ground_timer <= 0:
		current_puyo.locked = true
		
	if current_puyo.locked && current_puyo.rotation_animation_timer == 0:
		for p in current_puyo.slave_puyos + [[Vector2(0, 0), 0]]:
			var colour = current_puyo.c1
			if p[1] == 1:
				colour = current_puyo.c2
			create_falling_puyo(current_puyo.position + p[0], colour)
			
			
		
		current_puyo = null
		drop_garbage = true
		potential_pops = []
		
func fall_and_land_falling_puyos():
	var i = 0
	while i < len(falling_puyos):
		if !falling_puyos[i].grounded:
			falling_puyos[i].position.y += falling_puyos[i].velocity
		if is_solid(falling_puyos[i].position.x, floor(falling_puyos[i].position.y) + 1):
			if falling_puyos[i].animation <= 0:
				set_colour(falling_puyos[i].position.x, floor(falling_puyos[i].position.y),  falling_puyos[i].colour)
				falling_puyos.remove(i)
			else:
				# AAAAAAAAAAAAAAAAA fucking shoddy hackjob, this creates a ghost block that the puyos can't phase through
				set_colour(falling_puyos[i].position.x, floor(falling_puyos[i].position.y),  -2)
				falling_puyos[i].position.y = floor(falling_puyos[i].position.y)
				falling_puyos[i].animation -= 1
				falling_puyos[i].grounded = true
				i += 1
		else:
			falling_puyos[i].velocity += falling_puyos[i].gravity
			falling_puyos[i].velocity = min(falling_puyos[i].velocity, falling_puyos[i].TERMINAL_VELOCITY)
			i += 1


func update_board_height():
	for i in range(6):
		var height = 0
		while !is_solid(i, height):
			height += 1
		board_heights[i] = height

func find_piece_in_group(piece, group):
	for i in range(len(group)):
		if group[i][1] == piece[1] && group[i][2] == piece[2]:
			return true
	return false
	
func is_puyo_popping(x, y):
	for i in popping_puyos:
		if i[0] == x && i[1] == y:
			return true
	return false

func is_puyo_potentially_popping(x, y):
	for i in potential_pops:
		if i[0] == x && i[1] == y:
			return true
	return false

# Obsolete, duplicate in ChainSim
#func find_groups():
#	# List of groups, each group is an array, and each item is also an array in the form of [colour, x, y]
#	var matches = []
#	# Iterate over each cell on the board
#	for i in range(1, get_parent().board_size.y):
#		for j in range(get_parent().board_size.x):
#			# If the cell has a colour puyo
#			if get_colour(j, i) > 0:
#				# Touching ajacent pair flag
#				var has_match = false
#				# Iterating over each group
#				var group = 0
#				while group < len(matches):
#					# If the group is the same colour as the curent piece
#					if matches[group][0][0] == get_colour(j, i):
#						# Iterate over each piece
#						for piece in matches[group]:
#							# Same row and 1 height difference or same column and 1 row difference
#							if (piece[1] == j && piece[2] + 1 == i) || (piece[2] == i && piece[1] + 1 == j):
#								# If currently unmatched, aadd to group
#								if !has_match:
#									matches[group].append([get_colour(j, i), j, i])
#									has_match = true
#								# Otherwise, we have a merge
#								else:
#									# We only check ahead of our current group
#									for g in range(0, group):
#										if find_piece_in_group([get_colour(j, i), j, i], matches[g]):
#											for p in matches[g]:
#												matches[group].append(p)
#											matches.remove(g)
#											break
#												
#								break
#					group += 1
#					
#				# If no match has been found, create a new group
#				if !has_match:
#					matches.append([[get_colour(j, i), j, i]])
#
#	return matches
#	

func find_lowest_pop(matches):
	var peaks = [0, 0, 0, 0, 0, 0]
	# Find the lowest hole, 
	for i in range(get_parent().board_size.x):
		for j in range(get_parent().board_size.y - 1, -1, -1):
			if !is_solid(i,j):
				peaks[i] = j 
				break
	
	
	return peaks
		

func cascade_puyos(peaks):
	for j in range(get_parent().board_size.x - 1, -1, -1):
		for i in range(peaks[j] - 1, -1, -1):
			if get_colour(j, i) != 0:
				# Create falling puyos
				create_falling_puyo(Vector2(j, i), get_colour(j, i))
				set_colour(j, i, 0)
				




# Drawing

var garbage_flash_timer = 0
var garbage_flash_duration = 4

func _process(delta):
	
	garbage_flash_timer += delta
	if garbage_flash_timer > garbage_flash_duration:
		garbage_flash_timer -= garbage_flash_duration
	
	spinning_x_frame += delta 
	if spinning_x_frame > spinning_x_animation_duration:
		spinning_x_frame -= spinning_x_animation_duration
	
	potential_pop_flash_timer += delta
	if potential_pop_flash_timer > popping_animation_duration:
		potential_pop_flash_timer -= potential_pop_flash_duration
		
		
	update()
		

func _draw():
	if started:
		draw_x()
		draw_board()
		# If piece exists
		if current_puyo:
			draw_current_puyo()
		else:
			draw_falling_puyos()
		draw_next_puyos()
		draw_frame()
		draw_incoming_garbage()
		
	var c = [Color(0,0,0,1), Color(1,0,0,1), Color(0,1,0,1), Color(0,0,1,1)]
	
	draw_rect(Rect2(400, 0, 20, 20), c[state])
	
	
	update_score()
	update_zone_ui()
	
	
const x_positions = [Vector2(136, 0), Vector2(200, 0)]
const x_frames = [26/60.0,36/60.0,38/60.0,40/60.0,42/60.0,44/60.0,46/60.0,48/60.0,50/60.0,52/60.0,54/60.0,56/60.0,1]
const x_srcpos = [5, 6, 5, 6, 7, 8, 9, 9, 8, 7, 6, 5, 6]
const x_parity = [1,-1, 1, 1, 1, 1, 1,-1,-1,-1,-1, 1, 1]

func draw_x():
	
	
	for i in range(len(x_frames)):
		if spinning_x_frame < x_frames[i]:
			for position in x_positions:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(position, Vector2(x_parity[i] * 64, 64)), Rect2(Vector2(x_srcpos[i], 11) * 72, Vector2(64, 64)))
			break
	
	


const GHOST_LOCATIONS = [Rect2(15*72, 6*72, 64, 64), Rect2(14*72, 7*72, 64, 64), Rect2(15*72, 7*72, 64, 64), Rect2(14*72, 8*72, 64, 64), Rect2(15*72, 8*72, 64, 64)]
const POP_LOCATIONS = [Rect2(0, 12*72, 64, 64), Rect2(0, 13*72, 64, 64),Rect2(72*2, 12*72, 64, 64),Rect2(72*2, 13*72, 64, 64),Rect2(72*4, 12*72, 64, 64)]
const POPPED_LOCATIONS_1 = [Rect2(6*72, 10*72, 64, 64), Rect2(8*72, 10*72, 64, 64), Rect2(10*72, 10*72, 64, 64), Rect2(12*72, 10*72, 64, 64),Rect2(14*72, 10*72, 64, 64)]
const POPPED_LOCATIONS_2 = [Rect2(7*72, 10*72, 64, 64), Rect2(9*72, 10*72, 64, 64), Rect2(11*72, 10*72, 64, 64), Rect2(13*72, 10*72, 64, 64),Rect2(15*72, 10*72, 64, 64)]


func draw_board():
	for i in range(1, get_parent().board_size.y):
		for j in range(get_parent().board_size.x):
			var colour = get_colour(j, i)
			
			var puyo_popping = is_puyo_popping(j, i)
			# Colour Puyos
			if colour > 0:
				if puyo_popping && popping_animation_timer < 3:
					draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), POPPED_LOCATIONS_2[colour-1])
				elif puyo_popping && popping_animation_timer < 6:
					draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), POPPED_LOCATIONS_1[colour-1])
				elif puyo_popping && popping_animation_timer < 12:
					draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), POP_LOCATIONS[colour-1])
			
				elif !puyo_popping || (popping_animation_timer/2) % 2 == 0:
					var arrangement = 0
					
					if get_colour(j, i + 1) == colour:
						arrangement += 1
					if i > 1 && get_colour(j, i - 1) == colour:
						arrangement += 2
					if get_colour(j + 1, i) == colour:
						arrangement += 4
					if get_colour(j - 1, i) == colour:
						arrangement += 8
					
					var cm = Color(1, 1, 1, 1)
					if is_puyo_potentially_popping(j, i):
						cm += Color(0.1, 0.1, 0.1) * (sin(potential_pop_flash_timer * TAU) + 1)
					
					draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(Vector2(arrangement, colour - 1) * 72, Vector2(64, 64)), cm)
		
			# Garbage Puyos
			elif colour == -1:
				# Ah shit, can't be bothered to do garbage clumping right now, guess I'll figure it out later
				if j != 5 && false:
					if get_colour(j, i + 1) == -1 && get_colour(j + 1, i + 1) == -1 && get_colour(j + 1, i) == -1:
						draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(128, 128)), Rect2(Vector2(0, 7) * 72, Vector2(128, 128)))
					else:
						draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(Vector2(18, 1) * 72, Vector2(64, 64)))

				else:
					if !puyo_popping || ((popping_animation_timer/2) % 2 == 0 && popping_animation_timer > 11):
						if garbage_flash_timer < garbage_flash_duration - 0.2:
							draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(Vector2(18, 1) * 72, Vector2(64, 64)))
						elif garbage_flash_timer < garbage_flash_duration - 0.15:
							draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(Vector2(19, 1) * 72, Vector2(64, 64)))
						elif garbage_flash_timer < garbage_flash_duration - 0.05:
							draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(Vector2(20, 1) * 72, Vector2(64, 64)))
						elif garbage_flash_timer < garbage_flash_duration:
							draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(j * 64, (i - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(Vector2(19, 1) * 72, Vector2(64, 64)))
						
	
			
const SQUASH_RECTS = [Rect2(864, 648, 64, 64), Rect2(1008, 648, 64, 64), Rect2(0, 720, 64, 64), Rect2(144, 720, 64, 64), Rect2(288, 720, 64, 64)]
const STRETCH_RECTS = [Rect2(864 + 72, 648, 64, 64), Rect2(1008 + 72, 648, 64, 64), Rect2(72, 720, 64, 64), Rect2(144, 720, 64, 64), Rect2(288 + 72, 720, 64, 64)]

const FACE_RECTS = [Rect2(72, 864, 64, 64), Rect2(72, 936, 64, 64), Rect2(216, 864, 64, 64), Rect2(216, 936, 64, 64), Rect2(360, 864, 64, 64)]
const FACE_OFFSETS = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 1), Vector2(0, 0), Vector2(0, -2)]
const FACE_DISTANCES = [1, 1, 0.9, 0.7, 0.95]

func draw_current_puyo():
	
	var puyo_global = [[current_puyo.position.x, current_puyo.position.y, current_puyo.c1]]
	for puyo in current_puyo.slave_puyos:
		var colour = current_puyo.c2
		if puyo[1] == 0:
			colour = current_puyo.c1
		puyo_global.append([current_puyo.position.x + puyo[0].x, current_puyo.position.y + puyo[0].y, colour])
	
	var ghost_locations = ChainSim.get_land_locations(board_heights, puyo_global)
	
	for puyo in ghost_locations:
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(puyo[0] * 64 + 8, (puyo[1] - get_parent().hidden_rows - 1) * 60 , 64, 64), GHOST_LOCATIONS[puyo[2] - 1])
		
	
	if current_puyo.type == -1:
		# Draw ghost pieces
		if current_puyo.rotation % 2 != 0:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(current_puyo.position.x * 64 + 8, (board_heights[current_puyo.position.x] - get_parent().hidden_rows - 1) * 60 , 64, 64), GHOST_LOCATIONS[current_puyo.c1 - 1])
			draw_texture_rect_region(get_parent().puyo_texture, Rect2((current_puyo.position.x + PUYO_OFFSETS[current_puyo.rotation].x) * 64 + 8, (board_heights[current_puyo.position.x + PUYO_OFFSETS[current_puyo.rotation].x] - get_parent().hidden_rows - 1) * 60, 64, 64), GHOST_LOCATIONS[current_puyo.c2 - 1])
		elif current_puyo.rotation == 0:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(current_puyo.position.x * 64 + 8, (board_heights[current_puyo.position.x] - get_parent().hidden_rows - 1) * 60 , 64, 64), GHOST_LOCATIONS[current_puyo.c1 - 1])
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(current_puyo.position.x * 64 + 8, (board_heights[current_puyo.position.x] - get_parent().hidden_rows - 1 - 1) * 60 , 64, 64), GHOST_LOCATIONS[current_puyo.c2 - 1])
		else:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(current_puyo.position.x * 64 + 8, (board_heights[current_puyo.position.x] - get_parent().hidden_rows - 1) * 60 , 64, 64), GHOST_LOCATIONS[current_puyo.c2 - 1])
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(current_puyo.position.x * 64 + 8, (board_heights[current_puyo.position.x] - get_parent().hidden_rows - 1 - 1) * 60 , 64, 64), GHOST_LOCATIONS[current_puyo.c1 - 1])

	var rotation_time = 8.0
	if current_puyo.double_rotation:
		rotation_time = 4.0

	if (current_puyo.type == 0 && current_puyo.c1 == current_puyo.c2) || (current_puyo.type == 1 && current_puyo.c1 != current_puyo.c2):
		# Draw body
		var pos = Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0)) * 64, (current_puyo.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0) + Vector2(32, 30.2083333)
		draw_set_transform_matrix(Transform2D((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU/4, pos))
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(-Vector2(32, 90), Vector2(64, 128)), Rect2(72 * (current_puyo.c1 - 1), 360, 64, 128))
		draw_set_transform(Vector2(0, 0), 0, Vector2(1, 1))
		# Draw face
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + cos((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) * FACE_DISTANCES[current_puyo.c1 - 1]) * 64 + FACE_OFFSETS[current_puyo.c1 - 1].x, (current_puyo.position.y + sin((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) *  FACE_DISTANCES[current_puyo.c1 - 1] - get_parent().hidden_rows) * 60 + FACE_OFFSETS[current_puyo.c1 - 1].y) + Vector2(8, 0), Vector2(64, 64)), FACE_RECTS[current_puyo.c1 - 1])
		
		if current_puyo.type == 1:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + cos((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4)) * 64, (current_puyo.position.y + sin((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (current_puyo.c2 - 1), 64, 64))
	
	elif current_puyo.type == 1 || (current_puyo.type == 2 && current_puyo.c1 == current_puyo.c2):
		# Draw body
		var pos = Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0)) * 64, (current_puyo.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0) + Vector2(32, 30.2083333)
		draw_set_transform_matrix(Transform2D((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU/4, pos))
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(-Vector2(32, 90), Vector2(128, 128)), Rect2(72 * (5 + 2 * (current_puyo.c1 - 1)), 360, 128, 128))
		draw_set_transform(Vector2(0, 0), 0, Vector2(1, 1))
		# Draw face
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + cos((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) * FACE_DISTANCES[current_puyo.c1 - 1]) * 64 + FACE_OFFSETS[current_puyo.c1 - 1].x, (current_puyo.position.y + sin((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) *  FACE_DISTANCES[current_puyo.c1 - 1] - get_parent().hidden_rows) * 60 + FACE_OFFSETS[current_puyo.c1 - 1].y) + Vector2(8, 0), Vector2(64, 64)), FACE_RECTS[current_puyo.c1 - 1])
		
	elif current_puyo.type == 2:
		var pos = Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0)) * 64, (current_puyo.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0) + Vector2(32, 30.2083333)
		draw_set_transform_matrix(Transform2D((current_puyo.rotation + 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU/4, pos))
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(-Vector2(32, 90), Vector2(64, 128)), Rect2(72 * (current_puyo.c1 - 1), 360, 64, 128))
		draw_set_transform(Vector2(0, 0), 0, Vector2(1, 1))
		# Draw face
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + cos((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) * FACE_DISTANCES[current_puyo.c1 - 1]) * 64 + FACE_OFFSETS[current_puyo.c1 - 1].x, (current_puyo.position.y + sin((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) *  FACE_DISTANCES[current_puyo.c1 - 1] - get_parent().hidden_rows) * 60 + FACE_OFFSETS[current_puyo.c1 - 1].y) + Vector2(8, 0), Vector2(64, 64)), FACE_RECTS[current_puyo.c1 - 1])
		
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + cos((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4)) * 64, (current_puyo.position.y + sin((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (current_puyo.c2 - 1), 64, 64))
		
	# Normal pair
	elif current_puyo.type == 0:
		if current_puyo.double_rotation:
			if player == 1:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) - 0.5 * cos((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4)) * 64, (current_puyo.position.y + (current_puyo.rotation - 1) * abs(current_puyo.rotation_animation_timer / rotation_time) - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (current_puyo.c1 - 1), 64, 64))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + 0.5 * cos((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4)) * 64, (current_puyo.position.y + (current_puyo.rotation - 1) * abs(current_puyo.rotation_animation_timer / rotation_time) + sin((current_puyo.rotation - 1 + (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (current_puyo.c2 - 1), 64, 64))
		else:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0)) * 64, (current_puyo.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (current_puyo.c1 - 1), 64, 64))
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0) + cos((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4)) * 64, (current_puyo.position.y + sin((current_puyo.rotation - 1 - (current_puyo.rotation_animation_timer / rotation_time)) * TAU / 4) - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (current_puyo.c2 - 1), 64, 64))
	
	elif current_puyo.type == 3:
		var pos = Vector2((current_puyo.position.x + SWIRL_CENTRE_OFFSETS[current_puyo.rotation].x - (current_puyo.movement_animation_timer / 4.0)) * 64, (current_puyo.position.y + SWIRL_CENTRE_OFFSETS[current_puyo.rotation].y - 1) * 60)
		draw_set_transform_matrix(Transform2D((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU * 0.25, pos))
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(-63, -60), Vector2(128, 128)), Rect2(72 * (6 + 2 * (current_puyo.c1 - 1)), 72 * 12, 128, 128))
		draw_set_transform_matrix(Transform2D((current_puyo.rotation - (current_puyo.rotation_animation_timer / rotation_time)) * TAU * 0.25 + PI, pos))
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(-63, -60), Vector2(128, 128)), Rect2(72 * (6 + 2 * (current_puyo.c2 - 1)), 72 * 12, 128, 128))
		draw_set_transform(Vector2(0, 0), 0, Vector2(1, 1))
	# Blob
	else:
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2((current_puyo.position.x - (current_puyo.movement_animation_timer / 4.0)) * 64, (current_puyo.position.y - 1 - get_parent().hidden_rows) * 60), Vector2(128, 128)), Rect2(72 * (2 + 2 * (current_puyo.c1 - 1)), 72 * 7, 128, 128))
		
			
			
func draw_falling_puyos():
	for p in falling_puyos:
		if p.colour > 0:
			if (p.animation/4) % 2 == 0:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(p.position.x * 64, (p.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(0, 72 * (p.colour - 1), 64, 64))
			elif(p.animation/4) % 4 == 3:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(p.position.x * 64, (p.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), SQUASH_RECTS[p.colour - 1])
			elif (p.animation/4) % 4 == 1:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(p.position.x * 64, (p.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), STRETCH_RECTS[p.colour - 1])
		
		elif p.colour == -1:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(Vector2(p.position.x * 64, (p.position.y - get_parent().hidden_rows) * 60) + Vector2(8, 0), Vector2(64, 64)), Rect2(18 * 72, 72, 64, 64))
	

# WIP rendering is a little broken, fix

func draw_next_puyos():
	
	var x_position = 525
	if player == 2:
		x_position = -164
	
	for i in range(len(puyo_queue)):
		var puyo = puyo_queue[i]
		if puyo[2] == 0:
			if puyo[0] != puyo[1]:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position, 100 + 200 * i, 64, 64),  Rect2(0, 72 * (puyo[0] - 1), 64, 64))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position, 100 + 200 * i - 60, 64, 64),  Rect2(0, 72 * (puyo[1] - 1), 64, 64))
			else:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position, 100 + 200 * i - 60, 64, 128), Rect2(72 * (puyo[0] - 1), 360, 64, 128))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position + FACE_OFFSETS[puyo[0] - 1].x, 100 + 200 * i - 60 * FACE_DISTANCES[puyo[0] - 1] + FACE_OFFSETS[puyo[0] - 1].x, 64, 64), FACE_RECTS[puyo[0] - 1])
		elif puyo[2] == 1:
			if puyo[0] != puyo[1]:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32, 100 + 200 * i - 60, 64, 128), Rect2(72 * (puyo[0] - 1), 360, 64, 128))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32 + FACE_OFFSETS[puyo[0] - 1].x, 100 + 200 * i - 60 * FACE_DISTANCES[puyo[0] - 1] + FACE_OFFSETS[puyo[0] - 1].x, 64, 64), FACE_RECTS[puyo[0] - 1])
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32 + 64, 100 + 200 * i , 64, 64),  Rect2(0, 72 * (puyo[1] - 1), 64, 64))
			else:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32, 100 + 200 * i - 60, 128, 128), Rect2(72 * (5 + 2 * (puyo[0] - 1)), 360, 128, 128))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32 + FACE_OFFSETS[puyo[0] - 1].x, 100 + 200 * i - 60 * FACE_DISTANCES[puyo[0] - 1] + FACE_OFFSETS[puyo[0] - 1].x, 64, 64), FACE_RECTS[puyo[0] - 1])
		elif puyo[2] == 2:
			if puyo[0] != puyo[1]:
				draw_set_transform_matrix(Transform2D(TAU/4, Vector2(x_position , 100 + 200 * i + 32)))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(-32, -60 - 30 , 64, 128), Rect2(72 * (puyo[0] - 1), 360, 64, 128))
				draw_set_transform(Vector2(0, 0), 0, Vector2(1, 1))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32 + FACE_OFFSETS[puyo[0] - 1].x + 64 * FACE_DISTANCES[puyo[0] - 1], 100 + 200 * i + FACE_OFFSETS[puyo[0] - 1].x, 64, 64), FACE_RECTS[puyo[0] - 1])
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32, 100 + 200 * i - 60 , 64, 64),  Rect2(0, 72 * (puyo[1] - 1), 64, 64))
			else:
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32, 100 + 200 * i - 60, 128, 128), Rect2(72 * (5 + 2 * (puyo[0] - 1)), 360, 128, 128))
				draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32 + FACE_OFFSETS[puyo[0] - 1].x, 100 + 200 * i - 60 * FACE_DISTANCES[puyo[0] - 1] + FACE_OFFSETS[puyo[0] - 1].x, 64, 64), FACE_RECTS[puyo[0] - 1])
		elif puyo[2] == 3:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 31, 100 + 200 * i - 60, 128, 128), Rect2(72 * (6 + 2 * (puyo[0] - 1)), 72 * 12, 128, 128))
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 33, 100 + 200 * i - 60, -128, -120), Rect2(72 * (6 + 2 * (puyo[1] - 1)), 72 * 12, 128, 120))
		# Blob
		else:
			draw_texture_rect_region(get_parent().puyo_texture, Rect2(x_position - 32, 100 + 200 * i - 60, 128, 128), Rect2(72 * (2 + 2 * (puyo[0] - 1)), 72 * 7, 128, 128))
			
		
	
func draw_frame():
	draw_texture_rect_region(frame_texture, Rect2(-22, -56, 450, 60), Rect2(0,0,450,60))

const garbage_values = [1, 6, 30, 180, 360, 720, 1440]
const symbol_rects = [Rect2(1080, 792, 64, 64), Rect2(1008, 792, 64, 64), Rect2(936, 792, 64, 64), Rect2(864, 792, 64, 64), Rect2(792, 792, 64, 64), Rect2(720, 792, 64, 64), Rect2(864, 504 , 128, 128)]

func draw_incoming_garbage():
	var total_garbage = garbage_queue + incoming_garbage
	var symbols = [] # 0: single, 1: row, 2: rock, 3: star, 4: moon, 5: crown, 6: comet
	for i in range(len(garbage_values) -1, -1, -1):
		for j in range(total_garbage / garbage_values[i]):
			symbols.append(i)
			total_garbage -= garbage_values[i]
	
	var modulate = Color(1,1,1,1)
	if in_zone:
		modulate = Color(0.5, 0.5, 0.5, 1)
	
	for i in range(min(len(symbols), 6)):
		draw_texture_rect_region(get_parent().puyo_texture, Rect2(i * 64 - 32 * (symbols[i] / 6) + 8, - 72 - 32 * (symbols[i] / 6), 64 + 64 * (symbols[i] / 6), 64 + 64 * (symbols[i] / 6)), symbol_rects[symbols[i]], modulate)


func update_score():
	var score_string = ''
	if popping_animation_timer == 0:
		score_string = str(score)
		score_string = score_string.replace('0', 'O')
		if len(score_string) < 8:
			for i in range (8 - len(score_string)) :
				score_string = 'O' + score_string
	else:
		score_string = str(score_multiplier)
		if len(score_string) < 3:
			for i in range (3 - len(score_string)) :
				score_string = ' ' + score_string
		score_string = str(puyo_value) + '× ' + score_string
		score_string = score_string.replace('0', 'O')
		
	$Score.bbcode_text = '[right]' + score_string + '[/right]'


func update_zone_ui():
	$Timer.bbcode_text = '[center]' + str(ceil(max(zone_timer, 0))).replace('0', 'O') + '[/center]'
	$ZoneProgress.value = zone_meter
	if burst_garbage <= 6:
		$BurstMeter/Gague1.value = 0.05555555555 * burst_garbage
		$BurstMeter/Gague2.value = 0
		$BurstMeter/Gague3.value = 0
	elif burst_garbage <= 18:
		$BurstMeter/Gague1.value = 0.3333333333333333 + burst_garbage * 0.03472222222 - 0.20833333332
		$BurstMeter/Gague2.value = 0
		$BurstMeter/Gague3.value = 0
	elif burst_garbage <= 36:
		$BurstMeter/Gague1.value = 0.75 + burst_garbage * 0.01388888888 - 0.25
		$BurstMeter/Gague2.value = 0
		$BurstMeter/Gague3.value = 0
	elif burst_garbage <= 90:
		$BurstMeter/Gague1.value = 1
		$BurstMeter/Gague2.value = 0
		$BurstMeter/Gague3.value = 0

