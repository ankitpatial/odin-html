// src/lsp/rpc.odin
package lsp

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// read_message reads one LSP message from stdin using the Content-Length framing protocol.
// Returns the parsed JSON value and true on success, or nil and false on EOF/error.
read_message :: proc() -> (json.Value, bool) {
	header := make([dynamic]byte)
	defer delete(header)

	buf: [1]byte

	// Read byte by byte until we find \r\n\r\n
	for {
		n, err := os.read(os.stdin, buf[:])
		if n == 0 || err != nil {
			return nil, false
		}
		append(&header, buf[0])

		hl := len(header)
		if hl >= 4 &&
			header[hl - 4] == '\r' &&
			header[hl - 3] == '\n' &&
			header[hl - 2] == '\r' &&
			header[hl - 1] == '\n' {
			break
		}
	}

	// Parse Content-Length from headers
	header_str := string(header[:])
	content_length := 0
	for line in strings.split_lines(header_str) {
		trimmed := strings.trim_space(line)
		if strings.has_prefix(trimmed, "Content-Length:") {
			num_str := strings.trim_space(trimmed[len("Content-Length:"):])
			val, ok := strconv.parse_int(num_str)
			if ok {
				content_length = val
			}
		}
	}

	if content_length <= 0 {
		log("error: invalid Content-Length in header")
		return nil, false
	}

	// Read exactly content_length bytes for the body
	body := make([]byte, content_length)
	defer delete(body)

	total_read := 0
	for total_read < content_length {
		n, err := os.read(os.stdin, body[total_read:])
		if n == 0 || err != nil {
			log("error: failed to read message body (read %d of %d)", total_read, content_length)
			return nil, false
		}
		total_read += n
	}

	// Parse JSON
	val, parse_err := json.parse(body[:total_read])
	if parse_err != nil {
		log("error: JSON parse failed: %v", parse_err)
		return nil, false
	}

	return val, true
}

// normalize_id converts a JSON-RPC id so that integer values serialize cleanly.
// JSON parse returns all numbers as f64; this converts round f64 values to i64.
normalize_id :: proc(id: json.Value) -> json.Value {
	#partial switch v in id {
	case json.Float:
		iv := i64(v)
		if f64(iv) == v {
			return json.Value(iv)
		}
	}
	return id
}

// write_response sends a JSON-RPC response with the given id and result.
write_response :: proc(id: json.Value, result: json.Value) {
	resp := json.Object{}
	resp["jsonrpc"] = json.Value("2.0")
	resp["id"] = normalize_id(id)
	resp["result"] = result

	send_json(resp)
}

// write_error sends a JSON-RPC error response.
write_error :: proc(id: json.Value, code: int, message: string) {
	err_obj := json.Object{}
	err_obj["code"] = json.Value(i64(code))
	err_obj["message"] = json.Value(message)

	resp := json.Object{}
	resp["jsonrpc"] = json.Value("2.0")
	resp["id"] = normalize_id(id)
	resp["error"] = json.Value(err_obj)

	send_json(resp)
}

// write_notification sends a JSON-RPC notification (no id field).
write_notification :: proc(method: string, params: json.Value) {
	notif := json.Object{}
	notif["jsonrpc"] = json.Value("2.0")
	notif["method"] = json.Value(method)
	notif["params"] = params

	send_json(notif)
}

// send_json marshals a JSON object and writes it to stdout with Content-Length framing.
send_json :: proc(obj: json.Object) {
	marshaled, merr := json.marshal(obj)
	if merr != nil {
		log("error: failed to marshal JSON response: %v", merr)
		return
	}
	defer delete(marshaled)

	body := string(marshaled)
	header := fmt.tprintf("Content-Length: %d\r\n\r\n", len(body))

	os.write(os.stdout, transmute([]byte)header)
	os.write(os.stdout, marshaled)
}

// log writes a message to stderr for debugging.
log :: proc(format: string, args: ..any) {
	fmt.eprintfln(format, ..args)
}
