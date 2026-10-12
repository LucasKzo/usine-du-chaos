import bpy
import math
import os

OUTPUT_DIR = os.path.join(os.getcwd(), "fbx_models")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def apply_bevel(obj, width=0.05, segments=2):
    mod = obj.modifiers.new(name="Bevel", type='BEVEL')
    mod.width = width
    mod.segments = segments
    mod.limit_method = 'ANGLE'
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Bevel")

def add_box(name, size, loc, bevel=0.05, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        apply_bevel(obj, width=bevel, segments=2)
    return obj

def add_cyl(name, radius, depth, loc, rot=(0, 0, 0), vertices=20, bevel=0.03):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        apply_bevel(obj, width=bevel, segments=2)
    return obj

def add_cone(name, r1, r2, depth, loc, vertices=20):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    return obj

def add_sphere(name, radius, loc):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=radius, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    return obj

def join_group(objs, group_name):
    if not objs:
        return None
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = group_name
    return objs[0]

def export_model(name):
    filepath = os.path.join(OUTPUT_DIR, f"{name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=filepath,
        use_selection=False,
        apply_scale_options='FBX_SCALE_ALL',
        axis_forward='-Z',
        axis_up='Y'
    )
    print(f"Exporté : {name}.fbx")

# 1. MINES & FOREUSES (Séparées en Mesh_Dark, Mesh_Main, Mesh_Neon et DrillHead)
def build_extractor(model_name):
    clear_scene()
    dark, main, neon, drill = [], [], [], []

    dark.append(add_box("BasePlate", (4.4, 4.4, 0.5), (0, 0, 0.25), bevel=0.08))
    dark.append(add_box("TrackL", (0.9, 4.8, 0.9), (-2.0, 0, 0.45), bevel=0.15))
    dark.append(add_box("TrackR", (0.9, 4.8, 0.9), (2.0, 0, 0.45), bevel=0.15))
    dark.append(add_cyl("TopMotor", 1.1, 0.8, (0, 0, 5.3), bevel=0.06))

    for sx in (-1.5, 1.5):
        for sy in (-1.5, 1.5):
            main.append(add_box("Pillar", (0.5, 0.5, 3.8), (sx, sy, 2.3), bevel=0.05))
            dark.append(add_box("Joint", (0.65, 0.65, 0.4), (sx, sy, 1.2), bevel=0.04))

    main.append(add_box("TopHousing", (4.0, 4.0, 1.1), (0, 0, 4.5), bevel=0.12))
    neon.append(add_box("FrontLamp", (1.6, 0.25, 0.45), (0, -2.02, 4.5), bevel=0.02))
    neon.append(add_cone("OreVein", 1.3, 0.6, 0.9, (0, 0, 0.6), vertices=7))

    drill.append(add_cone("DrillCone", 0.1, 0.95, 3.2, (0, 0, 2.2), vertices=24))
    for i in range(6):
        z_pos = 1.0 + i * 0.42
        rad = 0.35 + i * 0.1
        drill.append(add_cyl(f"Blade_{i}", rad, 0.14, (0, 0, z_pos), rot=(math.radians(14), 0, i * 0.6), bevel=0.02))

    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(neon, "Mesh_Neon")
    join_group(drill, "DrillHead")
    export_model(model_name)

# 2. FOURS INDUSTRIELS
def build_furnace(model_name):
    clear_scene()
    dark = [
        add_box("Base", (4.8, 4.8, 0.6), (0, 0, 0.3), bevel=0.1),
        add_cone("TopCap", 1.9, 1.0, 1.0, (0, 0, 3.8), vertices=24),
        add_cyl("Band1", 2.15, 0.25, (0, 0, 1.3)),
        add_cyl("Band2", 1.98, 0.25, (0, 0, 2.7)),
        add_cyl("Chimney1", 0.45, 1.6, (-0.7, 0.6, 4.6)),
        add_cyl("Chimney2", 0.38, 1.3, (0.7, 0.6, 4.4)),
        add_box("DoorFrame", (2.2, 0.8, 2.0), (0, -1.85, 1.6), bevel=0.08),
    ]
    main = [add_cone("MainDome", 2.2, 1.8, 2.8, (0, 0, 2.0), vertices=24)]
    neon = [add_box("MoltenPool", (1.7, 0.95, 1.5), (0, -1.92, 1.55), bevel=0.04)]

    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(neon, "Mesh_Neon")
    export_model(model_name)

# 3. PRESSE HYDRAULIQUE
def build_hydraulic_press():
    clear_scene()
    dark = [
        add_box("Base", (4.8, 4.8, 0.6), (0, 0, 0.3), bevel=0.08),
        add_box("Anvil", (3.0, 3.0, 0.8), (0, 0, 0.9), bevel=0.1),
    ]
    main = [
        add_box("ColumnL", (0.8, 1.6, 4.4), (-1.8, 0, 2.6), bevel=0.06),
        add_box("ColumnR", (0.8, 1.6, 4.4), (1.8, 0, 2.6), bevel=0.06),
        add_box("TopBeam", (4.6, 2.0, 1.1), (0, 0, 4.8), bevel=0.08),
    ]
    piston = [
        add_cyl("PistonRod", 0.5, 1.8, (0, 0, 3.7)),
        add_box("HammerHead", (2.5, 2.5, 0.7), (0, 0, 2.6), bevel=0.08),
    ]
    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(piston, "Piston")
    export_model("HydraulicPress")

# 4. CUVES & RAFFINERIES
def build_vat_refinery(model_name):
    clear_scene()
    dark = [
        add_box("Base", (4.8, 4.8, 0.6), (0, 0, 0.3), bevel=0.08),
        add_cyl("TankBot", 2.0, 1.2, (0, 0, 1.1)),
        add_cyl("TopRing", 2.0, 0.6, (0, 0, 4.0)),
    ]
    silver = []
    for angle in (0, 90, 180, 270):
        rad = math.radians(angle)
        silver.append(add_box("Strut", (0.35, 0.35, 3.4), (math.cos(rad)*1.9, math.sin(rad)*1.9, 2.5), bevel=0.03))
    neon = [add_cyl("LiquidCore", 1.75, 2.6, (0, 0, 2.5))]

    join_group(dark, "Mesh_Dark")
    join_group(silver, "Mesh_Silver")
    join_group(neon, "Mesh_Neon")
    add_box("RotorSpinner", (3.2, 0.5, 0.4), (0, 0, 4.45), bevel=0.04)
    export_model(model_name)

# 5. TAILLEUSE LASER
def build_laser_cutter():
    clear_scene()
    dark = [
        add_box("Base", (4.8, 4.8, 0.6), (0, 0, 0.3), bevel=0.08),
        add_box("WallL", (0.7, 4.2, 4.0), (-1.9, 0, 2.4), bevel=0.06),
        add_box("WallR", (0.7, 4.2, 4.0), (1.9, 0, 2.4), bevel=0.06),
        add_cone("Emitter", 0.7, 0.3, 1.0, (0, 0, 3.6)),
    ]
    main = [add_box("Gantry", (4.6, 2.2, 0.9), (0, 0, 4.5), bevel=0.08)]
    neon = [add_cyl("LaserBeam", 0.18, 2.8, (0, 0, 2.0))]

    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(neon, "Mesh_Neon")
    export_model("LaserCutter")

# 6. CHAMBRES D'ALLIAGES
def build_alloy_chamber(model_name):
    clear_scene()
    dark = [
        add_box("Base", (4.8, 4.8, 0.6), (0, 0, 0.3), bevel=0.08),
        add_box("WingL", (1.3, 4.2, 3.8), (-1.7, 0, 2.3), bevel=0.08),
        add_box("WingR", (1.3, 4.2, 3.8), (1.7, 0, 2.3), bevel=0.08),
    ]
    main = [add_box("Crown", (4.8, 2.8, 0.8), (0, 0, 4.4), bevel=0.08)]
    neon = [add_sphere("FusionCore", 1.15, (0, 0, 2.5))]

    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(neon, "Mesh_Neon")
    add_box("RotorSpinner", (2.6, 2.6, 0.35), (0, 0, 2.5), bevel=0.05)
    export_model(model_name)

# 7. ÉNERGIE, LIVRAISON & STOCKAGE
def build_generator(model_name):
    clear_scene()
    dark = [
        add_box("Base", (4.8, 4.8, 0.8), (0, 0, 0.4), bevel=0.08),
        add_cyl("Pedestal", 1.8, 1.0, (0, 0, 1.1)),
    ]
    neon = [add_sphere("EnergyBall", 1.35, (0, 0, 2.9))]
    join_group(dark, "Mesh_Dark")
    join_group(neon, "Mesh_Neon")
    add_cyl("RotorSpinner", 1.85, 0.35, (0, 0, 2.9))
    export_model(model_name)

def build_delivery_and_storage():
    clear_scene()
    dark = [add_box("InnerPad", (4.4, 4.4, 0.55), (0, 0, 0.28), bevel=0.06)]
    main = [add_box("OuterPad", (5.2, 5.2, 0.45), (0, 0, 0.22), bevel=0.08)]
    neon = [add_cyl("GlowingCore", 1.75, 0.62, (0, 0, 0.32), vertices=28)]
    for sx in (-2.0, 2.0):
        for sy in (-2.0, 2.0):
            dark.append(add_cyl("Post", 0.22, 1.4, (sx, sy, 0.9)))
            neon.append(add_cyl("Beacon", 0.26, 0.35, (sx, sy, 1.7)))
    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(neon, "Mesh_Neon")
    export_model("DeliveryCenter")

    clear_scene()
    s_dark = [
        add_box("Base", (4.8, 4.8, 0.6), (0, 0, 0.3), bevel=0.08),
        add_sphere("SiloDome", 1.85, (0, 0, 4.2)),
    ]
    s_main = [add_cyl("SiloTank", 1.9, 3.8, (0, 0, 2.4), vertices=24)]
    join_group(s_dark, "Mesh_Dark")
    join_group(s_main, "Mesh_Main")
    export_model("Storage")

# 8. TAPIS ROULANTS
def build_belt(model_name, arch_type=None):
    clear_scene()
    dark = [add_box("BottomBed", (4.2, 5.6, 0.25), (0, 0, 0.12), bevel=0.03)]
    main = [
        add_box("SideRailL", (0.45, 5.6, 0.65), (-2.3, 0, 0.32), bevel=0.05),
        add_box("SideRailR", (0.45, 5.6, 0.65), (2.3, 0, 0.32), bevel=0.05),
    ]
    silver = []
    for y_pos in (-2.1, -1.05, 0.0, 1.05, 2.1):
        silver.append(add_cyl("Roller", 0.30, 4.1, (0, y_pos, 0.36), rot=(0, math.radians(90), 0), vertices=16))

    if arch_type == "Merger":
        main.append(add_box("MergerGate", (4.8, 1.8, 2.2), (0, 0, 1.3), bevel=0.08))
    elif arch_type == "Sorter":
        dark.append(add_box("ScannerArch", (4.8, 1.2, 2.6), (0, 0, 1.5), bevel=0.08))
        neon = [add_box("LaserBar", (4.0, 0.2, 0.25), (0, 0, 1.4), bevel=0.02)]
        join_group(neon, "Mesh_Neon")

    join_group(dark, "Mesh_Dark")
    join_group(main, "Mesh_Main")
    join_group(silver, "Mesh_Silver")
    export_model(model_name)

if __name__ == "__main__":
    for m in ["IronExtractor", "GoldExtractor", "DiamondDrill", "TitaniumExcavator", "NuclearDrill"]:
        build_extractor(m)
    for m in ["IndustrialFurnace", "PlasmaArcFurnace"]:
        build_furnace(m)
    build_hydraulic_press()
    for m in ["ChemicalBath", "UltrasonicRefinery", "AcidEtcher", "GasCentrifuge", "CryoStabilizer"]:
        build_vat_refinery(m)
    build_laser_cutter()
    for m in ["AlloySmelter", "RoyalJeweler", "SynthesisChamber", "QuantumAssembler"]:
        build_alloy_chamber(m)
    for m in ["ThermalGenerator", "FusionReactor"]:
        build_generator(m)
    build_delivery_and_storage()
    for b in ["Belt1_Straight", "Belt1_Left", "Belt1_Right", "Belt2_Straight", "Belt2_Left", "Belt2_Right", "Belt3_Straight", "Belt3_Left", "Belt3_Right", "Belt4_Straight"]:
        build_belt(b)
    build_belt("Merger", "Merger")
    build_belt("Sorter", "Sorter")
    print("=== TOUS LES MODÈLES SONT PRÊTS ET SÉPARÉS PAR COULEURS ! ===")