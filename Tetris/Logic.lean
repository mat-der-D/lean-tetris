import Tetris.Types
import Tetris.Tetrominoes

namespace Tetris.Logic

open Tetris

-- ピースの絶対座標リスト（盤面上方は負の row）
def pieceCells (p : Piece) : Array (Int × Int) :=
  (Tetrominoes.shape p.type p.rotation).map fun (dr, dc) =>
    (p.row + dr, p.col + dc)

-- 衝突判定: 盤面外 or 固定済みセルと重なる → false
def isValid (board : Board) (p : Piece) : Bool :=
  (pieceCells p).all fun (r, c) =>
    c >= 0 && c < (boardW : Int) && r < (boardH : Int) &&
    (r < 0 || board[boardIdx r.toNat c.toNat]! == none)

-- 移動（衝突時は元の Piece を返す）
def tryMove (board : Board) (p : Piece) (dr dc : Int) : Piece :=
  let p' := { p with row := p.row + dr, col := p.col + dc }
  if isValid board p' then p' else p

def moveLeft  (board : Board) (p : Piece) : Piece := tryMove board p 0 (-1)
def moveRight (board : Board) (p : Piece) : Piece := tryMove board p 0 1
def moveDown  (board : Board) (p : Piece) : Piece := tryMove board p 1 0

-- 回転（衝突時は元の Piece を返す）
def rotateCW (board : Board) (p : Piece) : Piece :=
  let p' := { p with rotation := (p.rotation + 1) % 4 }
  if isValid board p' then p' else p

def rotateCCW (board : Board) (p : Piece) : Piece :=
  let p' := { p with rotation := (p.rotation + 3) % 4 }
  if isValid board p' then p' else p

-- ハードドロップ: 最下部まで落とす
partial def hardDrop (board : Board) (p : Piece) : Piece :=
  let p' := moveDown board p
  if p' == p then p else hardDrop board p'

-- ミノを盤面に固定
def lockPiece (board : Board) (p : Piece) : Board :=
  (pieceCells p).foldl (fun b (r, c) =>
    if r >= 0 && r < boardH && c >= 0 && c < boardW
    then b.set! (boardIdx r.toNat c.toNat) (some p.type)
    else b
  ) board

-- 揃ったラインを消去し、消去ライン数を返す
def clearLines (board : Board) : Board × Nat :=
  let rows := Array.range boardH |>.map (fun r =>
    board.extract (r * boardW) ((r + 1) * boardW))
  let kept    := rows.filter (fun row => row.any (· == none))
  let cleared := boardH - kept.size
  let empty   := Array.replicate boardW none
  let newRows := Array.replicate cleared empty ++ kept
  (newRows.foldl (· ++ ·) #[], cleared)

-- スコア加算（テトリス標準）
def scoreForLines (cleared level : Nat) : Nat :=
  match cleared with
  | 0 => 0
  | 1 => 100 * (level + 1)
  | 2 => 300 * (level + 1)
  | 3 => 500 * (level + 1)
  | _ => 800 * (level + 1)

-- レベル → 落下間隔（ticks、1 tick ≈ 0.1s）
def dropIntervalForLevel (level : Nat) : Nat :=
  match level with
  | 0 => 10 | 1 => 9 | 2 => 8 | 3 => 7 | 4 => 6 | 5 => 5
  | 6 => 4  | 7 => 3 | 8 => 2 | 9 => 2  | _ => 1

-- 新しいピースをスポーン（盤面上部中央）
def spawnPiece (t : TetroType) : Piece :=
  { type := t, row := 1, col := 4, rotation := 0 }

-- ロック後の処理（lockPiece → clearLines → spawn → ゲームオーバー判定）
private def lockAndSpawn (state : GameState) (rand : TetroType) : GameState :=
  let newBoard          := lockPiece state.board state.current
  let (clearedBoard, n) := clearLines newBoard
  let newLines          := state.lines + n
  let newLevel          := min 10 (newLines / 10)
  let newScore          := state.score + scoreForLines n newLevel
  let newPiece          := spawnPiece state.next
  let isOver            := !isValid clearedBoard newPiece
  { board        := clearedBoard
    current      := newPiece
    next         := rand
    score        := newScore
    level        := newLevel
    lines        := newLines
    dropCounter  := 0
    dropInterval := dropIntervalForLevel newLevel
    paused       := false
    gameOver     := isOver
    quit         := false }

-- メインの状態遷移（純粋）
-- rand: スポーン時に次の next として使う乱数ミノ（毎フレーム渡す）
def update (state : GameState) (key : KeyEvent) (rand : TetroType) : GameState :=
  match key with
  | .Quit  => { state with quit := true }
  | .Pause => { state with paused := !state.paused }
  | _ =>
    if state.paused || state.gameOver then state
    else match key with
    | .Left     => { state with current := moveLeft  state.board state.current }
    | .Right    => { state with current := moveRight state.board state.current }
    | .SoftDrop => { state with current := moveDown  state.board state.current }
    | .RotateCW => { state with current := rotateCW  state.board state.current }
    | .RotateCCW=> { state with current := rotateCCW state.board state.current }
    | .HardDrop =>
        let dropped := hardDrop state.board state.current
        lockAndSpawn { state with current := dropped } rand
    | .Tick =>
        if state.dropCounter + 1 < state.dropInterval then
          { state with dropCounter := state.dropCounter + 1 }
        else
          let moved := moveDown state.board state.current
          if moved != state.current then
            { state with current := moved, dropCounter := 0 }
          else
            lockAndSpawn state rand
    | _ => state

end Tetris.Logic
