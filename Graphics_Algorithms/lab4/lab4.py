from __future__ import annotations

import math
from dataclasses import dataclass, field

import glfw
import numpy as np
from OpenGL.GL import *


WINDOW_WIDTH = 900
WINDOW_HEIGHT = 700
WINDOW_TITLE = "ЛР4 - A5 + Б2 (OpenGL, Python)"

BACKGROUND_COLOR = (245, 247, 252, 255)
FILL_COLOR = (105, 150, 245, 255)
OUTLINE_COLOR = (25, 50, 110, 255)
PREVIEW_COLOR = (220, 95, 75, 255)

Point = tuple[int, int]


@dataclass
class EdgeRecord:
    y_min: int
    y_max: int
    x: float
    inv_slope: float


@dataclass
class AppState:
    framebuffer_width: int = WINDOW_WIDTH
    framebuffer_height: int = WINDOW_HEIGHT
    raw_buffer: bytearray = field(default_factory=bytearray)
    display_buffer: bytearray = field(default_factory=bytearray)
    polygon_vertices: list[Point] = field(default_factory=list)
    polygon_closed: bool = False
    cursor_fb_pos: Point | None = None
    needs_redraw: bool = True


def init_gl():
    glClearColor(*(c / 255.0 for c in BACKGROUND_COLOR[:3]), 1.0)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_CULL_FACE)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)


def make_buffer(width: int, height: int, color: tuple[int, int, int, int]) -> bytearray:
    return bytearray(bytes(color) * (width * height))


def resize_buffers(state: AppState, width: int, height: int):
    state.framebuffer_width = max(1, width)
    state.framebuffer_height = max(1, height)
    state.raw_buffer = make_buffer(state.framebuffer_width, state.framebuffer_height, BACKGROUND_COLOR)
    state.display_buffer = make_buffer(state.framebuffer_width, state.framebuffer_height, BACKGROUND_COLOR)
    state.needs_redraw = True


def clear_buffer(state: AppState, buffer_name: str, color: tuple[int, int, int, int]):
    buf = getattr(state, buffer_name)
    buf[:] = bytes(color) * (state.framebuffer_width * state.framebuffer_height)


def pixel_index(state: AppState, x: int, y: int) -> int | None:
    if x < 0 or x >= state.framebuffer_width or y < 0 or y >= state.framebuffer_height:
        return None
    return (y * state.framebuffer_width + x) * 4


def put_pixel_raw(state: AppState, x: int, y: int, color: tuple[int, int, int, int]):
    idx = pixel_index(state, x, y)
    if idx is None:
        return
    state.raw_buffer[idx:idx + 4] = bytes(color)


def fill_horizontal_span_raw(
    state: AppState,
    y: int,
    x_start: int,
    x_end: int,
    color: tuple[int, int, int, int],
):
    if y < 0 or y >= state.framebuffer_height:
        return

    x_start = max(0, x_start)
    x_end = min(state.framebuffer_width - 1, x_end)
    if x_start > x_end:
        return

    row_start = (y * state.framebuffer_width + x_start) * 4
    state.raw_buffer[row_start:row_start + (x_end - x_start + 1) * 4] = bytes(color) * (x_end - x_start + 1)


def draw_line_bresenham(
    state: AppState,
    start: Point,
    end: Point,
    color: tuple[int, int, int, int],
):
    x0, y0 = start
    x1, y1 = end

    dx = abs(x1 - x0)
    sx = 1 if x0 < x1 else -1
    dy = -abs(y1 - y0)
    sy = 1 if y0 < y1 else -1
    err = dx + dy

    while True:
        put_pixel_raw(state, x0, y0, color)

        if x0 == x1 and y0 == y1:
            break

        e2 = err * 2
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def build_edge_list(vertices: list[Point]) -> list[EdgeRecord]:
    edges: list[EdgeRecord] = []
    total = len(vertices)

    for i in range(total):
        x0, y0 = vertices[i]
        x1, y1 = vertices[(i + 1) % total]

        if y0 == y1:
            continue

        if y0 > y1:
            x0, y0, x1, y1 = x1, y1, x0, y0

        inv_slope = (x1 - x0) / (y1 - y0)

        edges.append(
            EdgeRecord(
                y_min=y0,
                y_max=y1,
                x=x0 + 0.5 * inv_slope,
                inv_slope=inv_slope,
            )
        )

    edges.sort(key=lambda e: (e.y_min, e.x, e.y_max))
    return edges


