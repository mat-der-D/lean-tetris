import Tetris

open Tetris

def mkInitialState : IO GameState := do
  let cur ← Input.randomTetroType
  let nxt ← Input.randomTetroType
  return {
    board        := emptyBoard
    current      := Logic.spawnPiece cur
    next         := nxt
    score        := 0
    level        := 0
    lines        := 0
    dropCounter  := 0
    dropInterval := Logic.dropIntervalForLevel 0
    paused       := false
    gameOver     := false
    quit         := false }

partial def gameLoop (state : GameState) : IO Unit := do
  let key  ← Input.readKey
  let rand ← Input.randomTetroType
  let state' := Logic.update state key rand
  Render.render state'
  if not state'.quit && not state'.gameOver then
    gameLoop state'

def main : IO Unit := do
  FFI.enable_raw
  IO.print "\x1b[2J"
  IO.print "\x1b[?25l"
  let s ← mkInitialState
  Render.render s
  gameLoop s
  IO.print "\x1b[?25h\n"
  FFI.disable_raw
