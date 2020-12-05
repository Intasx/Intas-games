# Recursive Tic-Tac-Toe

Language: php 7.4.9

Framework/engine: [Raylib v3.0](https://www.raylib.com/), using the [raylib-php](https://github.com/joseph-montanez/raylib-php) binding.

# Instructions

Same rules of the classic Tic-Tac-Toe game, except for the "recursive" part:
If a player clicks on a tile where the opponent already placed an "X" or "O", a new smaller grid appears. Whoever wins on the smaller grid win the spot. If the game ends in a draw, whoever have placed first on the bigger grid is the winner.

# Installing

#### Requirements:
* php >= 7.x
* Raylib binaries.

See detailed instructions [here](https://github.com/joseph-montanez/raylib-php/blob/master/README.md#how-to-build-php-extension).

# Screenshots

![](/Recursive%20Tic-Tac-Toe/recursive-tictactoe.gif)