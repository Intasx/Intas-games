<?php

use raylib\Text;
use raylib\Color;
use raylib\Input;


class Player
{
    public $character;
    public $currentGrid;


    public function __construct(string $ch, bool $startsPlaying, Color $color)
    {
        $this->char = $ch;
        $this->canPlay = $startsPlaying;
        $this->color = $color;
    }

    public function setGridAndLevel(Grid $grid, int $level)
    {
        $this->currentGrid = $grid;
        $this->level = $level;
    }

    public function getGrid()
    {
        return $this->currentGrid;
    }

    public function getLevel(): int
    {
        return $this->level;
    }


    public function mousePressed(): array
    {
        $x = intval(Input\Mouse::getX());
        $y = intval(Input\Mouse::getY());
        $gridX = (($x - ($x % intval($this->currentGrid->tileWidth))) / intval($this->currentGrid->tileWidth)) % 3;
        $gridY = (($y - ($y % intval($this->currentGrid->tileHeight))) / intval($this->currentGrid->tileHeight)) % 3;
        $tileIndex = $gridX + (3 * $gridY);
        $result = [
            'changeTurn' => false, 
            'newLevel'  => $this->level, 
            'tileIndex' => $tileIndex,
            'gridX' => $gridX,
            'gridY' => $gridY
        ];
        $currentChar = $this->currentGrid->tiles[$tileIndex]['char'];
        $canChallenge = $this->currentGrid->tiles[$tileIndex]['canChallenge'];
        //echo($gridX . " " . $gridY . " " . $tileIndex . "\n");
        if ($currentChar == " ") {
            $this->currentGrid->tiles[$tileIndex]['char'] = $this->char;
            $this->currentGrid->tiles[$tileIndex]['color'] = $this->color;
            $result['changeTurn'] = true;
        } elseif ($currentChar != $this->char && $canChallenge) {
            // Challenge here...
            $result['newLevel'] = $this->level + 1;
        }
        return $result;
    }

    public function draw() {
        Text::draw("Turn: " . $this->char, 0, SCREEN_HEIGHT+30, 20, $this->color);
    }

}