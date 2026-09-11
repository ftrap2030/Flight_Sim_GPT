shader_type spatial;
render_mode cull_disabled;
varying vec3 local;
float rounded(vec2 p, vec2 b, float r){return length(max(abs(p)-b+r,0.0))-r;}
void vertex(){local=VERTEX;}
void fragment(){
 vec3 paint=vec3(0.83,0.855,0.85);
 float belly=1.0-smoothstep(-0.65,-0.55,local.y);
 float stripe=(1.0-smoothstep(0.035,0.06,abs(local.y-0.05)))*step(0.0,local.z);
 paint=mix(paint,vec3(0.018,0.13,0.17),max(belly,stripe));
 float cabin=step(3.0,local.z)*step(local.z,25.8)*step(1.6,abs(local.x));
 vec2 pane=vec2(mod(local.z-3.1,0.83)-0.415,local.y-1.12);
 float window=1.0-smoothstep(-0.008,0.008,rounded(pane,vec2(0.13,0.18),0.085));
 float rim=1.0-smoothstep(-0.008,0.008,rounded(pane,vec2(0.16,0.21),0.095));
 paint=mix(paint,vec3(0.42,0.47,0.48),rim*cabin);
 paint=mix(paint,vec3(0.018,0.045,0.058),window*cabin);
 float d=min(min(abs(local.z-1.5),abs(local.z-26.3)),min(abs(local.z-11.1),abs(local.z-12.4)));
 float door=abs(rounded(vec2(d,local.y-0.55),vec2(0.43,0.93),0.12));
 float seam=(1.0-smoothstep(0.009,0.025,door))*step(1.55,abs(local.x));
 paint=mix(paint,vec3(0.27,0.32,0.33),seam*0.8);
 ALBEDO=paint;
 ROUGHNESS=mix(0.3,0.15,window*cabin);
 METALLIC=0.18;
 SPECULAR=0.65;
}
