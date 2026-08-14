"""Verify canonical GrowUp avatar frame canvases and ground anchors."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CELL = (360, 600)
GROUND_Y = 580
ATLASES = {
    "avatar_idle_action.png": (4, 2),
    "avatar_walk.png": (4, 4),
    "avatar_interaction.png": (4, 4),
    "avatar_interaction_extra.png": (4, 2),
    "avatar_blue_top.png": (1, 1),
}


def verify() -> None:
    folder = ROOT / "assets/avatars/normalized"
    for name, (columns, rows) in ATLASES.items():
        image = Image.open(folder / name).convert("RGBA")
        assert image.size == (CELL[0] * columns, CELL[1] * rows), (
            name,
            image.size,
        )
        for row in range(rows):
            for column in range(columns):
                cell = image.crop(
                    (
                        column * CELL[0],
                        row * CELL[1],
                        (column + 1) * CELL[0],
                        (row + 1) * CELL[1],
                    )
                )
                bounds = cell.getchannel("A").getbbox()
                assert bounds is not None, (name, row, column, "empty")
                assert bounds[3] == GROUND_Y, (name, row, column, bounds)
                if name == "avatar_walk.png":
                    assert _large_component_count(cell) == 1, (
                        name,
                        row,
                        column,
                        "disconnected sprite bleed",
                    )
        print(f"PASS {name}: {columns}x{rows}, ground y={GROUND_Y}")


def _large_component_count(image: Image.Image) -> int:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = alpha.size
    visited = set()
    count = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] < 16 or (x, y) in visited:
                continue
            stack = [(x, y)]
            visited.add((x, y))
            size = 0
            while stack:
                px, py = stack.pop()
                size += 1
                for nx, ny in (
                    (px - 1, py),
                    (px + 1, py),
                    (px, py - 1),
                    (px, py + 1),
                ):
                    if (
                        0 <= nx < width
                        and 0 <= ny < height
                        and pixels[nx, ny] >= 16
                        and (nx, ny) not in visited
                    ):
                        visited.add((nx, ny))
                        stack.append((nx, ny))
            if size > 100:
                count += 1
    return count


if __name__ == "__main__":
    verify()
