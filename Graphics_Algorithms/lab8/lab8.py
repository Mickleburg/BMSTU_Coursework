import math

import glfw
from OpenGL.GL import *
from OpenGL.GL.shaders import compileProgram, compileShader


WINDOW_WIDTH = 900
WINDOW_HEIGHT = 800
WINDOW_TITLE = "ЛР8 - ЛР6 на шейдерах OpenGL"


# Состояние сцены / управления
view_alpha = 25.0
view_beta = -35.0
camera_distance = 5.2
object_scale = 1.0
fill = True
texture_enabled = True
animation_enabled = True
show_bounds = True

# Несколько источников света, как в ЛР6. Переключаются клавишами 1/2/3.
light_enabled = [True, True, True]
light_positions = [
    [2.8, 2.2, 2.0, 1.0],
    [-2.6, 1.4, 1.6, 1.0],
    [0.0, 2.8, -2.7, 1.0],
]
light_ambient = [
    [0.05, 0.04, 0.03],
    [0.02, 0.03, 0.05],
    [0.00, 0.00, 0.00],
]
light_diffuse = [
    [0.95, 0.82, 0.60],
    [0.35, 0.50, 0.95],
    [0.45, 0.95, 0.55],
]
light_specular = [
    [1.00, 0.92, 0.78],
    [0.35, 0.50, 0.95],
    [0.45, 0.95, 0.55],
]

# Движение тела с отражением от границ ограничивающего объема.
box_min = [-1.45, -1.05, -1.45]
box_max = [1.45, 1.05, 1.45]
object_radius = 0.36
object_pos = [0.0, 0.0, 0.0]
object_vel = [0.75, 0.52, 0.63]
spin_angle = 0.0

shader_program = None
checker_texture = None


VERTEX_SHADER = """
#version 120

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_tex_coord;

void main()
{
    vec4 eye_position = gl_ModelViewMatrix * gl_Vertex;
    v_position = eye_position.xyz;
    v_normal = normalize(gl_NormalMatrix * gl_Normal);
    v_tex_coord = gl_MultiTexCoord0.xy;
    gl_Position = gl_ProjectionMatrix * eye_position;
}
"""


FRAGMENT_SHADER = """
#version 120

struct LightSource
{
    vec4 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    int enabled;
};

uniform LightSource lights[3];
uniform vec3 globalAmbient;
uniform vec3 materialAmbient;
uniform vec3 materialDiffuse;
uniform vec3 materialSpecular;
uniform float materialShininess;
uniform bool textureEnabled;
uniform sampler2D surfaceTexture;

varying vec3 v_position;
varying vec3 v_normal;
varying vec2 v_tex_coord;

void main()
{
    vec3 normal = normalize(v_normal);
    vec3 view_dir = normalize(-v_position);
    vec3 diffuse_color = materialDiffuse;

    if (textureEnabled) {
        diffuse_color *= texture2D(surfaceTexture, v_tex_coord).rgb;
    }

    vec3 color = globalAmbient * materialAmbient;

    for (int i = 0; i < 3; i++) {
        if (lights[i].enabled == 0) {
            continue;
        }

        vec3 light_vector = lights[i].position.xyz - v_position;
        float distance_to_light = max(length(light_vector), 0.0001);
        vec3 light_dir = light_vector / distance_to_light;

        float diffuse_power = max(dot(normal, light_dir), 0.0);
        vec3 reflect_dir = reflect(-light_dir, normal);
        float specular_power = 0.0;

        if (diffuse_power > 0.0) {
            specular_power = pow(max(dot(view_dir, reflect_dir), 0.0), materialShininess);
        }

        float attenuation = 1.0 / (1.0 + 0.03 * distance_to_light + 0.01 * distance_to_light * distance_to_light);
        color += attenuation * (
            lights[i].ambient * materialAmbient +
            lights[i].diffuse * diffuse_color * diffuse_power +
            lights[i].specular * materialSpecular * specular_power
        );
    }

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
"""


