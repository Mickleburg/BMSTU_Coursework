import math
import sys
import time

import glfw
from OpenGL.GL import *


WINDOW_WIDTH = 900
WINDOW_HEIGHT = 800
WINDOW_TITLE = "ЛР7 - Оптимизация OpenGL-приложения"

MODE_IMMEDIATE = 0
MODE_ARRAYS = 1
MODE_DISPLAY_LISTS = 2

mode_names = {
    MODE_IMMEDIATE: "glBegin/glEnd",
    MODE_ARRAYS: "массивы вершин",
    MODE_DISPLAY_LISTS: "дисплейные списки",
}


# Состояние сцены / управления
view_alpha = 25.0
view_beta = -35.0
camera_distance = 5.2
object_scale = 1.0
fill = True
texture_enabled = True
animation_enabled = True
show_bounds = True
render_mode = MODE_DISPLAY_LISTS

# A6: несколько источников света.
light_enabled = [True, True, True]

# Б2: движение тела с отражением от границ ограничивающего объема.
box_min = [-1.45, -1.05, -1.45]
box_max = [1.45, 1.05, 1.45]
object_radius = 0.36
object_pos = [0.0, 0.0, 0.0]
object_vel = [0.75, 0.52, 0.63]
spin_angle = 0.0

checker_texture = None
main_mesh = None
reference_mesh = None
main_list = None
reference_list = None
cached_texture_state = None
cached_lighting_state = None


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


# Оптимизация 1: геометрия, нормали и текстурные координаты считаются один раз.
def build_mesh(size: float):
    vertices, faces = get_icosahedron_geometry(size)
    tex_coords = [(0.0, 0.0), (2.0, 0.0), (1.0, 2.0)]
    flat_vertices = []
    flat_normals = []
    flat_texcoords = []

    for face in faces:
        nx, ny, nz = face_normal(vertices, face)
        for j, vertex_index in enumerate(face):
            flat_vertices.extend(vertices[vertex_index])
            flat_normals.extend((nx, ny, nz))
            flat_texcoords.extend(tex_coords[j])

    return {
        "count": len(flat_vertices) // 3,
        "vertices": (GLfloat * len(flat_vertices))(*flat_vertices),
        "normals": (GLfloat * len(flat_normals))(*flat_normals),
        "texcoords": (GLfloat * len(flat_texcoords))(*flat_texcoords),
    }


def set_perspective_projection(fov_deg, aspect, near, far):
    f = 1.0 / math.tan(math.radians(fov_deg) / 2.0)
    proj_matrix = [
        f / aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, (far + near) / (near - far), -1.0,
        0.0, 0.0, (2.0 * far * near) / (near - far), 0.0,
    ]
    glMultMatrixf(proj_matrix)


def set_lighting_enabled(enable: bool):
    global cached_lighting_state
    if cached_lighting_state == enable:
        return
    if enable:
        glEnable(GL_LIGHTING)
    else:
        glDisable(GL_LIGHTING)
    cached_lighting_state = enable


def bind_surface_texture(enable: bool):
    global cached_texture_state
    if enable and checker_texture is not None:
        if cached_texture_state != checker_texture:
            glEnable(GL_TEXTURE_2D)
            glBindTexture(GL_TEXTURE_2D, checker_texture)
            cached_texture_state = checker_texture
    else:
        if cached_texture_state is not None:
            glBindTexture(GL_TEXTURE_2D, 0)
            glDisable(GL_TEXTURE_2D)
            cached_texture_state = None


def init_gl():
    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_LESS)
    glClearColor(0.08, 0.08, 0.10, 1.0)

    glShadeModel(GL_FLAT)
    glFrontFace(GL_CCW)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_BACK)

    glEnable(GL_NORMALIZE)
    set_lighting_enabled(True)

    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, [0.16, 0.16, 0.18, 1.0])
    glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE)
    glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_FALSE)
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)


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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
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
    # Оптимизация 4: mipmap-цепочка уменьшает стоимость фильтрации при удалении объекта.
    glGenerateMipmap(GL_TEXTURE_2D)
    glBindTexture(GL_TEXTURE_2D, 0)
    return tex_id


def apply_lights():
    lights = [
        {
            "id": GL_LIGHT0,
            "position": [2.8, 2.2, 2.0, 1.0],
            "ambient":  [0.05, 0.04, 0.03, 1.0],
            "diffuse":  [0.95, 0.82, 0.60, 1.0],
            "specular": [1.00, 0.92, 0.78, 1.0],
        },
        {
            "id": GL_LIGHT1,
            "position": [-2.6, 1.4, 1.6, 1.0],
            "ambient":  [0.02, 0.03, 0.05, 1.0],
            "diffuse":  [0.35, 0.50, 0.95, 1.0],
            "specular": [0.35, 0.50, 0.95, 1.0],
        },
        {
            "id": GL_LIGHT2,
            "position": [0.0, 2.8, -2.7, 1.0],
            "ambient":  [0.00, 0.00, 0.00, 1.0],
            "diffuse":  [0.45, 0.95, 0.55, 1.0],
            "specular": [0.45, 0.95, 0.55, 1.0],
        },
    ]

    for i, light in enumerate(lights):
        light_id = light["id"]
        if light_enabled[i]:
            glEnable(light_id)
            glLightfv(light_id, GL_POSITION, light["position"])
            glLightfv(light_id, GL_AMBIENT, light["ambient"])
            glLightfv(light_id, GL_DIFFUSE, light["diffuse"])
            glLightfv(light_id, GL_SPECULAR, light["specular"])
            glLightf(light_id, GL_CONSTANT_ATTENUATION, 1.0)
            glLightf(light_id, GL_LINEAR_ATTENUATION, 0.03)
            glLightf(light_id, GL_QUADRATIC_ATTENUATION, 0.01)
        else:
            glDisable(light_id)


