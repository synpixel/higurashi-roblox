export type Controls = {
	append: (
		speaker: string?,
		text: string?,
		behavior: "Line_Normal" | "Line_WaitForInput" | "Line_ContinueAfterTyping" | string
	) -> (),
	clear: () -> (),
	hide: () -> (),
	set_skip_allowed: (on: boolean) -> (),
	set_background: (name: string) -> (),
	draw_scene: (name: string, fade_in_time: number) -> (),
	fade_out_background: (duration: number) -> (),
	draw_sprite: (id: number, name: string, offset: vector, fade_in_time: number?, yield: boolean) -> (),
	move_sprite: (id: number, offset: vector, duration: number, yield: boolean) -> (),
	fade_out_sprite: (id: number, duration: number, yield: boolean) -> (),
	fade_out_all_sprites: (duration: number, yield: boolean) -> (),
	draw_character: (
		id: number,
		name: string,
		index: string,
		offset: vector,
		fade_in_time: number?,
		yield: boolean
	) -> (),
	play_music: (id: number, name: string) -> (),
	stop_music: (id: number) -> (),
	fade_out_music: (id: number, duration: number, yield: boolean) -> (),
	play_sound_effect: (name: string) -> (),
	play_movie: (name: string) -> (),
	prompt_selection: (options: { string }) -> (),
	wait: (milliseconds: number) -> (),
	save: (chapter: string, stage: string) -> (),
	set: (var: string, value: any) -> (),
	get: (var: string) -> any,
	set_global_flag: (flag: string, value: any) -> (),
	get_global_flag: (flag: string) -> any,
	noop: () -> (), -- unimplemented methods
}

return nil