# Геометрия икосаэдра
def get_icosahedron_geometry(size: float):
    phi = (1.0 + math.sqrt(5.0)) / 2.0
    radius = size / 2.0
    norm = math.sqrt(1.0 + phi * phi)

    vertices = [
        (-1,  phi,  0),
        ( 1,  phi,  0),
        (-1, -phi,  0),
        ( 1, -phi,  0),
        ( 0, -1,  phi),
        ( 0,  1,  phi),
        ( 0, -1, -phi),
        ( 0,  1, -phi),
        ( phi,  0, -1),
        ( phi,  0,  1),
        (-phi,  0, -1),
        (-phi,  0,  1),
    ]

    vertices = [
        (x * radius / norm, y * radius / norm, z * radius / norm)
        for x, y, z in vertices
    ]

    faces = [
        (0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
        (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
        (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
        (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)
    ]
    return vertices, faces


def normalize(v):
    length = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    if length < 1e-9:
        return 0.0, 1.0, 0.0
    return v[0] / length, v[1] / length, v[2] / length


def face_normal(vertices, face):
    a = vertices[face[0]]
    b = vertices[face[1]]
    c = vertices[face[2]]

    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]

    n = normalize((
        uy * vz - uz * vy,
        uz * vx - ux * vz,
        ux * vy - uy * vx,
    ))

    center = (
        (a[0] + b[0] + c[0]) / 3.0,
        (a[1] + b[1] + c[1]) / 3.0,
        (a[2] + b[2] + c[2]) / 3.0,
    )
    if n[0] * center[0] + n[1] * center[1] + n[2] * center[2] < 0.0:
        n = (-n[0], -n[1], -n[2])
    return n


def set_perspective_projection(fov_deg, aspect, near, far):
    f = 1.0 / math.tan(math.radians(fov_deg) / 2.0)
    proj_matrix = [
        f / aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, (far + near) / (near - far), -1.0,
        0.0, 0.0, (2.0 * far * near) / (near - far), 0.0,
    ]
    glMultMatrixf(proj_matrix)


def init_gl():
    global shader_program

    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_LESS)
    glClearColor(0.08, 0.08, 0.10, 1.0)

    glShadeModel(GL_FLAT)
    glFrontFace(GL_CCW)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_BACK)
    glEnable(GL_NORMALIZE)

    shader_program = compileProgram(
        compileShader(VERTEX_SHADER, GL_VERTEX_SHADER),
        compileShader(FRAGMENT_SHADER, GL_FRAGMENT_SHADER),
    )

    glUseProgram(shader_program)
    glUniform1i(glGetUniformLocation(shader_program, "surfaceTexture"), 0)
    glUseProgram(0)


def create_checker_texture(size: int = 64):
    data = bytearray()
    for y in range(size):
        for x in range(size):
            checker = ((x // 8) + (y // 8)) % 2
            if checker == 0:
                color = (235, 210, 155, 255)
            else:
                color = (90, 130, 205, 255)
            data.extend(color)

    tex_id = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, tex_id)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexImage2D(
        GL_TEXTURE_2D,
        0,
        GL_RGBA,
        size,
        size,
        0,
        GL_RGBA,
        GL_UNSIGNED_BYTE,
        bytes(data),
    )
    glBindTexture(GL_TEXTURE_2D, 0)
    return tex_id


def set_uniform_vec3(name, value):
    glUniform3f(glGetUniformLocation(shader_program, name), value[0], value[1], value[2])


def light_position_to_eye(position):
    x, y, z, w = position

    beta_rad = math.radians(view_beta)
    cos_b = math.cos(beta_rad)
    sin_b = math.sin(beta_rad)
    x, z = cos_b * x + sin_b * z, -sin_b * x + cos_b * z

    alpha_rad = math.radians(view_alpha)
    cos_a = math.cos(alpha_rad)
    sin_a = math.sin(alpha_rad)
    y, z = cos_a * y - sin_a * z, sin_a * y + cos_a * z

    if w != 0.0:
        z -= camera_distance

    return [x, y, z, w]


def set_shader_lights():
    glUniform3f(glGetUniformLocation(shader_program, "globalAmbient"), 0.16, 0.16, 0.18)

    for i in range(3):
        prefix = f"lights[{i}]"
        position = light_position_to_eye(light_positions[i])
        glUniform1i(glGetUniformLocation(shader_program, f"{prefix}.enabled"), int(light_enabled[i]))
        glUniform4f(
            glGetUniformLocation(shader_program, f"{prefix}.position"),
            position[0],
            position[1],
            position[2],
            position[3],
        )
        set_uniform_vec3(f"{prefix}.ambient", light_ambient[i])
        set_uniform_vec3(f"{prefix}.diffuse", light_diffuse[i])
        set_uniform_vec3(f"{prefix}.specular", light_specular[i])


def set_shader_material(reference: bool = False):
    if reference:
        ambient = [0.18, 0.18, 0.18]
        diffuse = [0.62, 0.62, 0.68]
        specular = [0.25, 0.25, 0.28]
        shininess = 24.0
    else:
        ambient = [0.20, 0.17, 0.13]
        diffuse = [0.95, 0.88, 0.72]
        specular = [0.90, 0.88, 0.80]
        shininess = 64.0

    set_uniform_vec3("materialAmbient", ambient)
    set_uniform_vec3("materialDiffuse", diffuse)
    set_uniform_vec3("materialSpecular", specular)
    glUniform1f(glGetUniformLocation(shader_program, "materialShininess"), shininess)


def bind_surface_texture(enable: bool):
    glActiveTexture(GL_TEXTURE0)
    if enable and checker_texture is not None:
        glEnable(GL_TEXTURE_2D)
        glBindTexture(GL_TEXTURE_2D, checker_texture)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)
        glDisable(GL_TEXTURE_2D)


