"""Modelos do Hotel Sem Saída feitos por script no Blender (bpy, sem interface).

Gera em art/models/ um .glb por peça: piano de cauda, lustre, cadeira de café e mesa redonda.
Cada parte usa um material com o NOME de um papel de HotelMaterials ("lacquer", "brass",
"ivory", "velvet"...): o Godot troca pelo material da época certa ao montar a sala.

Coordenadas: o Godot tem y para cima e o Blender z; o exportador glTF converte
(Blender x, y, z) -> (Godot x, z, -y). As medidas abaixo estão em metros, já no espaço do
Godot, e `g()` faz a conversão.

Rodar (de dentro da pasta do projeto), com o Blender 4.2+ ou o pacote bpy do pip:
    blender --background --python tools/blender/make_props.py
    python tools/blender/make_props.py          # com `pip install bpy`
"""

import math
import os
import sys

import bpy  # noqa: I001 (no pacote bpy do pip, bmesh e mathutils só existem depois dele)
import bmesh
from mathutils import Matrix, Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art", "models")


def g(x, y, z):
    """Ponto no espaço do Godot (y para cima) para o do Blender (z para cima)."""
    return Vector((x, -z, y))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
    return mat


def new_object(name, mesh_builder, role, smooth=False):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    mesh_builder(bm)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material(role))
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    return obj


def box(name, center, size, role, bevel=0.0):
    """Caixa pelo centro e tamanho (espaço do Godot), com chanfro opcional."""
    def build(bm):
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector((size[0], size[2], size[1])), verts=bm.verts)
        bmesh.ops.translate(bm, vec=g(*center), verts=bm.verts)
        if bevel > 0:
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, affect="EDGES")
    return new_object(name, build, role)


def cylinder(name, base, radius_bottom, radius_top, height, role, segments=24, axis="y"):
    """Cilindro (ou cone) com a base em `base`, ao longo do eixo y do Godot (ou x / z)."""
    def build(bm):
        bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius_bottom,
                              radius2=radius_top, depth=height)
        bmesh.ops.translate(bm, vec=Vector((0, 0, height / 2.0)), verts=bm.verts)
        if axis == "x":
            bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(-90), 3, "Y"), verts=bm.verts)
        elif axis == "z":
            bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(-90), 3, "X"), verts=bm.verts)
        bmesh.ops.translate(bm, vec=g(*base), verts=bm.verts)
    return new_object(name, build, role, smooth=True)


def torus(name, center, major, minor, role, segments=32, sides=8, tilt=0.0):
    def build(bm):
        verts = []
        for i in range(segments):
            a = 2 * math.pi * i / segments
            ring = []
            for j in range(sides):
                b = 2 * math.pi * j / sides
                r = major + minor * math.cos(b)
                ring.append(bm.verts.new((r * math.cos(a), r * math.sin(a), minor * math.sin(b))))
            verts.append(ring)
        for i in range(segments):
            for j in range(sides):
                a = verts[i][j]
                b = verts[(i + 1) % segments][j]
                c = verts[(i + 1) % segments][(j + 1) % sides]
                d = verts[i][(j + 1) % sides]
                bm.faces.new((a, b, c, d))
        if tilt:
            bmesh.ops.rotate(bm, cent=Vector(), matrix=Matrix.Rotation(math.radians(tilt), 3, "X"), verts=bm.verts)
        bmesh.ops.translate(bm, vec=g(*center), verts=bm.verts)
    return new_object(name, build, role, smooth=True)


def sphere(name, center, radius, role, scale=(1, 1, 1), segments=12, rings=8):
    def build(bm):
        bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
        bmesh.ops.scale(bm, vec=Vector((scale[0], scale[2], scale[1])), verts=bm.verts)
        bmesh.ops.translate(bm, vec=g(*center), verts=bm.verts)
    return new_object(name, build, role, smooth=True)


def tube(name, points, radius, role, sides=8):
    """Tubo que segue uma lista de pontos (espaço do Godot): braços de lustre, encosto de cadeira."""
    def build(bm):
        rings = []
        for i, p in enumerate(points):
            here = g(*p)
            ahead = g(*points[min(i + 1, len(points) - 1)])
            behind = g(*points[max(i - 1, 0)])
            direction = (ahead - behind).normalized()
            side = direction.orthogonal().normalized()
            up = direction.cross(side).normalized()
            ring = []
            for j in range(sides):
                a = 2 * math.pi * j / sides
                ring.append(bm.verts.new(here + (side * math.cos(a) + up * math.sin(a)) * radius))
            rings.append(ring)
        for i in range(len(rings) - 1):
            for j in range(sides):
                bm.faces.new((rings[i][j], rings[i + 1][j], rings[i + 1][(j + 1) % sides], rings[i][(j + 1) % sides]))
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    return new_object(name, build, role, smooth=True)


