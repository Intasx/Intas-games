import pygame

pygame.init()

from grid import *
from user_input import *

size = width, height = 900, 600

screen = pygame.display.set_mode(size)
pygame.display.set_caption('Word search shooter! Game by Intas')

clock = pygame.time.Clock()

def init(lvl):
	grid = Grid(lvl)
	grid.generate_grid()
	user_input = UserInput(grid)
	return (grid, user_input, 100, 100)

def render(screen, playerhp, enemyhp, mouse_pos=None, button=None):
	grid.render(screen, playerhp, enemyhp)
	return user_input.render_button(screen, playerhp, enemyhp, mouse_pos, button)

lvl = 1
grid, user_input, playerhp, enemyhp = init(lvl)
render(screen, playerhp, enemyhp)

closeGame = False

while not closeGame:
	for event in pygame.event.get():
		if event.type == pygame.QUIT:
			closeGame = True
		elif event.type == pygame.KEYDOWN:
			if event.unicode == '\x1b': # Escape key
				closeGame = True
			if playerhp == -0.01:
				lvl = 1
				screen.fill((0, 0, 0))
				grid, user_input, playerhp, enemyhp = init(lvl)
				render(screen, playerhp, enemyhp)
			elif enemyhp == -0.01:
				lvl += 1
				screen.fill((0, 0, 0))
				grid, user_input, playerhp, enemyhp = init(lvl)
				render(screen, playerhp, enemyhp)
		elif event.type == pygame.MOUSEMOTION:
			mouse_pos = event.pos
			user_input.mouse(mouse_pos)
			render(screen, playerhp, enemyhp, mouse_pos)
		elif event.type == pygame.MOUSEBUTTONUP:
			user_input.mouse_pressed(False, None)
			render(screen, playerhp, enemyhp)
		elif event.type == pygame.MOUSEBUTTONDOWN:
			button = event.button
			user_input.mouse_pressed(True, button)
			playerhp, enemyhp = render(screen, playerhp, enemyhp, None, button)
	clock.tick(60)
	if playerhp > 0 and enemyhp > 0:
		playerhp = grid.timer(clock.get_time(), screen, playerhp)
	elif playerhp == 0:
		grid.set_word("Game over! Press any key to restart", 8, 1)
		playerhp = -0.01
	elif enemyhp == 0:
		grid.set_word("Level complete! Press any key to continue", 8, 1)
		enemyhp = -0.01
	pygame.display.flip()

pygame.quit()