def draw_icosahedron(size: float, use_texture: bool = True, reference: bool = False):
    vertices, faces = get_icosahedron_geometry(size)
    tex_coords = [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0)]
    use_tex = use_texture and not reference and texture_enabled

    glUseProgram(shader_program)
    set_shader_lights()
    set_shader_material(reference=reference)
    glUniform1i(glGetUniformLocation(shader_program, "textureEnabled"), int(use_tex))
    bind_surface_texture(use_tex)

    glBegin(GL_TRIANGLES)
    for face in faces:
        nx, ny, nz = face_normal(vertices, face)
        glNormal3f(nx, ny, nz)
        for j, vertex_index in enumerate(face):
            if use_tex:
                glTexCoord2f(tex_coords[j][0] * 2.0, tex_coords[j][1] * 2.0)
            glVertex3f(*vertices[vertex_index])
    glEnd()

    bind_surface_texture(False)
    glUseProgram(0)


def draw_bounding_box():
    if not show_bounds:
        return

    x0, y0, z0 = box_min
    x1, y1, z1 = box_max
    edges = [
        ((x0, y0, z0), (x1, y0, z0)), ((x1, y0, z0), (x1, y1, z0)),
        ((x1, y1, z0), (x0, y1, z0)), ((x0, y1, z0), (x0, y0, z0)),
        ((x0, y0, z1), (x1, y0, z1)), ((x1, y0, z1), (x1, y1, z1)),
        ((x1, y1, z1), (x0, y1, z1)), ((x0, y1, z1), (x0, y0, z1)),
        ((x0, y0, z0), (x0, y0, z1)), ((x1, y0, z0), (x1, y0, z1)),
        ((x1, y1, z0), (x1, y1, z1)), ((x0, y1, z0), (x0, y1, z1)),
    ]

    glUseProgram(0)
    glDisable(GL_TEXTURE_2D)
    glColor3f(0.70, 0.72, 0.78)
    glLineWidth(1.0)
    glBegin(GL_LINES)
    for a, b in edges:
        glVertex3f(*a)
        glVertex3f(*b)
    glEnd()


def draw_light_markers():
    positions = [
        ([2.8, 2.2, 2.0], [1.0, 0.82, 0.45]),
        ([-2.6, 1.4, 1.6], [0.35, 0.55, 1.0]),
        ([0.0, 2.8, -2.7], [0.45, 1.0, 0.55]),
    ]

    glUseProgram(0)
    glDisable(GL_TEXTURE_2D)
    glLineWidth(2.0)

    for i, (p, color) in enumerate(positions):
        if not light_enabled[i]:
            continue
        glColor3f(*color)
        x, y, z = p
        s = 0.12
        glBegin(GL_LINES)
        glVertex3f(x - s, y, z)
        glVertex3f(x + s, y, z)
        glVertex3f(x, y - s, z)
        glVertex3f(x, y + s, z)
        glVertex3f(x, y, z - s)
        glVertex3f(x, y, z + s)
        glEnd()

    glLineWidth(1.0)


def display(window):
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    width, height = glfw.get_framebuffer_size(window)
    height = max(height, 1)

    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    set_perspective_projection(60.0, width / height, 0.1, 100.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0.0, 0.0, -camera_distance)
    glRotatef(view_alpha, 1.0, 0.0, 0.0)
    glRotatef(view_beta, 0.0, 1.0, 0.0)

    if fill:
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
        glEnable(GL_CULL_FACE)
    else:
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        glDisable(GL_CULL_FACE)

    draw_bounding_box()
    draw_light_markers()

    glPushMatrix()
    glTranslatef(-2.05, 1.15, -1.30)
    draw_icosahedron(0.55, use_texture=False, reference=True)
    glPopMatrix()

    glPushMatrix()
    glTranslatef(object_pos[0], object_pos[1], object_pos[2])
    glScalef(object_scale, object_scale, object_scale)
    glRotatef(spin_angle, 0.35, 1.0, 0.20)
    draw_icosahedron(0.72, use_texture=True, reference=False)
    glPopMatrix()

    glfw.swap_buffers(window)
    glfw.poll_events()


