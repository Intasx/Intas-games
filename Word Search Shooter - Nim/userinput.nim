import "lib/raylib"
import "lib/raygui"
import grid

from strutils import toLowerAscii
from math import floor

type Entity* = enum
    Player, Enemy

var
    selLetter: grid.letterInfo         # Letters choosed by the player
    oldColor: Color                    # Color of a letter before the user clicks it
    pos:      tuple[x: int, y: int]    # Position of a clicked letter
    letterList = newSeq[letterInfo]()  # Contains every letter the user clicked
    oldPos     = (x: -1, y: -1)        # Used to avoid the player to click the same letter twice
    wordsFound = 0                     # Used to control when the player completes the level

## Returns the x-y coords of a letter according to the mouse position
proc findLetterPos(letters: gridArray): tuple[x: int, y: int] = 
    let mousePos = GetMousePosition()
    for y in 0 ..< gridHeight:
        for x in 0 ..< gridWidth:
            if CheckCollisionPointRec(mousePos, letters[y][x].rect):
                return (x: x, y: y)
    return (x: -1, y: -1)

## Returns the player's selected word orientation
proc checkOrientation(list: seq[letterInfo], i: int): WordDirection =
    let 
        toTheRight = list[i].x-list[i+1].x == -1
        toBottom = list[i].y-list[i+1].y == -1
    if toTheRight and toBottom:
        return WordDirection.Dia
    elif toTheRight:
        return WordDirection.Hor
    elif toBottom:
        return WordDirection.Ver
    return WordDirection.None

## Determines whether the word is connected
## Used to check if the player didn't just click letters at random positions
proc isWordConnected(list: seq[letterInfo]): bool =
    var ori = list.checkOrientation(0)
    if ori == WordDirection.None: return false
    for i in countup(0, list.len div 2, 2):
        if list.checkOrientation(i) == WordDirection.None:
            return false
    return true

## Mouse handler
proc mouse*(letters: var gridArray) =
    pos = letters.findLetterPos
    if pos.x != oldPos.x or pos.y != oldPos.y:
        if oldPos.x != -1:
            letters[oldPos.y][oldPos.x].color = oldColor
        selLetter = letters[pos.y][pos.x]
        oldColor = selLetter.color
        letters[pos.y][pos.x].color = YELLOW
        oldPos.x = pos.x
        oldPos.y = pos.y

## Click handler
proc mousePressed*(button: int, letters: var gridArray) =
    let selPos = Vector2(x: pos.x.float, y: pos.y.float)
    if button == 0 and grid.insideBody(selPos) and selLetter.color != YELLOW:
        letterList.add(selLetter)
        oldPos.x = -1
        oldPos.y = -1
    elif button == 1 and letterList.len > 0:
        for c in letterList:
            letters[c.y][c.x].color = grid.enemyColor
        letterList.setLen(0)

proc isWordInList(word: string): bool =
    for w in wordsLeft:
        if w.word == word.toLowerAscii:
            return true
    return false

proc damage*(who: Entity, lettersOnScreen: var gridArray) = 
    if who == Entity.Enemy:
        enemyHP.width = enemyHP.width - float(100/amountWords)
        wordsFound += 1
        if wordsFound >= wordsLeft.len:
            grid.levelComplete = true
            grid.insertWord(4, 1, WordDirection.Hor, "Level complete! Any key to continue", WHITE, lettersOnScreen)
            wordsLeft.setLen(0)
    elif who == Entity.Player:
        playerHP.width = playerHP.width - float(100/amountWords)
        if floor(playerHP.width) <= 0.0:
            grid.gameOver = true
            grid.insertWord(4, 1, WordDirection.Hor, "Game over! Any key to reset", WHITE, lettersOnScreen)
            wordsLeft.setLen(0)

proc clearWord(lettersOnScreen: var gridArray, wordFound: bool, word: string, letterList: var seq[letterInfo]) =
    if wordFound:
        for i, w in wordsLeft:
            if w.word == word.toLowerAscii:
                insertWord(w.x, w.y, WordDirection.Hor, "---------", BLACK, lettersOnScreen)
                break
    else:
        for w in letterList:
            lettersOnScreen[w.y][w.x].color = enemyColor
    letterList.setLen(0)


proc button*(lettersOnScreen: var gridArray) =
    let pressed = GuiButton(Rectangle(x: 80, y: 500, width: 80, height: 40), "Shoot!")
    var word = ""
    if pressed and letterList.len > 1:
        for c in letterList:
            word &= c.letter
        if letterList.isWordConnected and word.isWordInList:
            Entity.Enemy.damage(lettersOnScreen)
            lettersOnScreen.clearWord(true, word, letterList)
        else:
            Entity.Player.damage(lettersOnScreen)
            lettersOnScreen.clearWord(false, word, letterList)