def draw_light_markers():
    positions = [
        ([2.8, 2.2, 2.0], [1.0, 0.82, 0.45]),
        ([-2.6, 1.4, 1.6], [0.35, 0.55, 1.0]),
        ([0.0, 2.8, -2.7], [0.45, 1.0, 0.55]),
    ]

    set_lighting_enabled(False)
    bind_surface_texture(False)
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
    set_lighting_enabled(True)


def set_surface_material(reference: bool = False):
    if reference:
        ambient = [0.18, 0.18, 0.18, 1.0]
        diffuse = [0.62, 0.62, 0.68, 1.0]
        specular = [0.25, 0.25, 0.28, 1.0]
        shininess = 24.0
    else:
        ambient = [0.20, 0.17, 0.13, 1.0]
        diffuse = [0.95, 0.88, 0.72, 1.0]
        specular = [0.90, 0.88, 0.80, 1.0]
        shininess = 64.0

    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambient)
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse)
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular)
    glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, shininess)


def draw_icosahedron_immediate(size: float, use_texture: bool = True, reference: bool = False):
    vertices, faces = get_icosahedron_geometry(size)
    set_surface_material(reference=reference)
    bind_surface_texture(use_texture and not reference and texture_enabled)

    tex_coords = [(0.0, 0.0), (2.0, 0.0), (1.0, 2.0)]

    glBegin(GL_TRIANGLES)
    for face in faces:
        nx, ny, nz = face_normal(vertices, face)
        glNormal3f(nx, ny, nz)
        for j, vertex_index in enumerate(face):
            if use_texture and not reference and texture_enabled:
                glTexCoord2f(*tex_coords[j])
            glVertex3f(*vertices[vertex_index])
    glEnd()

    bind_surface_texture(False)


# Оптимизация 2: отрисовка через массивы вершин вместо отдельных glVertex/glNormal/glTexCoord.
def draw_mesh_array(mesh):
    glEnableClientState(GL_VERTEX_ARRAY)
    glEnableClientState(GL_NORMAL_ARRAY)
    glEnableClientState(GL_TEXTURE_COORD_ARRAY)

    glVertexPointer(3, GL_FLOAT, 0, mesh["vertices"])
    glNormalPointer(GL_FLOAT, 0, mesh["normals"])
    glTexCoordPointer(2, GL_FLOAT, 0, mesh["texcoords"])
    glDrawArrays(GL_TRIANGLES, 0, mesh["count"])

    glDisableClientState(GL_TEXTURE_COORD_ARRAY)
    glDisableClientState(GL_NORMAL_ARRAY)
    glDisableClientState(GL_VERTEX_ARRAY)


def draw_icosahedron_array(mesh, use_texture: bool = True, reference: bool = False):
    set_surface_material(reference=reference)
    bind_surface_texture(use_texture and not reference and texture_enabled)
    draw_mesh_array(mesh)
    bind_surface_texture(False)


# Оптимизация 3: дисплейный список сохраняет готовые команды отрисовки геометрии.
def compile_mesh_list(mesh):
    list_id = glGenLists(1)
    glNewList(list_id, GL_COMPILE)
    draw_mesh_array(mesh)
    glEndList()
    return list_id


def init_optimized_geometry():
    global main_mesh, reference_mesh, main_list, reference_list
    main_mesh = build_mesh(0.72)
    reference_mesh = build_mesh(0.55)
    main_list = compile_mesh_list(main_mesh)
    reference_list = compile_mesh_list(reference_mesh)


def draw_icosahedron_list(list_id, use_texture: bool = True, reference: bool = False):
    set_surface_material(reference=reference)
    bind_surface_texture(use_texture and not reference and texture_enabled)
    glCallList(list_id)
    bind_surface_texture(False)


def draw_icosahedron(size: float, use_texture: bool = True, reference: bool = False):
    if render_mode == MODE_IMMEDIATE:
        draw_icosahedron_immediate(size, use_texture=use_texture, reference=reference)
    elif render_mode == MODE_ARRAYS:
        mesh = reference_mesh if reference else main_mesh
        draw_icosahedron_array(mesh, use_texture=use_texture, reference=reference)
    else:
        list_id = reference_list if reference else main_list
        draw_icosahedron_list(list_id, use_texture=use_texture, reference=reference)


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

    set_lighting_enabled(False)
    bind_surface_texture(False)
    glColor3f(0.70, 0.72, 0.78)
    glLineWidth(1.0)
    glBegin(GL_LINES)
    for a, b in edges:
        glVertex3f(*a)
        glVertex3f(*b)
    glEnd()
    set_lighting_enabled(True)


