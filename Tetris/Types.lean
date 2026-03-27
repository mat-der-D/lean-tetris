namespace Tetris

def boardW : Nat := 10
def boardH : Nat := 20

inductive TetroType where
  | I | O | T | S | Z | J | L
  deriving Repr, BEq, Inhabited

abbrev Board := Array (Option TetroType)

def emptyBoard : Board := Array.replicate (boardW * boardH) none

def boardIdx (row col : Nat) : Nat := row * boardW + col

structure Piece where
  type     : TetroType
  row      : Int
  col      : Int
  rotation : Nat
  deriving Repr, BEq

structure GameState where
  board        : Board
  current      : Piece
  next         : TetroType
  score        : Nat
  level        : Nat
  lines        : Nat
  dropCounter  : Nat
  dropInterval : Nat
  paused       : Bool
  gameOver     : Bool
  quit         : Bool

inductive KeyEvent where
  | Left | Right | SoftDrop | RotateCW | RotateCCW
  | HardDrop | Pause | Quit | Tick | Unknown
  deriving Repr

end Tetris
