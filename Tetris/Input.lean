import Tetris.FFI
import Tetris.Types
import Tetris.Tetrominoes

namespace Tetris.Input

open Tetris

def readKey : IO KeyEvent := do
  let b ← FFI.read_byte
  return match b with
    | 97  => .Left
    | 100 => .Right
    | 115 => .SoftDrop
    | 119 => .RotateCW   -- 'w'
    | 107 => .RotateCW   -- 'k'
    | 106 => .RotateCCW  -- 'j'
    | 32  => .HardDrop   -- Space
    | 112 => .Pause      -- 'p'
    | 113 => .Quit       -- 'q'
    | 0   => .Tick
    | _   => .Unknown

def randomTetroType : IO TetroType := do
  let n ← IO.rand 0 6
  return Tetrominoes.allTypes[n]!

end Tetris.Input
