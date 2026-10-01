"""Original First Claim opening kit. Units metres; Blender Z-up, GLB Y-up.
Editable mesh source; no external mesh or texture inputs."""
import bpy, math, random, pathlib, json
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'opening'; OUT.mkdir(parents=True,exist_ok=True)
random.seed(314)
exec((ROOT/"tools"/"material_maps.py").read_text())
def mat(name,color,metal=0,rough=.6):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 # Fine surface wear without external texture dependency.
 n=m.node_tree.nodes.new('ShaderNodeTexNoise');n.inputs['Scale'].default_value=130
 b=m.node_tree.nodes.new('ShaderNodeBump');b.inputs['Strength'].default_value=.12;b.inputs['Distance'].default_value=.002
 m.node_tree.links.new(n.outputs['Fac'],b.inputs['Height']);m.node_tree.links.new(b.outputs['Normal'],p.inputs['Normal'])
 material_maps(m,name,color,rough)
 return m
olive=mat('worn olive polymer',(.045,.067,.026),.08,.56)
rim=mat('abraded olive polymer rim',(.064,.083,.035),.05,.65)
steel=mat('brushed steel',(.37,.41,.43),.8,.32)
wood=mat('warm worn ash',(.34,.20,.10),0,.68)
gold=mat('alluvial gold',(.83,.55,.12),.94,.22)
glove=mat('ochre canvas glove',(.19,.135,.062),0,.85)
black=mat('dark rubber',(.035,.042,.036),0,.8)
glass=mat('vial pale blue glass',(.44,.69,.72),0,.12)
glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.28
glass.diffuse_color=(.44,.69,.72,.28)
glass.surface_render_method='DITHERED'
canvas=mat('faded canvas',(.43,.46,.31),0,.86)
def mesh(name,verts,faces,m):
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.data.materials.append(m)
 uv=me.uv_layers.new(name='UVMap')
 for polygon in me.polygons:
  axis=max(range(3),key=lambda i:abs(polygon.normal[i]));axes=[i for i in range(3) if i!=axis]
  for loop in polygon.loop_indices:
   co=me.vertices[me.loops[loop].vertex_index].co
   uv.data[loop].uv=(co[axes[0]],co[axes[1]])
 return o
def bevel(o,width=.008):
 mod=o.modifiers.new('soft worn edges','BEVEL');mod.width=width;mod.segments=3
 o.modifiers.new('weighted normals','WEIGHTED_NORMAL');return o
def box(name,loc,scale,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m);return bevel(o,min(scale)*.09)
def cyl(name,loc,r,depth,m,vertices=32):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc);o=bpy.context.object;o.name=name;o.data.materials.append(m);bevel(o,.002)
 for p in o.data.polygons:p.use_smooth=True
 return o
def rod(name,a,b,r,m):
 o=cyl(name,(Vector(a)+Vector(b))/2,r,(Vector(b)-Vector(a)).length,m);o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();return o
