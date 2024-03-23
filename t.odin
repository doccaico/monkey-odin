package main

import "core:fmt"
import "core:mem"
import "core:strings"

// @echo off
// 
// if        "%1" == "debug"       ( goto :DEBUG
// ) else if "%1" == "release"     ( goto :RELEASE
// ) else if "%1" == "debug-run"   ( goto :DEBUG_RUN
// ) else if "%1" == "release-run" ( goto :RELEASE_RUN
// ) else (
//   echo Usage:
//   echo     $ make.cmd [debug, release, debug-run, release-run]
//   goto :EOF
// )
// 
// :DEBUG
//   odin build . -debug
// goto :EOF
// 
// :RELEASE
//   odin build . -o:speed
// goto :EOF
// 
// :DEBUG_RUN
//   odin run . -debug
// goto :EOF
// 
// :RELEASE_RUN
//   odin run . -o:speed
// goto :EOF
// 
// REM vim: foldmethod=marker ft=dosbatch fenc=cp932 ff=dos

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
	{
		a := []string{"a", "b"}
		s := strings.join(a, "")
		fmt.println(s)
	}
	{
		// a := []string{"a", "b"}
		s := strings.join([]string{"a", "b"}, "")
		fmt.println(s)
	}
}
