
import "lib/raylib"
import grid
import userinput
import random
import times


#  Initialization
# --------------------------------------------------------------------------------------
const
    screenWidth = 800
    screenHeight = 600

proc initGame(letters: var gridArray, level: int, time: var Duration) = 
    letters.generateGrid(level)
    playerHP.width = 100
    enemyHP.width = 100
    time = initDuration(milliseconds = rand(60_000..70_000))

# This function could be a little more elegant...
proc timer(lettersOnScreen: var gridArray, time: var Duration, delta: float32) =
    let dt = initDuration(milliseconds = int32(delta))
    time -= dt
    var
        minutes = time.inMinutes
        seconds = time.inSeconds
    # Time's up, damage player and set a new time
    if minutes == 0 and seconds <= -1:
        time = initDuration(milliseconds = rand(60_000..70_000))
        damage("player", lettersOnScreen)
        return
    seconds -= 60 * (seconds div 60)
    let
        mm = if minutes < 10: ("0" & $minutes) else: $minutes
        ss = if seconds < 10: ("0" & $seconds) else: $seconds
        res = mm & ":" & ss
    #echo dt, " ", res
    grid.insertWord(30, 25, "hor", res, WHITE, lettersOnScreen)


var
    lettersOnScreen: grid.gridArray # 2D array with a tuple: [letter: string, color: Color, rect: Rectangle]
    currentTime: Duration
    level = 1

lettersOnScreen.initGame(1, currentTime)

InitWindow(screenWidth, screenHeight, "Word Search Shooter - Game by Intas")

SetTargetFPS(60)
#--------------------------------------------------------------------------------------

# Main game loop
while not WindowShouldClose():

    #  Update
    # ----------------------------------------------------------------------------------
    if grid.gameOver:
        if GetKeyPressed() != 0:
            level = 1
            grid.gameOver = false
            lettersOnScreen.initGame(level, currentTime)
    elif grid.levelComplete:
        if GetKeyPressed() != 0:
            level += 1
            grid.levelComplete = false
            lettersOnScreen.initGame(level, currentTime)
    else:
        lettersOnScreen.timer(currentTime, GetFrameTime()*1000.0f)
        userinput.mouse(lettersOnScreen)
        if IsMouseButtonPressed(0):   userinput.mousePressed(0, lettersOnScreen)
        elif IsMouseButtonPressed(1): userinput.mousePressed(1, lettersOnScreen)
    discard """
    for i in 0..1000:
        let 
            posY = rand(0..gridHeight-1)
            posX = rand(0..gridWidth-1)
        lettersOnScreen[posY][posX].letter = sample(letters)
    """
    # ----------------------------------------------------------------------------------

    #  Draw
    # ----------------------------------------------------------------------------------
    BeginDrawing()
    ClearBackground(BLACK)

    grid.drawGrid(lettersOnScreen)
    userinput.button(lettersOnScreen)

    EndDrawing()
    # ----------------------------------------------------------------------------------

# De-Initialization
# --------------------------------------------------------------------------------------
CloseWindow()
# --------------------------------------------------------------------------------------