def update_animation(dt: float):
    global spin_angle

    if not animation_enabled:
        return

    dt = min(dt, 0.05)

    for axis in range(3):
        object_pos[axis] += object_vel[axis] * dt

        min_allowed = box_min[axis] + object_radius * object_scale
        max_allowed = box_max[axis] - object_radius * object_scale

        if object_pos[axis] < min_allowed:
            object_pos[axis] = min_allowed
            object_vel[axis] = abs(object_vel[axis])
        elif object_pos[axis] > max_allowed:
            object_pos[axis] = max_allowed
            object_vel[axis] = -abs(object_vel[axis])

    spin_angle = (spin_angle + 70.0 * dt) % 360.0


def reset_animation():
    global spin_angle
    object_pos[:] = [0.0, 0.0, 0.0]
    object_vel[:] = [0.75, 0.52, 0.63]
    spin_angle = 0.0


def print_controls():
    print("\nУправление ЛР8")
    print("  Стрелки       - поворот сцены")
    print("  W / S         - приблизить / отдалить камеру")
    print("  + / -         - изменить размер основного объекта")
    print("  F             - каркас / твердотельное отображение")
    print("  T             - включить / выключить текстуру")
    print("  Space         - пауза / продолжение анимации")
    print("  R             - сброс движения объекта")
    print("  1 / 2 / 3     - включить / выключить источники света")
    print("  B             - показать / скрыть ограничивающий объем")
    print("  Esc           - выход\n")


def key_callback(window, key, scancode, action, mods):
    global view_alpha, view_beta, camera_distance, object_scale
    global fill, texture_enabled, animation_enabled, show_bounds

    del scancode, mods

    if key == glfw.KEY_ESCAPE and action == glfw.PRESS:
        glfw.set_window_should_close(window, True)
        return

    if action not in (glfw.PRESS, glfw.REPEAT):
        return

    if key == glfw.KEY_RIGHT:
        view_beta += 5.0
    elif key == glfw.KEY_LEFT:
        view_beta -= 5.0
    elif key == glfw.KEY_UP:
        view_alpha -= 5.0
    elif key == glfw.KEY_DOWN:
        view_alpha += 5.0

    elif key == glfw.KEY_W:
        camera_distance = max(2.5, camera_distance - 0.2)
    elif key == glfw.KEY_S:
        camera_distance = min(12.0, camera_distance + 0.2)

    elif key == glfw.KEY_EQUAL or key == glfw.KEY_KP_ADD:
        object_scale = min(1.8, object_scale + 0.1)
    elif key == glfw.KEY_MINUS or key == glfw.KEY_KP_SUBTRACT:
        object_scale = max(0.45, object_scale - 0.1)

    elif key == glfw.KEY_F:
        fill = not fill
    elif key == glfw.KEY_T:
        texture_enabled = not texture_enabled
    elif key == glfw.KEY_SPACE:
        animation_enabled = not animation_enabled
    elif key == glfw.KEY_B:
        show_bounds = not show_bounds
    elif key == glfw.KEY_R:
        reset_animation()

    elif key in (glfw.KEY_1, glfw.KEY_2, glfw.KEY_3):
        idx = {glfw.KEY_1: 0, glfw.KEY_2: 1, glfw.KEY_3: 2}[key]
        light_enabled[idx] = not light_enabled[idx]


def main():
    global checker_texture

    if not glfw.init():
        raise RuntimeError("Не удалось инициализировать GLFW")

    glfw.window_hint(glfw.RESIZABLE, glfw.TRUE)
    window = glfw.create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, None, None)
    if not window:
        glfw.terminate()
        raise RuntimeError("Не удалось создать окно GLFW")

    glfw.make_context_current(window)
    glfw.swap_interval(1)
    glfw.set_key_callback(window, key_callback)

    init_gl()
    checker_texture = create_checker_texture()
    print_controls()

    previous_time = glfw.get_time()
    while not glfw.window_should_close(window):
        current_time = glfw.get_time()
        dt = current_time - previous_time
        previous_time = current_time

        update_animation(dt)
        display(window)

    if checker_texture is not None:
        glDeleteTextures([checker_texture])
    if shader_program is not None:
        glDeleteProgram(shader_program)

    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()
