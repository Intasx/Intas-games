<?php

use raylib\Color;
use raylib\Draw;
use raylib\Rectangle;
use raylib\Text;


class Grid
{
    public $rectGrid;
    public $lineColor;

    public function __construct(
    	Rectangle $rectangle,
    	int $recursionLevel,
    	Color $color
    ) {
        $this->rectGrid = $rectangle;
        $this->color = $color;
        $this->level = $recursionLevel;
        $this->tiles = [];
        for ($i = 0; $i < 9; $i++) {
            $this->tiles[] = ['char' => " ", 'canChallenge' => $recursionLevel < 2, 'color' => $color];
        }

        $this->tileWidth = $this->rectGrid->getWidth()/3;
        $this->tileHeight = $this->rectGrid->getHeight()/3;

        $this->initialX = $this->rectGrid->getX() + $this->tileWidth;
        $this->initialY = $this->rectGrid->getY() + $this->tileHeight;
        $this->endX = $this->rectGrid->getX() + $this->rectGrid->getWidth();
        $this->endY = $this->rectGrid->getY() + $this->rectGrid->getHeight();

        $this->xOffset = $this->tileWidth/4;
        $this->fontSize = $this->tileWidth;
    }

    public function draw()
    {
        // Grid lines
        for ($y = $this->initialY; $y < $this->endY; $y += $this->tileHeight) {
            // Vertical
            for ($x = $this->initialX; $x < $this->endX; $x += $this->tileWidth) {
                Draw::line($x, $this->rectGrid->getY(), $x, $this->endY, $this->color);
            }
            // Horizontal
            Draw::line($this->rectGrid->getX(), $y, $this->endX, $y, $this->color);
        }

        // Grid letters: "X", "O" or " "
        for ($i = 0; $i < 9; $i++) {
            $x = $this->rectGrid->getX() + ($this->tileWidth * ($i % 3));
            $y = $this->rectGrid->getY() + ($this->tileHeight * ($i - ($i % 3)) / 3);
            Text::draw($this->tiles[$i]['char'], $x+$this->xOffset, $y, $this->fontSize, $this->tiles[$i]['color']);
        }
    }
}