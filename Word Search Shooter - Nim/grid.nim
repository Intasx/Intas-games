## Module that handles grids

import "lib/raylib"
import random
import strutils

const letters* = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" 
]

## Enemy's body parts
const body = [
    Rectangle(x: 17, y: 5,  width: 6, height: 5), # head    
    Rectangle(x: 16, y: 10, width: 8, height: 8), # body  
    Rectangle(x: 10, y: 11, width: 6, height: 2), # leftarm 
    Rectangle(x: 10, y: 9,  width: 3, height: 2), # lefthand
    Rectangle(x: 24, y: 11, width: 7, height: 2), # rightarm
    Rectangle(x: 28, y: 13, width: 3, height: 2), # righthand
    Rectangle(x: 20, y: 18, width: 3, height: 8), # leftleg 
    Rectangle(x: 17, y: 18, width: 3, height: 8)  # rightleg
]

const 
    gridWidth* = 40
    gridHeight* = 30
    colors = [RED, GREEN, BLUE] # Enemy's color

type letterInfo* = tuple[letter: string, color: Color, rect: Rectangle, x: int, y: int]
type gridArray* = array[gridHeight, array[gridWidth, letterInfo]]

type WordDirection* = enum
    None, Hor, Ver, Dia

var
    lettersOnScreen: gridArray
    enemyColor*:     Color
    amountWords*:    int
    enemyHP*         = Rectangle(x: 50, y: 320, width: 100, height: 30)
    playerHP*        = Rectangle(x: 50, y: 400, width: 100, height: 30)
    wordsLeft*       = newSeq[tuple[word: string, x: int, y: int]]()
    gameOver*        = false
    levelComplete*   = false

## LoadFileText returns a ptr char, cast it to string with $
## and split it into a sequence of words
let wordList = ($LoadFileText("englishWords.txt")).split("\n")

# The random numbers must be different every time
randomize()

## true if a given x-y is inside the enemy's body, false otherwise
proc insideBody*(pos: Vector2): bool =
    for rect in body:
        if CheckCollisionPointRec(pos, rect):
            return true
    return false

## used when inserting a word into the grid by a given orientation
## hor: left to right, ver: up to down, dia: up-left to bottom-right
proc moveLetter*(x, y: var int, ori: WordDirection) =
    case ori
        of WordDirection.Hor: inc x
        of WordDirection.Ver: inc y
        of WordDirection.Dia:
            inc x
            inc y
        else: discard

## Checks if a word fits in the enemy's body using the "-" characters
proc wordFits(posx, posy: int, ori: WordDirection, word: string, letters: gridArray): bool =
    var 
        x = posx
        y = posy
    for c in word:
        if letters[y][x].letter != "-":
            return false
        moveLetter(x, y, ori)
    return true

## Insert a word into the enemy's body
proc insertWord*(posx, posy: int, ori: WordDirection, word: string, color: Color, letters: var gridArray) =
    var
        x = posx
        y = posy
    for c in word:
        letters[y][x].letter = $c
        letters[y][x].color = color
        moveLetter(x, y, ori)

## First function to be called when initiating the game
## Generathe the grid and the enemy's body
proc generateGrid*(lettersOnScreen: var gridArray, level: int) =
    var pos: Vector2
    enemyColor = sample(colors)
    # Insert random letters and "-" in the enemy's body
    for y in 0 ..< gridHeight:
        for x in 0 ..< gridWidth:
            pos = Vector2(x: x.float, y: y.float)
            if pos.insideBody:
                lettersOnScreen[y][x].letter = "-"
                lettersOnScreen[y][x].color  = enemyColor
            else:
                lettersOnScreen[y][x].letter = sample(letters)
                lettersOnScreen[y][x].color  = DARKGRAY
            lettersOnScreen[y][x].rect = Rectangle(x: float(x*20), y: float(y*20), width: 20.0, height: 20.0)
            lettersOnScreen[y][x].x = x
            lettersOnScreen[y][x].y = y
    # Insert random words from the list
    var
        words = wordList
        selWord: string
        selOri: WordDirection
        x, y: int
        wordListX = 1
        wordListY = 5
        inserted: bool
    amountWords = rand(3..6)
    let ori = [WordDirection.Hor, WordDirection.Ver, WordDirection.Dia]
    for i in 1 .. amountWords:
        # Depending on the x-y coord and orientation the word
        # may or may not fit, wordFits takes care of that
        inserted = false
        while not inserted:
            selWord = sample(words)
            selOri = sample(ori)
            x = rand(10..31)
            y = rand(5..26)
            if selWord.len > 1 and selWord.len < 10:
                inserted = wordFits(x, y, selOri, selWord, lettersOnScreen)
        # Remove the word to avoid repeats
        words.delete(words.find(selWord))
        # Insert the word into the body
        insertWord(x, y, selOri, selWord.toUpperAscii, enemyColor, lettersOnScreen)
        # Add word to the list
        wordsLeft.add((word: selWord, x: wordListX, y: wordListY))
        inc wordListY
    # Fill the remaining "-" with random letters
    for y in 0 ..< gridHeight:
        for x in 0 ..< gridWidth:
            if lettersOnScreen[y][x].letter == "-":
                lettersOnScreen[y][x].letter = sample(letters)
    insertWord(1, 3, WordDirection.Hor, "WORDS:", WHITE, lettersOnScreen)
    for w in wordsLeft:
        insertWord(w.x, w.y, WordDirection.Hor, w.word.toUpperAscii, WHITE, lettersOnScreen)
    insertWord(3, 15, WordDirection.Hor, "ENEMY", RED, lettersOnScreen)
    insertWord(3, 19, WordDirection.Hor, "YOU", GREEN, lettersOnScreen)
    insertWord(3, 23, WordDirection.Hor, "LEVEL:" & $level, WHITE, lettersOnScreen)

proc drawGrid*(lettersOnScreen: gridArray) =
    for y in 0 ..< gridHeight:
        for x in 0 ..< gridWidth:
            DrawText lettersOnScreen[y][x].letter, x*20, y*20, 20, lettersOnScreen[y][x].color
    DrawRectangleRec(enemyHP, RED)
    DrawRectangleRec(playerHP, GREEN)
