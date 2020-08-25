// Word search shooter! Game by Intas

import "listUtil"

txtDisp = display(3)
sprDisp = display(4)
colDisp = display(7)

colDisp.color = color.black
text.color = color.white

// Create a green and red rectangle
// these will be the enemy and player's HP
gfx.fillRect(0, 0, 100, 25, color.green)
gfx.fillRect(0, 50, 100, 25, color.red)
playerHP = new Sprite
playerHP.image = gfx.getImage(0, 0, 100, 25)
playerHP.scale = [1, 1]
enemyHP = new Sprite
enemyHP.image = gfx.getImage(0, 50, 100, 25)
enemyHP.scale = [1, 1]

clear
gfx.clear

// -- Timer class --
Timer = {}

// Turns milliseconds into a formatted time mm:ss
Timer.formatMillis = function(t)
	m = floor((t / 60000) % 60)
	s = floor((t / 1000) % 60)
	mm = ""; ss = "";
	
	if m < 10 then
		mm = "0" + m
	else
		mm = m
	end if
	
	if s < 10 then
		ss = "0" + s
	else
		ss = s
	end if
	
	return mm + ":" + ss
end function

Timer.init = function()
	self.time = 0     // Time in milliseconds
	self.count = true // If the timer should count
end function

// Set the time in milliseconds
Timer.setTimer = function(min, sec=0)
	self.time = sec*1000 + min*60000
end function

Timer.update = function(dt)
	if not self.count then
		return null
	end if
	if self.time <= 0 then
		return true
	end if	
	self.time = self.time - 1000*dt
	return false
end function

// "Wrapper" for the formatMillis function
Timer.getTime = function()
	return self.formatMillis(self.time)
end function

// -- End of Timer class --

// -- UI class --
UI = {}

UI.offset = {"x": -3, "y": 0, "w": 3, "h": 0}

UI.buttons = {}
UI.inputs = {}

// Simple rectangle collision
UI.collision = function(x1,y1,w1,h1, x2,y2,w2,h2)
	return x1 < x2 + w2 and x1 + w1 > x2 and
	y1 < y2 + h2 and y1 + h1 > y2
end function

// Clear the buttons map
UI.reset = function()
	self.buttons = {}
end function

UI.Button = function(text, x, y, conf)
	pos = {
	"x": x + self.offset.x, "y": y + self.offset.y,
	"w": text.len*15 + self.offset.w,
	"h": 25+self.offset.h}
	
	// Set the default conf values
	if conf == null then conf = {}
	if not conf.hasIndex("bg") then conf["bg"] = color.gray
	if not conf.hasIndex("text") then conf["text"] = color.black
	if not conf.hasIndex("hovCol") then conf["hovCol"] = color.yellow		
	
	// When the function is called for the first time create
	// the button, otherwise check for mouse collision
	if not self.buttons.hasIndex(text) then
		self.buttons[text] = {"created": true, "hov": false, "pressed": false}
		gfx.fillRect(pos.x, pos.y, pos.w, pos.h, conf.bg)
		gfx.print(text, x, y, conf.text)
	else
		col = self.collision(mouse.x, mouse.y, 2, 2, pos.x, pos.y, pos.w, pos.h)
		// Was hovered but there's not collision
		if self.buttons[text].hov and not col then
			self.buttons[text].hov = false
			gfx.print(text, x, y, conf.text)
		end if
		if not col then return false
		// There is collision, so the
		// button must be currently hovered
		if not self.buttons[text].hov then
			self.buttons[text].hov = true
			gfx.print(text, x, y, conf.hovCol)
		end if
		// First wait for the mouse to be pressed
		if not self.buttons[text].pressed then
			self.buttons[text].pressed = mouse.button
		else
			// Now wait for the mouse to be released
			if not mouse.button and col then
				self.buttons[text].pressed = false
				return true
			end if
		end if
	end if
	// The only way to get to this point is when
	// the function is called for the first time,
	// so let's assume the button was not pressed
	return false
end function

// -- End of UI class --

// -- Helper functions --

// Create and play a sound
playSound = function(duration, freq, envelope, wave)
	sound = new Sound
	sound.init duration, freq, envelope
	sound.waveform = wave
	sound.play 0.5
end function

// Simple random function
rand = function(min, max)
	if min == null and max == null then
		// [0, 1]
		return rnd
	else if max == null then
		// [0, max]
		max = min
		min = 0
	end if
	// [min, max]
	return min+floor(rnd*(max+1))
end function

// -- End of helper functions --

Game = {}

