package main

@(require) import "core:fmt"
@(require) import "core:mem"

init_memory_tracker :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		temp_track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		mem.tracking_allocator_init(&temp_track, context.temp_allocator)
		context.allocator = mem.tracking_allocator(&track)
		context.temp_allocator = mem.tracking_allocator(&temp_track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}

		defer {
			if len(temp_track.allocation_map) > 0 {
				fmt.eprintf(
					"=== %v temp allocations not freed: ===\n",
					len(temp_track.allocation_map),
				)
				for _, entry in temp_track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&temp_track)
		}
	}
}
