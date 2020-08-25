import "lib/raylib"
import "lib/raygui"
import grid

from strutils import toLowerAscii
from math import floor

var
    selLetter: grid.letterInfo
    letterList = newSeq[letterInfo]()
    oldColor: Color
    oldPos = (x: -1, y: -1)
    pos: tuple[x: int, y: int]
    wordsFound = 0

proc findLetterPos(letters: gridArray): tuple[x: int, y: int] = 
    let mousePos = GetMousePosition()
    for y in 0 ..< gridHeight:
        for x in 0 ..< gridWidth:
            if CheckCollisionPointRec(mousePos, letters[y][x].rect):
                return (x: x, y: y)
    return (x: -1, y: -1)

proc checkOrientation(list: seq[letterInfo], i: int): string =
    let 
        toTheRight = list[i].x-list[i+1].x == -1
        toBottom = list[i].y-list[i+1].y == -1
    if toTheRight and toBottom:
        return "dia"
    elif toTheRight:
        return "hor"
    elif toBottom:
        return "ver"
    return ""

proc isWordConnected(list: seq[letterInfo]): bool =
    var ori = list.checkOrientation(0)
    if ori == "": return false
    for i in countup(0, list.len div 2, 2):
        if list.checkOrientation(i) == "":
            return false
    return true

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

proc mousePressed*(button: int, letters: var gridArray) =
    let selPos = Vector2(x: float(pos.x), y: float(pos.y))
    if button == 0 and grid.insideBody(selPos) and selLetter.color != YELLOW:
        letterList.add(selLetter)
        oldPos.x = -1
        oldPos.y = -1
        #echo letterList
    elif button == 1 and letterList.len > 0:
        for c in letterList:
            letters[c.y][c.x].color = grid.enemyColor
        letterList.setLen(0)

proc isWordInList(word: string): bool =
    for w in wordsLeft:
        if w.word == word.toLowerAscii:
            return true
    return false

proc damage*(who: string, lettersOnScreen: var gridArray) = 
    if who == "enemy":
        enemyHP.width = enemyHP.width - float(100/amountWords)
        wordsFound += 1
        if wordsFound >= wordsLeft.len:
            grid.levelComplete = true
            grid.insertWord(4, 1, "hor", "Level complete! Any key to continue", WHITE, lettersOnScreen)
            wordsLeft.setLen(0)
    else:
        playerHP.width = playerHP.width - float(100/amountWords)
        echo playerHP.width
        if floor(playerHP.width) <= 0.0:
            grid.gameOver = true
            grid.insertWord(4, 1, "hor", "Game over! Any key to reset", WHITE, lettersOnScreen)
            wordsLeft.setLen(0)

proc clearWord(lettersOnScreen: var gridArray, wordFound: bool, word: string, letterList: var seq[letterInfo]) =
    if wordFound:
        for i, w in wordsLeft:
            echo w.word
            if w.word == word.toLowerAscii:
                insertWord(w.x, w.y, "hor", "---------", BLACK, lettersOnScreen)
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
            damage("enemy", lettersOnScreen)
            lettersOnScreen.clearWord(true, word, letterList)
            #echo "Damage enemy!"
        else:
            damage("player", lettersOnScreen)
            lettersOnScreen.clearWord(false, word, letterList)
            #echo "Damage player!"


