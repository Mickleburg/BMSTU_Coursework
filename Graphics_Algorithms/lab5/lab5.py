from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import List, Tuple

import glfw
import numpy as np
from OpenGL.GL import *

WINDOW_WIDTH = 900
WINDOW_HEIGHT = 700
WINDOW_TITLE = "ЛР5 – Отсечение отрезка произвольным многоугольником"

BACKGROUND_COLOR = (245, 247, 252, 255)
FILL_COLOR = (105, 150, 245, 255)          # заливка многоугольника
OUTLINE_COLOR = (25, 50, 110, 255)          # контур многоугольника
PREVIEW_COLOR = (220, 95, 75, 255)          # предпросмотр отрезка / незамкнутого контура
CLIP_SEGMENT_COLOR = (50, 205, 50, 255)     # отсечённые отрезки (зелёный)

Point = Tuple[int, int]


@dataclass
class EdgeRecord:
    """Запись ребра для алгоритма заливки (A5)."""
    y_min: int
    y_max: int
    x: float
    inv_slope: float


class AppMode(Enum):
    POLYGON = 1
    CLIPPING = 2


@dataclass
class AppState:
    framebuffer_width: int = WINDOW_WIDTH
    framebuffer_height: int = WINDOW_HEIGHT
    raw_buffer: bytearray = field(default_factory=bytearray)
    display_buffer: bytearray = field(default_factory=bytearray)

    # Режим работы
    mode: AppMode = AppMode.POLYGON

    # Многоугольник отсечения
    polygon_vertices: List[Point] = field(default_factory=list)
    polygon_closed: bool = False

    # Ввод отрезков
    clip_first_point: Point | None = None   # первая зафиксированная точка отрезка
    cursor_fb_pos: Point | None = None      # текущая позиция курсора (для предпросмотра)
    clip_segments: List[Tuple[Point, Point]] = field(default_factory=list)  # видимые фрагменты

    needs_redraw: bool = True


def init_gl():
    glClearColor(*(c / 255.0 for c in BACKGROUND_COLOR[:3]), 1.0)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_CULL_FACE)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)


def make_buffer(width: int, height: int, color: Tuple[int, int, int, int]) -> bytearray:
    return bytearray(bytes(color) * (width * height))


def resize_buffers(state: AppState, width: int, height: int):
    state.framebuffer_width = max(1, width)
    state.framebuffer_height = max(1, height)
    state.raw_buffer = make_buffer(state.framebuffer_width, state.framebuffer_height, BACKGROUND_COLOR)
    state.display_buffer = make_buffer(state.framebuffer_width, state.framebuffer_height, BACKGROUND_COLOR)
    state.needs_redraw = True


def clear_buffer(state: AppState, buffer_name: str, color: Tuple[int, int, int, int]):
    buf = getattr(state, buffer_name)
    buf[:] = bytes(color) * (state.framebuffer_width * state.framebuffer_height)


def pixel_index(state: AppState, x: int, y: int) -> int | None:
    if x < 0 or x >= state.framebuffer_width or y < 0 or y >= state.framebuffer_height:
        return None
    return (y * state.framebuffer_width + x) * 4


def put_pixel_raw(state: AppState, x: int, y: int, color: Tuple[int, int, int, int]):
    idx = pixel_index(state, x, y)
    if idx is None:
        return
    state.raw_buffer[idx:idx + 4] = bytes(color)


def fill_horizontal_span_raw(state: AppState, y: int, x_start: int, x_end: int, color: Tuple[int, int, int, int]):
    if y < 0 or y >= state.framebuffer_height:
        return
    x_start = max(0, x_start)
    x_end = min(state.framebuffer_width - 1, x_end)
    if x_start > x_end:
        return
    row_start = (y * state.framebuffer_width + x_start) * 4
    state.raw_buffer[row_start:row_start + (x_end - x_start + 1) * 4] = bytes(color) * (x_end - x_start + 1)


def draw_line_bresenham(state: AppState, start: Point, end: Point, color: Tuple[int, int, int, int]):
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


# ------------------ Алгоритм заливки A5 (из lab4) ------------------
def build_edge_list(vertices: List[Point]) -> List[EdgeRecord]:
    edges: List[EdgeRecord] = []
    total = len(vertices)
    for i in range(total):
        x0, y0 = vertices[i]
        x1, y1 = vertices[(i + 1) % total]
        if y0 == y1:
            continue
        if y0 > y1:
            x0, y0, x1, y1 = x1, y1, x0, y0
        inv_slope = (x1 - x0) / (y1 - y0)
        edges.append(EdgeRecord(y_min=y0, y_max=y1, x=x0 + 0.5 * inv_slope, inv_slope=inv_slope))
    edges.sort(key=lambda e: (e.y_min, e.x, e.y_max))
    return edges


