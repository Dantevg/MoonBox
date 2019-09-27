// http://blogs.love2d.org/content/beginners-guide-shaders

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	vec4 pixel = Texel( texture, texture_coords ); //This is the current pixel color
	return pixel * vec4( 2.0, 0.5 / texture_coords.y, 0.5 / texture_coords.x, 1.0 );
}