import pygame
from grid import *

class UserInput:
	'''Class that handles user input: mouse and keyboard'''
	def __init__(self, grid):
		self.hovered = None
		self.grid = grid
		self.pressed = False
		self.old_color = ()
		self.letters = []

	def word_is_connected(self, word):
		'''True if the word the user selected is connected horizontal, vertical
		    or diagonal, False otherwise'''
		ori = ''
		if self.letters[1]['y']-self.letters[0]['y'] == 1:
			ori = 'ver'
		elif self.letters[0]['x']-self.letters[1]['x'] == -1:
			ori = 'hor'
		elif (self.letters[1]['y']-self.letters[0]['y'] == 1) and (self.letters[0]['x']-self.letters[1]['x'] == -1):
			ori = 'dia'
		else:
			return False
		for i in range(0, len(self.letters)-2):
			if ori == 'ver' and self.letters[i+1]['y']-self.letters[i]['y'] != 1:
				return False
			elif ori == 'hor' and self.letters[i]['x']-self.letters[i+1]['x'] != -1:
				return False
			elif ori == 'dia':
				if not ((self.letters[i+1]['y']-self.letters[i]['y'] == 1) and (self.letters[i]['x']-self.letters[i+1]['x'] == -1)):
					return False
		return True

	def render_button(self, screen, playerhp, enemyhp, mouse_pos=None, button=None):
		'''Handles both graphic and logic parts of the Shoot! button'''
		if mouse_pos is None:
			mouse_pos = pygame.mouse.get_pos()
		if button is None:
			button = pygame.mouse.get_pressed()[0]
		_rect = pygame.Rect(250, 450, 100, 50)
		collides = _rect.collidepoint(mouse_pos)
		pygame.draw.rect(screen, GRAY, _rect)
		if collides:
			_message = FONT.render('Shoot!', False, YELLOW)
		else:
			_message = FONT.render('Shoot!', False, WHITE)
		screen.blit(_message, dest=(260, 460))
		if collides and button == 1 and len(self.letters) > 0:
			word = ''.join([i['letter'] for i in self.letters])
			if word in self.grid.selected_words and self.word_is_connected(word):
				enemyhp = enemyhp - (100/len(self.grid.selected_words))
				enemyhp = 0 if enemyhp <= 0 else enemyhp
				self.grid.words_left.remove(word)
				for w, w_info in self.grid.selected_words.items():
					if w == word:
						self.grid.set_word("x"*len(w), w_info['x'], w_info['y'])
						break
			else:
				playerhp = playerhp - (100/len(self.grid.selected_words))
				playerhp = 0 if playerhp <= 0 else playerhp
				self.mouse_pressed(True, 3)
			self.letters.clear()
		return (playerhp, enemyhp)

	def get_hovered_surface(self, mouse_pos):
		'''Returns the letter the user is currently hovering, or None otherwise'''
		for y in range(0, HEIGHT):
			for x in range(0, WIDTH):
				letter = self.grid.letters_screen[y][x]
				if letter['rect'].collidepoint(mouse_pos) and letter not in self.letters:
					return letter

	def mouse_pressed(self, state, button):
		'''Handles the MOUSEBUTTONUP and MOUSEBUTTONDOWN pygame events'''
		self.pressed = state
		if self.pressed and button == 1 and self.hovered is not None:
			x = self.hovered['x']
			y = self.hovered['y']
			if self.grid.inside_body(x, y) and self.hovered not in self.letters:
				self.letters.append(self.hovered)
				self.grid.letters_screen[y][x]['color'] = YELLOW
				self.hovered = None
		elif self.pressed and button == 3:
			for letter in self.letters:
				x = letter['x']
				y = letter['y']
				fill(letter['surface'], self.grid.enemy_color)
				self.grid.letters_screen[y][x]['color'] = self.grid.enemy_color
			self.letters.clear()

	def mouse(self, mouse_pos):
		'''Handles the MOUSEMOTION pygame event'''
		new_surface = self.get_hovered_surface(mouse_pos)
		if self.hovered is None:
			self.hovered = new_surface
			# Save the old color only if a letter is being hovered
			if self.hovered is not None:
				self.old_color = self.hovered['color']
				fill(self.hovered['surface'], YELLOW)
		elif new_surface is not None and new_surface != self.hovered:
			# A new letter is being hovered, set the old color and change
			fill(self.hovered['surface'], self.old_color)
			self.hovered = new_surface.copy()
			self.old_color = self.hovered['color']
			fill(self.hovered['surface'], YELLOW)
		# Unused feature: when the user holds down the left click it would select
		# any hovered letter, but it conflicts with the mouse_pressed function
		'''
		if self.pressed and self.hovered is not None and self.hovered not in self.letters:
			if self.grid.inside_body(self.hovered['x'], self.hovered['y']):
				self.letters.append(self.hovered)
				self.hovered = None
		'''


# Word is in list? Word is connected?
# Yes: Let the word highlighted, damage enemy
# No: Damage player, clear selected words
# Timer: damage player over time


		