def fill_polygon_a5(state: AppState, vertices: List[Point], color: Tuple[int, int, int, int]):
    if len(vertices) < 3:
        return
    edges = build_edge_list(vertices)
    if not edges:
        return
    active: List[EdgeRecord] = []
    edge_index = 0
    min_y = max(0, min(e.y_min for e in edges))
    max_y = min(state.framebuffer_height, max(e.y_max for e in edges))
    for y in range(min_y, max_y):
        while edge_index < len(edges) and edges[edge_index].y_min == y:
            active.append(edges[edge_index])
            edge_index += 1
        active = [e for e in active if y < e.y_max]
        active.sort(key=lambda e: e.x)
        flag = False
        x_start = 0
        for e in active:
            if not flag:
                x_start = math.ceil(e.x - 0.5)
            else:
                x_end = math.floor(e.x - 0.5)
                fill_horizontal_span_raw(state, y, x_start, x_end, color)
            flag = not flag
        for e in active:
            e.x += e.inv_slope


def draw_polygon_edges(state: AppState, vertices: List[Point], color: Tuple[int, int, int, int], closed: bool):
    if len(vertices) < 2:
        return
    for i in range(len(vertices) - 1):
        draw_line_bresenham(state, vertices[i], vertices[i + 1], color)
    if closed and len(vertices) >= 3:
        draw_line_bresenham(state, vertices[-1], vertices[0], color)


def apply_postfilter_b2(state: AppState):
    w, h = state.framebuffer_width, state.framebuffer_height
    src = np.frombuffer(state.raw_buffer, dtype=np.uint8).reshape((h, w, 4))
    rgb = src[:, :, :3].astype(np.uint16)
    padded = np.pad(rgb, ((1, 1), (1, 1), (0, 0)), mode="edge")
    filtered = (
        padded[:-2, :-2] + 2 * padded[:-2, 1:-1] + padded[:-2, 2:] +
        2 * padded[1:-1, :-2] + 4 * padded[1:-1, 1:-1] + 2 * padded[1:-1, 2:] +
        padded[2:, :-2] + 2 * padded[2:, 1:-1] + padded[2:, 2:]
    ) // 16
    out = np.empty((h, w, 4), dtype=np.uint8)
    out[:, :, :3] = filtered.astype(np.uint8)
    out[:, :, 3] = 255
    state.display_buffer[:] = out.tobytes()


# ------------------ Алгоритм отсечения отрезка ------------------
def point_in_polygon(x: float, y: float, poly: List[Point]) -> bool:
    """Тест принадлежности точки многоугольнику (правило чётного-нечётного)."""
    inside = False
    n = len(poly)
    px, py = x, y
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        # Проверяем, пересекает ли луч (px,py) -> (+inf,py) ребро
        if ((y1 > py) != (y2 > py)):
            x_inter = (x2 - x1) * (py - y1) / (y2 - y1) + x1
            if px < x_inter:
                inside = not inside
    return inside


def line_intersection(p1: Point, p2: Point, q1: Point, q2: Point) -> Tuple[float, float] | None:
    """Возвращает точку пересечения отрезков (x,y) или None."""
    x1, y1 = p1
    x2, y2 = p2
    x3, y3 = q1
    x4, y4 = q2

    denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    if abs(denom) < 1e-10:
        return None

    t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
    u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom

    if 0 <= t <= 1 and 0 <= u <= 1:
        ix = x1 + t * (x2 - x1)
        iy = y1 + t * (y2 - y1)
        return (ix, iy)
    return None


