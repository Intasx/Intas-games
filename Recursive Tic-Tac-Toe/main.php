<?php

use raylib\Color;
use raylib\Draw;
use raylib\Rectangle;
use raylib\Text;
use raylib\Timming;
use raylib\Window;
use raylib\Input;

// Initialization
//--------------------------------------------------------------------------------------

// Screen size (recursion level zero)
const SCREEN_WIDTH = 600;
const SCREEN_HEIGHT = 600;

// Recursion level one
const GRID_ONE_WIDTH = SCREEN_WIDTH/3;
const GRID_ONE_HEIGHT = SCREEN_HEIGHT/3;

// Recursion level two
const GRID_TWO_WIDTH = SCREEN_WIDTH/9;
const GRID_TWO_HEIGHT = SCREEN_HEIGHT/9;

$BLACK = new Color(0, 0, 0, 255);
$WHITE = new Color(255, 255, 255, 255);
$RED   = new Color(255, 0, 0, 255);
$GREEN = new Color(0, 255, 0, 255);
$BLUE  = new Color(0, 0, 255, 255);

require 'grid.php';
require 'player.php';

/* Used to generate the inner grids.
 * int $level: the level recursion
 * float $witdh, $height: The size of the grid in pixels
 * Color $color: the color of the grid's lines
 * returns: an array containing the inner grids.
*/
function generateGrid(int $level, float $width, float $height, Color $color): array
{
    $grid = [];
    for ($baseY = 0; $baseY < $height; $baseY += $height) {
        for ($baseX = 0; $baseX < $width; $baseX += $width) {
            for ($y = $baseY; $y < $baseY+SCREEN_HEIGHT; $y += $height) {
                for ($x = $baseX; $x < $baseX+SCREEN_WIDTH; $x += $width) {
                    $grid[] = new Grid(new Rectangle($x, $y, $width, $height), $level, $color);
                }
            }
        }
    }
    return $grid;
}

/* Check the winner of a given array of tiles.
 * array $tiles: the tiles to check for a winner.
 * returns: a string containing the winner, "-" for a draw or " " if nobody won yet.
*/
function checkWinner(array $tiles): string
{
    $gridIsFull = true;
    
    // Check horizontal lines
    for ($x = 0; $x < 9; $x += 3) {
        if ($tiles[$x]['char'] != ' ' && $tiles[$x]['char'] == $tiles[$x+1]['char'] && $tiles[$x]['char'] == $tiles[$x+2]['char']) {
            return $tiles[$x]['char'];
        }
    }

    // Check vertical lines
    for ($y = 0; $y < 3; $y++) {
        if ($tiles[$y]['char'] != ' ' && $tiles[$y]['char'] == $tiles[$y+3]['char'] && $tiles[$y]['char'] == $tiles[$y+6]['char']) {
            return $tiles[$y]['char'];
        }
    }

    // Check diagonals
    if ($tiles[0]['char'] != ' ' && $tiles[0]['char'] == $tiles[4]['char'] && $tiles[0]['char'] == $tiles[8]['char']) {
        return $tiles[0]['char'];
    }
    if ($tiles[2]['char'] != ' ' && $tiles[2]['char'] == $tiles[4]['char'] && $tiles[2]['char'] == $tiles[6]['char']) {
        return $tiles[2]['char'];
    }

    // Check if the grid is full (draw)
    for ($i = 0; $i < 9; $i++) {
        if ($tiles[$i]['char'] == ' ') {
            $gridIsFull = false;
            break;
        }
    }

    return $gridIsFull ? '-' : ' ';
}

/*
 * Clear the given grid. Useful for reset.
 * Grid $grid: the grid to clear.
*/
function clearGrid(Grid $grid)
{
    for ($i = 0; $i < 9; $i++) {
        $grid->tiles[$i]['char'] = ' ';
        $grid->tiles[$i]['canChallenge'] = $grid->level < 2;
    }
}

// The biggest grid, the one that decides who won the game (recursion level zero)
$masterGrid = new Grid(new Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), 0, $WHITE);