Game.init = function(lvl)
	// Keep track of the x-y coords of the word list
	// so we can remove any word the player founds
	self.wordSelect = {"x": 10, "y": 20, "xbase": 10}
	
	self.wordsFound = 0
	
	// Enemy colors
	self.colors = [color.red, color.green, color.blue]
	self.color = self.colors[rand(self.colors.len-1)]
	
	self.letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	self.wordList = file.readLines("/sys/data/englishWords.txt")
	
	// Used for mouse collision with the letters
	self.hovered = {"x": -1, "y": -1, "oldColor": ""}
	
	// The body parts of the enemy are rectangles
	// The x-y values are based on the text display
	self.level = lvl
	self.body = {
	"head": {"x": 31, "y": 15, "w": 6, "h": 3},
	"body": {"x": 30, "y": 10, "w": 8, "h": 5},
	"leftarm":   {"x": 24, "y": 13, "w": 6, "h": 2},
	"lefthand":  {"x": 24, "y": 11, "w": 3, "h": 2},
	"rightarm":  {"x": 38, "y": 13, "w": 6, "h": 2},
	"righthand": {"x": 41, "y": 15, "w": 3, "h": 2},
	"leftleg":   {"x": 31, "y": 5,  "w": 3, "h": 5},
	"rightleg":  {"x": 34, "y": 5, "w": 3, "h": 5}}
	
	self.lettersOnScreen = []
	self.selectedLetters = []
	
	self.player = {"hp": 100}
	self.enemy = {"hp": 100}
	self.gameover = false
	self.levelComplete = false
end function

// Check if a given x-y coord is inside the enemy's body
Game.insideRect = function(x, y)
	for b in self.body.values
		if x >= b.x and x <= b.x+b.w and y >= b.y and y <= b.y+b.h then
			return true
		end if
	end for
	return false
end function

// Check if a word with a given orientation will
// fit into the enemy's body.
Game.wordFits = function(word, ori, x, y)
	for c in word
		if self.lettersOnScreen[y][x] != "-" then
			return false
		end if
		if ori == "hor" then
			x = x + 1
		else if ori == "ver" then
			y = y - 1
		else
			x = x + 1
			y = y - 1
		end if
	end for
	return true
end function

Game.generateGrid = function()
	self.words = []
	// First, insert random letters in the background
	// and "-" inside the enemy's body, this will be
	// useful when inserting the actual words
	for y in range(0, 25)
		pos = self.lettersOnScreen.len
		self.lettersOnScreen.push []
		for x in range(0, 67)
			if self.insideRect(x, y) then
				self.lettersOnScreen[pos].push "-"
			else
				letter = self.letters[rand(self.letters.len-1)]
				self.lettersOnScreen[pos].push letter
			end if
		end for
	end for
	
	// Now let's insert a random amount of words
	// into the enemy
	orientations = ["hor", "ver", "dia"]
	letters = []
	amount = rand(4, 6)
	for i in range(1, amount)
		pos = {"x": 0, "y": 0}
		insertedWord = false
		word = ""
		// Depending on the position and orientation,
		// the word may or may not fit into the body,
		// self.wordsFit takes care of that
		while not insertedWord
			word = self.wordList[rand(self.wordList.len-1)]
			ori = orientations[rand(orientations.len-1)]
			pos.x = rand(67)
			pos.y = rand(25)
			insertedWord = self.wordFits(word, ori, pos.x, pos.y)
		end while
		x = pos.x; y = pos.y;
		// A good position was found, insert the letters
		// on the screen
		for c in word
			self.lettersOnScreen[y][x] = upper(c)
			if ori == "hor" then
				x = x + 1
			else if ori == "ver" then
				y = y - 1
			else
				x = x + 1
				y = y - 1
			end if
		end for
		//print word
		//input
		self.words.push word
	end for
	
	//self.setWordDamage
	
	// Now that every word was inserted, replace the
	// remaining "-" with random letters and we're good to go
	for y in range(0, 25) 
		for x in range(0, 67)
			if self.lettersOnScreen[y][x] == "-" then
				self.lettersOnScreen[y][x] = self.letters[rand(self.letters.len-1)]
			end if
		end for
	end for
end function

Game.setWord = function(word, x, y, color)
	i = 0
	for _x in range(x, x+word.len-1)
		self.lettersOnScreen[y][_x] = word[i]
		txtDisp.setCellColor _x, y, color
		txtDisp.setCell _x, y, word[i]
		i = i + 1
	end for
end function

