from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACK_ROOT = (
    "res://humandropbox/KayKit_DungeonRemastered_1.1_FREE/"
    "KayKit_DungeonRemastered_1.1_FREE/Assets/gltf"
)

ASSETS = {
    "floor_tile_large": f"{PACK_ROOT}/floor_tile_large.gltf",
    "floor_tile_large_rocks": f"{PACK_ROOT}/floor_tile_large_rocks.gltf",
    "floor_tile_big_grate": f"{PACK_ROOT}/floor_tile_big_grate.gltf",
    "wall": f"{PACK_ROOT}/wall.gltf",
    "wall_window": f"{PACK_ROOT}/wall_window_open.gltf",
    "wall_door": f"{PACK_ROOT}/wall_doorway.gltf",
    "wall_door_open": f"{PACK_ROOT}/wall_doorway_sides.gltf",
    "wall_half": f"{PACK_ROOT}/wall_half.gltf",
    "wall_broken": f"{PACK_ROOT}/wall_broken.gltf",
    "wall_shelves": f"{PACK_ROOT}/wall_shelves.gltf",
    "pillar": f"{PACK_ROOT}/pillar.gltf",
    "torch": f"{PACK_ROOT}/torch_mounted.gltf",
    "banner_blue": f"{PACK_ROOT}/banner_patternA_blue.gltf",
    "banner_red": f"{PACK_ROOT}/banner_patternA_red.gltf",
    "barrel": f"{PACK_ROOT}/barrel_large.gltf",
    "chest": f"{PACK_ROOT}/chest.gltf",
    "table_long": f"{PACK_ROOT}/table_long.gltf",
    "table_medium": f"{PACK_ROOT}/table_medium_decorated_A.gltf",
    "chair": f"{PACK_ROOT}/chair.gltf",
    "rubble": f"{PACK_ROOT}/rubble_large.gltf",
    "shelf_large": f"{PACK_ROOT}/shelf_large.gltf",
    "box_large": f"{PACK_ROOT}/box_large.gltf",
    "box_stacked": f"{PACK_ROOT}/box_stacked.gltf",
    "stairs_narrow": f"{PACK_ROOT}/stairs_narrow.gltf",
}

BOUNDARY_HEIGHT = 4.0
BOUNDARY_THICKNESS = 1.0
EXIT_OPENING_DEPTH = 4.0
MAIN_ROUTE_TILE = "floor_tile_big_grate"

ROTATIONS = {
    0: ((1, 0, 0), (0, 1, 0), (0, 0, 1)),
    90: ((0, 0, -1), (0, 1, 0), (1, 0, 0)),
    -90: ((0, 0, 1), (0, 1, 0), (-1, 0, 0)),
    180: ((-1, 0, 0), (0, 1, 0), (0, 0, -1)),
}


def fmt(value: float) -> str:
    text = f"{value:.3f}"
    text = text.rstrip("0").rstrip(".")
    if text == "-0":
        return "0"
    return text


def transform(x: float, y: float, z: float, rot: int = 0) -> str:
    basis = ROTATIONS[rot]
    values = [
        basis[0][0],
        basis[0][1],
        basis[0][2],
        basis[1][0],
        basis[1][1],
        basis[1][2],
        basis[2][0],
        basis[2][1],
        basis[2][2],
        x,
        y,
        z,
    ]
    return "Transform3D(%s)" % ", ".join(fmt(v) for v in values)


