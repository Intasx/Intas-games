import os
import pygame
import random
import string
import datetime

# Color tuples
GRAY   = (50,  50,  50  )
WHITE  = (255, 255, 255 )
BLACK  = (0,   0,   0   )
RED    = (255, 0,   0   )
GREEN  = (0,   255, 0   )
BLUE   = (0,   0,   255 )
YELLOW = (255, 255, 0   )

FONT_SIZE = 25
FONT = pygame.font.Font(os.path.join('fonts', 'fixedsys.ttf'), FONT_SIZE)

# Body parts of the enemy are defined as rectangles
BODY = {
	'head':      pygame.Rect(20, 5, 6, 5),
	'body':      pygame.Rect(19, 10, 8, 8),
	'leftarm':   pygame.Rect(13, 11, 6, 2),
	'lefthand':  pygame.Rect(13, 9, 3, 2),
	'rightarm':  pygame.Rect(27, 11, 7, 2),
	'righthand': pygame.Rect(31, 13, 3, 2),
	'leftleg':   pygame.Rect(23, 18, 3, 8),
	'rightleg':  pygame.Rect(20, 18, 3, 8) 
}
# Amount of letters the screen will be made of
WIDTH = 83
HEIGHT = 90

# Change color of a surface without changing its tranparency
# Source: https://stackoverflow.com/q/42821442
def fill(surface, color):
	'''Fill all pixels of the surface with color, preserve transparency.'''
	w, h = surface.get_size()
	if (len(color) == 4):
		r, g, b, _ = color
	else:
		r, g, b = color
	for x in range(w):
		for y in range(h):
			a = surface.get_at((x, y))[3]
			surface.set_at((x, y), pygame.Color(r, g, b, a))

