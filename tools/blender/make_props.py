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
    """Cilindro (ou cone) com a base em `base`, ao longo do eixo y do Godot (ou x / z).
    Atenção: com axis="x" ou "z" ele cresce para -x / -z a partir da base."""
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


# --- Saguão: lustre grande, sofá, poltrona e relógio de carrilhão ---------------------------

def grand_chandelier():
    """Lustre do Saguão: três anéis (1,0 / 0,74 / 0,48 m), 12 velas, 40 gotas de cristal.
    O topo (y = 0) fica no teto; a gota de baixo, 2,3 m abaixo."""
    reset()
    cylinder("Haste", (0, -1.1, 0), 0.03, 0.03, 1.1, "brass", segments=8)
    cylinder("Coluna", (0, -2.0, 0), 0.08, 0.06, 0.9, "brass", segments=16)
    for k, y in enumerate((-1.25, -1.5, -1.75)):
        torus("Colar%d" % k, (0, y, 0), 0.085, 0.02, "brass", segments=16, sides=6)
    sphere("Bacia", (0, -2.05, 0), 0.26, "brass", scale=(1, 0.6, 1), segments=20, rings=10)
    sphere("Gota", (0, -2.28, 0), 0.07, "glass", scale=(1, 1.8, 1), segments=8, rings=6)
    rings = [(-1.95, 1.0, 24), (-1.64, 0.74, 16), (-1.37, 0.48, 0)]
    for k, (y, radius, drops) in enumerate(rings):
        torus("Anel%d" % k, (0, y, 0), radius, 0.035, "brass", segments=64, sides=8)
        # Raios do anel até a coluna
        for i in range(8):
            a = 2 * math.pi * (i + 0.5 * k) / 8
            tube("Raio", [(0, y + 0.12, 0), (math.cos(a) * radius * 0.5, y + 0.02, math.sin(a) * radius * 0.5),
                          (math.cos(a) * radius, y, math.sin(a) * radius)], 0.012, "brass", sides=6)
        for i in range(drops):
            a = 2 * math.pi * (i + 0.5) / drops
            hang = 0.12 + 0.05 * (i % 2)
            tube("Fio", [(math.cos(a) * radius, y, math.sin(a) * radius), (math.cos(a) * radius, y - hang + 0.04, math.sin(a) * radius)], 0.003, "brass", sides=4)
            sphere("Cristal", (math.cos(a) * radius, y - hang, math.sin(a) * radius), 0.03, "glass", scale=(1, 2.2, 1), segments=6, rings=4)
    # Braços em S e velas no anel de baixo
    for i in range(12):
        a = 2 * math.pi * i / 12
        dx, dz = math.cos(a), math.sin(a)
        points = []
        for k in range(9):
            t = k / 8
            points.append((dx * (0.3 + 0.7 * t), -1.95 - 0.12 * math.sin(math.pi * t) + 0.08 * t, dz * (0.3 + 0.7 * t)))
        tube("Braco", points, 0.016, "brass", sides=6)
        tip = (dx * 1.0, -1.87, dz * 1.0)
        cylinder("Bocal", (tip[0], tip[1] - 0.04, tip[2]), 0.04, 0.05, 0.06, "brass", segments=10)
        cylinder("Vela", (tip[0], tip[1] + 0.02, tip[2]), 0.018, 0.018, 0.11, "ivory", segments=8)
        sphere("Chama", (tip[0], tip[1] + 0.17, tip[2]), 0.035, "bulb", scale=(1, 1.4, 1), segments=8, rings=6)
    export("lustre_saguao")


def tufted_back(width, y0, y1, z, rows, cols, role):
    """Botões do capitonê numa face voltada para +z."""
    for r in range(rows):
        for c in range(cols):
            x = -width / 2 + width * (c + 0.5 + 0.5 * (r % 2)) / (cols + 0.5)
            y = y0 + (y1 - y0) * (r + 0.5) / rows
            sphere("Botao", (x, y, z), 0.018, role, segments=6, rings=4)


def sofa():
    """Sofá chesterfield de três lugares, 2,2 m; encosto do lado -z, frente para +z."""
    reset()
    box("Base", (0, 0.3, 0), (2.06, 0.3, 0.82), "velvet", bevel=0.04)
    box("Encosto", (0, 0.72, -0.34), (2.06, 0.56, 0.18), "velvet", bevel=0.05)
    tube("RoloEncosto", [(-1.0, 1.0, -0.34), (1.0, 1.0, -0.34)], 0.1, "velvet", sides=12)
    for x in (-1.0, 1.0):
        box("Braco", (x, 0.52, 0.0), (0.18, 0.36, 0.82), "velvet", bevel=0.04)
        tube("RoloBraco", [(x, 0.72, -0.4), (x, 0.72, 0.42)], 0.12, "velvet", sides=12)
        sphere("Voluta", (x, 0.72, 0.42), 0.12, "velvet", scale=(1, 1, 0.3), segments=12, rings=6)
    for k in range(3):
        box("Almofada%d" % k, (-0.62 + k * 0.62, 0.52, 0.06), (0.6, 0.14, 0.68), "velvet", bevel=0.05)
    tufted_back(1.85, 0.5, 0.95, -0.245, 2, 8, "brass")
    for x in (-0.95, 0.95):
        for z in (-0.33, 0.33):
            cylinder("Pe", (x, 0.0, z), 0.03, 0.045, 0.15, "dark_wood", segments=10)
            sphere("Rodizio", (x, 0.02, z), 0.03, "brass", segments=8, rings=6)
    export("sofa")


def armchair():
    """Poltrona de espaldar alto (bergère), 0,9 m; encosto do lado -z."""
    reset()
    box("Base", (0, 0.3, 0.0), (0.82, 0.28, 0.78), "velvet", bevel=0.04)
    box("Encosto", (0, 0.82, -0.32), (0.82, 0.8, 0.16), "velvet", bevel=0.05)
    tube("TopoEncosto", [(-0.41, 1.2, -0.32), (0.41, 1.2, -0.32)], 0.08, "velvet", sides=10)
    for x in (-0.37, 0.37):
        box("Braco", (x, 0.52, 0.02), (0.13, 0.3, 0.76), "velvet", bevel=0.03)
        tube("RoloBraco", [(x, 0.68, -0.34), (x, 0.68, 0.4)], 0.07, "velvet", sides=10)
    box("Almofada", (0, 0.5, 0.06), (0.6, 0.13, 0.62), "velvet", bevel=0.05)
    tufted_back(0.62, 0.62, 1.1, -0.235, 3, 3, "brass")
    for x in (-0.35, 0.35):
        for z in (-0.32, 0.32):
            cylinder("Pe", (x, 0.0, z), 0.025, 0.04, 0.16, "dark_wood", segments=10)
    export("poltrona")


