import Tetris.Types
import Tetris.Tetrominoes
import Tetris.Logic

namespace Tetris.Render

open Tetris

private def reset : String := "\x1b[0m"

-- ゴーストピースの位置（ハードドロップ先）
def ghostPiece (board : Board) (p : Piece) : Piece :=
  Logic.hardDrop board p

-- 盤面の 1 セルを文字列に変換
private def renderCell
    (boardCell : Option TetroType)
    (pieceType : TetroType)
    (isCurrent : Bool)
    (isGhost   : Bool) : String :=
  if isCurrent then
    Tetrominoes.color pieceType ++ "  " ++ reset
  else if isGhost then
    "\x1b[2m" ++ Tetrominoes.color pieceType ++ "  " ++ reset
  else
    match boardCell with
    | some t => Tetrominoes.color t ++ "  " ++ reset
    | none   => "  "

-- 盤面を文字列に変換（ゴーストピース・現在ミノを合成）
def boardToString (board : Board) (current : Piece) : String :=
  let ghost    := ghostPiece board current
  let curCells := Logic.pieceCells current
  let gstCells := Logic.pieceCells ghost
  let border   := "┌" ++ String.ofList (List.replicate (boardW * 2) '─') ++ "┐\n"
  let bottom   := "└" ++ String.ofList (List.replicate (boardW * 2) '─') ++ "┘"
  let rows := Array.range boardH |>.map fun (r : Nat) =>
    let rowStr := Array.range boardW |>.map fun (c : Nat) =>
      let ri := Int.ofNat r
      let ci := Int.ofNat c
      let isCur := curCells.any fun cell => cell == (ri, ci)
      let isGst := !isCur && gstCells.any fun cell => cell == (ri, ci)
      let bc    := board[boardIdx r c]!
      renderCell bc current.type isCur isGst
    "│" ++ rowStr.foldl (· ++ ·) "" ++ "│\n"
  border ++ rows.foldl (· ++ ·) "" ++ bottom

-- 数値を左ゼロ埋め
private def padLeft (width : Nat) (s : String) : String :=
  let pad := width - min width s.length
  String.ofList (List.replicate pad '0') ++ s

-- ネクストミノのプレビュー（4×4 グリッド）
private def nextPreview (t : TetroType) : String :=
  let cells := Tetrominoes.shape t 0
  let rows := Array.range 4 |>.map fun (r : Nat) =>
    let rowStr := Array.range 4 |>.map fun (c : Nat) =>
      let dr' := Int.ofNat r - 1
      let dc  := Int.ofNat c - 1
      if cells.any fun cell => cell == (dr', dc) then
        Tetrominoes.color t ++ "  " ++ reset
      else "  "
    "  " ++ rowStr.foldl (· ++ ·) "" ++ "\n"
  rows.foldl (· ++ ·) ""

-- ゲーム画面全体を文字列に変換
def stateToString (state : GameState) : String :=
  let board   := boardToString state.board state.current
  let overlay :=
    if state.gameOver then "\n  GAME OVER  (q: quit)\n"
    else if state.paused then "\n  PAUSED     (p: resume)\n"
    else ""
  board ++ "\n" ++
  "  NEXT\n" ++
  nextPreview state.next ++
  "\n" ++
  "  SCORE\n" ++
  "  " ++ padLeft 6 (toString state.score) ++ "\n" ++
  "\n" ++
  "  LEVEL  " ++ toString state.level ++ "\n" ++
  "  LINES  " ++ toString state.lines ++ "\n" ++
  "  a/d:move  w/k:rotateCW  j:rotateCCW  Space:drop  p:pause  q:quit\n" ++
  overlay

-- ANSI エスケープで画面を上書き描画
def render (state : GameState) : IO Unit := do
  IO.print "\x1b[?25l"
  IO.print "\x1b[H"
  IO.print (stateToString state)
  (← IO.getStdout).flush
  IO.print "\x1b[?25h"

end Tetris.Render