def lathe(name,profile,m,segments=96,start=0,end=math.tau):
 vs=[];fs=[]
 for radius,z in profile:
  for i in range(segments+1):
   angle=start+(end-start)*i/segments;vs.append((radius*math.cos(angle),radius*math.sin(angle),z))
 for j in range(len(profile)-1):
  for i in range(segments):
   a=j*(segments+1)+i;fs.append((a,a+segments+1,a+segments+2,a+1))
 o=mesh(name,vs,fs,m)
 uv=o.data.uv_layers.active or o.data.uv_layers.new(name='UVMap')
 for polygon in o.data.polygons:
  for loop in polygon.loop_indices:
   vertex=o.data.loops[loop].vertex_index
   uv.data[loop].uv=(float(vertex%(segments+1))/segments,float(vertex//(segments+1))/max(1,len(profile)-1))
 for p in o.data.polygons:p.use_smooth=True
 return o
def begin():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def save(name,role,sockets):
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'assets'/'editable'/(name+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True)
 entries.append(dict(id=name,stage='river',role=role,source='Original procedural Blender mesh',license='Original project asset',editable_source=str(ROOT/'assets'/'editable'/(name+'.blend')),generator=str(pathlib.Path(__file__).resolve()),game_export=str(OUT/(name+'.glb')),materials=sorted({m.name for o in bpy.context.scene.objects if hasattr(o.data,'materials') for m in o.data.materials if m}),texture_paths=sorted({node.image.filepath for o in bpy.context.scene.objects if hasattr(o.data,'materials') for m in o.data.materials if m and m.use_nodes for node in m.node_tree.nodes if node.type=='TEX_IMAGE' and node.image}),scale='metres',origin='functional base/center',collision='Godot authored interaction/body shapes',sockets=sockets,animations='Godot tool-root interaction transforms',preview=None,engine_verification='pending'))
entries=[]
manifest_path=ROOT/'asset-manifest.json'
if manifest_path.exists():
 entries=[a for a in json.loads(manifest_path.read_text()).get('assets',[]) if '/opening/' not in a.get('game_export','')]
begin()
lathe('pan bowl closed wall',[(0,0),(.096,0),(.112,.006),(.158,.062),(.162,.064),(.163,.061),(.159,.057),(.114,.002),(.098,-.004),(0,-.004)],olive)
for r,z in [(.122,.02),(.134,.035),(.146,.049)]:lathe('internal riffle',[(r-.003,z-.003),(r,z+.002),(r+.003,z-.001)],olive,48,.18,2.0)
lathe('worn rim',[(.159,.06),(.162,.064),(.164,.062)],rim)
# Rounded sewn work gloves, four curled fingers and a distinct thumb each.
def soft(name,loc,size,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,location=loc)
 o=bpy.context.object;o.name=name;o.scale=size;o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 return o
for side in [-1,1]:
 soft('gloved palm',(.194*side,0,.03),(.035,.045,.027),glove)
 for j in range(4):
  y=-.03+j*.020
  curve=bpy.data.curves.new('continuous curled glove finger','CURVE');curve.dimensions='3D';curve.bevel_depth=.0076;curve.bevel_resolution=4;curve.use_fill_caps=True;curve.resolution_u=10
  path=curve.splines.new('BEZIER');path.bezier_points.add(4)
  for point,(x,z) in zip(path.bezier_points,[(.193,.038),(.181,.062),(.165,.076),(.151,.069),(.147,.051)]):
   point.co=(x*side,y,z-(.003 if j in [0,3] else 0));point.handle_left_type='AUTO';point.handle_right_type='AUTO'
  finger=bpy.data.objects.new('one connected curled finger',curve);bpy.context.collection.objects.link(finger);finger.data.materials.append(glove)
 thumb=soft('opposing gloved thumb',(.18*side,.043,.054),(.025,.014,.016),glove);thumb.rotation_euler[1]=side*.4;thumb.rotation_euler[2]=side*.4
 soft('canvas wrist',(.224*side,.0,.012),(.034,.031,.024),glove)
 cuff=lathe('rounded elastic cuff',[(.027,0),(.032,0),(.033,.02),(.028,.022)],black,40);cuff.rotation_euler[1]=side*math.pi/2;cuff.location=(.238*side,0,.012)
 soft('work sleeve',(.275*side,0,.005),(.035,.033,.027),canvas)
save('hero_pan','Held pan with real bowl, three riffles and gripping gloves',{'contents':[0,0,.011],'left_grip':[-.16,0,0],'right_grip':[.16,0,0]})
begin()
# Curved shovel spade with real thickness and raised shoulders.
verts=[]
for thickness in [0,.004]:
 for y,w,z in [(-.16,.055,0),(-.12,.095,.007),(0,.10,.035),(.10,.078,.045)]:
  verts.extend([(-w,y,z+thickness),(0,y,z-.016+thickness),(w,y,z+thickness)])
faces=[]
for layer in [0,12]:
 for row in range(3):
  for col in range(2):
   a=layer+row*3+col;faces.append((a,a+1,a+4,a+3))
for a,b in [(0,1),(1,2),(2,5),(5,8),(8,11),(11,10),(10,9),(9,6),(6,3),(3,0)]:faces.append((a,b,b+12,a+12))
bevel(mesh('curved steel shovel blade',verts,faces,steel),.003)
rod('shaft',(0,.04,.04),(0,.72,.15),.017,wood)
rod('D grip left',(-.047,.82,.17),(0,.70,.15),.011,steel);rod('D grip right',(.047,.82,.17),(0,.70,.15),.011,steel);rod('rubber grip',(-.047,.82,.17),(.047,.82,.17),.017,black)
save('shovel','Scoop shovel',{'blade':[0,-.13,0],'grip':[0,.7,.15]})
begin()
lathe('vial',[(0,0),(.018,0),(.019,.006),(.019,.076),(.014,.084),(.014,.09)],glass,48)
cyl('cap',(0,0,.094),.016,.014,black)
save('vial','Bench collection vial',{'pickup':[0,0,.05]})
begin()
box('top',(0,0,.79),(1.6,.7,.065),wood)
for x in [-.68,.68]:
 for y in [-.24,.24]:box('leg',(x,y,.39),(.075,.075,.78),wood)
box('brace',(0,.24,.25),(1.42,.045,.08),wood)
for x in [-.7,.7]:
 for y in [-.24,.24]:cyl('peg',(x,y,.826),.009,.003,steel,12)
save('bench','Camp workbench',{'surface':[0,0,.83]})
begin()
box('scale base',(0,0,.04),(.28,.22,.08),olive)
box('display frame',(0,-.08,.104),(.13,.02,.06),black)
rod('scale post',(0,.035,.05),(0,.035,.19),.016,steel)
lathe('weigh tray',[(0,.19),(.1,.19),(.13,.22),(.13,.226),(.098,.197),(0,.197)],steel)
save('scale','Explicit gold weighing and sale point',{'tray':[0,0,.22]})
begin()
for x in [-.62,.62]:box('board post',(x,0,.85),(.09,.09,1.7),wood)
box('notice backing',(0,.02,1.28),(1.5,.08,.8),wood)
for x in [-.42,0,.42]:box('paper notice',(x,-.028,1.3),(.31,.008,.49),canvas)
save('board','Supply and contract board',{'interact':[0,-.1,1.3]})
begin()
lathe('classifier polymer rim',[(.147,0),(.167,0),(.17,.025),(.166,.034),(.15,.031),(.147,0)],olive,72)
for j in range(-7,8):
 x=j*.02;reach=math.sqrt(max(0,.145**2-x*x))
 rod('classifier wire',(x,-reach,.012),(x,reach,.012),.0013,steel)
 rod('classifier crosswire',(-reach,x,.014),(reach,x,.014),.0013,steel)
save('classifier','Visible removable river gravel classifier upgrade',{'screen':[0,0,.014]})
begin()
box('sample tray base',(0,0,.013),(.33,.19,.026),steel)
for y in [-.095,.095]:box('tray rim',(0,y,.034),(.35,.009,.055),steel)
for x in [-.17,-.056,.056,.17]:box('sample dividers',(x,0,.029),(.008,.19,.04),steel)
for x in [-.112,0,.112]:lathe('sample cup',[(0,.025),(.036,.025),(.037,.07),(.034,.072),(.032,.030),(0,.030)],glass,32).location.x=x
save('sample_tray','Three physical containers for uphill prospecting samples',{'sample0':[-.112,0,.043],'sample1':[0,0,.043],'sample2':[.112,0,.043]})
p=(ROOT/'asset-manifest.json');p.write_text(json.dumps({'schema':1,'assets':entries},indent=2))
print('ASSET_BATCH_EXPORTED',len(entries))