def grandfather_clock(hours=3, minutes=7, name="relogio_carrilhao"):
    """Relógio de carrilhão, 2,55 m; mostrador para +z. Hoje parado em 3h07; em 1923, 11h40
    (a mesma hora da torre antes de Helena mexer)."""
    reset()
    box("Pedestal", (0, 0.15, 0), (0.62, 0.3, 0.38), "mahogany", bevel=0.02)
    box("Rodape", (0, 0.02, 0), (0.68, 0.04, 0.42), "dark_wood")
    box("Tronco", (0, 1.1, 0), (0.48, 1.6, 0.3), "mahogany", bevel=0.015)
    box("Porta", (0, 1.1, 0.155), (0.32, 1.15, 0.015), "dark_wood", bevel=0.005)
    box("Vidro", (0, 1.15, 0.165), (0.24, 0.9, 0.005), "glass")
    tube("Haste", [(0, 1.55, 0.13), (0, 0.85, 0.13)], 0.006, "brass", sides=6)
    cylinder("Peso", (0, 0.7, 0.13), 0.08, 0.08, 0.015, "brass", segments=20, axis="z")
    box("Capitel", (0, 2.15, 0), (0.62, 0.55, 0.38), "mahogany", bevel=0.02)
    # Frontão em arco e pináculos
    arch = [(-0.3 + 0.6 * i / 16, 2.42 + 0.12 * math.sin(math.pi * i / 16)) for i in range(17)]
    for i in range(16):
        x0, y0 = arch[i]
        x1, y1 = arch[i + 1]
        box("Arco%d" % i, ((x0 + x1) / 2, (y0 + y1) / 2 + 0.03, 0), (0.04, 0.06, 0.4), "dark_wood")
    for x in (-0.28, 0.0, 0.28):
        sphere("Pinaculo", (x, 2.62 if x == 0 else 2.5, 0.12), 0.04, "brass", segments=10, rings=6)
    cylinder("Aro", (0, 2.15, 0.19), 0.23, 0.23, 0.02, "brass", segments=32, axis="z")
    cylinder("Mostrador", (0, 2.15, 0.205), 0.2, 0.2, 0.008, "ivory", segments=32, axis="z")
    for h in range(12):
        a = 2 * math.pi * h / 12
        box("Marca%d" % h, (math.sin(a) * 0.17, 2.15 + math.cos(a) * 0.17, 0.215), (0.012, 0.03, 0.004), "lacquer")
    # Ponteiros na hora pedida
    for length, angle, width in ((0.1, 2 * math.pi * (hours + minutes / 60) / 12, 0.014),
                                 (0.16, 2 * math.pi * minutes / 60, 0.009)):
        cx = math.sin(angle) * length / 2
        cy = math.cos(angle) * length / 2
        hand = box("Ponteiro", (cx, 2.15 + cy, 0.222), (width, length, 0.004), "lacquer")
        # Gira no plano do mostrador, em torno do próprio centro (eixo z do Godot = -y do Blender)
        hand.data.transform(Matrix.Translation(-g(cx, 2.15 + cy, 0.222)))
        hand.data.transform(Matrix.Rotation(angle, 4, "Y"))
        hand.data.transform(Matrix.Translation(g(cx, 2.15 + cy, 0.222)))
    export(name)


# --- Quartos: cama, guarda-roupa, escrivaninha e baú --------------------------------------

def panel(name, center, size, role, depth=0.012):
    """Almofada de porta: uma moldura em relevo sobre a face voltada para -z."""
    cx, cy, cz = center
    w, h = size
    box(name + "Fundo", (cx, cy, cz - depth / 2), (w, h, depth), role, bevel=0.004)
    for dy in (-h / 2, h / 2):
        box(name + "H", (cx, cy + dy, cz - depth), (w, 0.025, 0.012), role)
    for dx in (-w / 2, w / 2):
        box(name + "V", (cx + dx, cy, cz - depth), (0.025, h, 0.012), role)


def bed():
    """Cama de casal: 1,6 x 2,2 m, colchão a 0,55 m, cabeceira do lado +z."""
    reset()
    box("Estrado", (0, 0.27, 0), (1.56, 0.16, 2.12), "mahogany", bevel=0.02)
    box("Colchao", (0, 0.45, -0.02), (1.5, 0.2, 2.04), "paper", bevel=0.05)
    box("Colcha", (0, 0.52, -0.25), (1.58, 0.07, 1.62), "velvet", bevel=0.03)
    box("DobraColcha", (0, 0.565, 0.5), (1.58, 0.05, 0.22), "velvet", bevel=0.02)
    for x in (-0.38, 0.38):
        box("Travesseiro", (x, 0.6, 0.82), (0.62, 0.13, 0.36), "paper", bevel=0.06)
    # Cabeceira alta com almofadas, pés torneados
    box("Cabeceira", (0, 0.8, 1.13), (1.62, 0.9, 0.06), "mahogany", bevel=0.01)
    tube("TopoCabeceira", [(-0.81, 1.27, 1.13), (0, 1.36, 1.13), (0.81, 1.27, 1.13)], 0.035, "mahogany", sides=8)
    for x in (-0.4, 0.4):
        panel("Almofada", (x, 0.85, 1.1), (0.62, 0.5), "dark_wood")
    box("Peseira", (0, 0.5, -1.1), (1.62, 0.5, 0.05), "mahogany", bevel=0.01)
    for x in (-0.81, 0.81):
        for z, top in ((1.13, 1.4), (-1.1, 0.8)):
            cylinder("Coluna", (x, 0, z), 0.045, 0.04, top, "mahogany", segments=10)
            sphere("Pomo", (x, top + 0.03, z), 0.045, "brass", segments=10, rings=6)
    export("cama")


def wardrobe():
    """Guarda-roupa de duas portas: 1,2 x 0,7 x 2,2 m, frente para -z."""
    reset()
    box("Corpo", (0, 1.12, 0), (1.16, 1.96, 0.66), "mahogany", bevel=0.01)
    box("Base", (0, 0.09, 0), (1.22, 0.18, 0.7), "dark_wood", bevel=0.01)
    box("Cornija", (0, 2.14, 0.01), (1.26, 0.12, 0.72), "dark_wood", bevel=0.015)
    for x in (-0.29, 0.29):
        box("Porta", (x, 1.12, -0.335), (0.56, 1.82, 0.02), "mahogany", bevel=0.004)
        panel("AlmofadaAlta", (x, 1.5, -0.345), (0.42, 0.8), "dark_wood")
        panel("AlmofadaBaixa", (x, 0.62, -0.345), (0.42, 0.6), "dark_wood")
        cylinder("Puxador", (x * 0.12, 1.15, -0.36), 0.012, 0.012, 0.04, "brass", segments=8, axis="z")
    cylinder("Fechadura", (0.02, 1.25, -0.36), 0.015, 0.015, 0.01, "brass", segments=8, axis="z")
    export("guarda_roupa")


def writing_desk():
    """Escrivaninha: 0,7 de fundo (x) por 1,2 de largura (z), tampo a 0,78 m; gaveta para +x."""
    reset()
    box("Tampo", (0, 0.75, 0), (0.72, 0.04, 1.22), "mahogany", bevel=0.01)
    box("Saia", (0, 0.65, 0), (0.62, 0.16, 1.12), "mahogany")
    box("Gaveta", (0.315, 0.64, 0), (0.02, 0.12, 0.7), "dark_wood", bevel=0.004)
    sphere("Puxador", (0.33, 0.64, 0), 0.018, "brass", segments=8, rings=6)
    for x in (-0.3, 0.3):
        for z in (-0.53, 0.53):
            points = [(x, 0.57, z), (x * 0.97, 0.3, z * 0.98), (x * 1.04, 0.0, z * 1.03)]
            tube("Perna", points, 0.025, "mahogany", sides=8)
    # Galeria com escaninhos atrás
    box("Galeria", (-0.3, 0.92, 0), (0.1, 0.3, 1.1), "mahogany", bevel=0.005)
    for z in (-0.3, 0.0, 0.3):
        box("Divisoria", (-0.24, 0.92, z), (0.02, 0.28, 0.01), "dark_wood")
    export("escrivaninha")


