// src/errors/errors.odin
package errors

import "core:fmt"

Error :: struct {
    file: string,
    line: int,
    col:  int,
    msg:  string,
}

format :: proc(e: Error) -> string {
    return fmt.tprintf("%s:%d:%d - error: %s", e.file, e.line, e.col, e.msg)
}
