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
        print(f"PASS {name}: {columns}x{rows}, ground y={GROUND_Y}")


if __name__ == "__main__":
    verify()