def trunk():
    """Baú de viagem de couro: 0,8 x 0,5 x 0,42 m, com cintas, cantoneiras e tampa abaulada."""
    reset()
    box("Caixa", (0, 0.18, 0), (0.78, 0.34, 0.48), "leather", bevel=0.015)
    # Tampa abaulada
    for i in range(8):
        a0 = math.pi * i / 8
        a1 = math.pi * (i + 1) / 8
        z0, y0 = -0.24 * math.cos(a0), 0.35 + 0.07 * math.sin(a0)
        z1, y1 = -0.24 * math.cos(a1), 0.35 + 0.07 * math.sin(a1)
        seg = box("Tampa%d" % i, (0, (y0 + y1) / 2, (z0 + z1) / 2), (0.8, 0.02, math.hypot(z1 - z0, y1 - y0) + 0.01), "leather")
        angle = math.atan2(y1 - y0, z1 - z0)
        center = g(0, (y0 + y1) / 2, (z0 + z1) / 2)
        seg.data.transform(Matrix.Translation(-center))
        seg.data.transform(Matrix.Rotation(angle, 4, "X"))
        seg.data.transform(Matrix.Translation(center))
    for x in (-0.25, 0.25):
        box("Cinta", (x, 0.2, 0), (0.05, 0.36, 0.5), "brass")
    for x in (-0.39, 0.39):
        for z in (-0.24, 0.24):
            box("Cantoneira", (x, 0.05, z), (0.04, 0.1, 0.04), "brass")
    box("Fecho", (0, 0.32, -0.25), (0.08, 0.08, 0.02), "brass")
    for x in (-0.41, 0.41):
        tube("Alca", [(x, 0.22, -0.08), (x * 1.06, 0.26, 0.0), (x, 0.22, 0.08)], 0.01, "leather", sides=6)
    export("bau")


# --- Utilidades para peças giradas ------------------------------------------------------------

def turn(obj, pivot, angle, axis="z"):
    """Gira a malha em torno de `pivot` (espaço do Godot). `axis` é o eixo do Godot."""
    blender_axis = {"x": "X", "y": "Z", "z": "Y"}[axis]
    # O eixo z do Godot vira -y no Blender: o sinal inverte
    if axis == "z":
        angle = -angle
    center = g(*pivot)
    obj.data.transform(Matrix.Translation(-center))
    obj.data.transform(Matrix.Rotation(math.radians(angle), 4, blender_axis))
    obj.data.transform(Matrix.Translation(center))
    return obj


# --- Biblioteca: estantes, mesa de leitura, cadeira, luminária e lustre ---------------------

BOOK_ROLES = ["green_velvet", "mahogany", "velvet", "oak", "leather", "green_velvet", "velvet"]


def book_row(rng, x0, x1, y, room, present):
    """Uma fileira de livros entre x0 e x1, apoiada em y, com a lombada para +z. `room` é a
    altura livre até a prateleira de cima. Hoje faltam livros e alguns caíram de lado."""
    x = x0
    while x < x1 - 0.04:
        w = rng.uniform(0.035, 0.075)
        h = min(room - 0.04, rng.uniform(0.2, 0.34))
        depth = rng.uniform(0.2, 0.27)
        role = rng.choice(BOOK_ROLES)
        if present and rng.random() < 0.33:
            x += w + 0.01
            continue
        if rng.random() < 0.06 and x + 0.3 < x1:
            # Pilha deitada
            for k in range(rng.randint(2, 4)):
                bh = rng.uniform(0.03, 0.05)
                box("Deitado", (x + 0.14, y + 0.025 + k * 0.045, 0.13 - depth / 2 + 0.02),
                    (rng.uniform(0.22, 0.27), bh, depth - 0.02), rng.choice(BOOK_ROLES))
            x += 0.3
            continue
        book = box("Livro", (x + w / 2, y + h / 2, 0.2 - depth / 2), (w, h, depth), role)
        if rng.random() < 0.5:
            box("Friso", (x + w / 2, y + h * 0.82, 0.201), (w * 0.9, 0.012, 0.004), "brass")
        lean = 0.0
        if present and rng.random() < 0.25:
            lean = rng.uniform(8, 22) * rng.choice((-1, 1))
        elif rng.random() < 0.04:
            lean = rng.uniform(5, 10)
        if lean:
            pivot = (x + (w if lean < 0 else 0.0), y, 0.0)
            turn(book, pivot, lean, "z")
            x += h * math.sin(math.radians(abs(lean)))
        x += w + rng.uniform(0.0, 0.006)


def bookcase(name, width, height, seed, present):
    """Estante com a frente para +z, ocupando x ±width/2, z ±0,35 e y 0..height (a colisão)."""
    import random
    reset()
    rng = random.Random(seed)
    box("Fundo", (0, height / 2, -0.29), (width - 0.1, height - 0.1, 0.06), "dark_wood")
    for side in (-1, 1):
        box("Lateral", (side * (width / 2 - 0.05), height / 2, 0), (0.1, height, 0.66), "mahogany", bevel=0.008)
        box("Pilastra", (side * (width / 2 - 0.05), height / 2, 0.335), (0.12, height - 0.3, 0.02), "mahogany", bevel=0.004)
    box("Rodape", (0, 0.06, 0.01), (width, 0.12, 0.68), "mahogany", bevel=0.008)
    box("Cornija", (0, height - 0.05, 0.005), (width, 0.1, 0.69), "mahogany", bevel=0.012)
    box("Friso", (0, height - 0.13, 0.33), (width - 0.2, 0.05, 0.02), "dark_wood", bevel=0.004)
    rows = 4
    step = (height - 0.25) / rows
    for row in range(rows + 1):
        y = 0.12 + row * step
        box("Prateleira", (0, y, 0.0), (width - 0.2, 0.05, 0.62), "mahogany", bevel=0.004)
        box("Borda", (0, y - 0.005, 0.315), (width - 0.2, 0.06, 0.02), "mahogany")
        if row < rows:
            book_row(rng, -width / 2 + 0.12, width / 2 - 0.12, y + 0.025, step - 0.03, present)
    export(name)


