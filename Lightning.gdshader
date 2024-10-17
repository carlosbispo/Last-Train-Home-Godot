shader_type canvas_item;
const int dither_buffer[64] = int[64] (
  0,  32, 8,  40, 2,  34, 10, 42, /* 8x8 Bayer ordered dithering */
  48, 16, 56, 24, 50, 18, 58, 26, /* pattern. Each input pixel */
  12, 44, 4,  36, 14, 46, 6,  38, /* is scaled to the 0..63 range */
  60, 28, 52, 20, 62, 30, 54, 22, /* before looking in this table */
  3,  35, 11, 43, 1,  33, 9,  41, /* to determine the action. */
  51, 19, 59, 27, 49, 17, 57, 25,
  15, 47, 7,  39, 13, 45, 5,  37,
  63, 31, 55, 23, 61, 29, 53, 21
);

const float STEPS = 4.0;
const float CENTER_PERCENT = 0.8;
const float PI = 3.1415926;

// Godot does not support arrays, that sucks...
uniform vec2 position0;
uniform vec2 position1;
uniform vec2 position2;
uniform vec2 position3;
uniform vec2 position4;
uniform vec2 position5;
uniform vec2 position6;
uniform vec2 position7;
uniform vec2 position8;
uniform vec2 position9;

uniform vec4 color0;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;
uniform vec4 color5;
uniform vec4 color6;
uniform vec4 color7;
uniform vec4 color8;
uniform vec4 color9;

uniform float radii0;
uniform float radii1;
uniform float radii2;
uniform float radii3;
uniform float radii4;
uniform float radii5;
uniform float radii6;
uniform float radii7;
uniform float radii8;
uniform float radii9;

uniform vec2 camera_pos;
uniform vec3 ambient;
uniform vec2 screen_size;

float get_dither_buffer(int idx){
  for(int i=0;i<64;i++){
    if(i==idx)return float(dither_buffer[i]);
  }
  return 0.;
}

vec2 get_position(int index) {
	if (index == 0) return position0;
	if (index == 1) return position1;
	if (index == 2) return position2;
	if (index == 3) return position3;
	if (index == 4) return position4;
	if (index == 5) return position5;
	if (index == 6) return position6;
	if (index == 7) return position7;
	if (index == 8) return position8;
	if (index == 9) return position9;
}

float get_radii(int index) {
	if (index == 0) return radii0;
	if (index == 1) return radii1;
	if (index == 2) return radii2;
	if (index == 3) return radii3;
	if (index == 4) return radii4;
	if (index == 5) return radii5;
	if (index == 6) return radii6;
	if (index == 7) return radii7;
	if (index == 8) return radii8;
	if (index == 9) return radii9;
}

vec4 get_color(int index) {
	if (index == 0) return color0;
	if (index == 1) return color1;
	if (index == 2) return color2;
	if (index == 3) return color3;
	if (index == 4) return color4;
	if (index == 5) return color5;
	if (index == 6) return color6;
	if (index == 7) return color7;
	if (index == 8) return color8;
	if (index == 9) return color9;
}

float get_dipher(vec2 xy) {
	int x = int(mod(floor(abs(xy.x)), 8.0));
	int y = int(mod(floor(abs(xy.y)), 8.0));
	return(get_dither_buffer(x*8+y)-32.)/32.;
}

float get_mask(float d, float radius) {
	float value = 0.0;
	float center_percent = CENTER_PERCENT;
	if (d<radius*center_percent) {
		return 1.0;
	}
	float shifted_d=max(0.0, d-radius*center_percent);
	value=1.0-(shifted_d/(radius*(1.0-center_percent)));
	float cur_step=floor(value/(1.0/STEPS));
	value = cur_step*1.0/STEPS;
	return value;
}

vec4 light_color(vec2 screen_coords) {
	vec2 pixel_pos = screen_coords;
	vec3 light_color = vec3(0.0, 0.0, 0.0);
	float mask = 0.0;
	
	for (int i = 0;i<10;i++) {
		vec2 pos = get_position(i)-camera_pos;
		vec4 col = get_color(i);
		if (col.a == 0.0) continue;
		float dist = length(pos-pixel_pos);
		float radius = get_radii(i);
		if (radius == 0.0) continue;
		float dither = get_dipher(pixel_pos-pos);
		float dither_dist=dist-floor(dither*radius/STEPS/4.0);
		if (dither_dist<radius) 
			mask+=get_mask(dither_dist, radius);

			light_color+=col.rgb*(cos(min(dist/1.2,radius)/radius*PI)*0.5+0.5)*col.a;
	
	}
	mask = min(mask, 1.0);
	light_color *= mask;
	light_color = max(light_color, ambient);
	return vec4(light_color, 1.0);
}


void fragment(){
	COLOR = texture(TEXTURE, UV);
	vec2 pos = vec2(UV.x, 1.0 - UV.y);
	COLOR = COLOR * light_color(pos * screen_size);
}