#version 410 core

layout (points) in;

uniform mat4 u_ModelViewProjectionMatrix;
uniform mat4 u_NormalMatrix;
uniform mat4 u_ModelViewMatrix;
uniform mat4 u_ViewportMatrix;

uniform int u_clip;
uniform vec3 u_clip_point;
uniform vec3 u_clip_normal;

uniform vec2 u_ViewportSize = vec2(800, 600);

noperspective out vec3 v_Position;
noperspective out vec3 altitude;

uniform samplerBuffer coordinates;
uniform usamplerBuffer index;

layout (triangle_strip , max_vertices = 24) out;

flat in int[] v_id;
flat out int id;
out vec3 v_Normal;
uniform float u_alpha;

#define LARGE_DISTANCE 1000000

void
make_triangle( vec4 x0 , vec4 x1 , vec4 x2 , int d1 , int d2 , int d3 ) {

  vec4 u = x1 - x0;
  vec4 v = x2 - x0;
  vec3 n = normalize(mat3(u_NormalMatrix) * cross(u.xyz,v.xyz));
  //if (floor(u_alpha) * n[2] < 0) return; // normal is facing away, this will be false if there is any transparency active

  vec4 p0 = u_ModelViewProjectionMatrix * x0;
  vec4 p1 = u_ModelViewProjectionMatrix * x1;
  vec4 p2 = u_ModelViewProjectionMatrix * x2;

  vec2 q0 = p0.xy / p0.w;
  vec2 q1 = p1.xy / p1.w;
  vec2 q2 = p2.xy / p2.w;

  vec2 v1 = u_ViewportSize * (q1 - q0);
  vec2 v2 = u_ViewportSize * (q2 - q0);
  vec2 v3 = u_ViewportSize * (q2 - q1);

  float area = abs(v1.x * v2.y - v1.y * v2.x); // twice the area

  float a1 = area / length(v3);
  float a2 = area / length(v2);
  float a3 = area / length(v1);

  float h1 = (1 - d1) * LARGE_DISTANCE + d1 * a1;
  float h2 = (1 - d2) * LARGE_DISTANCE + d2 * a2;
  float h3 = (1 - d3) * LARGE_DISTANCE + d3 * a3;

  gl_Position = p0;
  v_Position  = (u_ModelViewMatrix * x0).xyz;
  altitude    = vec3(h1, 0, 0);
  id = v_id[0];
  v_Normal = n;
  EmitVertex();

  gl_Position = p1;
  v_Position  = (u_ModelViewMatrix * x1).xyz;
  altitude    = vec3(0, h2, 0);
  id = v_id[0];
  v_Normal = n;
  EmitVertex();

  gl_Position = p2;
  v_Position  = (u_ModelViewMatrix * x2).xyz;
  altitude    = vec3(0, 0, h3);
  id = v_id[0];
  v_Normal = n;

  gl_PrimitiveID = gl_PrimitiveIDIn;
  EmitVertex();

  EndPrimitive();
}

void
main() {

  uint i0 = texelFetch(index, 6 * v_id[0]    ).r;
  uint i1 = texelFetch(index, 6 * v_id[0] + 1).r;
  uint i2 = texelFetch(index, 6 * v_id[0] + 2).r;
  uint i3 = texelFetch(index, 6 * v_id[0] + 3).r;
  uint i4 = texelFetch(index, 6 * v_id[0] + 4).r;
  uint i5 = texelFetch(index, 6 * v_id[0] + 5).r;

  vec3 p0 = texelFetch(coordinates, int(i0)).xyz;
  vec3 p1 = texelFetch(coordinates, int(i1)).xyz;
  vec3 p2 = texelFetch(coordinates, int(i2)).xyz;
  vec3 p3 = texelFetch(coordinates, int(i3)).xyz;
  vec3 p4 = texelFetch(coordinates, int(i4)).xyz;
  vec3 p5 = texelFetch(coordinates, int(i5)).xyz;
  if (u_clip > 0) {
    float result =
      sign(dot(u_clip_normal, p0 - u_clip_point)) +
      sign(dot(u_clip_normal, p1 - u_clip_point)) +
      sign(dot(u_clip_normal, p2 - u_clip_point)) +
      sign(dot(u_clip_normal, p3 - u_clip_point)) +
      sign(dot(u_clip_normal, p4 - u_clip_point)) +
      sign(dot(u_clip_normal, p5 - u_clip_point));
    if (result < 6) return;
  }

  vec4 x0 = vec4(p0, 1.0);
  vec4 x1 = vec4(p1, 1.0);
  vec4 x2 = vec4(p2, 1.0);
  vec4 x3 = vec4(p3, 1.0);
  vec4 x4 = vec4(p4, 1.0);
  vec4 x5 = vec4(p5, 1.0);

  make_triangle( x2 , x1 , x0 , 1 , 1 , 1 );
  make_triangle( x3 , x4 , x5 , 1 , 1 , 1 );

  make_triangle( x0 , x1 , x3 , 0 , 1 , 1 );
  make_triangle( x1 , x4 , x3 , 1 , 0 , 1 );

  make_triangle( x2 , x0 , x3 , 1 , 0 , 1 );
  make_triangle( x2 , x3 , x5 , 1 , 1 , 0 );

  make_triangle( x1 , x2 , x4 , 0 , 1 , 1 );
  make_triangle( x2 , x5 , x4 , 1 , 0 , 1 );

}