def reading_table():
    """Mesa de leitura de 2,9 x 1,2 m, tampo a 0,97 m com feltro verde (colisão até 0,99)."""
    reset()
    box("Tampo", (0, 0.92, 0), (2.9, 0.08, 1.2), "mahogany", bevel=0.015)
    box("Feltro", (0, 0.966, 0), (2.6, 0.012, 1.0), "green_velvet")
    box("Saia", (0, 0.8, 0), (2.6, 0.16, 0.95), "mahogany", bevel=0.006)
    for z in (-0.476, 0.476):
        for x in (-0.65, 0.65):
            box("Gaveta", (x, 0.8, z), (0.7, 0.11, 0.01), "dark_wood", bevel=0.003)
            sphere("Puxador", (x, 0.8, z * 1.025), 0.016, "brass", segments=8, rings=6)
    for x in (-1.25, 1.25):
        for z in (-0.4, 0.4):
            cylinder("Perna", (x, 0.0, z), 0.05, 0.06, 0.1, "mahogany", segments=12)
            cylinder("Perna", (x, 0.1, z), 0.06, 0.045, 0.45, "mahogany", segments=12)
            sphere("Anel", (x, 0.58, z), 0.065, "mahogany", scale=(1, 0.6, 1), segments=12, rings=6)
            cylinder("Perna", (x, 0.6, z), 0.045, 0.06, 0.12, "mahogany", segments=12)
            box("Topo", (x, 0.79, z), (0.13, 0.18, 0.13), "mahogany", bevel=0.006)
    box("Travessa", (0, 0.2, 0), (2.5, 0.05, 0.06), "mahogany", bevel=0.006)
    for x in (-1.25, 1.25):
        box("Travessa", (x, 0.2, 0), (0.06, 0.05, 0.8), "mahogany", bevel=0.006)
    export("mesa_leitura")


def library_chair():
    """Cadeira de biblioteca com assento estofado e encosto de travessas; encosto em -z."""
    reset()
    box("Assento", (0, 0.47, 0.01), (0.52, 0.08, 0.5), "green_velvet", bevel=0.03)
    box("Quadro", (0, 0.42, 0), (0.55, 0.05, 0.55), "mahogany", bevel=0.008)
    for x in (-0.24, 0.24):
        cylinder("PernaFrente", (x, 0, 0.24), 0.022, 0.03, 0.42, "mahogany", segments=10)
        tube("PernaTras", [(x, 0, -0.27), (x, 0.42, -0.24), (x * 0.96, 0.95, -0.27), (x * 0.94, 1.3, -0.3)], 0.025, "mahogany")
    box("Travessa", (0, 1.24, -0.29), (0.5, 0.1, 0.04), "mahogany", bevel=0.01)
    box("Travessa", (0, 0.66, -0.25), (0.48, 0.05, 0.03), "mahogany", bevel=0.006)
    for x in (-0.12, 0.0, 0.12):
        box("Ripa", (x, 0.95, -0.27), (0.05, 0.55, 0.02), "mahogany", bevel=0.004)
    for z in (-0.24, 0.24):
        box("Trave", (0, 0.15, z), (0.46, 0.03, 0.03), "mahogany")
    export("cadeira_biblioteca")


def bankers_lamp():
    """Luminária de mesa com cúpula verde. A base fica em y = 0 (sobre o tampo)."""
    reset()
    cylinder("Base", (0, 0, 0), 0.15, 0.12, 0.035, "brass", segments=24)
    cylinder("Haste", (0, 0.035, 0), 0.016, 0.016, 0.42, "brass", segments=10)
    tube("Arco", [(0, 0.45, 0), (0, 0.48, 0.03), (0, 0.49, 0.08)], 0.012, "brass", sides=6)
    # Cúpula meia-cana, comprida no eixo x
    def shade(bm):
        segs = 12
        length = 0.42
        rings = []
        for side in (-1, 1):
            ring = []
            for i in range(segs + 1):
                a = math.pi * i / segs
                ring.append(bm.verts.new(g(side * length / 2, 0.42 + 0.1 * math.sin(a), 0.08 + 0.12 * math.cos(a))))
            rings.append(ring)
        for i in range(segs):
            bm.faces.new((rings[0][i], rings[1][i], rings[1][i + 1], rings[0][i + 1]))
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.006)
    new_object("Cupula", shade, "green_velvet", smooth=True)
    for x in (-0.211, 0.211):
        box("Tampa", (x, 0.46, 0.08), (0.006, 0.08, 0.2), "brass")
    cylinder("Lampada", (0.12, 0.44, 0.08), 0.022, 0.022, 0.24, "bulb", segments=8, axis="x")
    sphere("Corrente", (0.05, 0.37, 0.12), 0.01, "brass", segments=6, rings=4)
    export("luminaria_banco")


def library_chandelier():
    """Lustre da Biblioteca: aro com seis globos foscos. O topo (y = 0) é o forro; desce 1,2 m."""
    reset()
    cylinder("Haste", (0, -0.85, 0), 0.02, 0.02, 0.85, "brass", segments=10)
    cylinder("Canopla", (0, -0.06, 0), 0.1, 0.06, 0.06, "brass", segments=16)
    torus("Aro", (0, -0.95, 0), 0.47, 0.02, "brass", segments=48)
    sphere("Centro", (0, -0.97, 0), 0.07, "brass", scale=(1, 1.4, 1))
    cylinder("Pinha", (0, -1.12, 0), 0.01, 0.04, 0.1, "brass", segments=10)
    for i in range(6):
        a = 2 * math.pi * i / 6
        dx, dz = math.cos(a), math.sin(a)
        tube("Raio", [(0, -0.9, 0), (dx * 0.25, -0.93, dz * 0.25), (dx * 0.47, -0.95, dz * 0.47)], 0.01, "brass", sides=6)
        cylinder("Bocal", (dx * 0.47, -0.97, dz * 0.47), 0.03, 0.035, 0.04, "brass", segments=10)
        sphere("Globo", (dx * 0.47, -1.04, dz * 0.47), 0.075, "bulb", segments=12, rings=8)
    export("lustre_biblioteca")


# --- Caldeiras ---------------------------------------------------------------------------------