class Grid:
	'''Grid class: handles the text on screen, both background
		and inside the enemy's body'''
	def __init__(self, lvl):
		self.enemy_color = random.choice([RED, GREEN, BLUE]) # (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
		self.time = datetime.timedelta(seconds=random.randint(60, 75))
		self.counter = datetime.timedelta()
		self.letters_screen = []
		self.selected_words = {}
		self.words_left = []
		self.lvl = lvl
		with open('englishWords.txt') as file:
			self.wordList = [line.rstrip('\n') for line in file]

	def inside_body(self, x, y):
		'''True if the given x-y is inside the enemy's body, False otherwise'''
		for b in BODY.values():
			if x >= b.x and x < b.x+b.w and y >= b.y and y < b.y+b.h:
				return True
		return False

	def wordFits(self, word, ori, x, y):
		'''True if the given x-y and orientation fit within the enemy's body,
		   False otherwise'''
		for c in word:
			if self.letters_screen[y][x]['letter'] != '-':
				return False
			x = x+1 if (ori == 'hor' or ori == 'dia') else x
			y = y+1 if (ori == 'ver' or ori == 'dia') else y
		return True

	def set_word(self, word, x, y, color=None, ori=None):
		'''Set the given word into the grid'''
		if ori is None:
			ori = 'hor'
		if color is None:
			color = WHITE
		for c in word:
			self.letters_screen[y][x]['letter'] = c
			self.letters_screen[y][x]['surface'] = FONT.render(c, False, color).convert_alpha()
			self.letters_screen[y][x]['color'] = color
			x = x+1 if (ori == 'hor' or ori == 'dia') else x
			y = y+1 if (ori == 'ver' or ori == 'dia') else y

	def generate_grid(self):
		'''Generate the grid and the enemy's body'''
		# Insert random letters and '-' where the enemy's body will be
		for y in range(0, HEIGHT):
			i = len(self.letters_screen)
			self.letters_screen.append([])
			for x in range(0, WIDTH):
				letter = random.choice(string.ascii_uppercase)
				if self.inside_body(x, y):
					w, h = FONT.size('-')
					self.letters_screen[i].append({
						'letter': '-',
						'surface': None, #_NOTHING,
						'color': self.enemy_color,
						'x': x, 'y': y,
						'rect': pygame.Rect((x*20), (y*20), w, h)
					})
				else:
					w, h = FONT.size(letter)
					self.letters_screen[i].append({
						'letter': letter,
						'surface': FONT.render(letter, False, GRAY).convert_alpha(),
						'color': GRAY,
						'x': x, 'y': y,
						'rect': pygame.Rect((x*20), (y*20), w, h)
					})
		orientations = ['hor', 'ver', 'dia']
		letters = []
		amount = random.randint(4, 6)
		# Copy the list by value to remove
		# the selected words so there's no repeats
		_words = self.wordList[:]
		for i in range(0, amount):
			x = 0
			y = 0
			insertedWord = False
			ori = ''
			word = ' '
			# Depending on the x-y coord and orientation the word
			# may or may not fit, self.wordFits takes care of that
			while not insertedWord:
				word = random.choice(_words)
				# Word length limits
				if len(word) == 1 or len(word) >= 13:
					continue
				ori = random.choice(orientations)
				x = random.randint(13, 32)
				y = random.randint(5, 25)
				insertedWord = self.wordFits(word, ori, x, y)
			_words.remove(word)
			word = word.upper()
			self.selected_words[word] = {}
			self.words_left.append(word)
			self.set_word(word, x, y, self.enemy_color, ori)
		# Every word was inserted, so replace the remaining "-"
		# with random letters and we're good to go
		for y in range(0, HEIGHT):
			for x in range(0, WIDTH):
				if self.letters_screen[y][x]['letter'] == '-':
					letter = random.choice(string.ascii_uppercase)
					self.letters_screen[y][x]['letter'] = letter
					self.letters_screen[y][x]['surface'] = FONT.render(letter, False, self.enemy_color).convert_alpha()
		# Set the word list so the player knowns what words to look
		self.set_word('WORDS:', 1, 3)
		word_list_x = 1
		word_list_y = 5
		for word, word_info in self.selected_words.items():
			# Save the coords so we can cross them when
			# the player founds them
			word_info['x'] = word_list_x
			word_info['y'] = word_list_y
			self.set_word(word, word_list_x, word_list_y)
			word_list_y += 1
		self.set_word("YOU:", 3, 13)               # Player HP bar
		self.set_word("ENEMY:", 3, 18)             # Enemy HP bar
		self.set_word(f"LEVEL:{self.lvl}", 3, 27)  # Level counter
		self.set_word(" "*4, 4, 25)                # Countdown timer

	def timer(self, dt, screen, playerhp):
		'''Handles the timer on screen'''
		self.time = self.time - datetime.timedelta(milliseconds=dt)
		self.counter = self.counter + datetime.timedelta(milliseconds=dt)
		timer = str(self.time)[2:7] # h:mm:ss.microseconds -> mm:ss
		# If timedelta goes negative it turns into (days=-1, seconds=86399)
		if self.time.seconds <= 0 or self.time.seconds >= 1000:
			self.time = datetime.timedelta(seconds=random.randint(60, 75))
			damage = 100/len(self.selected_words)
			playerhp = playerhp - damage/3
		if self.counter.seconds >= 1:
			pygame.draw.rect(screen, BLACK, (80, 503, 75, 20))
			screen.blit(FONT.render(timer, False, WHITE), dest=(80, 500))
			self.counter = datetime.timedelta()
		return playerhp

	def render(self, screen, playerhp, enemyhp):
		'''Draw the letters on screen and the player/enemy healthbars'''
		for letter_row in self.letters_screen:
			for letter in letter_row:
				screen.blit(letter['surface'], dest=(letter['x']*20, letter['y']*20))
		# The black rect creates the illusion that the healthbar is decreasing its width
		pygame.draw.rect(screen, GREEN, (60, 290, playerhp, 30))
		pygame.draw.rect(screen, BLACK, (160, 290, playerhp-100, 30))
		pygame.draw.rect(screen, RED,   (60, 390, enemyhp, 30))
		pygame.draw.rect(screen, BLACK, (160, 390, enemyhp-100, 30))		

