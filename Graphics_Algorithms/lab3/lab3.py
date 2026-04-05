import glfw
from OpenGL.GL import *
import math


alpha = 0.0   # вращение вокруг Ox
beta = 0.0    # вращение вокруг Oy
scale = 1.0   # размер объекта
fill = True   # заливка / каркас


def main():
    if not glfw.init():
        return

    window = glfw.create_window(800, 800, "LAB 2 - Трёхточечная перспектива (икосаэдр)", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_LESS)
    glClearColor(0.1, 0.1, 0.1, 1.0)

    while not glfw.window_should_close(window):
        display(window)

    glfw.destroy_window(window)
    glfw.terminate()


def set_perspective_projection(fov_deg, aspect, near, far):
    f = 1.0 / math.tan(math.radians(fov_deg) / 2.0)

    proj_matrix = [
        f / aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, (far + near) / (near - far), -1.0,
        0.0, 0.0, (2.0 * far * near) / (near - far), 0.0
    ]
    glMultMatrixf(proj_matrix)


def icosahedron(sz):
    phi = (1.0 + math.sqrt(5.0)) / 2.0
    radius = sz / 2.0
    norm = math.sqrt(1 + phi * phi)

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

    colors = [
        (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0), (1.0, 1.0, 0.0),
        (1.0, 0.0, 1.0), (0.0, 1.0, 1.0), (1.0, 0.5, 0.0), (0.5, 0.0, 1.0),
        (0.5, 1.0, 0.0), (1.0, 0.0, 0.5), (0.0, 0.5, 1.0), (0.5, 0.5, 0.5),
        (0.8, 0.2, 0.2), (0.2, 0.8, 0.2), (0.2, 0.2, 0.8), (0.8, 0.8, 0.2),
        (0.8, 0.2, 0.8), (0.2, 0.8, 0.8), (0.9, 0.4, 0.1), (0.4, 0.9, 0.1)
    ]

    glBegin(GL_TRIANGLES)
    for i, face in enumerate(faces):
        glColor3f(*colors[i % len(colors)])
        for vertex_index in face:
            glVertex3f(*vertices[vertex_index])
    glEnd()


def display(window):
    global fill

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    width, height = glfw.get_framebuffer_size(window)
    if height == 0:
        height = 1

    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    set_perspective_projection(60.0, width / height, 0.1, 100.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    if fill:
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
    else:
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)

    # сдвиг камеры назад
    glTranslatef(0.0, 0.0, -4.0)

    # трёхточечная перспектива
    glRotatef(30.0, 1.0, 0.0, 0.0)
    glRotatef(-45.0, 0.0, 1.0, 0.0)

    # маленький икосаэдр для примера
    glPushMatrix()
    glTranslatef(-1.5, 1.0, -1.5)
    icosahedron(0.6)
    glPopMatrix()

    # основной объект
    glPushMatrix()
    glScalef(scale, scale, scale)
    glRotatef(alpha, 1.0, 0.0, 0.0)
    glRotatef(beta, 0.0, 1.0, 0.0)
    icosahedron(1.4)
    glPopMatrix()

    glfw.swap_buffers(window)
    glfw.poll_events()


def key_callback(window, key, scancode, action, mods):
    global alpha, beta, scale, fill

    if action == glfw.PRESS or action == glfw.REPEAT:
        if key == glfw.KEY_RIGHT:
            beta += 5.0
        elif key == glfw.KEY_LEFT:
            beta -= 5.0
        elif key == glfw.KEY_UP:
            alpha -= 5.0
        elif key == glfw.KEY_DOWN:
            alpha += 5.0

        elif key == glfw.KEY_EQUAL or key == glfw.KEY_KP_ADD:
            scale += 0.1
        elif key == glfw.KEY_MINUS or key == glfw.KEY_KP_SUBTRACT:
            scale = max(0.1, scale - 0.1)

        elif key == glfw.KEY_F:
            fill = not fill


if __name__ == "__main__":
    main()