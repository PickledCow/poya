extends Node2D

var puyo_texture = preload("res://puyo_beta.png")


var board_size = Vector2(6, 13)
var hidden_rows = 1

var pop_goal = 4

var continuous_offsetting = true
var target_points = 120

var score = [0, 0]

# Colour pools for puyo

var cp = []

func _ready():
	randomize()
	generate_colours()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if $Player2.win_lose == -1:
			score[0] += 1
		elif $Player1.win_lose == -1:
			score[1] += 1
		update_score()
		generate_colours()
		$Player1.reset()
		$Player2.reset()

func shuffle_array(arr):
	var shuffled_array = []
	while len(arr) > 0:
		var item = randi() % len(arr)
		shuffled_array.append(arr[item])
		arr.remove(item)
	
	return shuffled_array

func generate_colours():
	cp = []
	var cp3 = []
	for i in range(85):
		cp3.append(1)
		cp3.append(2)
		cp3.append(3)
	
	cp3.append(randi()%3 + 1)
	
	cp3 = shuffle_array(cp3)
	
	cp.append(cp3)
	
	var cp4 = []
	for i in range(64):
		cp4.append(1)
		cp4.append(2)
		cp4.append(3)
		cp4.append(4)
	
	cp4 = shuffle_array(cp4)
	
	for i in range(4):
		cp4[i] = cp3[i]
	
	
	cp.append(cp4)
	
	var cp5 = []
	for i in range(51):
		cp5.append(1)
		cp5.append(2)
		cp5.append(3)
		cp5.append(4)
		cp5.append(5)
	cp5.append(randi()%5 + 1)
	
	cp5 = shuffle_array(cp5)
	
	for i in range(8):
		cp5[i] = cp4[i]
	
	cp.append(cp5)
	
# There is some port bias, might want to fix it

func send_garbage(amount, pid):
	if pid == 1:
		$Player2.incoming_garbage += amount
	elif pid == 2:
		$Player1.incoming_garbage += amount

func lock_garbage(pid):
	if pid == 1:
		$Player2.garbage_queue += $Player2.incoming_garbage
		$Player2.incoming_garbage = 0
	elif pid == 2:
		$Player1.garbage_queue += $Player1.incoming_garbage
		$Player1.incoming_garbage = 0

func counter(pid):
	if pid == 1:
		if !$Player2.in_zone:
			$Player2.zone_timer = min($Player2.zone_timer + 1, 45)
	elif pid == 2:
		if !$Player1.in_zone:
			$Player1.zone_timer = min($Player1.zone_timer + 1, 45)
	
func is_opponent_lost(pid):
	if pid == 1:
		if $Player2.win_lose == -1:
			return true
	elif pid == 2:
		if $Player1.win_lose == -1:
			return true
	
	return false


func update_score():
	var p1_text = str(score[0]).replace('0', 'O')
	var p2_text = str(score[1]).replace('0', 'O')

	while len(p1_text) > len(p2_text):
		p2_text += ' '
	
	while len(p2_text) > len(p1_text):
		p1_text = ' ' + p1_text
	
	$Score.bbcode_text = '[center]' + p1_text + '-' + p2_text

