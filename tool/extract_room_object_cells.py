"""Extract tightly-cropped room object PNGs from the source atlases.

The atlas cells intentionally include generous transparent margins. Rendering a
whole cell into a floor-anchored box made the visible object stop above its
logical ground point. This one-time asset step removes that margin while
preserving the original pixels and aspect ratio.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "avatar_layers" / "objects"
OUTPUT = SOURCE / "extracted"

CELLS = {
    "bathroom": {
        "bathroom_mirror": (0, 0),
        "bathroom_sink": (1, 0),
        "bathroom_bathtub": (2, 0),
        "bathroom_shower": (3, 0),
    },
    "bedroom": {
        "bedroom_bed": (0, 0),
        "bedroom_mirror": (1, 0),
        "bedroom_wardrobe": (2, 0),
        "bedroom_drawer": (3, 0),
    },
    "kitchen": {
        "kitchen_table": (0, 0),
        "kitchen_cabinet": (1, 0),
        "kitchen_sink": (2, 0),
        "kitchen_fridge": (3, 0),
    },
    "playroom": {
        "playroom_low_shelf": (0, 0),
        "playroom_bookshelf": (1, 0),
    },
    "entrance": {
        "entrance_shoe_rack": (0, 0),
        "entrance_hooks": (1, 0),
        "entrance_traffic_light": (0, 1),
        "entrance_crosswalk": (1, 1),
    },
    "toilet": {
        "toilet_bowl": (0, 0),
        "toilet_sink": (1, 0),
        "toilet_flush": (2, 0),
        "toilet_paper_holder": (3, 0),
    },
}


def extract() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for theme, cells in CELLS.items():
        atlas = Image.open(SOURCE / f"{theme}.png").convert("RGBA")
        cell_width = atlas.width / 4
        cell_height = atlas.height / 2
        for object_id, (column, row) in cells.items():
            left = round(column * cell_width)
            top = round(row * cell_height)
            right = round((column + 1) * cell_width)
            bottom = round((row + 1) * cell_height)
            cell = atlas.crop((left, top, right, bottom))
            # Some source atlases have a thin opaque cell guide. It is not
            # part of the artwork and would otherwise prevent alpha cropping.
            alpha = cell.getchannel("A")
            edge = max(3, round(min(cell.size) * 0.012))
            alpha.paste(0, (0, 0, cell.width, edge))
            alpha.paste(0, (0, cell.height - edge, cell.width, cell.height))
            alpha.paste(0, (0, 0, edge, cell.height))
            alpha.paste(0, (cell.width - edge, 0, cell.width, cell.height))
            cell.putalpha(alpha)
            alpha_bounds = cell.getchannel("A").getbbox()
            if alpha_bounds is None:
                raise RuntimeError(f"{object_id} cell has no visible pixels")
            visible = cell.crop(alpha_bounds)
            padding = max(2, round(max(visible.size) * 0.015))
            result = Image.new(
                "RGBA",
                (visible.width + padding * 2, visible.height + padding * 2),
            )
            result.alpha_composite(visible, (padding, padding))
            result.save(OUTPUT / f"{object_id}.png", optimize=True)


if __name__ == "__main__":
    extract()
