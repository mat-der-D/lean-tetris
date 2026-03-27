import Lake
open Lake DSL
open System (FilePath)

package stopwatch

lean_lib Stopwatch
lean_lib Tetris

target terminalO (pkg : NPackage __name__) : FilePath := do
  let oFile := pkg.buildDir / "c_src" / "terminal.o"
  let srcFile := pkg.dir / "c_src" / "terminal.c"
  let srcJob ← inputFile srcFile false
  let lean ← getLeanInstall
  buildO oFile srcJob #[s!"-I{lean.includeDir}"] #[]

lean_exe tetris where
  root := `TetrisMain
  moreLinkObjs := #[terminalO]
