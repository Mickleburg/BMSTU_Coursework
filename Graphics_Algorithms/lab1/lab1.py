import glfw
from OpenGL.GL import *
import math

angle = 0.0          # текущий угол поворота (в градусах)
delta = 2.0          # шаг вращения (скорость), положительное значение

radius1 = 0.2        # радиус первого круга
radius2 = 0.35        # радиус второго круга
distance = 0.45       # расстояние от центра вращения до центров кругов

color1 = (0.8, 0.2, 0.2)   # краснфй
color2 = (0.2, 0.2, 0.8)   # синий

def draw_circle(radius, color, num_segments=50):

    glColor3f(*color)
    glBegin(GL_TRIANGLE_FAN)
    glVertex2f(0.0, 0.0)  # центр
    for i in range(num_segments + 1):
        theta = 2.0 * math.pi * i / num_segments
        x = radius * math.cos(theta)
        y = radius * math.sin(theta)
        glVertex2f(x, y)
    glEnd()

def display(window):

    global angle

    glClear(GL_COLOR_BUFFER_BIT)
    glLoadIdentity()
    glClearColor(1.0, 1.0, 1.0, 1.0)

    # Рисуем первый круг (справа от центра)
    glPushMatrix()
    glRotatef(angle, 0, 0, 1)  # поворот вокруг центра
    glTranslatef(distance, 0.0, 0.0)     # смещение вправо
    draw_circle(radius1, color1)
    glPopMatrix()

    # Рисуем второй круг (слева от центра)
    glPushMatrix()
    glRotatef(angle, 0, 0, 1)
    glTranslatef(-distance, 0.0, 0.0)        # смещение влево
    draw_circle(radius2, color2)
    glPopMatrix()

    angle += delta          # увеличиваем угол поворота
    glfw.swap_buffers(window)
    glfw.poll_events()

def key_callback(window, key, scancode, action, mods):

    global delta
    if action == glfw.PRESS:
        if key == glfw.KEY_SPACE:
            delta = -delta  # менеям направление вращения

def main():
    if not glfw.init():
        print("Не удалось инициализировать GLFW")
        return

    window = glfw.create_window(640, 640, "Two Circles", None, None)
    if not window:
        print("Не удалось создать окно")
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)


    while not glfw.window_should_close(window):
        display(window)

    glfw.destroy_window(window)
    glfw.terminate()

if __name__ == "__main__":
    main()