def boiler():
    """Caldeira horizontal: casco de 1,08 m de raio e 3,1 m de comprimento ao longo de +z, a partir
    da origem (centro do fundo). Fornalha na frente (+z) e chaminé que sobe até o forro (y = 3,93)."""
    reset()
    cylinder("Casco", (0, 0, 3.1), 1.08, 1.08, 3.1, "cast_iron", segments=36, axis="z")
    for z in (0.12, 1.08, 2.12, 3.05):
        cylinder("Cinta", (0, 0, z + 0.03), 1.105, 1.105, 0.06, "copper", segments=36, axis="z")
        for i in range(28):
            a = 2 * math.pi * i / 28
            sphere("Rebite", (math.cos(a) * 1.11, math.sin(a) * 1.11, z), 0.016, "iron", segments=6, rings=4)
    # Costura longitudinal de rebites no alto
    for k in range(24):
        z = 0.2 + k * 0.115
        for a in (math.radians(80), math.radians(100)):
            sphere("Rebite", (math.cos(a) * 1.085, math.sin(a) * 1.085, z), 0.014, "iron", segments=6, rings=4)
    # Frente: espelho, porta da fornalha com grelha e parafusos
    cylinder("Espelho", (0, 0, 3.13), 1.0, 1.0, 0.03, "iron", segments=36, axis="z")
    cylinder("Porta", (0, -0.07, 3.175), 0.62, 0.62, 0.075, "iron", segments=28, axis="z")
    torus("Moldura", (0, -0.07, 3.18), 0.57, 0.05, "copper", segments=32, sides=6, tilt=90)
    for i in range(5):
        x = (i - 2) * 0.145
        box("Grelha", (x, -0.07, 3.18), (0.073, 0.54 - abs(i - 2) * 0.1, 0.008), "street")
    for i in range(10):
        a = 2 * math.pi * i / 10
        sphere("Parafuso", (math.cos(a) * 0.9, math.sin(a) * 0.9, 3.13), 0.045, "brass", segments=8, rings=5)
    box("Trinco", (0.5, -0.07, 3.2), (0.2, 0.05, 0.04), "brass", bevel=0.008)
    cylinder("Dobradica", (-0.64, -0.3, 3.15), 0.03, 0.03, 0.46, "iron", segments=8)
    # Manômetro pequeno e visor de nível
    cylinder("Manometro", (0.62, 0.55, 3.17), 0.11, 0.11, 0.05, "brass", segments=20, axis="z")
    cylinder("Mostrador", (0.62, 0.55, 3.176), 0.09, 0.09, 0.006, "enamel", segments=20, axis="z")
    box("Ponteiro", (0.64, 0.57, 3.178), (0.008, 0.07, 0.003), "dark")
    cylinder("Visor", (-0.6, 0.25, 3.12), 0.025, 0.025, 0.4, "glass", segments=8)
    for y in (0.25, 0.65):
        box("Suporte", (-0.6, y, 3.14), (0.07, 0.04, 0.06), "brass")
    box("Placa", (0, 0.72, 3.12), (0.5, 0.14, 0.02), "lacquer", bevel=0.004)
    # Domo de vapor e válvula de segurança no alto
    cylinder("Domo", (0, 0.95, 2.1), 0.26, 0.26, 0.32, "cast_iron", segments=20)
    sphere("Tampa", (0, 1.27, 2.1), 0.26, "cast_iron", scale=(1, 0.35, 1), segments=20, rings=8)
    cylinder("Valvula", (0.35, 1.0, 2.6), 0.05, 0.05, 0.3, "brass", segments=10)
    tube("Alavanca", [(0.35, 1.3, 2.6), (0.35, 1.33, 2.85)], 0.012, "brass", sides=6)
    sphere("Peso", (0.35, 1.31, 2.88), 0.05, "iron", segments=8, rings=6)
    # Chaminé até o forro
    cylinder("Chamine", (0, 1.0, 0.5), 0.31, 0.31, 2.93, "iron", segments=20)
    cylinder("Gola", (0, 1.0, 0.5), 0.36, 0.36, 0.1, "iron", segments=20)
    torus("Anel", (0, 1.27, 0.5), 0.32, 0.03, "brass", segments=24, sides=6)
    torus("Anel", (0, 2.9, 0.5), 0.32, 0.025, "iron", segments=24, sides=6)
    export("caldeira")


def industrial_lamp():
    """Luminária pendente de esmalte. Origem na boca da cúpula; a haste sobe 0,74 m."""
    reset()
    cylinder("Haste", (0, 0.17, 0), 0.016, 0.016, 0.57, "iron", segments=8)
    cylinder("Canopla", (0, 0.68, 0), 0.06, 0.04, 0.06, "iron", segments=12)
    def shade(bm):
        segs = 24
        profile = [(0.25, 0.0), (0.22, 0.04), (0.14, 0.11), (0.07, 0.16), (0.045, 0.19)]
        rings = []
        for r, y in profile:
            ring = []
            for i in range(segs):
                a = 2 * math.pi * i / segs
                ring.append(bm.verts.new(g(math.cos(a) * r, y, math.sin(a) * r)))
            rings.append(ring)
        for k in range(len(rings) - 1):
            for i in range(segs):
                j = (i + 1) % segs
                bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.006)
    new_object("Cupula", shade, "enamel", smooth=True)
    torus("Borda", (0, 0.0, 0), 0.25, 0.008, "iron", segments=32, sides=6)
    cylinder("Bocal", (0, 0.1, 0), 0.04, 0.04, 0.1, "iron", segments=12)
    sphere("Lampada", (0, 0.05, 0), 0.07, "bulb", segments=12, rings=8)
    export("luminaria_industrial")


# --- Cozinha: fogão a lenha, geladeira de gelo, portas da bancada e estante da despensa -------

def wood_stove():
    """Fogão a lenha de ferro, 2 x 1 m, chapa a 0,85 m. Origem no canto oeste do fundo; a frente
    fica em z = 1 (forno aberto à esquerda, fornalha à direita)."""
    reset()
    for x in (0.08, 1.92):
        for z in (0.12, 0.9):
            cylinder("Pe", (x, 0, z), 0.05, 0.035, 0.13, "cast_iron", segments=10)
    box("Corpo", (1.0, 0.475, 0.5), (2.0, 0.71, 1.0), "cast_iron", bevel=0.01)
    box("Chapa", (1.0, 0.83, 0.51), (2.04, 0.04, 1.02), "iron", bevel=0.004)
    for x, z in ((0.45, 0.4), (1.0, 0.55), (1.55, 0.4)):
        torus("Boca", (x, 0.852, z), 0.12, 0.018, "cast_iron", segments=24, sides=6)
        cylinder("Tampa", (x, 0.845, z), 0.1, 0.1, 0.01, "iron", segments=20)
    box("Frisos", (1.0, 0.13, 1.005), (2.0, 0.02, 0.01), "brass")
    # Forno aberto: boca escura, porta caída para a frente
    box("BocaForno", (0.5, 0.42, 1.002), (0.7, 0.4, 0.006), "dark")
    box("PortaForno", (0.5, 0.2, 1.16), (0.7, 0.04, 0.32), "cast_iron", bevel=0.006)
    box("PuxadorForno", (0.5, 0.215, 1.31), (0.4, 0.02, 0.02), "brass")
    for x in (0.18, 0.82):
        box("Dobradica", (x, 0.2, 1.0), (0.05, 0.05, 0.04), "iron")
    # Fornalha: duas portinholas e a fresta com brasa
    box("Fornalha", (1.425, 0.42, 1.015), (0.85, 0.4, 0.03), "cast_iron", bevel=0.005)
    box("Trinco", (1.425, 0.38, 1.037), (0.75, 0.04, 0.015), "brass")
    box("Cinzeiro", (1.425, 0.71, 1.015), (0.85, 0.1, 0.03), "cast_iron", bevel=0.004)
    box("Brasa", (1.4, 0.71, 1.031), (0.6, 0.06, 0.003), "bulb")
    for x in (1.1, 1.75):
        sphere("Botao", (x, 0.55, 1.04), 0.022, "brass", segments=8, rings=5)
    # Barra de latão na frente
    cylinder("Barra", (2.05, 0.78, 1.12), 0.015, 0.015, 2.1, "brass", segments=8, axis="x")
    for x in (-0.03, 2.03):
        box("Suporte", (x, 0.78, 1.065), (0.03, 0.04, 0.13), "brass")
    # Panelas
    cylinder("Panela", (1.0, 0.85, 0.55), 0.17, 0.17, 0.24, "copper", segments=20)
    cylinder("TampaPanela", (1.0, 1.09, 0.55), 0.175, 0.175, 0.02, "copper", segments=20)
    sphere("Pegador", (1.0, 1.12, 0.55), 0.025, "brass", segments=8, rings=5)
    for side in (-1, 1):
        torus("Alca", (1.0 + side * 0.19, 1.0, 0.55), 0.03, 0.008, "copper", segments=10, sides=4, tilt=90)
    cylinder("Chaleira", (1.55, 0.85, 0.4), 0.11, 0.08, 0.2, "enamel", segments=16)
    tube("Bico", [(1.62, 0.92, 0.4), (1.7, 1.0, 0.4), (1.74, 1.05, 0.4)], 0.012, "enamel", sides=6)
    tube("AlcaChaleira", [(1.47, 1.04, 0.4), (1.55, 1.12, 0.4), (1.63, 1.04, 0.4)], 0.008, "iron", sides=5)
    export("fogao_lenha")


