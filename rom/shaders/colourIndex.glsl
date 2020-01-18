vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	return vec4( texture_coords.x, texture_coords.y, 0, 1 );
}