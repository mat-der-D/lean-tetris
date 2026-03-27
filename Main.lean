import Stopwatch

def main : IO Unit := do
  Stopwatch.FFI.enable_raw
  IO.print "\x1b[2J"
  Stopwatch.render Stopwatch.initialState
  Stopwatch.mainLoop Stopwatch.initialState
  Stopwatch.FFI.disable_raw