def icebox():
    """Geladeira de gelo de carvalho: 1,4 x 0,9 m, 1,66 m de altura. Origem no canto oeste do
    fundo; portas para +z (z = 0,9). O letreiro GELO é desenhado pela sala."""
    reset()
    box("Corpo", (0.7, 0.84, 0.45), (1.4, 1.52, 0.9), "oak", bevel=0.01)
    box("Tampo", (0.7, 1.63, 0.465), (1.46, 0.06, 0.93), "dark_wood", bevel=0.01)
    box("Base", (0.7, 0.1, 0.45), (1.42, 0.06, 0.92), "dark_wood", bevel=0.006)
    for x in (0.05, 1.35):
        cylinder("Pe", (x, 0, 0.84), 0.035, 0.03, 0.08, "brass", segments=10)
    for y0, y1 in ((0.95, 1.52), (0.16, 0.85)):
        box("Porta", (0.7, (y0 + y1) / 2, 0.92), (1.24, y1 - y0, 0.04), "panel", bevel=0.006)
        # Moldura das bordas: o centro fica liso para o letreiro
        h = y1 - y0
        for dy in (-h / 2 + 0.04, h / 2 - 0.04):
            box("Moldura", (0.7, (y0 + y1) / 2 + dy, 0.945), (1.12, 0.025, 0.012), "oak")
        for dx in (-0.56, 0.56):
            box("Moldura", (0.7 + dx, (y0 + y1) / 2, 0.945), (0.025, h - 0.06, 0.012), "oak")
        box("Trinco", (1.18, (y0 + y1) / 2, 0.955), (0.1, 0.12, 0.03), "brass", bevel=0.005)
        cylinder("Alavanca", (1.18, (y0 + y1) / 2, 1.02), 0.015, 0.015, 0.05, "brass", segments=8, axis="z")
        for hy in (y0 + 0.08, y1 - 0.08):
            box("Dobradica", (0.08, hy, 0.925), (0.08, 0.08, 0.05), "brass")
    box("Bandeja", (0.7, 0.025, 1.1), (0.8, 0.05, 0.3), "copper", bevel=0.006)
    export("geladeira")
    # Hoje: a mesma geladeira sem a bandeja (some com o gelo)


def cabinet_door():
    """Porta de armário da bancada, 0,63 x 0,58 m. Origem no canto de baixo à esquerda, no
    plano do corpo; a frente fica em +z."""
    reset()
    box("Folha", (0.315, 0.29, 0.012), (0.63, 0.58, 0.024), "panel", bevel=0.004)
    for y in (0.05, 0.53):
        box("Moldura", (0.315, y, 0.028), (0.55, 0.025, 0.01), "oak")
    for x in (0.04, 0.59):
        box("Moldura", (x, 0.29, 0.028), (0.025, 0.5, 0.01), "oak")
    sphere("Puxador", (0.55, 0.34, 0.04), 0.018, "brass", segments=8, rings=6)
    export("porta_armario")


def pantry_shelves(present):
    """Estante da despensa: 5 x 0,5 m, cinco tábuas de 0,3 a 1,98 m; origem no canto oeste do
    fundo. Hoje a quarta tábua cedeu numa ponta."""
    reset()
    length = 5.0
    boards = [0.3, 0.72, 1.14, 1.56, 1.98]
    for x in (0.03, length / 2, length - 0.03):
        for z in (0.04, 0.46):
            box("Montante", (x, 1.14, z), (0.06, 2.28, 0.06), "oak", bevel=0.006)
        box("Travessa", (x, 0.06, 0.25), (0.05, 0.06, 0.45), "oak")
    for x0 in (0.06, length / 2 + 0.03):
        # Mão-francesa em X no fundo
        for sign in (-1, 1):
            brace = box("Diagonal", (x0 + 1.21, 1.14, 0.015), (2.6, 0.04, 0.02), "plank")
            turn(brace, (x0 + 1.21, 1.14, 0.015), sign * 36, "z")
    for i, y in enumerate(boards):
        board = box("Tabua", (length / 2, y - 0.02, 0.25), (length, 0.04, 0.5), "oak", bevel=0.004)
        box("Borda", (length / 2, y - 0.03, 0.495), (length, 0.06, 0.012), "oak")
        if present and i == 3:
            turn(board, (length / 2, y - 0.02, 0.25), -12, "z")
    export("estante_despensa_hoje" if present else "estante_despensa")


# --- Portas ---------------------------------------------------------------------------------

def door_leaf(prefix, cx, width, height, thickness, knob, swing=False):
    """Uma folha almofadada centrada em x = cx, de 0 a height, espessura no eixo z (centrada).
    As almofadas e a maçaneta ficam nas duas faces; `knob` é o lado da maçaneta (-1 / 1)."""
    box(prefix + "Folha", (cx, height / 2, 0), (width, height, thickness), "mahogany", bevel=0.006)
    margin = 0.13
    inner = width - 2 * margin
    if swing:
        layout = [(0.18, height * 0.42)]
    elif width > 0.9:
        layout = [(0.2, height * 0.42), (height * 0.48, height - 0.2)]
    else:
        layout = [(0.18, height * 0.42), (height * 0.47, height - 0.18)]
    for face in (-1, 1):
        z = face * thickness / 2
        for y0, y1 in layout:
            cols = 2 if inner > 0.85 and not swing else 1
            w = (inner - (cols - 1) * 0.1) / cols
            for c in range(cols):
                x = cx - inner / 2 + w / 2 + c * (w + 0.1)
                box(prefix + "Almofada", (x, (y0 + y1) / 2, z + face * 0.006), (w, y1 - y0, 0.012), "panel", bevel=0.004)
                for dy in (-(y1 - y0) / 2, (y1 - y0) / 2):
                    box(prefix + "Moldura", (x, (y0 + y1) / 2 + dy, z + face * 0.012), (w + 0.03, 0.025, 0.014), "mahogany")
                for dx in (-w / 2, w / 2):
                    box(prefix + "Moldura", (x + dx, (y0 + y1) / 2, z + face * 0.012), (0.025, y1 - y0 + 0.03, 0.014), "mahogany")
        if swing:
            # Visor redondo e placas de latão de empurrar e de chute
            cylinder(prefix + "Visor", (cx, 1.6, z + max(face, 0) * 0.03), 0.17, 0.17, 0.03, "brass", segments=24, axis="z")
            cylinder(prefix + "Vidro", (cx, 1.6, z + face * 0.03 + max(face, 0) * 0.004), 0.14, 0.14, 0.004, "glass", segments=24, axis="z")
            box(prefix + "Chute", (cx, 0.25, z + face * 0.008), (width - 0.2, 0.12, 0.016), "brass")
            box(prefix + "Empurrar", (cx + knob * (width / 2 - 0.14), 1.15, z + face * 0.008), (0.1, 0.3, 0.016), "brass")
        else:
            kx = cx + knob * (width / 2 - 0.13)
            box(prefix + "Espelho", (kx, 1.0, z + face * 0.006), (0.05, 0.2, 0.012), "brass", bevel=0.003)
            cylinder(prefix + "Haste", (kx, 1.03, z + max(face, 0) * 0.05), 0.008, 0.008, 0.05, "brass", segments=8, axis="z")
            sphere(prefix + "Macaneta", (kx, 1.03, z + face * 0.06), 0.028, "brass", segments=10, rings=6)
            box(prefix + "Fechadura", (kx, 0.92, z + face * 0.0125), (0.012, 0.03, 0.003), "dark")