def clip_segment_by_polygon(poly: List[Point], p1: Point, p2: Point) -> List[Tuple[Point, Point]]:
    """
    Отсекает отрезок (p1,p2) произвольным многоугольником poly.
    Возвращает список видимых фрагментов (каждый — пара точек).
    """
    if len(poly) < 3:
        return []

    # Собираем все особые точки вдоль отрезка: концы + пересечения с рёбрами полигона
    points_on_segment: List[Tuple[float, float]] = [p1, p2]
    n = len(poly)
    for i in range(n):
        inter = line_intersection(p1, p2, poly[i], poly[(i + 1) % n])
        if inter is not None:
            points_on_segment.append(inter)

    # Параметризуем вдоль отрезка
    dx = p2[0] - p1[0]
    dy = p2[1] - p1[1]
    length_sq = dx*dx + dy*dy

    def param(pt: Tuple[float, float]) -> float:
        # Проекция на вектор p1->p2
        return ((pt[0] - p1[0]) * dx + (pt[1] - p1[1]) * dy) / length_sq if length_sq > 0 else 0.0

    # Убираем дубликаты с допуском
    unique = []
    for pt in points_on_segment:
        t = param(pt)
        # Допуск на совпадение
        if not any(abs(t - param(ex)) < 1e-7 for ex in unique):
            unique.append(pt)
    unique.sort(key=param)

    # Анализ интервалов
    fragments = []
    for i in range(len(unique) - 1):
        a = unique[i]
        b = unique[i+1]
        mid = ((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5)
        if point_in_polygon(*mid, poly):
            # Округляем до целых (можно и вещественные оставить, но рисуем целочисленно)
            frag_start = (int(round(a[0])), int(round(a[1])))
            frag_end = (int(round(b[0])), int(round(b[1])))
            # Игнорируем вырожденные фрагменты
            if frag_start != frag_end:
                fragments.append((frag_start, frag_end))
    return fragments


def redraw_scene(state: AppState):
    clear_buffer(state, "raw_buffer", BACKGROUND_COLOR)

    # Рисуем залитый многоугольник (если замкнут)
    if state.polygon_closed and len(state.polygon_vertices) >= 3:
        fill_polygon_a5(state, state.polygon_vertices, FILL_COLOR)

    # Контур многоугольника
    draw_polygon_edges(state, state.polygon_vertices, OUTLINE_COLOR, state.polygon_closed)

    # Предпросмотр незамкнутого многоугольника (от последней вершины к курсору)
    if (not state.polygon_closed and state.cursor_fb_pos is not None
            and len(state.polygon_vertices) >= 1):
        draw_line_bresenham(state, state.polygon_vertices[-1], state.cursor_fb_pos, PREVIEW_COLOR)

    # Отсечённые отрезки (зелёным)
    for seg in state.clip_segments:
        draw_line_bresenham(state, seg[0], seg[1], CLIP_SEGMENT_COLOR)

    # Предпросмотр вводимого отрезка в режиме отсечения
    if (state.mode == AppMode.CLIPPING and state.clip_first_point is not None
            and state.cursor_fb_pos is not None):
        draw_line_bresenham(state, state.clip_first_point, state.cursor_fb_pos, PREVIEW_COLOR)

    apply_postfilter_b2(state)
    state.needs_redraw = False


def render_buffer(state: AppState):
    glViewport(0, 0, state.framebuffer_width, state.framebuffer_height)
    glClear(GL_COLOR_BUFFER_BIT)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glWindowPos2i(0, 0)
    glDrawPixels(state.framebuffer_width, state.framebuffer_height, GL_RGBA, GL_UNSIGNED_BYTE, state.display_buffer)


def window_to_framebuffer_coords(window, state: AppState, xpos: float, ypos: float) -> Point:
    win_w, win_h = glfw.get_window_size(window)
    win_w = max(win_w, 1)
    win_h = max(win_h, 1)
    x = int(xpos * state.framebuffer_width / win_w)
    y = int((win_h - ypos - 1) * state.framebuffer_height / win_h)
    x = max(0, min(state.framebuffer_width - 1, x))
    y = max(0, min(state.framebuffer_height - 1, y))
    return x, y


def reset_to_initial(state: AppState):
    """Полный сброс состояния."""
    state.mode = AppMode.POLYGON
    state.polygon_vertices.clear()
    state.polygon_closed = False
    state.clip_first_point = None
    state.clip_segments.clear()
    state.cursor_fb_pos = None
    state.needs_redraw = True


def close_polygon(state: AppState):
    if len(state.polygon_vertices) >= 3 and not state.polygon_closed:
        state.polygon_closed = True
        state.mode = AppMode.CLIPPING   # переключаемся в режим отсечения
        state.needs_redraw = True


# ------------------ Callbacks GLFW ------------------
def cursor_position_callback(window, xpos, ypos):
    state: AppState = glfw.get_window_user_pointer(window)
    state.cursor_fb_pos = window_to_framebuffer_coords(window, state, xpos, ypos)

    if not state.polygon_closed and state.polygon_vertices:
        state.needs_redraw = True
    elif state.mode == AppMode.CLIPPING and state.clip_first_point is not None:
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
        if state.mode == AppMode.POLYGON:
            state.polygon_vertices.append(point)
            state.needs_redraw = True
        elif state.mode == AppMode.CLIPPING:
            if state.clip_first_point is None:
                # Начало нового отрезка
                state.clip_first_point = point
                state.needs_redraw = True
            else:
                # Завершаем отрезок и отсекаем
                p1 = state.clip_first_point
                p2 = point
                fragments = clip_segment_by_polygon(state.polygon_vertices, p1, p2)
                state.clip_segments.extend(fragments)
                state.clip_first_point = None
                state.needs_redraw = True

    elif button == glfw.MOUSE_BUTTON_RIGHT:
        if state.mode == AppMode.POLYGON:
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
        reset_to_initial(state)
        return

    if key in (glfw.KEY_ENTER, glfw.KEY_KP_ENTER):
        if state.mode == AppMode.POLYGON and not state.polygon_closed:
            close_polygon(state)
        return

    if key == glfw.KEY_BACKSPACE:
        if state.mode == AppMode.POLYGON and not state.polygon_closed and state.polygon_vertices:
            state.polygon_vertices.pop()
            state.needs_redraw = True
        elif state.mode == AppMode.CLIPPING and state.clip_first_point is not None:
            state.clip_first_point = None
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