def fill_polygon_a5(
    state: AppState,
    vertices: list[Point],
    color: tuple[int, int, int, int],
):
    if len(vertices) < 3:
        return

    edges = build_edge_list(vertices)
    if not edges:
        return

    active: list[EdgeRecord] = []
    edge_index = 0

    min_y = max(0, min(edge.y_min for edge in edges))
    max_y = min(state.framebuffer_height, max(edge.y_max for edge in edges))

    for y in range(min_y, max_y):
        while edge_index < len(edges) and edges[edge_index].y_min == y:
            active.append(edges[edge_index])
            edge_index += 1

        active = [edge for edge in active if y < edge.y_max]
        active.sort(key=lambda edge: edge.x)

        flag = False
        x_start = 0

        for edge in active:
            if not flag:
                x_start = math.ceil(edge.x - 0.5)
            else:
                x_end = math.floor(edge.x - 0.5)
                fill_horizontal_span_raw(state, y, x_start, x_end, color)
            flag = not flag

        for edge in active:
            edge.x += edge.inv_slope


def draw_polygon_edges(
    state: AppState,
    vertices: list[Point],
    color: tuple[int, int, int, int],
    closed: bool,
):
    if len(vertices) < 2:
        return

    for i in range(len(vertices) - 1):
        draw_line_bresenham(state, vertices[i], vertices[i + 1], color)

    if closed and len(vertices) >= 3:
        draw_line_bresenham(state, vertices[-1], vertices[0], color)


def apply_postfilter_b2(state: AppState):
    w = state.framebuffer_width
    h = state.framebuffer_height

    src = np.frombuffer(state.raw_buffer, dtype=np.uint8).reshape((h, w, 4))
    rgb = src[:, :, :3].astype(np.uint16)

    padded = np.pad(rgb, ((1, 1), (1, 1), (0, 0)), mode="edge")

    filtered = (
        padded[:-2, :-2]
        + 2 * padded[:-2, 1:-1]
        + padded[:-2, 2:]
        + 2 * padded[1:-1, :-2]
        + 4 * padded[1:-1, 1:-1]
        + 2 * padded[1:-1, 2:]
        + padded[2:, :-2]
        + 2 * padded[2:, 1:-1]
        + padded[2:, 2:]
    ) // 16

    out = np.empty((h, w, 4), dtype=np.uint8)
    out[:, :, :3] = filtered.astype(np.uint8)
    out[:, :, 3] = 255

    state.display_buffer[:] = out.tobytes()


def redraw_scene(state: AppState):
    clear_buffer(state, "raw_buffer", BACKGROUND_COLOR)

    if state.polygon_closed and len(state.polygon_vertices) >= 3:
        fill_polygon_a5(state, state.polygon_vertices, FILL_COLOR)

    draw_polygon_edges(
        state,
        state.polygon_vertices,
        OUTLINE_COLOR,
        state.polygon_closed,
    )

    if (
        not state.polygon_closed
        and state.cursor_fb_pos is not None
        and len(state.polygon_vertices) >= 1
    ):
        draw_line_bresenham(
            state,
            state.polygon_vertices[-1],
            state.cursor_fb_pos,
            PREVIEW_COLOR,
        )

    apply_postfilter_b2(state)
    state.needs_redraw = False


def render_buffer(state: AppState):
    glViewport(0, 0, state.framebuffer_width, state.framebuffer_height)
    glClear(GL_COLOR_BUFFER_BIT)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glWindowPos2i(0, 0)
    glDrawPixels(
        state.framebuffer_width,
        state.framebuffer_height,
        GL_RGBA,
        GL_UNSIGNED_BYTE,
        state.display_buffer,
    )