def door(name, width, height, knob=1, double=False, swing=False, thickness=0.06):
    """Folha de porta (sem batente): x ±width/2, y 0..height, z ±thickness/2."""
    reset()
    if double:
        half = width / 2
        door_leaf("E", -half / 2, half - 0.004, height, thickness, 1)
        door_leaf("D", half / 2, half - 0.004, height, thickness, -1)
    else:
        door_leaf("", 0.0, width, height, thickness, knob, swing)
    export(name)


# --- Torre: mecanismo do relógio ------------------------------------------------------------

def gear(name, center, radius, teeth, thickness, role, hub=True):
    """Engrenagem de dentes retos no plano x-y (eixo ao longo de z), centrada em `center`."""
    cx, cy, cz = center
    def build(bm):
        outline = []
        depth = min(0.035, radius * 0.18)
        for k in range(teeth * 4):
            a = 2 * math.pi * k / (teeth * 4)
            r = radius if (k % 4) in (1, 2) else radius - depth
            outline.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
        front = [bm.verts.new(g(x, y, cz + thickness / 2)) for x, y in outline]
        back = [bm.verts.new(g(x, y, cz - thickness / 2)) for x, y in outline]
        n = len(outline)
        bm.faces.new(front)
        bm.faces.new(list(reversed(back)))
        for k in range(n):
            bm.faces.new((back[k], back[(k + 1) % n], front[(k + 1) % n], front[k]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    obj = new_object(name, build, role)
    if hub:
        cylinder(name + "Cubo", (cx, cy, cz + thickness / 2 + 0.012), radius * 0.22, radius * 0.22, thickness + 0.024, role, segments=12, axis="z")
        for k in range(4):
            a = 2 * math.pi * k / 4 + 0.4
            x2, y2 = cx + math.cos(a) * radius * 0.6, cy + math.sin(a) * radius * 0.6
            box(name + "Raio", ((cx + x2) / 2, (cy + y2) / 2, cz), (0.02, radius * 0.75, thickness * 1.2), role)
    return obj


def clock_machine():
    """Mecanismo do relógio da torre, 1,6 x 1,2 m, armação até 1,2 m e engrenagens até 1,65 m.
    Origem no canto noroeste do piso (o mostrador de acerto fica na face z = 0, desenhado pela sala)."""
    reset()
    box("Base", (0.8, 0.06, 0.6), (1.6, 0.12, 1.2), "cast_iron", bevel=0.01)
    box("Tampo", (0.8, 1.18, 0.6), (1.6, 0.05, 1.2), "cast_iron", bevel=0.008)
    # Armação: duas chapas recortadas nas pontas (z) e colunas de latão nos cantos
    for z in (0.12, 1.08):
        box("Chapa", (0.8, 0.65, z), (1.4, 1.0, 0.04), "cast_iron", bevel=0.006)
    for x in (0.08, 1.52):
        for z in (0.08, 1.12):
            cylinder("Coluna", (x, 0.12, z), 0.035, 0.035, 1.04, "brass", segments=10)
            sphere("Pomo", (x, 1.22, z), 0.04, "brass", segments=10, rings=6)
    # Trem de engrenagens entre as chapas (eixos ao longo de z)
    for x, y, r, t in ((0.4, 0.55, 0.3, 40), (0.95, 0.75, 0.18, 24), (1.25, 0.45, 0.14, 18)):
        gear("Roda", (x, y, 0.6), r, t, 0.025, "brass")
        cylinder("Eixo", (x, y, 1.1), 0.012, 0.012, 1.0, "iron", segments=8, axis="z")
    # Tambor do peso com o cabo
    cylinder("Tambor", (0.4, 0.55, 0.95), 0.12, 0.12, 0.2, "cast_iron", segments=20, axis="z")
    # Engrenagens de cima e o escape (âncora sobre a roda de escape)
    for x, r, t in ((0.35, 0.22, 30), (0.8, 0.18, 24), (1.25, 0.14, 15)):
        gear("Topo", (x, 1.21 + r + 0.02, 0.6), r, t, 0.035, "brass")
        box("Mancal", (x, 1.21 + r * 0.5, 0.6), (0.05, r + 0.04, 0.05), "cast_iron")
    tube("Ancora", [(1.08, 1.6, 0.6), (1.25, 1.52, 0.6), (1.42, 1.6, 0.6)], 0.012, "iron", sides=6)
    cylinder("Pino", (1.25, 1.52, 0.66), 0.015, 0.015, 0.12, "iron", segments=8, axis="z")
    # Volante de acerto na lateral leste e manivela
    gear("Volante", (1.6, 0.85, 0.6), 0.1, 12, 0.02, "brass", hub=False)
    turn(bpy.data.objects["Volante"], (1.6, 0.85, 0.6), 90, "y")
    tube("Manivela", [(1.62, 0.85, 0.6), (1.66, 0.85, 0.6), (1.66, 0.95, 0.6)], 0.01, "iron", sides=6)
    box("Placa", (0.8, 0.95, 1.105), (0.5, 0.12, 0.012), "lacquer", bevel=0.003)
    export("mecanismo_relogio")


# --- Manutenção: bancada, armário de ferramentas e aquecedor ---------------------------------

def workbench():
    """Bancada de oficina 3,2 x 0,9 m, tampo a 0,9 m; origem no centro do piso. Morsa na ponta
    leste; o meio do tampo fica livre (a chave de 1951 fica ali)."""
    reset()
    box("Tampo", (0, 0.84, 0), (3.2, 0.12, 0.9), "oak", bevel=0.01)
    for x in (-1.5, 1.5):
        for z in (-0.38, 0.38):
            box("Perna", (x, 0.39, z), (0.08, 0.78, 0.08), "iron", bevel=0.005)
    box("Prateleira", (0, 0.18, 0), (3.0, 0.03, 0.78), "oak")
    for x in (-1.5, 1.5):
        box("Travessa", (x, 0.18, 0), (0.06, 0.05, 0.8), "iron")
    box("Frente", (0, 0.72, 0.43), (3.1, 0.12, 0.02), "oak")
    # Morsa
    box("MorsaBase", (1.35, 0.93, 0.3), (0.22, 0.06, 0.2), "cast_iron", bevel=0.006)
    box("MorsaFixa", (1.35, 1.02, 0.25), (0.22, 0.12, 0.06), "cast_iron", bevel=0.006)
    box("MorsaMovel", (1.35, 1.02, 0.4), (0.22, 0.12, 0.05), "cast_iron", bevel=0.006)
    cylinder("Fuso", (1.35, 1.0, 0.6), 0.015, 0.015, 0.22, "iron", segments=8, axis="z")
    cylinder("Alavanca", (1.45, 1.0, 0.56), 0.008, 0.008, 0.2, "iron", segments=6, axis="x")
    # Caixas e uma lata na prateleira de baixo
    box("Caixa", (-1.0, 0.31, 0.0), (0.5, 0.22, 0.4), "plank", bevel=0.006)
    cylinder("Lata", (0.6, 0.195, -0.1), 0.09, 0.09, 0.2, "iron", segments=12)
    # Martelo e chave inglesa na ponta oeste do tampo
    box("Cabo", (-1.25, 0.915, 0.1), (0.3, 0.025, 0.03), "oak")
    box("Cabeca", (-1.1, 0.925, 0.1), (0.04, 0.04, 0.11), "iron")
    box("ChaveInglesa", (-1.3, 0.908, -0.15), (0.26, 0.012, 0.03), "iron")
    export("bancada_oficina")


def tool_locker():
    """Armário de aço de ferramentas, 1,3 x 2,1 x 0,7 m, duas portas para +z; origem no centro do piso."""
    reset()
    box("Corpo", (0, 1.05, 0), (1.3, 2.1, 0.7), "iron", bevel=0.01)
    for x in (-0.32, 0.32):
        box("Porta", (x, 1.07, 0.36), (0.6, 1.95, 0.02), "iron", bevel=0.004)
        for k in range(6):
            box("Veneziana", (x, 1.75 + k * 0.045, 0.373), (0.36, 0.012, 0.01), "dark")
        box("Puxador", (x * 0.18, 1.0, 0.385), (0.025, 0.18, 0.025), "brass")
    box("Rodape", (0, 0.04, 0.02), (1.32, 0.08, 0.7), "cast_iron")
    box("Etiqueta", (-0.32, 1.45, 0.373), (0.16, 0.06, 0.004), "paper")
    export("armario_ferramentas")


def water_heater():
    """Aquecedor de água de cobre: r 0,45, 2,1 m de corpo e tampo abaulado; origem no centro do piso."""
    reset()
    cylinder("Corpo", (0, 0.1, 0), 0.45, 0.45, 2.0, "copper", segments=28)
    sphere("Tampo", (0, 2.1, 0), 0.45, "copper", scale=(1, 0.35, 1), segments=28, rings=10)
    for y in (0.3, 1.0, 1.7):
        torus("Cinta", (0, y, 0), 0.455, 0.018, "iron", segments=36, sides=6)
    for k in range(3):
        a = 2 * math.pi * k / 3
        cylinder("Pe", (math.cos(a) * 0.33, 0, math.sin(a) * 0.33), 0.04, 0.04, 0.12, "iron", segments=8)
    tube("Cano", [(0, 2.2, 0), (0, 2.45, 0), (-0.45, 2.45, 0), (-0.45, 3.6, 0)], 0.035, "copper", sides=10)
    tube("Saida", [(0.45, 0.4, 0), (0.62, 0.4, 0), (0.62, 0.05, 0)], 0.03, "copper", sides=10)
    cylinder("Manometro", (0.32, 1.4, 0.43), 0.08, 0.08, 0.12, "brass", segments=16, axis="z")
    cylinder("Mostrador", (0.32, 1.4, 0.436), 0.065, 0.065, 0.004, "ivory", segments=16, axis="z")
    torus("Registro", (0.45, 0.65, 0.2), 0.06, 0.008, "iron", segments=16, sides=6)
    export("aquecedor")


ALL = {
    "piano_cauda": lambda: grand_piano(),
    "lustre": lambda: chandelier(),
    "cadeira_cafe": lambda: cafe_chair(),
    "mesa_redonda": lambda: round_table(),
    "lustre_saguao": lambda: grand_chandelier(),
    "sofa": lambda: sofa(),
    "poltrona": lambda: armchair(),
    "relogio_carrilhao": lambda: grandfather_clock(),
    "relogio_carrilhao_1923": lambda: grandfather_clock(11, 40, "relogio_carrilhao_1923"),
    "cama": lambda: bed(),
    "guarda_roupa": lambda: wardrobe(),
    "escrivaninha": lambda: writing_desk(),
    "bau": lambda: trunk(),
    # Biblioteca: duas arrumações da estante alta para as fileiras não se repetirem
    "estante_alta_a": lambda: bookcase("estante_alta_a", 2.2, 3.7, 11, False),
    "estante_alta_b": lambda: bookcase("estante_alta_b", 2.2, 3.7, 23, False),
    "estante_baixa": lambda: bookcase("estante_baixa", 2.0, 3.1, 37, False),
    "estante_arquivo": lambda: bookcase("estante_arquivo", 2.2, 2.7, 41, False),
    "estante_alta_a_hoje": lambda: bookcase("estante_alta_a_hoje", 2.2, 3.7, 11, True),
    "estante_alta_b_hoje": lambda: bookcase("estante_alta_b_hoje", 2.2, 3.7, 23, True),
    "estante_baixa_hoje": lambda: bookcase("estante_baixa_hoje", 2.0, 3.1, 37, True),
    "estante_arquivo_hoje": lambda: bookcase("estante_arquivo_hoje", 2.2, 2.7, 41, True),
    "mesa_leitura": lambda: reading_table(),
    "cadeira_biblioteca": lambda: library_chair(),
    "luminaria_banco": lambda: bankers_lamp(),
    "lustre_biblioteca": lambda: library_chandelier(),
    # Caldeiras
    "caldeira": lambda: boiler(),
    "luminaria_industrial": lambda: industrial_lamp(),
    # Cozinha
    "fogao_lenha": lambda: wood_stove(),
    "geladeira": lambda: icebox(),
    "porta_armario": lambda: cabinet_door(),
    "estante_despensa": lambda: pantry_shelves(False),
    "estante_despensa_hoje": lambda: pantry_shelves(True),
    # Portas (largura x altura em cm)
    "porta_100x230": lambda: door("porta_100x230", 1.0, 2.3),
    "porta_130x240": lambda: door("porta_130x240", 1.3, 2.4),
    "porta_150x240": lambda: door("porta_150x240", 1.5, 2.4, knob=-1),
    "porta_dupla_160x250": lambda: door("porta_dupla_160x250", 1.6, 2.5, double=True),
    # Torre e manutenção
    "mecanismo_relogio": lambda: clock_machine(),
    "bancada_oficina": lambda: workbench(),
    "armario_ferramentas": lambda: tool_locker(),
    "aquecedor": lambda: water_heater(),
    "porta_vaivem_120x238": lambda: door("porta_vaivem_120x238", 1.2, 2.38, knob=1, swing=True, thickness=0.05),
}


if __name__ == "__main__":
    # Sem argumentos gera tudo; com nomes depois de "--", só esses
    wanted = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(ALL)
    for key in wanted:
        ALL[key]()
