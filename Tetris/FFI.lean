namespace Tetris.FFI

@[extern "enable_raw"]  opaque enable_raw  : IO Unit
@[extern "disable_raw"] opaque disable_raw : IO Unit
@[extern "read_byte"]   opaque read_byte   : IO UInt8

end Tetris.FFI
