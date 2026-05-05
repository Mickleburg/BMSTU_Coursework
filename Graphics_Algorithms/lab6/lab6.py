import math
from typing import Iterable

import glfw
from OpenGL.GL import *


WINDOW_WIDTH = 900
WINDOW_HEIGHT = 800
WINDOW_TITLE = "ЛР6 - Реалистичные изображения: A6 + Б2 + В2"


# Состояние сцены / управления
view_alpha = 25.0          # поворот всей сцены вокруг Ox
view_beta = -35.0          # поворот всей сцены вокруг Oy
camera_distance = 5.2      # отдаление камеры через model-view transform, без gluLookAt
object_scale = 1.0
fill = True
texture_enabled = True
animation_enabled = True
show_bounds = True

# A6: несколько источников света. Источники можно отключать кнопками 1/2/3.
light_enabled = [True, True, True]

# Б2: движение тела с отражением от границ ограничивающего объема.
box_min = [-1.45, -1.05, -1.45]
box_max = [1.45, 1.05, 1.45]
object_radius = 0.36
object_pos = [0.0, 0.0, 0.0]
object_vel = [0.75, 0.52, 0.63]  # начальная скорость по x/y/z
spin_angle = 0.0

# OpenGL id процедурной текстуры.
checker_texture = None


# Геометрия икосаэдра
def get_icosahedron_geometry(size: float):
    """Возвращает вершины и грани икосаэдра размера size."""
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

    # Защита от неправильного направления нормали: для центральной модели
    # внешняя нормаль должна иметь положительное скалярное произведение с центром грани.
    center = (
        (a[0] + b[0] + c[0]) / 3.0,
        (a[1] + b[1] + c[1]) / 3.0,
        (a[2] + b[2] + c[2]) / 3.0,
    )
    if n[0] * center[0] + n[1] * center[1] + n[2] * center[2] < 0.0:
        n = (-n[0], -n[1], -n[2])
    return n


# Проекция и OpenGL-настройки
def set_perspective_projection(fov_deg, aspect, near, far):
    """Матрица перспективы вручную, без gluPerspective/gluLookAt."""
    f = 1.0 / math.tan(math.radians(fov_deg) / 2.0)
    proj_matrix = [
        f / aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, (far + near) / (near - far), -1.0,
        0.0, 0.0, (2.0 * far * near) / (near - far), 0.0,
    ]
    glMultMatrixf(proj_matrix)


def init_gl():
    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_LESS)
    glClearColor(0.08, 0.08, 0.10, 1.0)

    glShadeModel(GL_FLAT)
    glFrontFace(GL_CCW)
    glEnable(GL_CULL_FACE)
    glCullFace(GL_BACK)

    glEnable(GL_NORMALIZE)  # нормали остаются корректными при масштабировании модели
    glEnable(GL_LIGHTING)

    # Глобальная модель освещения OpenGL.
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, [0.16, 0.16, 0.18, 1.0])
    glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE)
    glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_FALSE)

    # Текстура будет модулировать результат освещения/диффузную составляющую поверхности.
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)


def create_checker_texture(size: int = 64):
    """Процедурная BMP-подобная шахматная текстура без внешнего файла."""
    data = bytearray()
    for y in range(size):
        for x in range(size):
            checker = ((x // 8) + (y // 8)) % 2
            # Две близкие по тону области: имитируют неодинаковый коэффициент диффузного отражения.
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


# A6: несколько источников света
def apply_lights():
    """Настройка трех источников света: ключевой, заполняющий и контровой."""
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

            # Небольшое ослабление делает сцену мягче; основной исследуемый пункт все равно A6.
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

    glDisable(GL_LIGHTING)
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
    glEnable(GL_LIGHTING)


# Материалы и текстуры
def set_surface_material(reference: bool = False):
    if reference:
        ambient = [0.18, 0.18, 0.18, 1.0]
        diffuse = [0.62, 0.62, 0.68, 1.0]
        specular = [0.25, 0.25, 0.28, 1.0]
        shininess = 24.0
    else:
        # Базовые свойства материала поверхности.
        # При включенной текстуре коэффициент диффузного отражения дополнительно
        # модулируется процедурным рисунком через GL_MODULATE.
        ambient = [0.20, 0.17, 0.13, 1.0]
        diffuse = [0.95, 0.88, 0.72, 1.0]
        specular = [0.90, 0.88, 0.80, 1.0]
        shininess = 64.0

    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambient)
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuse)
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular)
    glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, shininess)


def bind_surface_texture(enable: bool):
    if enable and checker_texture is not None:
        glEnable(GL_TEXTURE_2D)
        glBindTexture(GL_TEXTURE_2D, checker_texture)
    else:
        glBindTexture(GL_TEXTURE_2D, 0)
        glDisable(GL_TEXTURE_2D)


# Отрисовка
def draw_icosahedron(size: float, use_texture: bool = True, reference: bool = False):
    vertices, faces = get_icosahedron_geometry(size)
    set_surface_material(reference=reference)
    bind_surface_texture(use_texture and not reference and texture_enabled)

    # На каждую грань задаем нормаль. Это необходимо для реалистичного освещения.
    tex_coords = [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0)]

    glBegin(GL_TRIANGLES)
    for face in faces:
        nx, ny, nz = face_normal(vertices, face)
        glNormal3f(nx, ny, nz)
        for j, vertex_index in enumerate(face):
            if use_texture and not reference and texture_enabled:
                # Координаты больше 1.0 специально разрешены через GL_REPEAT.
                glTexCoord2f(tex_coords[j][0] * 2.0, tex_coords[j][1] * 2.0)
            glVertex3f(*vertices[vertex_index])
    glEnd()

    bind_surface_texture(False)


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

    glDisable(GL_LIGHTING)
    glDisable(GL_TEXTURE_2D)
    glColor3f(0.70, 0.72, 0.78)
    glLineWidth(1.0)
    glBegin(GL_LINES)
    for a, b in edges:
        glVertex3f(*a)
        glVertex3f(*b)
    glEnd()
    glEnable(GL_LIGHTING)


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

    # Навигация камеры через модельно-видовые преобразования, без gluLookAt.
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

    draw_bounding_box()
    draw_light_markers()

    # Контрольный икосаэдр в стандартной ориентации, как в ЛР3.
    glPushMatrix()
    glTranslatef(-2.05, 1.15, -1.30)
    draw_icosahedron(0.55, use_texture=False, reference=True)
    glPopMatrix()

    # Основной объект: движется внутри кубического объема и отражается от его границ.
    glPushMatrix()
    glTranslatef(object_pos[0], object_pos[1], object_pos[2])
    glScalef(object_scale, object_scale, object_scale)
    glRotatef(spin_angle, 0.35, 1.0, 0.20)
    draw_icosahedron(0.72, use_texture=True, reference=False)
    glPopMatrix()

    glfw.swap_buffers(window)
    glfw.poll_events()


# Б2: анимация с упругим отражением
def update_animation(dt: float):
    global spin_angle

    if not animation_enabled:
        return

    # Защита от слишком большого скачка при переносе/зависании окна.
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
    print("\nУправление ЛР6")
    print("  Стрелки       - поворот сцены")
    print("  W / S         - приблизить / отдалить камеру")
    print("  + / -         - изменить размер основного объекта")
    print("  F             - каркас / твердотельное отображение")
    print("  T             - включить / выключить текстуру В2")
    print("  Space         - пауза / продолжение анимации Б2")
    print("  R             - сброс движения объекта")
    print("  1 / 2 / 3     - включить / выключить источники света A6")
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

    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()