def draw_scene_objects():
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


def display(window, swap_buffers=True):
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

    apply_lights()

    if fill:
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
        glEnable(GL_CULL_FACE)
    else:
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        glDisable(GL_CULL_FACE)

    draw_scene_objects()

    if swap_buffers:
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


def measure_mode(window, mode, frames=360, warmup=60):
    global render_mode, animation_enabled

    old_mode = render_mode
    old_animation = animation_enabled
    render_mode = mode
    animation_enabled = False

    for _ in range(warmup):
        display(window, swap_buffers=False)
        glFinish()

    start = time.perf_counter()
    for _ in range(frames):
        display(window, swap_buffers=False)
        glFinish()
    elapsed = time.perf_counter() - start

    render_mode = old_mode
    animation_enabled = old_animation
    avg_ms = elapsed * 1000.0 / frames
    fps = frames / elapsed
    return avg_ms, fps


def run_benchmark(window):
    results = []
    baseline_ms = None

    for mode in (MODE_IMMEDIATE, MODE_ARRAYS, MODE_DISPLAY_LISTS):
        avg_ms, fps = measure_mode(window, mode)
        if baseline_ms is None:
            baseline_ms = avg_ms
        speedup = baseline_ms / avg_ms if avg_ms > 0 else 0.0
        results.append((mode_names[mode], avg_ms, fps, speedup))

    print("\nРезультаты замеров производительности")
    print("| Метод отрисовки | Среднее время кадра, мс | FPS | Ускорение |")
    print("|---|---:|---:|---:|")
    for name, avg_ms, fps, speedup in results:
        print(f"| {name} | {avg_ms:.3f} | {fps:.1f} | {speedup:.2f}x |")
    print()
    return results


def print_controls():
    print("\nУправление ЛР7")
    print("  Стрелки       - поворот сцены")
    print("  W / S         - приблизить / отдалить камеру")
    print("  + / -         - изменить размер основного объекта")
    print("  F             - каркас / твердотельное отображение")
    print("  T             - включить / выключить текстуру")
    print("  Space         - пауза / продолжение анимации")
    print("  R             - сброс движения объекта")
    print("  1 / 2 / 3     - включить / выключить источники света")
    print("  B             - показать / скрыть ограничивающий объем")
    print("  M             - выполнить замер производительности")
    print("  7             - glBegin/glEnd")
    print("  8             - массивы вершин")
    print("  9             - дисплейные списки")
    print("  Esc           - выход\n")


def key_callback(window, key, scancode, action, mods):
    global view_alpha, view_beta, camera_distance, object_scale
    global fill, texture_enabled, animation_enabled, show_bounds, render_mode

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
    elif key == glfw.KEY_M:
        run_benchmark(window)

    elif key == glfw.KEY_7:
        render_mode = MODE_IMMEDIATE
        print("Режим:", mode_names[render_mode])
    elif key == glfw.KEY_8:
        render_mode = MODE_ARRAYS
        print("Режим:", mode_names[render_mode])
    elif key == glfw.KEY_9:
        render_mode = MODE_DISPLAY_LISTS
        print("Режим:", mode_names[render_mode])

    elif key in (glfw.KEY_1, glfw.KEY_2, glfw.KEY_3):
        idx = {glfw.KEY_1: 0, glfw.KEY_2: 1, glfw.KEY_3: 2}[key]
        light_enabled[idx] = not light_enabled[idx]


def create_window(hidden=False):
    if not glfw.init():
        raise RuntimeError("Не удалось инициализировать GLFW")

    glfw.window_hint(glfw.RESIZABLE, glfw.TRUE)
    if hidden:
        glfw.window_hint(glfw.VISIBLE, glfw.FALSE)

    window = glfw.create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, None, None)
    if not window:
        glfw.terminate()
        raise RuntimeError("Не удалось создать окно GLFW")

    glfw.make_context_current(window)
    glfw.swap_interval(0)
    glfw.set_key_callback(window, key_callback)
    return window


def cleanup(window):
    if main_list is not None:
        glDeleteLists(main_list, 1)
    if reference_list is not None:
        glDeleteLists(reference_list, 1)
    if checker_texture is not None:
        glDeleteTextures([checker_texture])
    glfw.destroy_window(window)
    glfw.terminate()


def main():
    global checker_texture

    benchmark_only = "--benchmark" in sys.argv
    window = create_window(hidden=benchmark_only)

    init_gl()
    checker_texture = create_checker_texture()
    init_optimized_geometry()

    if benchmark_only:
        run_benchmark(window)
        cleanup(window)
        return

    print_controls()
    previous_time = glfw.get_time()
    while not glfw.window_should_close(window):
        current_time = glfw.get_time()
        dt = current_time - previous_time
        previous_time = current_time

        update_animation(dt)
        display(window)

    cleanup(window)


if __name__ == "__main__":
    main()