def extrude(name, outline, y0, y1, role, bevel=0.0):
    """Prisma com a planta `outline` (pontos x, z do Godot) entre as alturas y0 e y1."""
    def build(bm):
        bottom = [bm.verts.new(g(x, y0, z)) for x, z in outline]
        top = [bm.verts.new(g(x, y1, z)) for x, z in outline]
        n = len(outline)
        bm.faces.new(list(reversed(bottom)))
        bm.faces.new(top)
        for i in range(n):
            bm.faces.new((bottom[i], bottom[(i + 1) % n], top[(i + 1) % n], top[i]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        if bevel > 0:
            bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=2, affect="EDGES")
    return new_object(name, build, role)


def join_by_material():
    """Junta as peças de mesmo material num objeto só: no Godot, cada objeto é uma chamada de
    desenho, e o piano tem mais de cem teclas."""
    groups = {}
    for obj in list(bpy.context.collection.objects):
        groups.setdefault(obj.data.materials[0].name, []).append(obj)
    for role, objects in groups.items():
        # Aplica as transformações (a tampa inclinada) antes de juntar
        for obj in objects:
            obj.data.transform(obj.matrix_world)
            obj.matrix_world = Matrix.Identity(4)
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        objects[0].name = role


def export(name):
    join_by_material()
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True,
                              export_materials="PLACEHOLDER", export_yup=True)
    print("exportado", os.path.relpath(path))


# --- Piano de cauda -------------------------------------------------------------------------

def smooth_outline():
    """Planta do piano de cauda (metros): lado reto ao norte, curva ao sul, teclado a oeste.
    Ocupa x -1.25..1.25 e z -0.75..0.75, como a colisão das salas."""
    points = [(-1.25, -0.75), (1.05, -0.75)]
    # Rabo arredondado
    for i in range(1, 9):
        a = math.pi / 2 * i / 8
        points.append((1.05 + 0.2 * math.sin(a), -0.75 + 0.2 * (1 - math.cos(a))))
    # Curva dupla do lado da plateia
    for i in range(1, 17):
        t = i / 16
        x = 1.25 - t * 1.75
        z = -0.55 + 1.3 * (0.5 - 0.5 * math.cos(math.pi * t)) ** 0.8
        points.append((x, min(z, 0.75)))
    points.append((-1.25, 0.75))
    return points


def grand_piano():
    reset()
    outline = smooth_outline()
    extrude("Corpo", outline, 0.62, 0.98, "lacquer", bevel=0.01)
    extrude("Friso", outline, 0.98, 1.0, "brass")
    # Tampa aberta, apoiada na vareta (gira pelo lado reto, ao norte)
    lid = extrude("Tampa", [(x, z + 0.75) for x, z in outline], 0.0, 0.022, "lacquer", bevel=0.005)
    lid.rotation_mode = "XYZ"
    lid.location = g(0, 1.0, -0.75)
    lid.rotation_euler = (math.radians(-36), 0, 0)
    tube("Vareta", [(0.3, 1.0, -0.25), (0.3, 1.58, -0.47)], 0.01, "brass")
    # Teclado: caixa, 52 brancas e as pretas
    box("Teclado", (-1.365, 0.8, 0.0), (0.23, 0.16, 1.44), "lacquer", bevel=0.008)
    white = 52
    width = 1.38 / white
    for i in range(white):
        z = -0.69 + (i + 0.5) * width
        box("Branca%d" % i, (-1.4, 0.89, z), (0.15, 0.022, width - 0.002), "ivory")
    for i in range(white - 1):
        if i % 7 in (2, 6):
            continue
        z = -0.69 + (i + 1) * width
        box("Preta%d" % i, (-1.36, 0.91, z), (0.09, 0.03, width * 0.55), "lacquer")
    # Estante de partitura
    box("Estante", (-1.12, 1.17, 0.0), (0.02, 0.3, 0.7), "lacquer", bevel=0.004)
    # Pernas torneadas, lira e pedais
    for x, z in [(-1.05, -0.6), (-1.05, 0.6), (1.0, -0.55)]:
        cylinder("Perna", (x, 0.0, z), 0.05, 0.075, 0.62, "lacquer", segments=12)
        cylinder("Rodizio", (x, 0.0, z), 0.055, 0.055, 0.04, "brass", segments=12)
        torus("Anel", (x, 0.5, z), 0.07, 0.012, "brass", segments=16, sides=6)
    box("Lira", (-0.98, 0.36, 0.0), (0.04, 0.52, 0.16), "lacquer", bevel=0.01)
    for k in range(3):
        box("Pedal%d" % k, (-1.06, 0.1, -0.05 + k * 0.05), (0.14, 0.015, 0.03), "brass")
    export("piano_cauda")