// Remove the selected word
Game.clear = function(clearWord)
	if clearWord then
		for letter in self.selectedLetters
			if self.insideRect(letter.x, letter.y) then
				txtDisp.setCellColor letter.x, letter.y, self.color
				//else
				//txtDisp.setCellColor letter.x, letter.y, "#202020"
			end if
		end for
	end if
	for x in range(self.wordSelect.xbase, self.wordSelect.x)
		txtDisp.setCellColor(x, self.wordSelect.y, "#202020")
		txtDisp.setCell(x, self.wordSelect.y, self.letters[rand(self.letters.len-1)])
	end for
	self.wordSelect.x = self.wordSelect.xbase
	self.selectedLetters = []
end function

// Check if the word is connected, i.e the player
// didn't just click random letters to form the words
// in the list
Game.wordIsConnected = function()
	wordPos = self.selectedLetters
	ori = ""
	if wordPos[0].y-wordPos[1].y == 1 then
		ori = "ver"
	else if wordPos[0].x-wordPos[1].x == -1 then	
		ori = "hor"
	else if ((wordPos[0].y-wordPos[1].y == 1) and (wordPos[0].x-wordPos[1].x == -1)) then	
		ori = "dia"
	else
		return false	
	end if
	for i in range(0, wordPos.len-2)
		if ori == "ver" and wordPos[i].y-wordPos[i+1].y != 1 then
			return false
		else if ori == "hor" and wordPos[i].x-wordPos[i+1].x != -1 then
			return false
		else if ori == "dia" and not ((wordPos[0].y-wordPos[1].y == 1) and (wordPos[0].x-wordPos[1].x == -1)) then	
			return false
		end if
	end for
	return true
end function

Game.damage = function(who, damage)
	if who == "enemy" then
		enemyHP.scale = [enemyHP.scale[0]-damage, 1]
		//print enemyHP.scale[0]
		self.wordsFound = self.wordsFound + 1
		if self.wordsFound == self.words.len then
			self.levelComplete = true
			for y in range(0, 25)
				for x in range(0, 67)
					if self.insideRect(x, y) and txtDisp.cellColor(x, y) != color.yellow then
						txtDisp.setCellColor x, y, "#202020"
					end if
				end for
			end for
		end if
		playSound 0.2, noteFreq(90), [0, 1], Sound.sineWave
	else
		playerHP.scale = [playerHP.scale[0]-damage, 1]
		//text.row = 22
		//text.column = 20
		//print "Word not found! " + round(damage*100) + " damage to Player!"
		self.player.hp = self.player.hp - damage*100
		if self.player.hp <= 0 then
			self.gameover = true
			playSound 0.4, noteFreq(20), [1, 0], Sound.sawtoothWave
		end if
		playSound 0.2, 40, [1, 0.5], Sound.sineWave
	end if
end function

// Game logic
Game.update = function(dt)
	// Game over / Level completed
	if self.gameover and Timer.count then
		Timer.count = false
		self.setWord("Game over! Press any key to reset", 20, 25, color.white)
	else if self.gameover then
		if key.get then
			key.clear
			clear; reset; load "game"; run;
		end if	
	end if
	// Transform the cells coords to "gfx" coords to
	// check collision between the mouse and
	// the letter the user wants to press
	hovX = floor((mouse.x * 68.572) / 960.008)
	hovY = round((mouse.y * 24.6159) / 640.013)
	// The user moved the mouse to a new letter,
	// set the old letter its original color
	if hovX != self.hovered.x or hovY != self.hovered.y then
		txtDisp.setCellColor self.hovered.x, self.hovered.y, self.hovered.oldColor
		self.hovered.x = -1; self.hovered.y = -1;
	end if
	// Set the hovered letter white color 
	if self.hovered.x == -1 or self.hovered.y == -1 then
		oldColor = txtDisp.cellColor(hovX, hovY)
		//text.row = 1
		//print oldColor
		if oldColor != "#FFFF00FF" then
			self.hovered.x = hovX
			self.hovered.y = hovY
			//text.row = 1
			//print x + " " + y + " " + floor(x) + " " + ceil(y)
			self.hovered.oldColor = txtDisp.cellColor(self.hovered.x, self.hovered.y)
			txtDisp.setCellColor self.hovered.x, self.hovered.y, color.white
		end if
	end if
	
	if mouse.button(0) then 	// Left click
		if self.insideRect(self.hovered.x, self.hovered.y) then
			txtDisp.setCellColor self.hovered.x, self.hovered.y, color.yellow
			//print(txtDisp.cell(self.hovered.x, self.hovered.y))
			self.selectedLetters.push {"x": self.hovered.x, "y": self.hovered.y}
			if self.wordSelect.x < 68 then
				letter = txtDisp.cell(self.hovered.x, self.hovered.y)
				self.setWord(letter, self.wordSelect.x, self.wordSelect.y, color.white)
				self.wordSelect.x = self.wordSelect.x + 1
			end if
			self.hovered.x = -1; self.hovered.y = -1;
		end if
	else if mouse.button(1) then // Right click
		self.clear true
	end if
	
	if UI.Button("Shoot!", 450, 50) and self.selectedLetters.len > 0 then
		word = ""
		clearWord = true
		for coord in self.selectedLetters
			word = word + txtDisp.cell(coord.x, coord.y)
		end for
		word = lower(word)
		if self.words.contains(word) then
			// Word not connected: damage the player
			if not self.wordIsConnected then
				print "word not connected!"
				self.damage "player", (1/self.words.len)+rnd*0.03
				self.clear true
				return
			end if
			//print "word found!"
			// Damage enemy, remove word from list, highlight word in body
			xlist = self.wordListPos[word][0]
			ylist = self.wordListPos[word][1]
			self.setWord(word, xlist, ylist, "#202020")
			self.damage "enemy", (1/self.words.len)
			clearWord = false
		else
			// Word not found
			self.damage "player", (1/self.words.len)+rnd*0.01
		end if
		self.clear clearWord
	end if
	
	// Damage player when the timer ends	
	if Timer.update(dt) then
		Timer.setTimer(1, rand(5, abs(30-self.level)))
		self.damage "player", rnd*0.1
	end if
	text.row = 3
	text.column = 5
	text.color = color.white
	print(Timer.getTime)