def window_to_framebuffer_coords(window, state: AppState, xpos: float, ypos: float) -> Point:
    window_width, window_height = glfw.get_window_size(window)
    window_width = max(window_width, 1)
    window_height = max(window_height, 1)

    x = int(xpos * state.framebuffer_width / window_width)
    y = int((window_height - ypos - 1) * state.framebuffer_height / window_height)

    x = max(0, min(state.framebuffer_width - 1, x))
    y = max(0, min(state.framebuffer_height - 1, y))
    return x, y


def clear_polygon_state(state: AppState):
    state.polygon_vertices.clear()
    state.polygon_closed = False
    state.cursor_fb_pos = None
    state.needs_redraw = True


def close_polygon(state: AppState):
    if len(state.polygon_vertices) >= 3 and not state.polygon_closed:
        state.polygon_closed = True
        state.needs_redraw = True


def cursor_position_callback(window, xpos, ypos):
    state: AppState = glfw.get_window_user_pointer(window)
    state.cursor_fb_pos = window_to_framebuffer_coords(window, state, xpos, ypos)

    if not state.polygon_closed and state.polygon_vertices:
        state.needs_redraw = True


def framebuffer_size_callback(window, width, height):
    state: AppState = glfw.get_window_user_pointer(window)
    resize_buffers(state, width, height)


def mouse_button_callback(window, button, action, mods):
    del mods
    state: AppState = glfw.get_window_user_pointer(window)

    if action != glfw.PRESS:
        return

    xpos, ypos = glfw.get_cursor_pos(window)
    point = window_to_framebuffer_coords(window, state, xpos, ypos)
    state.cursor_fb_pos = point

    if button == glfw.MOUSE_BUTTON_LEFT:
        if state.polygon_closed:
            state.polygon_vertices = [point]
            state.polygon_closed = False
        else:
            state.polygon_vertices.append(point)
        state.needs_redraw = True

    elif button == glfw.MOUSE_BUTTON_RIGHT:
        close_polygon(state)


def key_callback(window, key, scancode, action, mods):
    del scancode, mods
    state: AppState = glfw.get_window_user_pointer(window)

    if key == glfw.KEY_ESCAPE and action == glfw.PRESS:
        glfw.set_window_should_close(window, True)
        return

    if action not in (glfw.PRESS, glfw.REPEAT):
        return

    if key == glfw.KEY_C:
        clear_polygon_state(state)
        return

    if key in (glfw.KEY_ENTER, glfw.KEY_KP_ENTER):
        close_polygon(state)
        return

    if key == glfw.KEY_BACKSPACE and not state.polygon_closed and state.polygon_vertices:
        state.polygon_vertices.pop()
        state.needs_redraw = True


def main():
    if not glfw.init():
        raise RuntimeError("Не удалось инициализировать GLFW")

    glfw.window_hint(glfw.RESIZABLE, glfw.TRUE)

    window = glfw.create_window(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, None, None)
    if not window:
        glfw.terminate()
        raise RuntimeError("Не удалось создать окно GLFW")

    glfw.make_context_current(window)
    glfw.swap_interval(1)

    state = AppState()
    resize_buffers(state, *glfw.get_framebuffer_size(window))
    glfw.set_window_user_pointer(window, state)

    glfw.set_cursor_pos_callback(window, cursor_position_callback)
    glfw.set_mouse_button_callback(window, mouse_button_callback)
    glfw.set_key_callback(window, key_callback)
    glfw.set_framebuffer_size_callback(window, framebuffer_size_callback)

    init_gl()

    while not glfw.window_should_close(window):
        width, height = glfw.get_framebuffer_size(window)
        if width != state.framebuffer_width or height != state.framebuffer_height:
            resize_buffers(state, width, height)

        if state.needs_redraw:
            redraw_scene(state)

        render_buffer(state)
        glfw.swap_buffers(window)
        glfw.poll_events()

    glfw.destroy_window(window)
    glfw.terminate()


if __name__ == "__main__":
    main()