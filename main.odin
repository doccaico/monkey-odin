package main

import "core:fmt"
import "core:mem"
import "core:os"

import "monkey"

main :: proc() {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}


	fmt.println("Monkey Lang")
	// fmt.println(token.LPAREN)

	v := monkey.new_token(monkey.COMMA, ',')
	defer monkey.delete_token(v)
	// defer delete(v.literal)

	fmt.println(v.type)
	fmt.println(v.literal)
	// stream := os.stream_from_handle(os.stdin)
	// repl.start(stream)
}
