"""Normalize GrowUp avatar atlases to one bottom-center character frame.

Every output cell is 360x600. The ground anchor is (180, 580). This script is
deterministic so future character or interaction frames can use the same rules.
"""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CANVAS = (360, 600)
GROUND = (180, 580)


def keep_largest_subject(cell: Image.Image, alpha_threshold: int = 16) -> Image.Image:
    """Remove disconnected sprite-sheet bleed without cropping the subject."""
    alpha = cell.getchannel("A")
    pixels = alpha.load()
    width, height = alpha.size
    visited = set()
    components = []
    for y in range(height):
        for x in range(width):
            if pixels[x, y] < alpha_threshold or (x, y) in visited:
                continue
            stack = [(x, y)]
            visited.add((x, y))
            component = []
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in (
                    (px - 1, py),
                    (px + 1, py),
                    (px, py - 1),
                    (px, py + 1),
                ):
                    if (
                        0 <= nx < width
                        and 0 <= ny < height
                        and pixels[nx, ny] >= alpha_threshold
                        and (nx, ny) not in visited
                    ):
                        visited.add((nx, ny))
                        stack.append((nx, ny))
            components.append(component)
    if not components:
        return cell
    keep = set(max(components, key=len))
    clean = cell.copy()
    clean_alpha = clean.getchannel("A")
    clean_pixels = clean_alpha.load()
    for y in range(height):
        for x in range(width):
            if pixels[x, y] >= alpha_threshold and (x, y) not in keep:
                clean_pixels[x, y] = 0
    clean.putalpha(clean_alpha)
    return clean


def normalize(source: str, output: str, columns: int, rows: int, mode: str) -> None:
    image = Image.open(ROOT / source).convert("RGBA")
    atlas = Image.new("RGBA", (CANVAS[0] * columns, CANVAS[1] * rows))
    for row in range(rows):
        for column in range(columns):
            source_row = 2 if mode == "walk" and row == 3 else row
            left = round(column * image.width / columns)
            top = round(source_row * image.height / rows)
            right = round((column + 1) * image.width / columns)
            bottom = round((source_row + 1) * image.height / rows)
            cell = image.crop((left, top, right, bottom))
            if mode == "walk":
                cell = keep_largest_subject(cell)
            if mode == "walk" and row == 3:
                cell = cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            bounds = cell.getchannel("A").getbbox()
            if bounds is None:
                continue
            subject = cell.crop(bounds)
            if mode == "walk":
                scale = 500 / subject.height
            elif mode == "interaction_square":
                scale = 1.65
            elif mode == "interaction_tall":
                scale = 1.0
            else:
                scale = 1.0
            # Legacy interaction sheets sometimes include a wide prop in the
            # same cell. Preserve the whole pose instead of clipping it; new
            # character-only frames should not need this safety cap.
            scale = min(scale, (CANVAS[0] - 8) / subject.width)
            width = max(1, round(subject.width * scale))
            height = max(1, round(subject.height * scale))
            subject = subject.resize((width, height), Image.Resampling.LANCZOS)
            cell_out = Image.new("RGBA", CANVAS)
            x = GROUND[0] - width // 2
            y = GROUND[1] - height
            cell_out.alpha_composite(
                subject,
                (max(0, x), max(0, y)),
                (
                    max(0, -x),
                    max(0, -y),
                    min(width, CANVAS[0] - x),
                    min(height, CANVAS[1] - y),
                ),
            )
            atlas.alpha_composite(cell_out, (column * CANVAS[0], row * CANVAS[1]))
    destination = ROOT / output
    destination.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(destination, optimize=True)
    print(f"{destination}: {atlas.size}")


def normalize_single(source: str, output: str, target_height: int = 495) -> None:
    """Put a single full-body costume image on the canonical character cell."""
    image = Image.open(ROOT / source).convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"No visible pixels in {source}")
    subject = image.crop(bounds)
    scale = target_height / subject.height
    size = (round(subject.width * scale), round(subject.height * scale))
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    cell = Image.new("RGBA", CANVAS)
    cell.alpha_composite(
        subject,
        (GROUND[0] - size[0] // 2, GROUND[1] - size[1]),
    )
    destination = ROOT / output
    destination.parent.mkdir(parents=True, exist_ok=True)
    cell.save(destination, optimize=True)
    print(f"{destination}: {cell.size}")


if __name__ == "__main__":
    normalize(
        "assets/avatars/avatar_motion_atlas.png",
        "assets/avatars/normalized/avatar_idle_action.png",
        4,
        2,
        "idle",
    )
    normalize(
        "assets/avatars/avatar_walk_source_v2.png",
        "assets/avatars/normalized/avatar_walk.png",
        4,
        4,
        "walk",
    )
    normalize(
        "assets/avatars/avatar_interaction_atlas.png",
        "assets/avatars/normalized/avatar_interaction.png",
        4,
        4,
        "interaction_square",
    )
    normalize(
        "assets/avatars/avatar_interaction_extra_atlas.png",
        "assets/avatars/normalized/avatar_interaction_extra.png",
        4,
        2,
        "interaction_tall",
    )
    normalize_single(
        "assets/avatars/avatar_blue_top.png",
        "assets/avatars/normalized/avatar_blue_top.png",
    )