def tile_centers(length: float) -> list[float]:
    tile_count = int(length // 4.0)
    used = tile_count * 4.0
    margin = (length - used) * 0.5
    start = margin + 2.0
    return [start + i * 4.0 for i in range(tile_count)]


def depth_centers(depth: float) -> list[float]:
    count = int(depth // 4.0)
    used = count * 4.0
    margin = (depth - used) * 0.5
    start = -depth * 0.5 + margin + 2.0
    return [start + i * 4.0 for i in range(count)]


def perimeter_wall_positions(width: float, depth: float) -> dict[str, list[tuple[float, float, int]]]:
    xs = tile_centers(width)
    zs = depth_centers(depth)
    return {
        "north": [(x, -depth * 0.5 + 0.5, 0) for x in xs],
        "south": [(x, depth * 0.5 - 0.5, 180) for x in xs],
        "west": [(0.5, z, -90) for z in zs],
        "east": [(width - 0.5, z, 90) for z in zs],
    }


def floor_tiles(width: float, depth: float, variants: dict[tuple[int, int], str] | None = None) -> list[tuple[str, float, float, float, int]]:
    variants = variants or {}
    xs = tile_centers(width)
    zs = depth_centers(depth)
    for (xi, zi), asset in variants.items():
        if xi < 0 or xi >= len(xs) or zi < 0 or zi >= len(zs):
            raise ValueError(
                "floor variant %s is outside the %dx%d tile grid for %.1fx%.1f room"
                % ((xi, zi), len(xs), len(zs), width, depth)
            )
        if asset not in ASSETS:
            raise ValueError("unknown floor asset %r" % asset)
    tiles: list[tuple[str, float, float, float, int]] = []
    for xi, x in enumerate(xs):
        for zi, z in enumerate(zs):
            asset = variants.get((xi, zi), "floor_tile_large")
            tiles.append((asset, x, 0.05, z, 0))
    return tiles


def make_wall_nodes(
    side: str,
    positions: list[tuple[float, float, int]],
    pattern: list[str],
) -> list[tuple[str, str, float, float, float, int]]:
    if len(positions) != len(pattern):
        raise ValueError(
            "%s pattern has %d entries but room edge needs %d"
            % (side, len(pattern), len(positions))
        )
    nodes = []
    for index, ((x, z, rot), asset) in enumerate(zip(positions, pattern), start=1):
        if not asset:
            continue
        nodes.append((asset, f"{side.capitalize()}{index}", x, 0.0, z, rot))
    return nodes


def merge_variants(*variant_maps: dict[tuple[int, int], str]) -> dict[tuple[int, int], str]:
    merged: dict[tuple[int, int], str] = {}
    for variant_map in variant_maps:
        merged.update(variant_map)
    return merged


def lane_tiles(
    columns: list[int] | range,
    rows: list[int] | range,
    asset: str = MAIN_ROUTE_TILE,
) -> dict[tuple[int, int], str]:
    return {
        (int(column), int(row)): asset
        for column in columns
        for row in rows
    }


def exit_guide_props(room: dict) -> list[tuple[str, str, float, float, float, int]]:
    exit_cfg = room.get("stage_exit")
    if not exit_cfg:
        return []
    width = float(room["width"])
    exit_z = float(exit_cfg.get("z", 0.0))
    guide_x = width - 3.0
    return [
        ("torch", "ExitTorchNorth", guide_x, 1.8, exit_z - 4.0, 90),
        ("torch", "ExitTorchSouth", guide_x, 1.8, exit_z + 4.0, 90),
    ]


def torch_light_offset(rot: int) -> tuple[float, float]:
    if rot == 0:
        return 0.0, 0.9
    if rot == 180:
        return 0.0, -0.9
    if rot == 90:
        return -0.9, 0.0
    if rot == -90:
        return 0.9, 0.0
    return 0.0, 0.0


ROOMS = [
    {
        "path": ROOT / "scenes/dungeon/rooms/academy_b1_entry.tscn",
        "name": "AcademyB1Entry",
        "width": 30.0,
        "depth": 24.0,
        "floor_variants": merge_variants(
            lane_tiles(range(0, 7), [3]),
            lane_tiles([2, 3, 4, 5, 6], [2]),
            {(1, 1): "floor_tile_large_rocks", (5, 4): "floor_tile_large_rocks"},
        ),
        "north": ["wall", "wall_window", "wall", "wall_door", "wall", "wall_window", "wall"],
        "south": ["wall", "wall_window", "wall", "wall", "wall", "wall_window", "wall"],
        "west": ["wall", "wall_door", "wall", "wall_window", "wall", "wall"],
        "east": ["wall", "wall_window", "wall", "wall_door_open", "wall_window", "wall"],
        "props": [
            ("pillar", "PillarNW", 9.0, 0.0, -7.5, 0),
            ("pillar", "PillarSW", 9.0, 0.0, 7.5, 0),
            ("pillar", "PillarNE", 21.0, 0.0, -7.5, 0),
            ("pillar", "PillarSE", 21.0, 0.0, 7.5, 0),
            ("torch", "TorchNorthA", 7.0, 1.8, -11.2, 0),
            ("torch", "TorchNorthB", 23.0, 1.8, -11.2, 0),
            ("torch", "TorchSouthA", 7.0, 1.8, 11.2, 180),
            ("torch", "TorchSouthB", 23.0, 1.8, 11.2, 180),
            ("banner_blue", "BannerNorthA", 11.0, 0.0, -11.25, 0),
            ("banner_red", "BannerNorthB", 19.0, 0.0, -11.25, 0),
            ("barrel", "BarrelClusterA", 3.8, 0.0, 9.0, 0),
            ("barrel", "BarrelClusterB", 5.2, 0.0, 8.4, 90),
            ("barrel", "BarrelEast", 26.2, 0.0, -9.0, 0),
            ("chest", "SupplyChest", 24.8, 0.0, 9.2, 180),
            ("table_medium", "EntryTable", 6.5, 0.0, -8.8, 90),
            ("chair", "EntryChair", 8.2, 0.0, -8.5, 90),
        ],
        "stage_exit": {"x": 30.0, "z": 2.0, "rot": 90, "stairs_name": "FloorExitStairs", "asset": "stairs_narrow"},
    },
    {
        "path": ROOT / "scenes/dungeon/rooms/academy_b1_corridors.tscn",
        "name": "AcademyB1Corridors",
        "width": 30.0,
        "depth": 24.0,
        "floor_variants": merge_variants(
            lane_tiles(range(0, 7), [3]),
            lane_tiles([0, 1, 5, 6], [2]),
        ),
        "north": ["wall", "wall", "wall_window", "wall", "wall_window", "wall", "wall"],
        "south": ["wall", "wall", "wall_window", "wall", "wall_window", "wall", "wall"],
        "west": ["wall", "wall_door_open", "wall", "wall", "wall_window", "wall"],
        "east": ["wall", "wall_window", "wall", "wall", "wall_door_open", "wall"],
        "props": [
            ("pillar", "MidPillarA", 15.0, 0.0, -8.0, 0),
            ("pillar", "MidPillarB", 15.0, 0.0, 8.0, 0),
            ("shelf_large", "ShelfNorthA", 7.0, 0.6, -10.8, 180),
            ("shelf_large", "ShelfNorthB", 23.0, 0.6, -10.8, 180),
            ("shelf_large", "ShelfSouthA", 7.0, 0.6, 10.8, 0),
            ("shelf_large", "ShelfSouthB", 23.0, 0.6, 10.8, 0),
            ("barrel", "CorridorBarrelA", 4.5, 0.0, -8.4, 0),
            ("barrel", "CorridorBarrelB", 25.5, 0.0, 8.4, 0),
            ("torch", "TorchWest", 3.0, 1.8, 0.0, -90),
            ("torch", "TorchEast", 27.0, 1.8, 0.0, 90),
            ("banner_blue", "BannerSouth", 15.0, 0.0, 11.25, 180),
        ],
    },
    {
        "path": ROOT / "scenes/dungeon/rooms/academy_b2_storage.tscn",
        "name": "AcademyB2Storage",
        "width": 30.0,
        "depth": 24.0,
        "floor_variants": merge_variants(
            lane_tiles(range(0, 7), [3]),
            lane_tiles([0, 1, 4, 5, 6], [2]),
            {(0, 0): "floor_tile_large_rocks", (6, 5): "floor_tile_large_rocks"},
        ),
        "north": ["wall", "wall_shelves", "wall", "wall_door", "wall", "wall_shelves", "wall"],
        "south": ["wall", "wall", "wall_window", "wall", "wall_window", "wall", "wall"],
        "west": ["wall", "wall", "wall_window", "wall", "wall", "wall"],
        "east": ["wall", "wall_window", "wall", "wall_door_open", "wall", "wall"],
        "props": [
            ("box_stacked", "BoxesNW", 5.0, 0.0, -7.5, 0),
            ("box_large", "BoxNorth", 8.0, 0.0, -8.5, 0),
            ("barrel", "StorageBarrelA", 11.0, 0.0, -8.5, 0),
            ("barrel", "StorageBarrelB", 24.0, 0.0, -8.2, 0),
            ("box_stacked", "BoxesSouth", 23.5, 0.0, 8.5, 180),
            ("chest", "CacheChest", 20.5, 0.0, 8.6, 180),
            ("table_long", "Workbench", 15.0, 0.0, 8.4, 180),
            ("shelf_large", "StorageShelfA", 7.0, 0.6, 10.8, 0),
            ("shelf_large", "StorageShelfB", 23.0, 0.6, 10.8, 0),
            ("torch", "StorageTorchA", 7.0, 1.8, -11.2, 0),
            ("torch", "StorageTorchB", 23.0, 1.8, 11.2, 180),
            ("banner_red", "StorageBanner", 15.0, 0.0, -11.25, 0),
        ],
        "stage_exit": {"x": 30.0, "z": 2.0, "rot": 90, "stairs_name": "StorageExitStairs", "asset": "stairs_narrow"},
    },
    {
        "path": ROOT / "scenes/dungeon/rooms/academy_b2_library.tscn",
        "name": "AcademyB2Library",
        "width": 36.0,
        "depth": 24.0,
        "floor_variants": merge_variants(
            lane_tiles(range(0, 9), [3]),
            lane_tiles([0, 1, 4, 7, 8], [2]),
        ),
        "north": ["wall", "wall_window", "wall_shelves", "wall", "wall_door", "wall", "wall_shelves", "wall_window", "wall"],
        "south": ["wall", "wall_window", "wall", "wall", "wall", "wall", "wall", "wall_window", "wall"],
        "west": ["wall", "wall", "wall_window", "wall_door_open", "wall", "wall"],
        "east": ["wall", "wall_window", "wall", "wall_door_open", "wall_window", "wall"],
        "props": [
            ("pillar", "PillarA", 10.0, 0.0, -8.5, 0),
            ("pillar", "PillarB", 10.0, 0.0, 8.5, 0),
            ("pillar", "PillarC", 26.0, 0.0, -8.5, 0),
            ("pillar", "PillarD", 26.0, 0.0, 8.5, 0),
            ("table_long", "ArchiveTableA", 8.0, 0.0, -8.4, 180),
            ("table_long", "ArchiveTableB", 28.0, 0.0, 8.4, 0),
            ("shelf_large", "ShelfSouthA", 9.0, 0.6, 10.8, 0),
            ("shelf_large", "ShelfSouthB", 27.0, 0.6, 10.8, 0),
            ("torch", "TorchNorthA", 8.0, 1.8, -11.2, 0),
            ("torch", "TorchNorthB", 28.0, 1.8, -11.2, 0),
            ("torch", "TorchWestGuide", 3.0, 1.8, 2.0, -90),
            ("torch", "TorchEastGuide", 33.0, 1.8, 2.0, 90),
            ("banner_blue", "BannerNorth", 18.0, 0.0, -11.25, 0),
        ],
    },
    {
        "path": ROOT / "scenes/dungeon/rooms/academy_b3_gauntlet.tscn",
        "name": "AcademyB3Gauntlet",
        "width": 36.0,
        "depth": 24.0,
        "floor_variants": merge_variants(
            lane_tiles(range(0, 9), [3]),
            lane_tiles([0, 1, 7, 8], [2]),
            {
                (1, 1): "floor_tile_large_rocks",
                (7, 4): "floor_tile_large_rocks",
            },
        ),
        "north": ["wall", "wall_broken", "wall", "wall_window", "wall", "wall_broken", "wall", "wall_window", "wall"],
        "south": ["wall", "wall_window", "wall", "wall", "wall", "wall", "wall", "wall_broken", "wall"],
        "west": ["wall", "wall", "wall_door_open", "wall", "wall_broken", "wall"],
        "east": ["wall", "wall_broken", "wall", "wall_door_open", "wall", "wall"],
        "props": [
            ("rubble", "RubbleNorth", 7.0, 0.0, -9.0, 0),
            ("rubble", "RubbleSouth", 29.0, 0.0, 9.0, 180),
            ("barrel", "BarrelNorth", 30.0, 0.0, -8.8, 0),
            ("barrel", "BarrelSouth", 6.0, 0.0, 8.8, 0),
            ("torch", "TorchA", 9.0, 1.8, -11.2, 0),
            ("torch", "TorchB", 27.0, 1.8, 11.2, 180),
            ("torch", "TorchWestGuide", 3.0, 1.8, 2.0, -90),
            ("torch", "TorchEastGuide", 33.0, 1.8, 2.0, 90),
            ("banner_red", "BannerA", 18.0, 0.0, -11.25, 0),
            ("banner_red", "BannerB", 18.0, 0.0, 11.25, 180),
        ],
    },
    {
        "path": ROOT / "scenes/dungeon/rooms/academy_b3_boss.tscn",
        "name": "AcademyB3Boss",
        "width": 36.0,
        "depth": 24.0,
        "floor_variants": merge_variants(
            lane_tiles(range(0, 9), [3]),
            lane_tiles([0, 1, 4, 7, 8], [2]),
            {
                (2, 1): "floor_tile_large_rocks",
                (6, 4): "floor_tile_large_rocks",
            },
        ),
        "north": ["wall", "wall_window", "wall", "wall", "wall_door", "wall", "wall", "wall_window", "wall"],
        "south": ["wall", "wall", "wall", "wall_window", "wall", "wall_window", "wall", "wall", "wall"],
        "west": ["wall", "wall", "wall_door_open", "wall", "wall", "wall"],
        "east": ["wall", "wall", "wall", "wall_door_open", "wall", "wall"],
        "props": [
            ("pillar", "BossPillarNW", 9.0, 0.0, -9.0, 0),
            ("pillar", "BossPillarSW", 9.0, 0.0, 9.0, 0),
            ("pillar", "BossPillarNE", 27.0, 0.0, -9.0, 0),
            ("pillar", "BossPillarSE", 27.0, 0.0, 9.0, 0),
            ("rubble", "BossRubbleLeft", 5.5, 0.0, -9.0, 0),
            ("rubble", "BossRubbleRight", 30.5, 0.0, 9.0, 180),
            ("torch", "BossTorchA", 8.0, 1.8, -11.2, 0),
            ("torch", "BossTorchB", 28.0, 1.8, -11.2, 0),
            ("banner_red", "BossBannerA", 14.0, 0.0, -11.25, 0),
            ("banner_blue", "BossBannerB", 22.0, 0.0, -11.25, 0),
        ],
        "stage_exit": {"x": 36.0, "z": 2.0, "rot": 90, "stairs_name": "BossExitStairs", "asset": "stairs_narrow"},
    },
]


def build_scene(room: dict) -> str:
    width = room["width"]
    depth = room["depth"]
    ext_resources = []
    for asset_id, asset_path in ASSETS.items():
        ext_resources.append(
            '[ext_resource type="PackedScene" path="%s" id="%s"]' % (asset_path, asset_id)
        )

    sub_resources = [
        '[sub_resource type="BoxShape3D" id="floor_shape"]',
        "size = Vector3(%s, 1, %s)" % (fmt(width), fmt(depth)),
        "",
        '[sub_resource type="BoxShape3D" id="wall_ns_shape"]',
        "size = Vector3(%s, %s, %s)" % (fmt(width), fmt(BOUNDARY_HEIGHT), fmt(BOUNDARY_THICKNESS)),
        "",
        '[sub_resource type="BoxShape3D" id="wall_ew_shape"]',
        "size = Vector3(%s, %s, %s)" % (fmt(BOUNDARY_THICKNESS), fmt(BOUNDARY_HEIGHT), fmt(depth)),
        "",
        '[sub_resource type="BoxMesh" id="foundation_mesh"]',
        "size = Vector3(%s, 4, %s)" % (fmt(width), fmt(depth)),
        "",
        '[sub_resource type="StandardMaterial3D" id="foundation_mat"]',
        "albedo_color = Color(0.153, 0.153, 0.184, 1)",
        "roughness = 1.0",
        "",
        '[sub_resource type="BoxShape3D" id="exit_shape"]',
        "size = Vector3(4, 3, 6)",
    ]

    exit_cfg = room.get("stage_exit")
    split_east_boundary = False
    east_north_shape_id = "wall_ew_shape"
    east_south_shape_id = "wall_ew_shape"
    east_north_center_z = 0.0
    east_south_center_z = 0.0
    if exit_cfg and exit_cfg.get("rot", 90) == 90:
        gap_center_z = float(exit_cfg.get("z", 0.0))
        gap_min_z = gap_center_z - EXIT_OPENING_DEPTH * 0.5
        gap_max_z = gap_center_z + EXIT_OPENING_DEPTH * 0.5
        north_length = gap_min_z - (-depth * 0.5)
        south_length = depth * 0.5 - gap_max_z
        if north_length > 0.0 and south_length > 0.0:
            split_east_boundary = True
            east_north_shape_id = "east_boundary_north_shape"
            east_south_shape_id = "east_boundary_south_shape"
            east_north_center_z = (-depth * 0.5 + gap_min_z) * 0.5
            east_south_center_z = (gap_max_z + depth * 0.5) * 0.5
            sub_resources.extend([
                "",
                '[sub_resource type="BoxShape3D" id="east_boundary_north_shape"]',
                "size = Vector3(%s, %s, %s)" % (
                    fmt(BOUNDARY_THICKNESS),
                    fmt(BOUNDARY_HEIGHT),
                    fmt(north_length),
                ),
                "",
                '[sub_resource type="BoxShape3D" id="east_boundary_south_shape"]',
                "size = Vector3(%s, %s, %s)" % (
                    fmt(BOUNDARY_THICKNESS),
                    fmt(BOUNDARY_HEIGHT),
                    fmt(south_length),
                ),
            ])

    sub_resource_count = sum(1 for line in sub_resources if line.startswith("[sub_resource"))
    header = '[gd_scene load_steps=%d format=3]' % (len(ext_resources) + sub_resource_count)
    lines = [header, ""]
    lines.extend(ext_resources)
    lines.append("")
    lines.extend(sub_resources)
    lines.append("")

    root_name = room["name"]
    lines.append('[node name="%s" type="Node3D"]' % root_name)
    lines.append("")

    floor_center_x = width * 0.5
    lines.append('[node name="Floor" type="StaticBody3D" parent="."]')
    lines.append('transform = %s' % transform(floor_center_x, -0.5, 0.0))
    lines.append("collision_layer = 1")
    lines.append("collision_mask = 0")
    lines.append("")
    lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Floor"]')
    lines.append('shape = SubResource("floor_shape")')
    lines.append("")
    lines.append('[node name="Foundation" type="MeshInstance3D" parent="Floor"]')
    lines.append('transform = %s' % transform(0.0, -2.0, 0.0))
    lines.append('mesh = SubResource("foundation_mesh")')
    lines.append('surface_material_override/0 = SubResource("foundation_mat")')
    lines.append("")

    boundary_defs = [
        ("NorthBoundary", floor_center_x, 1.5, -depth * 0.5, "wall_ns_shape"),
        ("SouthBoundary", floor_center_x, 1.5, depth * 0.5, "wall_ns_shape"),
        ("WestBoundary", 0.0, 1.5, 0.0, "wall_ew_shape"),
    ]
    if split_east_boundary:
        boundary_defs.extend([
            ("EastBoundaryNorth", width, 1.5, east_north_center_z, east_north_shape_id),
            ("EastBoundarySouth", width, 1.5, east_south_center_z, east_south_shape_id),
        ])
    else:
        boundary_defs.append(("EastBoundary", width, 1.5, 0.0, "wall_ew_shape"))
    for name, x, y, z, shape_id in boundary_defs:
        lines.append('[node name="%s" type="StaticBody3D" parent="."]' % name)
        lines.append('transform = %s' % transform(x, y, z))
        lines.append("collision_layer = 1")
        lines.append("collision_mask = 0")
        lines.append("")
        lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="%s"]' % name)
        lines.append('shape = SubResource("%s")' % shape_id)
        lines.append("")

    lines.append('[node name="Visuals" type="Node3D" parent="."]')
    lines.append("")

    floor_nodes = floor_tiles(width, depth, room.get("floor_variants"))
    for index, (asset, x, y, z, rot) in enumerate(floor_nodes, start=1):
        lines.append('[node name="FloorTile%02d" parent="Visuals" instance=ExtResource("%s")]' % (index, asset))
        lines.append('transform = %s' % transform(x, y, z, rot))
        lines.append("")

    wall_positions = perimeter_wall_positions(width, depth)
    wall_nodes = []
    wall_nodes.extend(make_wall_nodes("northWall", wall_positions["north"], room["north"]))
    wall_nodes.extend(make_wall_nodes("southWall", wall_positions["south"], room["south"]))
    wall_nodes.extend(make_wall_nodes("westWall", wall_positions["west"], room["west"]))
    wall_nodes.extend(make_wall_nodes("eastWall", wall_positions["east"], room["east"]))
    for asset, name, x, y, z, rot in wall_nodes:
        lines.append('[node name="%s" parent="Visuals" instance=ExtResource("%s")]' % (name, asset))
        lines.append('transform = %s' % transform(x, y, z, rot))
        lines.append("")

    props = list(room["props"])
    props.extend(exit_guide_props(room))
    for asset, name, x, y, z, rot in props:
        lines.append('[node name="%s" parent="Visuals" instance=ExtResource("%s")]' % (name, asset))
        lines.append('transform = %s' % transform(x, y, z, rot))
        lines.append("")
        if asset == "torch":
            light_offset_x, light_offset_z = torch_light_offset(rot)
            lines.append('[node name="%sLight" type="OmniLight3D" parent="Visuals"]' % name)
            lines.append('transform = %s' % transform(x + light_offset_x, y + 0.35, z + light_offset_z, rot))
            lines.append("light_color = Color(1, 0.76, 0.43, 1)")
            lines.append("light_energy = 1.8")
            lines.append("omni_range = 8.0")
            lines.append("shadow_enabled = true")
            lines.append("")

    if exit_cfg:
        exit_x = exit_cfg["x"]
        exit_z = exit_cfg.get("z", 0.0)
        exit_rot = exit_cfg.get("rot", 90)
        var_asset = exit_cfg.get("asset", "stairs_narrow")
        lines.append('[node name="%s" parent="Visuals" instance=ExtResource("%s")]' % (
            exit_cfg.get("stairs_name", "ExitStairs"),
            var_asset,
        ))
        lines.append('transform = %s' % transform(exit_x, 0.0, exit_z, exit_rot))
        lines.append("")
        lines.append('[node name="StageExitArea" type="Area3D" parent="."]')
        lines.append('transform = %s' % transform(exit_x - 1.5, 1.5, exit_z, 0))
        lines.append("collision_layer = 0")
        lines.append("collision_mask = 2")
        lines.append("monitoring = true")
        lines.append("monitorable = true")
        lines.append("")
        lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="StageExitArea"]')
        lines.append('shape = SubResource("exit_shape")')
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    for room in ROOMS:
        scene_text = build_scene(room)
        room["path"].write_text(scene_text, encoding="utf-8")
        print(f"wrote {room['path'].relative_to(ROOT)}")


if __name__ == "__main__":
    main()