# --- Lustre ---------------------------------------------------------------------------------

def chandelier():
    """Lustre de latão com 12 braços em dois andares e pingentes. O topo (y = 0) é o ponto de
    fixação; ele desce 1,3 m."""
    reset()
    cylinder("Haste", (0, -0.45, 0), 0.025, 0.025, 0.45, "brass", segments=10)
    sphere("Bola", (0, -0.55, 0), 0.08, "brass")
    cylinder("Coluna", (0, -1.15, 0), 0.05, 0.03, 0.6, "brass", segments=12)
    sphere("Pinha", (0, -1.2, 0), 0.06, "brass", scale=(1, 1.6, 1))
    torus("AroGrande", (0, -0.95, 0), 0.62, 0.018, "brass", segments=48)
    torus("AroPequeno", (0, -0.7, 0), 0.34, 0.014, "brass", segments=40)
    for tier, (count, radius, height, droop) in enumerate([(8, 0.62, -0.95, 0.12), (4, 0.34, -0.7, 0.08)]):
        for i in range(count):
            a = 2 * math.pi * (i + 0.5 * tier) / count
            dx, dz = math.cos(a), math.sin(a)
            # Braço em S do centro até o bocal
            points = []
            for k in range(9):
                t = k / 8
                r = radius * t
                y = height - 0.05 - droop * math.sin(math.pi * t) + 0.1 * t * t
                points.append((dx * r, y, dz * r))
            tube("Braco", points, 0.012, "brass", sides=6)
            tip = (dx * radius, height + 0.05, dz * radius)
            cylinder("Bocal", (tip[0], tip[1] - 0.03, tip[2]), 0.03, 0.04, 0.04, "brass", segments=10)
            cylinder("Vela", (tip[0], tip[1] + 0.01, tip[2]), 0.012, 0.012, 0.09, "ivory", segments=8)
            sphere("Chama", (tip[0], tip[1] + 0.13, tip[2]), 0.022, "bulb", scale=(1, 1.5, 1), segments=8, rings=6)
            # Pingente de cristal pendurado no aro
            drop = (dx * (radius - 0.03), height - 0.12, dz * (radius - 0.03))
            sphere("Cristal", drop, 0.025, "glass", scale=(1, 1.8, 1), segments=6, rings=4)
    export("lustre")


# --- Cadeira de café e mesa redonda --------------------------------------------------------

def cafe_chair():
    """Cadeira de madeira curvada (estilo café de 1920). Assento a 0,46 m; encosto do lado +z."""
    reset()
    cylinder("Assento", (0, 0.43, 0), 0.21, 0.21, 0.035, "velvet", segments=24)
    torus("AroAssento", (0, 0.43, 0), 0.21, 0.014, "dark_wood", segments=32, sides=6)
    for x, z in [(-0.16, -0.14), (0.16, -0.14)]:
        tube("PernaFrente", [(x, 0.43, z), (x * 1.1, 0.2, z * 1.15), (x * 1.18, 0.0, z * 1.25)], 0.016, "dark_wood")
    for x in (-0.15, 0.15):
        tube("PernaTras", [(x * 1.2, 0.0, 0.2), (x, 0.43, 0.17), (x * 0.95, 0.75, 0.2), (x * 0.7, 0.92, 0.18)], 0.016, "dark_wood")
    # Encosto em arco
    arc = []
    for k in range(13):
        a = math.pi * k / 12
        arc.append((-0.105 * math.cos(a), 0.92 + 0.05 * math.sin(a), 0.18 + 0.03 * math.sin(a)))
    tube("Encosto", arc, 0.016, "dark_wood")
    torus("AroPernas", (0, 0.2, 0.02), 0.19, 0.01, "dark_wood", segments=28, sides=6)
    export("cadeira_cafe")


def round_table():
    """Mesa redonda de pé central, tampo a 0,75 m, toalha."""
    reset()
    cylinder("Tampo", (0, 0.71, 0), 0.55, 0.55, 0.04, "dark_wood", segments=40)
    cylinder("Toalha", (0, 0.66, 0), 0.6, 0.6, 0.095, "paper", segments=40)
    cylinder("Pe", (0, 0.08, 0), 0.05, 0.035, 0.6, "dark_wood", segments=12)
    torus("Anel", (0, 0.4, 0), 0.045, 0.01, "brass", segments=16, sides=6)
    for i in range(3):
        a = 2 * math.pi * i / 3
        tube("Garra", [(0, 0.12, 0), (math.cos(a) * 0.2, 0.06, math.sin(a) * 0.2), (math.cos(a) * 0.3, 0.0, math.sin(a) * 0.3)], 0.022, "dark_wood")
    export("mesa_redonda")


if __name__ == "__main__":
    grand_piano()
    chandelier()
    cafe_chair()
    round_table()
