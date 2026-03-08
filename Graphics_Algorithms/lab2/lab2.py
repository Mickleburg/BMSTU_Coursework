import glfw
from OpenGL.GL import *
import math

alpha = 0.0  # Ox
beta = 0.0  # Oy
scale = 1.0  # размер объекта
fill = True  # задливка/каркас

def main():
    if not glfw.init():
        return
    window = glfw.create_window(800, 800, "LAB 2 - Трёхточечная перспектива", None, None)
    if not window:
        glfw.terminate()
        return
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_LESS)
    glClearColor(0.1, 0.1, 0.1, 1.0) # темный фон для контраста

    while not glfw.window_should_close(window):
        display(window)
    glfw.destroy_window(window)
    glfw.terminate()

def set_perspective_projection(fov_deg, aspect, near, far):
    # cоздаем матрицу перспективной проекции
    
    f = 1.0 / math.tan(math.radians(fov_deg) / 2.0)
    
    # матрица для куба
    proj_matrix = [
        f / aspect, 0.0, 0.0, 0.0,
        0.0, f, 0.0, 0.0,
        0.0, 0.0, (far + near) / (near - far), -1.0,
        0.0, 0.0, (2.0 * far * near) / (near - far), 0.0
    ]
    glMultMatrixf(proj_matrix)

def cube(sz):

    h = sz / 2.0
    glBegin(GL_QUADS)
    
    # передняя грнаь
    glColor3f(0.0, 0.0, 1.0)
    glVertex3f(-h, -h,  h); glVertex3f( h, -h,  h)
    glVertex3f( h,  h,  h); glVertex3f(-h,  h,  h)
    # задняя грань
    glColor3f(1.0, 0.0, 0.0)
    glVertex3f(-h, -h, -h); glVertex3f(-h,  h, -h)
    glVertex3f( h,  h, -h); glVertex3f( h, -h, -h)
    # верхняя граьн
    glColor3f(0.0, 1.0, 0.0)
    glVertex3f(-h,  h, -h); glVertex3f(-h,  h,  h)
    glVertex3f( h,  h,  h); glVertex3f( h,  h, -h)
    # нижняя грань
    glColor3f(1.0, 1.0, 0.0)
    glVertex3f(-h, -h, -h); glVertex3f( h, -h, -h)
    glVertex3f( h, -h,  h); glVertex3f(-h, -h,  h)
    # правая грань
    glColor3f(0.0, 1.0, 1.0)
    glVertex3f( h, -h, -h); glVertex3f( h,  h, -h)
    glVertex3f( h,  h,  h); glVertex3f( h, -h,  h)
    # левая грань
    glColor3f(1.0, 0.0, 1.0)
    glVertex3f(-h, -h, -h); glVertex3f(-h, -h,  h)
    glVertex3f(-h,  h,  h); glVertex3f(-h,  h, -h)
    
    glEnd()

def display(window):
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    set_perspective_projection(60.0, 1.0, 0.1, 100.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    # вглуюь по оси Z
    glTranslatef(0.0, 0.0, -4.0)
    
    # поворачиваем каеру по осям, тогда будем смотреть по трем направлениям => трехточечная модель
    glRotatef(30.0, 1.0, 0.0, 0.0)  # камеру вниз
    glRotatef(-45.0, 0.0, 1.0, 0.0)  # и вбок

    # куб для примера
    glPushMatrix()
    glTranslatef(-1.5, 1.0, -1.5)  # смещаем в сторону
    cube(0.5)
    glPopMatrix()

    # модельные преобразования
    glPushMatrix()
    glScalef(scale, scale, scale)  # размер
    glRotatef(alpha, 1.0, 0.0, 0.0)  # вокруг Оx
    glRotatef(beta, 0.0, 1.0, 0.0)  # вращение вокруг Оу
    
    cube(1.2)
    glPopMatrix()

    glfw.swap_buffers(window)
    glfw.poll_events()

def key_callback(window, key, scancode, action, mods):
    global alpha, beta, scale, fill
    if action == glfw.PRESS or action == glfw.REPEAT:
        # вращение куба
        if key == glfw.KEY_RIGHT:
            beta += 5.0
        elif key == glfw.KEY_LEFT:
            beta -= 5.0
        elif key == glfw.KEY_UP:
            alpha -= 5.0
        elif key == glfw.KEY_DOWN:
            alpha += 5.0
        
        # масштабирование при помощи + и -
        elif key == glfw.KEY_EQUAL or key == glfw.KEY_KP_ADD:
            scale += 0.1
        elif key == glfw.KEY_MINUS or key == glfw.KEY_KP_SUBTRACT:
            scale = max(0.1, scale - 0.1)
            
        # переключеие между каркасос и твердотелым режимом
        elif key == glfw.KEY_F:
            fill = not fill
            if fill:
                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
            else:
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)

if __name__ == "__main__":
    main()