end function

Game.draw = function()
	for y in range(1, 26)
		for x in range(1, 68)
			if self.insideRect(x-1, y-1) then
				txtDisp.setCellColor x-1, y-1, self.color
			else
				txtDisp.setCellColor x-1, y-1, "#202020"				
			end if
			//print self.lettersOnScreen[y][x]
			txtDisp.setCell x-1, y-1, self.lettersOnScreen[y-1][x-1]
		end for
	end for
	self.setWord("WORDS:", 49, 16, color.white)
	self.wordListPos = {}
	x = 49; y = 14
	for word in self.words
		self.setWord(word, x, y, color.white)
		self.wordListPos[word] = [x, y]
		y = y - 1
	end for
	UI.offset.w = 5
	self.setWord(" "*8, 31, 2, color.white)
	
	playerHP.x = 67
	playerHP.y = 255
	sprDisp.sprites.push playerHP
	enemyHP.x = 67
	enemyHP.y = 209
	sprDisp.sprites.push enemyHP
	
	self.setWord("  YOU  ", 1, 10, color.white)
	self.setWord(" ENEMY ", 1, 8, color.white)
	
	self.setWord("Level: " + self.level, 1, 15, color.white)
end function

loadGame = function(lvl)
	game = new Game
	
	game.init lvl
	game.generateGrid
	game.draw
	
	Timer.init
	Timer.setTimer 1
	
	enemyHP.scale = [1, 1]
	
	return game
end function

game = loadGame(1)
dt = time

// Main game loop
while true
	t = time
	game.update
	Timer.update dt
	if game.levelComplete and Timer.count then
		Timer.count = false
		game.setWord("Level complete! Press any key to continue", 20, 25, color.white)
	else if game.levelComplete then
		if key.get then
			key.clear
			clear
			UI.reset
			game = loadGame(game.level+1)
		end if
	end if
	yield
	dt = time-t
end while

// 1. Draw random letters on screen, draw "-" where the
//    important letters will be.
// 2. Highlight certain letters to form the body of the enemy
//    or maybe draw rectangles with low alpha so the letters are visible.
// 3. Add the words to the body.
// 4. Add random letters to the rest of the body.
// 5. Show word list, timer, player and enemy's HP.
// 6. The player must be able to click on the letters and these
//    letters are highlighted.
// 7. The player must have a button to click when the word
//    is selected. When pressed, check if the word is valid.
//    7.1 If the word is valid, remove it from the list and
//        damage the enemy, otherwise, damage the player.
//    7.2 If the words is correct, check if it's connected,
//        if it isn't, damage the player.
// 8. When player hp is below 0, game over; when enemy hp is
//    below 0, level complete.

// Some Mini micro information:
// Text display: 68 x 26
// Font size: 14 x 24
// gfx size: 960 x 640
// 14 * 68.572 = 960.008
// 26 * 24.6159 = 640.013