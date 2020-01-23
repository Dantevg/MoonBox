uniform vec4[64] palette;

vec4 closestColour( vec4 colour ){
	int closestIndex;
	float closestDistance;
	for( int i = 0; i < 64; i++ ){
		float d = distance(colour, palette[i]);
		if( i == 0 || d < closestDistance ){
			closestIndex = i;
			closestDistance = d;
		}
	}
	return palette[closestIndex];
}

vec4 effect( vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords ){
	vec4 pixel = Texel( texture, texture_coords ); //This is the current pixel color
	return closestColour( pixel * colour );
}