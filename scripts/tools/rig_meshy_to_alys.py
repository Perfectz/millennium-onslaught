import bpy
import os
import sys
from mathutils import Vector


def _argv() -> list[str]:
    if "--" not in sys.argv:
        return []
    return sys.argv[sys.argv.index("--") + 1 :]


def _arg_value(flag: str, default: str = "") -> str:
    args = _argv()
    if flag not in args:
        return default
    index = args.index(flag)
    if index + 1 >= len(args):
        return default
    return args[index + 1]


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.users == 0:
            bpy.data.collections.remove(collection)
    for datablock_list in (
        bpy.data.meshes,
        bpy.data.armatures,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.actions,
    ):
        for datablock in list(datablock_list):
            if datablock.users == 0:
                datablock_list.remove(datablock)


def _import_fbx(path: str) -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, use_image_search=True)
    return [obj for obj in bpy.data.objects if obj not in before]


def _armatures(objects: list[bpy.types.Object]) -> list[bpy.types.Object]:
    return [obj for obj in objects if obj.type == "ARMATURE"]


def _meshes(objects: list[bpy.types.Object]) -> list[bpy.types.Object]:
    return [obj for obj in objects if obj.type == "MESH"]


def _largest_mesh(objects: list[bpy.types.Object]) -> bpy.types.Object | None:
    mesh_objects = _meshes(objects)
    if not mesh_objects:
        return None
    return max(mesh_objects, key=lambda obj: len(obj.data.vertices))


def _bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    mins = Vector((float("inf"), float("inf"), float("inf")))
    maxs = Vector((float("-inf"), float("-inf"), float("-inf")))
    for obj in objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            world_corner = obj.matrix_world @ Vector(corner)
            mins.x = min(mins.x, world_corner.x)
            mins.y = min(mins.y, world_corner.y)
            mins.z = min(mins.z, world_corner.z)
            maxs.x = max(maxs.x, world_corner.x)
            maxs.y = max(maxs.y, world_corner.y)
            maxs.z = max(maxs.z, world_corner.z)
    return mins, maxs


def _set_rest_pose(armature: bpy.types.Object) -> None:
    if armature and armature.type == "ARMATURE":
        armature.data.pose_position = "REST"


def _reset_object_transform(obj: bpy.types.Object) -> None:
    obj.rotation_euler = (0.0, 0.0, 0.0)
    obj.location = (0.0, 0.0, 0.0)


def _apply_scale(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def _normalize_source_mesh(moving_mesh: bpy.types.Object, reference_mesh: bpy.types.Object) -> None:
    _reset_object_transform(moving_mesh)

    target_min, target_max = _bounds([reference_mesh])
    source_min, source_max = _bounds([moving_mesh])

    source_size = source_max - source_min
    target_size = target_max - target_min

    if source_size.z <= 0.0001:
        raise RuntimeError("Source mesh height is zero")

    scale = target_size.z / source_size.z
    moving_mesh.scale = (scale, scale, scale)
    _apply_scale(moving_mesh)

    source_min, source_max = _bounds([moving_mesh])
    source_center = (source_min + source_max) * 0.5
    target_center = (target_min + target_max) * 0.5

    moving_mesh.location.x += target_center.x - source_center.x
    moving_mesh.location.y += target_center.y - source_center.y
    moving_mesh.location.z += target_min.z - source_min.z


def _transfer_weights(source_mesh: bpy.types.Object, target_mesh: bpy.types.Object) -> bool:
    bpy.ops.object.select_all(action="DESELECT")
    source_mesh.select_set(True)
    target_mesh.select_set(True)
    bpy.context.view_layer.objects.active = source_mesh

    before_groups = len(target_mesh.vertex_groups)
    try:
        bpy.ops.object.data_transfer(
            data_type="VGROUP_WEIGHTS",
            use_reverse_transfer=False,
            use_create=True,
            vert_mapping="POLYINTERP_NEAREST",
            layers_select_src="ALL",
            layers_select_dst="NAME",
            mix_mode="REPLACE",
            mix_factor=1.0,
        )
    except RuntimeError as exc:
        print(f"weight_transfer_failed: {exc}")
        return False

    return len(target_mesh.vertex_groups) > before_groups


def _auto_weight(armature: bpy.types.Object, target_mesh: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    armature.select_set(True)
    target_mesh.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def _bind_to_armature(armature: bpy.types.Object, target_mesh: bpy.types.Object) -> None:
    for modifier in list(target_mesh.modifiers):
        if modifier.type == "ARMATURE":
            target_mesh.modifiers.remove(modifier)

    modifier = target_mesh.modifiers.new(name="Armature", type="ARMATURE")
    modifier.object = armature
    target_mesh.parent = armature
    target_mesh.matrix_parent_inverse = armature.matrix_world.inverted()


def _cleanup_export_scene(imported_meshes: list[bpy.types.Object], keep_mesh: bpy.types.Object, armature: bpy.types.Object) -> None:
    for obj in imported_meshes:
        if obj != keep_mesh and obj != armature:
            bpy.data.objects.remove(obj, do_unlink=True)

    keep_mesh.name = "AlysMeshy"
    armature.name = "AlysRig"

    bpy.ops.object.select_all(action="DESELECT")
    keep_mesh.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature


def _export_fbx(path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        path_mode="COPY",
        embed_textures=False,
        bake_anim=False,
        add_leaf_bones=False,
    )


def main() -> None:
    source_path = _arg_value("--source")
    target_path = _arg_value("--target")
    output_path = _arg_value("--output")

    if not source_path or not target_path or not output_path:
        raise RuntimeError("usage: blender -b -P rig_meshy_to_alys.py -- --source <fbx> --target <fbx> --output <fbx>")

    print(f"source: {source_path}")
    print(f"target: {target_path}")
    print(f"output: {output_path}")

    _clear_scene()

    target_objects = _import_fbx(target_path)
    target_armature = _armatures(target_objects)[0]
    _set_rest_pose(target_armature)
    source_mesh = _largest_mesh(target_objects)
    if source_mesh is None:
        raise RuntimeError("Target FBX did not produce a mesh")

    imported_source_objects = _import_fbx(source_path)
    imported_source_mesh = _largest_mesh(imported_source_objects)
    if imported_source_mesh is None:
        raise RuntimeError("Source FBX did not produce a mesh")

    _normalize_source_mesh(imported_source_mesh, source_mesh)

    transferred = _transfer_weights(source_mesh, imported_source_mesh)
    print(f"transferred_weights: {transferred}")
    if not transferred:
        _auto_weight(target_armature, imported_source_mesh)
    else:
        _bind_to_armature(target_armature, imported_source_mesh)

    _cleanup_export_scene(target_objects + imported_source_objects, imported_source_mesh, target_armature)
    _export_fbx(output_path)
    print("export_complete")


if __name__ == "__main__":
    main()