// Recursion level one
$gridLevelOne = generateGrid(1, GRID_ONE_WIDTH, GRID_ONE_HEIGHT, $GREEN);

// Recursion level two
$gridLevelTwo = generateGrid(2, GRID_TWO_WIDTH, GRID_TWO_HEIGHT, $BLUE);

$playerOne = new Player("X", true, $GREEN);
$playerOne->setGridAndLevel($masterGrid, 0);
$playerTwo = new Player("O", false, $RED);
$playerTwo->setGridAndLevel($masterGrid, 0);

// Global variables
$currentPlayer = $playerOne;  // Current player playing
$currentLevel = 0;            // Current recursion level
$gridOneIndex = -1;           // Index in the array of grids ($masterGrid) of the first recursion
$gridTwoIndex = -1;           // Index in the array of grids ($gridLevelOne) of the second recursion
$gridTwoPos = -1;             // Contains the last tile pressed on the second recursion
$lastTileOne = [];            // Holds information of the last tile when entering a new recursion level
$lastTileTwo = [];
$message = '';                // Shows the game's winner

Window::init(SCREEN_WIDTH, SCREEN_HEIGHT+50, "Recursive Tic-Tac-Toe");
Timming::setTargetFps(60);

//--------------------------------------------------------------------------------------

// Main game loop
while (!Window::shouldClose()) { // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    // Left click pressed
    if (Input\Mouse::isButtonPressed(0)) {
        $result = $currentPlayer->mousePressed();
        // Check for winner
        $winner = ' ';
        $colorWinner = $WHITE;
        switch ($currentLevel) {
            case 0: // master grid
                $winner = checkWinner($masterGrid->tiles);
                if ($winner == '-') {
                    $message = "Draw. Press R to reset.";
                } elseif($winner != ' ') {
                    $message = "Winner: " . $winner . ". Press R to reset.";
                }
                break;
            case 1: // recursion level one
                $winner = checkWinner($gridLevelOne[$gridOneIndex]->tiles);

                // In case of a draw the last character placed is the winner
                if ($winner == '-') {
                    $winner = $lastTileOne['char'];
                    $colorWinner = $lastTileOne['color'];
                } else {
                    $colorWinner = ($winner == $playerOne->char) ? $playerOne->color : $playerTwo->color;
                }

                // Set the winner on the biggest grid
                $masterGrid->tiles[$gridOneIndex]['char'] = $winner;
                $masterGrid->tiles[$gridOneIndex]['color'] = $colorWinner;
                
                // If a winner was found set the previous recursion level
                if ($winner != ' ' && $winner != '-') {
                    $playerOne->setGridAndLevel($masterGrid, 0);
                    $playerTwo->setGridAndLevel($masterGrid, 0);
                }
                break;
            case 2: // recursion level two
                $winner = checkWinner($gridLevelTwo[$gridTwoIndex]->tiles);
                
                // Draw
                if ($winner == '-') {
                    $winner = $lastTileTwo['char'];
                    $colorWinner = $lastTileTwo['color'];
                } else {
                    $colorWinner = ($winner == $playerOne->char) ? $playerOne->color : $playerTwo->color;
                }

                // Set the winner
                $gridLevelOne[$gridOneIndex]->tiles[$gridTwoPos]['char'] = $winner;
                $gridLevelOne[$gridOneIndex]->tiles[$gridTwoPos]['color'] = $colorWinner;
                // If a winner was found set the previous recursion level
                if ($winner != ' ' && $winner != '-') {
                    $playerOne->setGridAndLevel($gridLevelOne[$gridOneIndex], 1);
                    $playerTwo->setGridAndLevel($gridLevelOne[$gridOneIndex], 1);
                }
                break;
        }

        if ($winner != ' ' && $winner != '-' && $currentLevel > 0) {
            $currentLevel--;
        }

        // If there's a new Level and there's no winner yet...
        if ($result['newLevel'] != $currentLevel && $winner == ' ') {
            if ($currentLevel == 0) {
                $gridOneIndex = $result['tileIndex'];
                
                // Save the last tile placed on the biggest grid in case of a draw
                $lastTileOne = $masterGrid->tiles[$gridOneIndex];
                
                // Remove it
                $masterGrid->tiles[$gridOneIndex]['char'] = ' ';
                $masterGrid->tiles[$gridOneIndex]['canChallenge'] = false;

                // Set the last tile placed in the new grid
                $gridLevelOne[$gridOneIndex]->tiles[$gridOneIndex] = $lastTileOne;

                // Set the new grid
                $playerOne->setGridAndLevel($gridLevelOne[$gridOneIndex], 1);
                $playerTwo->setGridAndLevel($gridLevelOne[$gridOneIndex], 1);
            } elseif ($currentLevel == 1) {
                $gridTwoPos = $result['tileIndex'];

                // Get the coords of the second level grid placed
                $gridOneX = (($gridOneIndex > 2) ? ($gridOneIndex % 3) : $gridOneIndex);
                $gridOneY = (($gridOneIndex - ($gridOneIndex % 3)) / 3);
                
                // Get the index of the second grid
                $gridTwoIndex = ($gridOneY * 27) + ($result['gridY'] * 9) + ($gridOneX * 3) + $result['gridX'];
                
                // Save the last tile placed on the biggest grid in case of a draw
                $lastTileTwo = $gridLevelOne[$gridOneIndex]->tiles[$gridTwoPos];

                // Remove it
                $gridLevelOne[$gridOneIndex]->tiles[$gridTwoPos]['char'] = ' ';
                $gridLevelOne[$gridOneIndex]->tiles[$gridTwoPos]['canChallenge'] = false;
                
                // Set the last tile palced in the new grid
                $gridLevelTwo[$gridTwoIndex]->tiles[$gridTwoPos] = $lastTileTwo;
                
                // Set the new grid
                $playerOne->setGridAndLevel($gridLevelTwo[$gridTwoIndex], 2);
                $playerTwo->setGridAndLevel($gridLevelTwo[$gridTwoIndex], 2);
            }
            $currentLevel = $result['newLevel'];
        }

        // Change turn
        if ($result['changeTurn']) {
            $newPlayer = ($playerOne->canPlay) ? $playerTwo : $playerOne;
            $currentPlayer->canPlay = false;
            $currentPlayer = $newPlayer;
            $currentPlayer->canPlay = true;
        }
    }
    
    // Reset the game
    if (Input\Key::isPressed(Input\Key::R)) {
        $currentPlayer = $playerOne;
        $currentLevel = 0;
        $gridOneIndex = -1;
        $gridTwoIndex = -1;
        $gridTwoPos = -1;
        $lastTileOne = [];
        $lastTileTwo = [];
        $message = '';
        $playerOne->canPlay = true;
        $playerTwo->canPlay = false;
        clearGrid($masterGrid);
        foreach ($gridLevelOne as $gridOne) {
            clearGrid($gridOne);
        }
        foreach ($gridLevelTwo as $gridTwo) {
            clearGrid($gridTwo);
        }
    }
    //----------------------------------------------------------------------------------


    // Draw
    //----------------------------------------------------------------------------------
    Draw::begin();

    Draw::clearBackground($BLACK);
    //Text::drawFps(SCREEN_WIDTH-80, 630);
    
    $masterGrid->draw();
    $currentPlayer->draw();
    if ($message != '') {
        Text::draw($message, 0, SCREEN_HEIGHT, 20, $WHITE);
    }
    if ($currentLevel >= 1) {
        $gridLevelOne[$gridOneIndex]->draw();
        if ($currentLevel == 2) {
            $gridLevelTwo[$gridTwoIndex]->draw();
        }
    }    

    Draw::end();
    //----------------------------------------------------------------------------------
}

// De-Initialization
//--------------------------------------------------------------------------------------
Window::close(); // Close window and OpenGL context
//--------------------------------------------------------------------------------------
