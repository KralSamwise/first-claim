extends Node3D

const State = preload("res://source/claim.gd")
var game = State.new()
var player: CharacterBody3D
var camera: Camera3D
var held: Node3D
var pan: Node3D
var sediment: MeshInstance3D
var water_pan: MeshInstance3D
var flakes: Node3D
var ui: CanvasLayer
var hud_back: Panel
var prompt_back: Panel
var hud: Label
var prompt: Label
var notice: Label
var panel: PanelContainer
var panel_box: VBoxContainer
var panel_open_tick=0
var title: Label
var tool = 1
var mode = "title"
var toast = ""
var toast_time = 0.0
var pan_motion = 0.0
var last_swirl = 0
var swirl_time = 0.0
var wash_held = false
var interactables: Array = []
var mats: Dictionary = {}
var settings = {"sensitivity":0.0022,"invert":false,"simple":false,"motion":true,"master":0.7,"water":0.65,"tools":0.8,"signal":0.7,"quality":1,"resolution":0}
var slot = "campaign"
var autosave = 0.0
var frame_samples: Array = []
var capture_at = -1
var ticks = 0
var elapsed_view = 0.0
var mining_lamp: SpotLight3D
var sound: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var river_audio: AudioStreamPlayer
var forest_audio: AudioStreamPlayer
var wash_audio: AudioStreamPlayer
var foley_players: Array=[]
var foley_clips: Dictionary={}
var foley_index=0
var step_clock=0.0
var last_roof_state="stable"
var tone_clock = 0.0
var effect_left = 0.0
var effect_hz = 180.0
var effect_type = "water"
var ground_patches: Array = []
var tree_cache: Dictionary={}
var active_point: Dictionary = {}
var sky_time = 0.0
var preview_play = false
var qa_river = false
var qa_detector = false
var qa_campaign=false
var qa_inspect=false
var qa_compare=false
var mine: ClaimMine
var detector: Node3D
var detector_readout: Label3D
var pick: Node3D
var barrow: Node3D
var barrow_shape: CollisionShape3D
var parked_barrow_shape: CollisionShape3D
var barrow_fill: MultiMeshInstance3D
var targets: Array=[]
var sample_points: Array=[]
var tool_motion=0.0
var detector_beep=0.0
var remove_confirm=0.0
var workshop_root: Node3D
var product_displays: Dictionary={}
var casting_crucible: Node3D
var furnace_melt: MeshInstance3D
var casting_stream: MeshInstance3D
var polishing_rotor: Node3D
var rough_workpiece: MeshInstance3D
var fine_screen_grid: Node3D
var classifier_display: Node3D
var sample_tray: Node3D
var sample_displays: Array=[]
var vial_fill: MultiMeshInstance3D
var support_hammer: Node3D
var hammer_motion=0.0
var recovery_motion=0.0
var trowel: Node3D
var recovered_find: Node3D
var recovery_gold: MeshInstance3D
var recovery_scrap: Node3D
var final_display: Node3D
var gravel_visual: MultiMeshInstance3D
var scoop_tool: Node3D
var placement_mode=false
var frame_preview: Node3D
var frame_preview_material: StandardMaterial3D

func material(name_: String, color: Color, roughness = 0.8, metal = 0.0) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color=color;m.roughness=roughness;m.metallic=metal
 mats[name_]=m
 return m

func mesh_object(mesh: Mesh, pos: Vector3, mat: Material, parent: Node = self) -> MeshInstance3D:
 var o=MeshInstance3D.new();o.mesh=mesh;o.position=pos;o.material_override=mat;parent.add_child(o)
 return o

func cube(pos: Vector3, size: Vector3, mat: Material, collision=false, parent: Node=self) -> MeshInstance3D:
 var shape=BoxMesh.new();shape.size=size
 var obj=mesh_object(shape,pos,mat,parent)
 if collision:obj.create_trimesh_collision()
 return obj

func model(name_: String, pos: Vector3, parent: Node=self, yaw=0.0) -> Node3D:
 var path="res://assets/opening/"+name_+".glb"
 if not ResourceLoader.exists(path):path="res://assets/field/"+name_+".glb"
 if not ResourceLoader.exists(path):path="res://assets/workshop/"+name_+".glb"
 var scene=load(path).instantiate()
 parent.add_child(scene);scene.position=pos;scene.rotation.y=yaw
 return scene

func marker(text_: String, pos: Vector3, size=32) -> Label3D:
 var l=Label3D.new();l.text=text_;l.position=pos;l.font_size=size;l.pixel_size=.003;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.modulate=Color("e5dec1");l.outline_size=5
 add_child(l)
 return l

func _ready():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--slot="):slot=arg.get_slice("=",1)
  if arg=="--preview":preview_play=true
  if arg=="--qa=river":qa_river=true
  if arg=="--qa=detector":qa_detector=true
  if arg=="--qa=campaign":qa_campaign=true
  if arg=="--qa=inspect":qa_inspect=true
  if arg=="--qa=compare":qa_compare=true
  if arg.begins_with("--snapshot="):capture_at=int(arg.get_slice("=",1))
 get_window().content_scale_size=Vector2i(1280,720);get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 make_world()
 make_player()
 make_field_systems()
 make_workshop()
 make_ui()
 make_audio()
 load_settings()
 apply_graphics()
 show_title()
 if preview_play:start_new()
 if qa_river or qa_detector or qa_campaign or qa_inspect or qa_compare:
  var qa=Node.new();qa.set_script(load("res://source/qa_compare.gd" if qa_compare else "res://source/qa_inspect.gd" if qa_inspect else "res://source/qa_campaign.gd" if qa_campaign else "res://source/qa_detector.gd" if qa_detector else "res://source/qa_river.gd"));add_child(qa)
 print("FIRST_CLAIM_READY renderer=",RenderingServer.get_current_rendering_method()," slot=",slot)

func make_world():
 material("earth",Color("79715a"))
 material("bank",Color("9b947b"))
 material("rock",Color("727b77"),.89)
 material("darkrock",Color("48575a"),.86)
 material("wood",Color("705238"))
 material("grass",Color("4e6348"))
 material("leaves",Color("314d43"))
 material("gold",Color("e2b548"),.23,.9)
 material("sand",Color("514b3d"),.93)
 material("water",Color(.18,.40,.43,.78),.18,.2)
 mats.water.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 var surface_noise=FastNoiseLite.new();surface_noise.seed=911;surface_noise.frequency=.065
 var surface=NoiseTexture2D.new();surface.noise=surface_noise;surface.width=512;surface.height=512;surface.seamless=true
 var tone=Gradient.new();tone.set_color(0,Color(.42,.46,.43));tone.set_color(1,Color(.94,.96,.89));surface.color_ramp=tone
 var relief=NoiseTexture2D.new();relief.noise=surface_noise;relief.width=512;relief.height=512;relief.seamless=true;relief.as_normal_map=true;relief.bump_strength=1.8
 for key in ["earth","rock","darkrock"]:
  mats[key].albedo_texture=surface;mats[key].normal_enabled=true;mats[key].normal_texture=relief;mats[key].normal_scale=.45
  if key!="earth":mats[key].uv1_triplanar=true;mats[key].uv1_scale=Vector3.ONE*.55
 mats.wood.albedo_texture=load("res://assets/materials/warm-worn-ash-albedo.png")
 mats.wood.normal_enabled=true;mats.wood.normal_texture=load("res://assets/materials/warm-worn-ash-normal.png");mats.wood.normal_scale=.35
 mats.wood.uv1_triplanar=true
 var env=WorldEnvironment.new();var e=Environment.new()
 e.background_mode=Environment.BG_SKY
 var sky=Sky.new();var sky_mat=ProceduralSkyMaterial.new()
 sky_mat.sky_top_color=Color("496d87");sky_mat.sky_horizon_color=Color("c0d2cc");sky_mat.ground_bottom_color=Color("455144");sky_mat.ground_horizon_color=Color("bac9bd")
 sky.sky_material=sky_mat;e.sky=sky;e.ambient_light_source=Environment.AMBIENT_SOURCE_SKY;e.ambient_light_energy=.3
 e.tonemap_mode=Environment.TONE_MAPPER_ACES
 e.fog_enabled=true;e.fog_light_color=Color("b4c6c0");e.fog_density=.0025
 env.environment=e;add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-43,-36,0);sun.light_color=Color("fff0cf");sun.light_energy=.85;sun.shadow_enabled=true;sun.shadow_bias=.06;sun.shadow_normal_bias=2.0;sun.directional_shadow_max_distance=80;add_child(sun)
 # Ground is a continuous editable authored grid; riverbed physically recessed.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in range(-70,41,2):
  for x in range(-60,61,2):
   var a=Vector3(x,height_at(x,z),z);var b=Vector3(x+2,height_at(x+2,z),z);var c=Vector3(x,height_at(x,z+2),z+2);var d=Vector3(x+2,height_at(x+2,z+2),z+2)
   for v in [a,b,c,b,d,c]:
    st.set_color(Color("77715d") if abs(v.x-river_x(v.z))<5.6 else Color("45533a"));st.set_uv(Vector2(v.x,v.z)*.3);st.add_vertex(v)
 st.generate_normals();var terrain=MeshInstance3D.new();terrain.mesh=st.commit()
 var groundmat=mats.earth.duplicate();groundmat.vertex_color_use_as_albedo=true;groundmat.albedo_color=Color.WHITE;terrain.material_override=groundmat;add_child(terrain);terrain.create_trimesh_collision()
 # Shader current and river strip follows the bed; no flat rectangle across camp.
 var shader=Shader.new();shader.code="shader_type spatial; render_mode blend_mix,depth_draw_opaque,cull_disabled; uniform vec3 shallow:source_color=vec3(0.22,0.46,0.48); void vertex(){VERTEX.y+=sin(VERTEX.z*2.0+TIME*1.4)*0.014+cos(VERTEX.x*4.0+TIME)*0.01;} void fragment(){float r=sin(UV.y*80.0-TIME*2.0+sin(UV.x*22.0))*0.5+0.5; ALBEDO=shallow+vec3(r*0.035);METALLIC=0.28;ROUGHNESS=0.19;ALPHA=0.79;}"
 var wm=ShaderMaterial.new();wm.shader=shader
 st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in range(-69,41,2):
  var a=Vector3(river_x(z)-3,-.18,z);var b=Vector3(river_x(z)+3,-.18,z);var c=Vector3(river_x(z+2)-3,-.18,z+2);var d=Vector3(river_x(z+2)+3,-.18,z+2)
  for v in [a,b,c,b,d,c]:st.set_uv(Vector2(v.x*.1,v.z*.015));st.add_vertex(v)
 st.generate_normals();mesh_object(st.commit(),Vector3.ZERO,wm)
 add_ground_detail()
 var rng=RandomNumberGenerator.new();rng.seed=414
 # Layered irregular ridgeline, shared with the visible mining destination.
 make_ridgeline()
 make_mine_ridge()
 for i in range(170):
  var x=rng.randf_range(-40,40);var z=rng.randf_range(-57,28)
  if (abs(x)<7 and z>-38) or abs(x-river_x(z))<5 or Vector2(x,z-8).length()<9 or (x> -14 and x<1 and z> -7 and z<11) or (abs(x)<8 and z< -28 and z> -53):continue
  tree(Vector3(x,height_at(x,z),z),rng.randf_range(.7,1.35),rng)
 for i in range(240):
  var z=rng.randf_range(-45,30);var x=river_x(z)+rng.randf_range(-5.1,5.1)
  if abs(x-river_x(z))<2.3:continue
  var s=rng.randf_range(.06,.36)
  var rock=SphereMesh.new();rock.radius=s;rock.height=s*1.3;rock.radial_segments=7;rock.rings=4
  var o=mesh_object(rock,Vector3(x,height_at(x,z)+s*.23,z),mats.rock);o.rotation=Vector3(rng.randf(),rng.randf(),rng.randf())
 for pos in [Vector3(9,0,1),Vector3(10,0,-9),Vector3(4,0,-16),Vector3(-8,0,-9)]:
  var rock=SphereMesh.new();rock.radius=1.4;rock.height=2.0;rock.radial_segments=9;rock.rings=5
  var o=mesh_object(rock,pos+Vector3(0,height_at(pos.x,pos.z)+.4,0),mats.rock);o.scale=Vector3(1.2,1,.9);o.create_trimesh_collision()
 model("bench",Vector3(-3,0,5),self,.2)
 model("scale",Vector3(-3,.825,5),self,.2)
 model("vial",Vector3(-2.55,.825,5),self)
 classifier_display=model("classifier",Vector3(-3.55,.84,5.08),self)
 sample_tray=model("sample_tray",Vector3(-3.2,.84,5.2),self)
 for i in range(3):
  var sample=SphereMesh.new();sample.radius=.02;sample.height=.035;sample.radial_segments=7;sample.rings=4
  sample_displays.append(mesh_object(sample,Vector3(-3.312+i*.112,.872,5.2),mats.rock))
 vial_fill=MultiMeshInstance3D.new();vial_fill.multimesh=MultiMesh.new();vial_fill.multimesh.transform_format=MultiMesh.TRANSFORM_3D
 var fleck=SphereMesh.new();fleck.radius=.0024;fleck.height=.0015;fleck.radial_segments=6;fleck.rings=3
 vial_fill.multimesh.mesh=fleck;vial_fill.multimesh.instance_count=80
 vial_fill.material_override=material("vial gold",Color(.84,.57,.12),.24,.86);vial_fill.position=Vector3(-2.55,.83,5);add_child(vial_fill)
 for i in range(80):
  var angle=i*2.39996;var radius=.003+.008*float(i%7)/7.0
  vial_fill.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(angle)*radius,.004+floorf(i/10.0)*.005,sin(angle)*radius)))
 cube(Vector3(-3,.43,5),Vector3(1.65,.86,.75),mats.wood,true).visible=false
 model("board",Vector3(-5,0,1),self,.5)
 marker("SUPPLIES / ORDERS",Vector3(-5,1.83,1.05),38).rotation.y=.5
 marker("WEIGH & SELL",Vector3(-3,1.25,5),31)
 interactables.append({"type":"sell","pos":Vector3(-3,1,5),"label":"E · Weigh and sell gold"})
 interactables.append({"type":"board","pos":Vector3(-5,1.1,1),"label":"E · Supplies and custom orders"})
 # Readable shovel and supply crate, no factory at fresh launch.
 model("shovel",Vector3(-1.9,.1,5.4),self,1.2)
 cube(Vector3(-4,.3,6.3),Vector3(.72,.6,.48),mats.wood,true)
 for i in range(36):
  var z=9.0-i*1.15;var x=river_x(z)-3.7
  ground_patches.append(Vector3(x,height_at(x,z),z))
 marker("THE CLAIM\nRiver • Gravel bars • Quartz ridge",Vector3(-1,1.5,-7),32)

func river_x(z: float) -> float:
 return 7.0+sin(z*.055)*2.8+smoothstep(16.0,30.0,-z)*9.0
func height_at(x: float,z: float) -> float:
 var river=abs(x-river_x(z))
 if river<3.5:return -.55+river*.06
 if river<5:return lerpf(-.34,0.0,(river-3.5)/1.5)
 var foothill=clampf((-z-16)/16.0,0,1)*2.4
 if z< -28 and absf(x)>4.8 and absf(x)<18:
  foothill+=clampf((-z-28)/8.0,0,1)*(7.5+sin(x*.48)*1.2)*clampf((19-absf(x))/9,0,1)
 # Join the recessed riverbank to the hillside continuously. The old early
 # return jumped straight from sea level to the plateau at five metres.
 return foothill*smoothstep(5.0,8.0,river)

func tree(pos: Vector3,scale_: float,rng: RandomNumberGenerator):
 var trunk=CylinderMesh.new();trunk.top_radius=.012;trunk.bottom_radius=.20;trunk.height=7.0*scale_;trunk.radial_segments=9
 mesh_object(trunk,pos+Vector3(0,3.5*scale_,0),mats.wood)
 var variant=rng.randi_range(0,3)
 if not tree_cache.has(variant):
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var shape_rng=RandomNumberGenerator.new();shape_rng.seed=812+variant
  for layer in 16:
   var radius=2.05-float(layer)*.125
   for branch in 8:
    var angle=float(branch)/8*TAU+float(layer)*.61+shape_rng.randf_range(-.12,.12)
    var direction=Vector3(cos(angle),0,sin(angle));var side=Vector3(-sin(angle),0,cos(angle))
    var base=Vector3(0,1.0+layer*.37,0)
    var tip=base+direction*radius+Vector3(0,-.27+layer*.025,0)
    for sprig in 8:
     var t=.12+sprig*.105
     var center=base.lerp(tip,t)
     var spread=radius*.46*(1-t)*shape_rng.randf_range(.8,1.15)
     var ridge=center+Vector3(0,.14,0)
     var underside=center+Vector3(0,-.10,0)
     var left=center-side*spread-direction*.11
     var right=center+side*spread-direction*.11
     var end=center+direction*(.28+radius*.09)+Vector3(0,-.065,0)
     var tint=Color(.82,.95,.73).lerp(Color(.38,.57,.43),float(layer%3)/3)
     for point in [left,ridge,end,ridge,right,end,left,end,underside,underside,end,right]:
      st.set_color(tint);st.set_normal(Vector3.UP);st.add_vertex(point)
  tree_cache[variant]=st.commit()
 var foliage=mats.leaves.duplicate();foliage.vertex_color_use_as_albedo=true;foliage.cull_mode=BaseMaterial3D.CULL_DISABLED
 var crown=mesh_object(tree_cache[variant],pos,foliage);crown.scale=Vector3.ONE*scale_;crown.rotation.y=rng.randf()*TAU

func ridge_roof_height(x: float,z: float) -> float:
 var blend=1.0-smoothstep(5.0,18.0,absf(x))
 var rise=smoothstep(34.0,58.0,-z)
 var top=6.4+rise*(15.0+sin(x*.37+z*.12)*2.0+cos(x*.91-z*.18)*.8)
 return lerpf(height_at(x,z),top,blend)
func make_mine_ridge():
 # Continuous rocky shoulder and roof join the mine top to the distant ridge.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in range(-64,-34):
  for x in range(-18,18):
   var points=[]
   for offset in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
    var xx=x+offset.x;var zz=z+offset.y
    points.append(Vector3(xx,ridge_roof_height(xx,zz),zz))
   for i in [0,1,2,1,3,2]:
    st.set_uv(Vector2(points[i].x,points[i].z)*.4);st.add_vertex(points[i])
 for side in [-1,1]:
  var xs=[4.8,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,17.0,18.0]
  for i in xs.size()-1:
   var x0=xs[i]*side;var x1=xs[i+1]*side
   var a=Vector3(x0,height_at(x0,-34),-34);var b=Vector3(x1,height_at(x1,-34),-34)
   var c=Vector3(x0,ridge_roof_height(x0,-34),-34);var d=Vector3(x1,ridge_roof_height(x1,-34),-34)
   var face=[a,c,b,c,d,b] if side==1 else [a,b,c,c,b,d]
   for v in face:st.set_uv(Vector2(v.x,v.y)*.4);st.add_vertex(v)
 st.generate_normals();var ridge=mesh_object(st.commit(),Vector3.ZERO,mats.rock);ridge.create_trimesh_collision()

func make_ridgeline():
 var noise=FastNoiseLite.new();noise.seed=834;noise.frequency=.055
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for z in range(-100,-44,3):
  for x in range(-80,81,3):
   var points=[]
   for offset in [Vector2(0,0),Vector2(3,0),Vector2(0,3),Vector2(3,3)]:
    var xx=x+offset.x;var zz=z+offset.y
    var ridge=18.0+sin(xx*.06)*8+noise.get_noise_2d(xx,zz)*15
    var rise=clampf((-zz-43)/18.0,0,1)
    points.append(Vector3(xx,2.4+ridge*rise,zz))
   for i in [0,1,2,1,3,2]:
    st.set_color(Color(.76,.8,.78) if points[i].y>23 else Color(.62,.72,.68));st.add_vertex(points[i])
 st.generate_normals();var m=mats.darkrock.duplicate();m.vertex_color_use_as_albedo=true;mesh_object(st.commit(),Vector3.ZERO,m)

func make_player():
 player=CharacterBody3D.new();player.name="Prospector";add_child(player);player.position=Vector3(0,1,8)
 var col=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.27;capsule.height=1.75;col.shape=capsule;player.add_child(col)
 camera=Camera3D.new();camera.position.y=.67;camera.fov=68;camera.near=.04;player.add_child(camera);camera.current=true
 mining_lamp=SpotLight3D.new();mining_lamp.light_color=Color("fff2d5");mining_lamp.light_energy=1.1;mining_lamp.spot_range=10;mining_lamp.spot_angle=48;mining_lamp.spot_attenuation=1.4;mining_lamp.position=Vector3(0,-.06,.02);mining_lamp.visible=false;camera.add_child(mining_lamp)
 player.rotation.y=-.38
 held=Node3D.new();camera.add_child(held)
 pan=model("hero_pan",Vector3(.02,-.22,-.55),held)
 pan.rotation.x=.30
 var contents=CylinderMesh.new();contents.top_radius=.109;contents.bottom_radius=.101;contents.height=.01;contents.radial_segments=64
 sediment=mesh_object(contents,Vector3(0,.012,0),mats.sand,pan)
 var wat=CylinderMesh.new();wat.top_radius=.129;wat.bottom_radius=.12;wat.height=.002;wat.radial_segments=64
 water_pan=mesh_object(wat,Vector3(0,.03,0),mats.water,pan)
 flakes=Node3D.new();pan.add_child(flakes)
 var rng=RandomNumberGenerator.new();rng.seed=33
 for i in range(16):
  var flake=SphereMesh.new();flake.radius=rng.randf_range(.0025,.0045);flake.height=.0018;flake.radial_segments=7;flake.rings=4
  var o=mesh_object(flake,Vector3(rng.randf_range(-.068,.068),.018,rng.randf_range(-.067,.067)),mats.gold,flakes);o.rotation.y=rng.randf()*6

 var gravel_mesh=SphereMesh.new();gravel_mesh.radius=.004;gravel_mesh.height=.0045;gravel_mesh.radial_segments=6;gravel_mesh.rings=3
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=gravel_mesh;mm.instance_count=80
 for i in 80:
  var angle=rng.randf()*TAU;var radius=sqrt(rng.randf())*.101
  mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(angle)*radius,.022,sin(angle)*radius)))
 gravel_visual=MultiMeshInstance3D.new();gravel_visual.multimesh=mm;gravel_visual.material_override=mats.rock;pan.add_child(gravel_visual)
 scoop_tool=model("shovel",Vector3(.33,-.3,-.6),held);scoop_tool.scale=Vector3.ONE*.8;scoop_tool.visible=false

func make_ui():
 ui=CanvasLayer.new();add_child(ui)
 hud_back=Panel.new();hud_back.position=Vector2(22,18);hud_back.size=Vector2(570,118);var hs=StyleBoxFlat.new();hs.bg_color=Color(.025,.045,.04,.8);hs.set_corner_radius_all(7);hud_back.add_theme_stylebox_override("panel",hs);ui.add_child(hud_back)
 prompt_back=Panel.new();prompt_back.position=Vector2(240,636);prompt_back.size=Vector2(800,64);prompt_back.add_theme_stylebox_override("panel",hs);ui.add_child(prompt_back)
 hud=Label.new();hud.position=Vector2(35,25);hud.size=Vector2(540,100);hud.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hud.add_theme_font_size_override("font_size",18);hud.add_theme_color_override("font_color",Color("ece6cf"));hud.add_theme_color_override("font_outline_color",Color(.04,.07,.06));hud.add_theme_constant_override("outline_size",0);ui.add_child(hud)
 prompt=Label.new();prompt.position=Vector2(260,642);prompt.size=Vector2(760,52);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prompt.add_theme_font_size_override("font_size",20);prompt.add_theme_color_override("font_outline_color",Color(.04,.07,.06));prompt.add_theme_constant_override("outline_size",5);ui.add_child(prompt)
 notice=Label.new();notice.position=Vector2(290,158);notice.size=Vector2(700,80);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.add_theme_font_size_override("font_size",18);notice.add_theme_color_override("font_outline_color",Color(.025,.04,.03));notice.add_theme_constant_override("outline_size",4);notice.add_theme_color_override("font_color",Color("ffe2a0"));ui.add_child(notice)
 var reticle=Label.new();reticle.text="·";reticle.position=Vector2(634,344);reticle.add_theme_font_size_override("font_size",28);ui.add_child(reticle)
 panel=PanelContainer.new();panel.position=Vector2(315,105);panel.size=Vector2(650,510)
 var style=StyleBoxFlat.new();style.bg_color=Color(.06,.105,.11,.96);style.border_color=Color("8a916c");style.set_border_width_all(1);style.set_corner_radius_all(9);style.content_margin_left=30;style.content_margin_right=30;style.content_margin_top=23;style.content_margin_bottom=23;panel.add_theme_stylebox_override("panel",style);ui.add_child(panel)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(590,445);panel.add_child(scroll)
 panel_box=VBoxContainer.new();panel_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel_box.add_theme_constant_override("separation",10);scroll.add_child(panel_box)

func clear_panel(heading: String):
 panel_open_tick=ticks
 for c in panel_box.get_children():c.queue_free();panel_box.remove_child(c)
 title=Label.new();title.text=heading;title.add_theme_font_size_override("font_size",29);title.add_theme_color_override("font_color",Color("eee0b8"));panel_box.add_child(title)
 panel.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func text_line(text_: String):
 var l=Label.new();l.text=text_;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.custom_minimum_size.x=540;l.add_theme_font_size_override("font_size",18);panel_box.add_child(l)
func button(text_: String,fn: Callable):
 var b=Button.new();b.text=text_;b.clip_text=true;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.custom_minimum_size.y=37;b.add_theme_font_size_override("font_size",18);b.pressed.connect(fn);panel_box.add_child(b);return b
func close_panel():
 mode="play";panel.hide();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func show_title():
 mode="title";clear_panel("FIRST CLAIM")
 text_line("A river. A pan. A mountain worth exploring.\n\nBuild your claim from the first gold flake to a signature piece of your own. Fictional geology and mining mechanics.")
 if FileAccess.file_exists(save_path()) or FileAccess.file_exists(save_path()+".bak"):button("Continue claim",load_game)
 button("Start a new claim",func():
  if FileAccess.file_exists(save_path()) or FileAccess.file_exists(save_path()+".bak"):show_new_confirm()
  else:start_new())
 button("Settings",show_settings)
 button("Quit",func():get_tree().quit())
 text_line("WASD walk • Mouse look • E interact • Esc pause\nFirst step: walk down to the pale gravel beside the river.")
func show_new_confirm():
 clear_panel("Start a new claim?");text_line("Your existing campaign will be backed up before starting again.");button("Start new",start_new);button("Back",show_title)
func start_new():
 if FileAccess.file_exists(save_path()):DirAccess.copy_absolute(save_path(),save_path()+".previous")
 game=State.new();sync_field();player.position=Vector3(0,1,8);player.rotation.y=game.view_yaw;camera.rotation.x=0;tool=1;placement_mode=false;remove_confirm=0;close_panel();say("Walk to the river gravel. E scoops your first pan.",9)
func save_path() -> String:return "user://first_claim_"+slot+".json"
func save_game():
 game.player=[player.position.x,player.position.y,player.position.z]
 game.view_yaw=player.rotation.y;game.view_pitch=camera.rotation.x;game.equipped_tool=tool
 if game.save_to(save_path()):say("Claim saved",2)
 else:say("Save failed — check available disk space",6)
func load_game():
 var restored=false;var recovered=false
 for suffix in ["",".bak"]:
  if not FileAccess.file_exists(save_path()+suffix):continue
  var data=JSON.parse_string(FileAccess.get_file_as_string(save_path()+suffix))
  if data is Dictionary and game.restore(data):restored=true;recovered=suffix==".bak";break
 if not restored:say("Save could not be read. Existing files are preserved.",7);return
 if recovered:
  if FileAccess.file_exists(save_path()):DirAccess.copy_absolute(save_path(),save_path()+".corrupt")
  DirAccess.copy_absolute(save_path()+".bak",save_path())
 player.position=Vector3(game.player[0],game.player[1],game.player[2]);player.rotation.y=game.view_yaw;camera.rotation.x=game.view_pitch
 tool=int(game.equipped_tool)
 if tool<1 or tool>3 or (tool==2 and not game.owned.has("detector")) or (tool==3 and not game.owned.has("mining")):tool=1
 placement_mode=false;sync_field();close_panel();say("Recovered your backup. The unreadable file is preserved." if recovered else "Welcome back to your claim",5)
func material_summary(contents: Dictionary) -> String:
 var parts=[]
 for key in contents:parts.append("%s %.2f"%[key.replace("_"," ").capitalize(),contents[key]])
 return ", ".join(parts)
func say(text_: String,seconds=4.0):toast=text_;toast_time=seconds
func show_pause():
 mode="pause";clear_panel("Rest at the claim")
 button("Return",close_panel);button("Save claim",save_game);button("Settings",show_settings);button("Save and title",func():save_game();show_title());button("Save and quit",func():save_game();get_tree().quit())
func show_settings():
 mode="settings";clear_panel("Field settings")
 button("Graphics: "+["Low","Balanced","High"][int(settings.quality)],func():settings.quality=(int(settings.quality)+1)%3;apply_graphics();save_settings();show_settings())
 button("Window: "+["1280 × 720","1920 × 1080"][int(settings.resolution)],func():settings.resolution=1-int(settings.resolution);apply_graphics();save_settings();show_settings())
 for key in ["simple","motion","invert"]:
  var name_={"simple":"Simple pan input (hold Q to swirl)","motion":"Tool motion","invert":"Invert mouse Y"}[key]
  button(name_+": "+("On" if settings[key] else "Off"),func():settings[key]=not settings[key];save_settings();show_settings())
 for key in ["master","water","tools","signal","sensitivity"]:
  text_line(key.capitalize())
  var slider=HSlider.new();slider.min_value=.0005 if key=="sensitivity" else 0;slider.max_value=.006 if key=="sensitivity" else 1;slider.step=.0001 if key=="sensitivity" else .05;slider.value=settings[key]
  slider.value_changed.connect(func(v):settings[key]=v;save_settings());panel_box.add_child(slider)
 button("Back",func():if game.elapsed>0:show_pause()
 else:show_title())
func settings_path() -> String:
 return "user://settings.json" if slot=="campaign" else "user://settings_"+slot+".json"
func save_settings():
 var f=FileAccess.open(settings_path(),FileAccess.WRITE);f.store_string(JSON.stringify(settings))
func load_settings():
 if FileAccess.file_exists(settings_path()):
  var s=JSON.parse_string(FileAccess.get_file_as_string(settings_path()))
  if s is Dictionary:settings.merge(s,true)
func show_board():
 mode="board";clear_panel("Claim supply board  ·  C %.2f" % game.money)
 text_line("First upgrade: a classifier separates gravel faster and captures finer gold. Then earn a detector to search the exposed bars.")
 for item in ["classifier","detector","mining","workshop","barrow","fine_screen","timber"]:
  if game.owned.has(item) and item!="timber":continue
  if item=="mining" and not game.owned.has("detector"):continue
  if item in ["workshop","barrow","fine_screen"] and not game.owned.has("mining"):continue
  button("Buy "+item.replace("_"," ")+"  ·  C "+str(State.SHOP[item]),func():
   if game.buy(item):say("Purchased "+item.replace("_"," "));play_effect("wood");save_game()
   else:say("Need enough claim currency and required prospecting samples.")
   show_board())
 button("Custom orders",show_orders);button("Close",close_panel)
func show_orders():
 mode="orders";clear_panel("Custom orders")
 for order in game.orders():
  if not game.eligible(order):continue
  var requirements=""
  for key in order.need:requirements+="%s: %s / %s   " %[key,str(game.stock.get(key,0)),str(order.need[key])]
  text_line(order.title+"\n"+requirements+"\nPayout C "+str(order.pay)+" · bonus over raw value")
  if not game.contracts.has(order.id):button("Accept "+order.title,func():game.accept(order.id);show_orders())
  else:button("Deliver "+order.title,func():
   if game.fulfill(order.id):say("Order complete · reward paid once");save_game()
   else:say("Keep gathering — requirements are shown above.")
   if game.completed:show_ending()
   else:show_orders())
 button("Back",show_board)
func show_sell():
 mode="sell";clear_panel("Weigh & sell  ·  C %.2f" % game.money)
 text_line("Sales are explicit. Keep materials for an accepted order if you want its bonus.")
 for id_ in game.mine_batches:
  var b=game.mine_batches[id_]
  if not b.processed and not b.contents.has("specimen"):
   button("Sell raw source batch "+id_,func():
    var value=game.sell_ore_batch(id_);say("Raw batch sold for C %.2f"%value);show_sell())
 for key in State.PRICES:
  if game.stock.get(key,0)<=0:continue
  var quantity=float(game.stock[key]);button("Sell %.2f %s  ·  C %.2f" %[quantity,key,quantity*State.PRICES[key]],func():
   var value=game.sell(key,game.stock[key]);say("Sold for C %.2f" % value);play_effect("gold");save_game();show_sell())
 button("Close",close_panel)
func show_journal():
 mode="journal";clear_panel("Field journal")
 text_line("Your claim\n"+objective()+"\n\nVial: %.2f gold · C %.2f\nPans: %d · Finds: %d\nElapsed play: %.1f minutes" %[game.stock.gold,game.money,game.statistics.pans,game.statistics.targets,game.elapsed/60])
 text_line("Panning: E scoop gravel. E immerse beside water. Alternate Q / R to loosen sediment, then hold F to wash. Refill as needed. Gold stays in the pan. Simple-input mode holds Q instead.\n\nWASD walk • Shift faster walk • Mouse look • E interact • Tab journal • Esc pause")
 button("Save claim",save_game);button("Close",close_panel)
func objective() -> String:
 if game.completed:return "Claim complete. Your specimen is on display. Keep prospecting at your own pace."
 if not game.owned.has("classifier"):return "Wash your first gold. Sell at camp; buy classifier (C 24)."
 if not game.owned.has("detector"):return "Search the gravel bars. Earn your detector (C 95)."
 if not game.owned.has("mining"):return "Sweep the banks, recover targets, then sample the quartz trail."
 if not game.owned.has("workshop"):return "Open the mountain and build a workshop."
 if not game.owned.has("final"):return "Fulfill the millwright and lapidary contracts."
 return "Recover the final specimen and craft your signature pendant."

func _unhandled_input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   if mode=="play":show_pause()
   elif mode!="title":close_panel()
  if mode!="play":return
  if event.keycode==KEY_E:interact()
  if event.keycode==KEY_TAB:show_journal()
  if event.keycode==KEY_Q:swirl(-1)
  if event.keycode==KEY_R:swirl(1)
  if event.keycode==KEY_1:tool=1
  if event.keycode==KEY_2 and game.owned.has("detector"):tool=2
  if event.keycode==KEY_3 and game.owned.has("mining"):tool=3
  if event.keycode==KEY_4 and game.owned.has("barrow"):toggle_barrow()
  if event.keycode==KEY_T and game.owned.has("barrow"):
   if game.barrow_attached or player.position.distance_to(barrow.position+Vector3.UP)<2.4:
    say("Transferred %d source batches into the barrow."%game.transfer_pack_to_barrow(),5);tool_motion=1.0
   else:say("Stand by your physical barrow to transfer the load.",4)
  if event.keycode==KEY_B:place_frame()
  if event.keycode==KEY_H:
   var before=game.stock.timber
   say(mine.lag_nearest(player.position),5)
   if game.stock.timber<before:hammer_motion=1.0;play_effect("wood")
  if event.keycode==KEY_X:
   say(mine.remove_nearest(player.position,remove_confirm>0),5);remove_confirm=0 if remove_confirm>0 else 3
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and mode=="play":field_use()
 if event is InputEventMouseMotion and mode=="play":
  player.rotation.y-=event.relative.x*settings.sensitivity
  camera.rotation.x=clampf(camera.rotation.x-event.relative.y*settings.sensitivity*(-1 if settings.invert else 1),-1.4,1.3)

func nearest_patch() -> int:
 var best=-1;var distance=2.7
 for i in ground_patches.size():
  if game.batches.has("river_"+str(i)):continue
  var d=player.position.distance_to(ground_patches[i]+Vector3.UP)
  if d<distance:distance=d;best=i
 return best
func splash_pan():
 var drops=CPUParticles3D.new();pan.add_child(drops);drops.position=Vector3(0,.055,0);drops.amount=18;drops.lifetime=.5;drops.one_shot=true
 drops.direction=Vector3.UP;drops.spread=50;drops.initial_velocity_min=.12;drops.initial_velocity_max=.3;drops.gravity=Vector3(0,-.7,0)
 var bead=SphereMesh.new();bead.radius=.0025;bead.height=.005;bead.radial_segments=5;bead.rings=3;bead.material=mats.water;drops.mesh=bead;drops.emitting=true
 drops.finished.connect(drops.queue_free)

func near_water() -> bool:return abs(player.position.x-river_x(player.position.z))<5.5
func interaction_point() -> Dictionary:
 var best: Dictionary={};var distance=2.8
 for point in interactables:
  if point.has("requires") and not game.owned.has(point.requires):continue
  var d=camera.global_position.distance_to(point.pos)
  var direction=(point.pos-camera.global_position).normalized()
  if d<distance and (-camera.global_basis.z).dot(direction)>.35:best=point;distance=d
 return best
func interact():
 if not active_point.is_empty():
  if active_point.type=="sell":show_sell()
  if active_point.type=="board":show_board()
  if active_point.type=="station":show_station(active_point.station)
  return
 if field_interact():return
 if tool!=1:return
 if not game.batch.is_empty():
  if game.batch.loose<=.01:
   var amount=game.collect();say("Recovered %.2f gold. Weigh it at the camp scale." % amount,6);play_effect("gold");return
  if near_water():game.batch.water=1.0;tool_motion=.8;say("Pan filled. Alternate Q / R to loosen, hold F to wash.",4);play_effect("water");splash_pan();return
 elif nearest_patch()>=0:
  game.scoop("river_"+str(nearest_patch()));tool_motion=1.5;say("A real batch of gravel. E beside the river adds water.",5);play_effect("gravel")
func swirl(direction: int):
 if game.batch.is_empty() or game.batch.water<=0:return
 if direction!=last_swirl or settings.simple:
  game.batch.agitation=minf(1,float(game.batch.agitation)+.16);pan_motion=float(direction)*.08;last_swirl=direction;play_effect("gravel")
 else:say("Reverse the swirl to loosen the heavy concentrate.",1.5)

func _physics_process(delta):
 if mode!="play":return
 game.elapsed+=delta;autosave+=delta;game.tick_job(delta)
 var movement=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
 var direction=player.basis*Vector3(movement.x,0,movement.y)
 var speed=4.2 if Input.is_physical_key_pressed(KEY_SHIFT) else 2.8
 player.velocity.x=direction.x*speed;player.velocity.z=direction.z*speed;player.velocity.y-=12*delta
 if player.is_on_floor():player.velocity.y=-.1
 player.move_and_slide()
 game.player=[player.position.x,player.position.y,player.position.z]
 game.view_yaw=player.rotation.y;game.view_pitch=camera.rotation.x;game.equipped_tool=tool
 if player.position.y < -5:player.position=Vector3(0,1,8)
 if autosave>40:autosave=0;save_game()
 if not game.batch.is_empty():
  if settings.simple and Input.is_physical_key_pressed(KEY_Q):
   swirl_time+=delta
   if swirl_time>.18:swirl_time=0;swirl(-1)
  if Input.is_physical_key_pressed(KEY_F) and game.batch.water>0:
   if game.batch.agitation>.12:
    var rate=.09 if game.owned.has("classifier") else .057
    game.batch.loose=maxf(0,float(game.batch.loose)-delta*rate)
    game.batch.water=maxf(0,float(game.batch.water)-delta*.045)
    game.batch.agitation=maxf(0,float(game.batch.agitation)-delta*.09)
    effect_left=.06;effect_type="water";pan_motion=.1
   elif toast_time<.2:say("Swirl Q / R to loosen more sediment.",1.5)

func _process(delta):
 remove_confirm=maxf(0,remove_confirm-delta)
 ticks+=1;elapsed_view+=delta;toast_time=maxf(0,toast_time-delta)
 if mode=="play":frame_samples.append(delta*1000)
 active_point=interaction_point()
 notice.text=toast if toast_time>0 else ""
 hud.visible=mode=="play";held.visible=mode=="play";hud_back.visible=mode=="play";prompt_back.visible=mode=="play"
 hud.text="FIRST CLAIM    ·    C %.2f\nVial %.2f gold\n%s" %[game.money,game.stock.gold,objective()]
 prompt.text=""
 if mode=="play":
  if not active_point.is_empty():prompt.text=active_point.label
  elif not game.batch.is_empty():
   var b=game.batch
   if b.loose<=.01:prompt.text="Gold revealed  ·  E collect into vial"
   elif b.water<=0:prompt.text="Gravel collected  ·  E add river water" if near_water() else "Carry your pan to the river"
   else:prompt.text="Q / R swirl  ·  Hold F wash  ·  E refill\nSediment %d%%   Water %d%%   Loosened %d%%" %[int(b.loose*100),int(b.water*100),int(b.agitation*100)]
  elif tool==1 and nearest_patch()>=0:prompt.text="River gravel  ·  E scoop a batch"
  else:prompt.text="WASD walk  ·  E interact  ·  Tab journal"
 sediment.visible=not game.batch.is_empty() and game.batch.loose>.01
 water_pan.visible=not game.batch.is_empty() and game.batch.water>0
 flakes.visible=not game.batch.is_empty() and game.batch.loose<.32
 if not game.batch.is_empty():
  sediment.scale=Vector3(1,maxf(.05,game.batch.loose),1)
  gravel_visual.multimesh.visible_instance_count=int(clampf((game.batch.loose-.3)/.7,0,1)*80)
  if game.batch.loose<=.01:water_pan.visible=false
 else:gravel_visual.multimesh.visible_instance_count=0
 pan_motion=lerpf(pan_motion,0,delta*4)
 if settings.motion:
  pan.rotation.z=pan_motion;pan.rotation.x=lerpf(pan.rotation.x,.46 if Input.is_physical_key_pressed(KEY_F) and mode=="play" else .3,delta*5)
 else:pan.rotation=Vector3(.3,0,0)
 if capture_at>0 and ticks==capture_at:
  var folder="res://evidence/runs/"+slot;DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
  var path=folder+"/preview.png";get_viewport().get_texture().get_image().save_png(path);print("SNAPSHOT ",path)
  get_tree().quit()
 refresh_workshop()
 update_field(delta)
 update_audio(delta)

func loop_audio(name_: String) -> AudioStreamPlayer:
 var voice=AudioStreamPlayer.new();add_child(voice)
 var clip=load("res://assets/audio/"+name_+".wav").duplicate() as AudioStreamWAV
 clip.loop_mode=AudioStreamWAV.LOOP_FORWARD;clip.loop_end=int(clip.get_length()*clip.mix_rate)
 voice.stream=clip;voice.volume_db=-80;voice.play();return voice
func make_audio():
 sound=AudioStreamPlayer.new();add_child(sound)
 var stream=AudioStreamGenerator.new();stream.mix_rate=22050;stream.buffer_length=.2;sound.stream=stream;sound.play();audio_playback=sound.get_stream_playback()
 river_audio=loop_audio("river");forest_audio=loop_audio("forest");wash_audio=loop_audio("water")
 for name_ in ["water","gravel","step","wood","rock","gold","pour","creak","fall"]:foley_clips[name_]=load("res://assets/audio/"+name_+".wav")
 for i in 6:
  var voice=AudioStreamPlayer.new();add_child(voice);foley_players.append(voice)
func play_effect(kind: String):
 if not foley_clips.has(kind):return
 var voice=foley_players[foley_index%foley_players.size()];foley_index+=1
 voice.stream=foley_clips[kind];voice.pitch_scale=randf_range(.96,1.04);voice.set_meta("kind",kind)
 voice.volume_db=linear_to_db(maxf(.0001,settings.master*(settings.water if kind=="water" else settings.tools)*.7));voice.play()
func mine_notice(message_: String,seconds: float=4):
 say(message_,seconds)
 if "roof fall" in message_:play_effect("fall")
func update_audio(delta):
 effect_left=maxf(0,effect_left-delta)
 var river_distance=absf(player.position.x-river_x(player.position.z))
 var water_gain=clampf(1.0-river_distance/24.0,.08,1.0)
 if player.position.z< -34:water_gain*=.12
 river_audio.volume_db=linear_to_db(maxf(.0001,settings.master*settings.water*water_gain*.65))
 forest_audio.volume_db=linear_to_db(maxf(.0001,settings.master*settings.water*.24))
 var washing=mode=="play" and tool==1 and Input.is_physical_key_pressed(KEY_F) and not game.batch.is_empty() and game.batch.get("water",0)>0 and game.batch.get("loose",0)>.01
 wash_audio.volume_db=lerpf(wash_audio.volume_db,linear_to_db(maxf(.0001,settings.master*settings.water*.8)) if washing else -80.0,minf(1,delta*14))
 for voice in foley_players:
  var gain=settings.water if voice.get_meta("kind","")=="water" else settings.tools
  voice.volume_db=linear_to_db(maxf(.0001,settings.master*gain*.7))
 if mode=="play" and player.is_on_floor() and Vector2(player.velocity.x,player.velocity.z).length()>.2:
  step_clock+=delta
  if step_clock>.48:step_clock=0;play_effect("step")
 if audio_playback==null:return
 var frames=audio_playback.get_frames_available()
 for i in frames:
  tone_clock+=1.0/22050
  var value=0.0
  if effect_type=="signal" and effect_left>0:
   value=sin(tone_clock*TAU*effect_hz)*.10*clampf(effect_left/.07,0,1)*settings.signal*settings.master
  audio_playback.push_frame(Vector2(value,value))

func add_ground_detail():
 var noise=FastNoiseLite.new();noise.seed=411;noise.frequency=.06
 var grass_mesh=ArrayMesh.new();var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rng=RandomNumberGenerator.new();rng.seed=421
 for blade in 7:
  var angle=rng.randf()*TAU;var base=Vector3(rng.randf_range(-.12,.12),0,rng.randf_range(-.12,.12));var side=Vector3(cos(angle),0,sin(angle))*.025
  var tip=base+Vector3(rng.randf_range(-.07,.07),rng.randf_range(.15,.38),rng.randf_range(-.07,.07))
  for v in [base-side,tip,base+side]:st.set_normal(Vector3.UP);st.add_vertex(v)
 grass_mesh=st.commit()
 var grassmat=mats.grass.duplicate();grassmat.cull_mode=BaseMaterial3D.CULL_DISABLED;grassmat.roughness=1
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=grass_mesh
 var transforms=[];var colors=[]
 for i in 12000:
  var x=rng.randf_range(-42,42);var z=rng.randf_range(-54,28)
  if abs(x-river_x(z))<5.4 or (abs(x)<2.6 and z<5 and z>-38) or Vector2(x+3,z-5).length()<3 or (x> -11 and x< -3 and z> -5 and z<8) or (abs(x)<6 and z< -28 and z> -50):continue
  if noise.get_noise_2d(x*2,z*2)<-.25:continue
  var transform=Transform3D(Basis(Vector3.UP,rng.randf()*TAU),Vector3(x,height_at(x,z),z))
  transforms.append(transform);colors.append(Color(rng.randf_range(.65,1),rng.randf_range(.75,1),.65))
 mm.instance_count=transforms.size()
 for i in transforms.size():mm.set_instance_transform(i,transforms[i]);mm.set_instance_color(i,colors[i])
 var instance=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=grassmat;add_child(instance)

func make_field_systems():
 mine=ClaimMine.new();mine.position=Vector3(0,1.6,-34);add_child(mine);mine.setup(game,mine_notice)
 for i in 14:
  var z=4.0-i*2.0
  var x=river_x(z)+(-4.4 if i%2==0 else 4.3)
  if i==7:x+=2.0
  targets.append({"id":i,"pos":Vector3(x,height_at(x,z),z),"depth":.15+float(i%4)*.12,"contents":({"gold":5.4,"scrap":1} if i==5 else {"scrap":2,"gold":.75+float(i%3)*.3})})
 for i in 3:
  var pos=Vector3(-.6+float(i%2),height_at(0,-15-i*7),-15-i*7)
  sample_points.append(pos)
  var crystal=PrismMesh.new();crystal.size=Vector3(.45,.65,.35)
  mesh_object(crystal,pos+Vector3(0,.25,0),material("quartz"+str(i),Color("c4d5cf"),.3,.2)).rotation.z=.2
 detector=model("detector",Vector3(.28,-.83,-1.35),player)
 detector.rotation=Vector3(0,PI,0);detector.visible=false
 detector_readout=Label3D.new();detector.add_child(detector_readout);detector_readout.position=Vector3(0,1.358,-.487);detector_readout.rotation=Vector3(-PI/2,0,PI);detector_readout.font_size=24;detector_readout.pixel_size=.0014;detector_readout.modulate=Color(.1,.17,.12);detector_readout.outline_size=0;detector_readout.no_depth_test=false
 trowel=model("trowel",Vector3(.25,-.16,-.6),held);trowel.rotation.x=.4;trowel.visible=false
 recovered_find=Node3D.new();held.add_child(recovered_find);recovered_find.position=Vector3(-.14,-.18,-.52)
 var nugget=SphereMesh.new();nugget.radius=.028;nugget.height=.043;nugget.radial_segments=9;nugget.rings=5
 recovery_gold=mesh_object(nugget,Vector3.ZERO,mats.gold,recovered_find);recovery_gold.scale=Vector3(1.3,.8,.85)
 recovery_scrap=Node3D.new();recovered_find.add_child(recovery_scrap)
 cube(Vector3.ZERO,Vector3(.058,.013,.036),mats.darkrock,false,recovery_scrap).rotation.z=.3
 cube(Vector3(.022,.01,0),Vector3(.012,.037,.033),mats.darkrock,false,recovery_scrap)
 recovered_find.visible=false
 support_hammer=model("support_hammer",Vector3(.3,-.5,-.65),held);support_hammer.visible=false
 pick=model("pickaxe",Vector3(.32,-.46,-.6),held);pick.rotation=Vector3(-.5,0,-.5);pick.visible=false
 barrow=model("barrow",Vector3(-4,0,7),self,PI);barrow.visible=false
 var parked=StaticBody3D.new();barrow.add_child(parked);parked_barrow_shape=CollisionShape3D.new();var parked_box=BoxShape3D.new();parked_box.size=Vector3(1.25,.8,1.5);parked_barrow_shape.shape=parked_box;parked_barrow_shape.position=Vector3(0,.45,0);parked.add_child(parked_barrow_shape);parked_barrow_shape.disabled=true
 var fill=MultiMesh.new();fill.transform_format=MultiMesh.TRANSFORM_3D;var chunk=SphereMesh.new();chunk.radius=.085;chunk.height=.13;chunk.radial_segments=6;chunk.rings=3;fill.mesh=chunk;fill.instance_count=30
 var fill_rng=RandomNumberGenerator.new();fill_rng.seed=337
 for i in 30:fill.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(fill_rng.randf_range(-.25,.25),.61+fill_rng.randf_range(0,.12),fill_rng.randf_range(-.30,.30))))
 barrow_fill=MultiMeshInstance3D.new();barrow_fill.multimesh=fill;barrow_fill.material_override=mats.rock;barrow.add_child(barrow_fill)
 barrow_shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(1.25,.65,1.45);barrow_shape.shape=box;barrow_shape.position=Vector3(0,-.28,-.95);barrow_shape.disabled=true;player.add_child(barrow_shape)
 marker("QUARTZ RIDGE",Vector3(0,4.7,-33),40)
 frame_preview=Node3D.new();add_child(frame_preview);frame_preview_material=StandardMaterial3D.new();frame_preview_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;frame_preview_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 for x in [-1.2,1.2]:cube(Vector3(x,1.15,0),Vector3(.16,2.3,.18),frame_preview_material,false,frame_preview)
 cube(Vector3(0,2.35,0),Vector3(2.56,.18,.2),frame_preview_material,false,frame_preview);frame_preview.visible=false

func sync_field():
 if mine!=null:mine.state=game;mine.rebuild_state()
func field_probe() -> Vector3:
 var p=detector.global_position
 p.y=height_at(p.x,p.z)
 return p
func closest_target() -> Dictionary:
 var best: Dictionary={};var strongest=0.0
 var probe=field_probe()
 for t in targets:
  if game.depleted.has(t.id):continue
  var distance=Vector2(t.pos.x-probe.x,t.pos.z-probe.z).length()
  var signal_strength=maxf(0,1.0-distance/2.8)*maxf(0,1.0-float(t.depth)/.85)
  if signal_strength>strongest:strongest=signal_strength;best=t.duplicate();best.signal=signal_strength;best.distance=distance
 return best
func field_interact() -> bool:
 if placement_mode:
  var before=game.supports.size()
  say(mine.place_support(frame_center()),6)
  if game.supports.size()>before:hammer_motion=1.0;play_effect("wood")
  placement_mode=false;return true
 if game.owned.has("barrow") and not game.barrow_attached and player.position.distance_to(barrow.position+Vector3.UP)<2:
  toggle_barrow();return true
 if mine!=null and mine.clear_rubble(player.position):say("Rubble cleared. The excavated passage is open again.");play_effect("gravel");return true
 var target=closest_target() if tool==2 else {}
 # A localized coil target gets the dig interaction instead of a nearby sample site.
 if tool==2 and not target.is_empty() and target.distance<=.55:
  if game.recover_target(target.id,target.contents):
   say("Recovered "+material_summary(target.contents)+" · this find is collected",6);play_effect("gold");tool_motion=1.0;recovery_motion=1.25
   recovery_gold.visible=target.contents.get("gold",0)>0;recovery_scrap.visible=not recovery_gold.visible
   recovery_gold.scale=Vector3(1.3,.8,.85)*(1.25 if target.contents.get("gold",0)>1 else 1.0);save_game()
  return true
 for i in sample_points.size():
  if game.samples.has(i):continue
  var point=sample_points[i]+Vector3(0,.4,0)
  var facing=(-camera.global_basis.z).dot((point-camera.global_position).normalized())>.25
  if player.position.distance_to(sample_points[i]+Vector3.UP)<2 and game.owned.has("detector") and facing:
   game.samples.append(i);say(["River quartz fragments: trace their source uphill.","Angular quartz and copper stain: the source is closer.","Exposed quartz with copper/tin minerals. Mining kit now available."][i],7);play_effect("gravel")
   return true
 if tool==2:
  say("Sweep closer. A strong, narrow signal marks the shallow target.");return true
 return false

func field_use():
 if tool!=3 or not game.owned.has("mining"):return
 var from=camera.global_position;var to=from-camera.global_basis.z*3.3
 var query=PhysicsRayQueryParameters3D.create(from,to);query.exclude=[player.get_rid()]
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty():say("Move closer to the working face.");return
 var result=mine.dig(hit.position,hit.normal)
 if result.ok:say("Cut rock · "+material_summary(result.contents),2);play_effect("rock");tool_motion=1
 else:say(result.reason,4)
func frame_center() -> Vector3:
 var local=mine.to_local(player.position-player.global_basis.z*1.2)
 var x=(floorf(local.x/.8)+.5)*.8
 var z=-(floorf(-local.z/.8)+.5)*.8
 return mine.to_global(Vector3(x,.8,z))
func place_frame():
 if not game.owned.has("mining"):say("First follow the samples and buy the mining kit.");return
 placement_mode=not placement_mode
 say("Frame preview · E install · B cancel",4)
func update_field(delta: float):
 if detector==null:return
 mining_lamp.visible=game.owned.has("mining") and player.position.z< -28 and mode=="play"
 hammer_motion=maxf(0,hammer_motion-delta*1.7)
 recovery_motion=maxf(0,recovery_motion-delta)
 trowel.visible=recovery_motion>.7;recovered_find.visible=recovery_motion>0 and recovery_motion<.8
 trowel.rotation.z=sin(recovery_motion*PI*2)*.4
 recovered_find.rotation.y=sin(recovery_motion*2)*.35
 support_hammer.visible=hammer_motion>0;support_hammer.rotation=Vector3(-.3,0,-.6-sin(hammer_motion*PI*3)*.6)
 pan.visible=tool==1 and hammer_motion==0;detector.visible=tool==2 and hammer_motion==0 and recovery_motion==0;pick.visible=tool==3 and hammer_motion==0;barrow.visible=game.owned.has("barrow");barrow_fill.multimesh.visible_instance_count=mini(30,game.loaded_batches("barrow"))
 barrow_shape.set_deferred("disabled",not game.barrow_attached)
 parked_barrow_shape.set_deferred("disabled",game.barrow_attached or not game.owned.has("barrow"))
 if game.barrow_attached:
  var at=player.global_position-player.global_basis.z*1.2;at.y=height_at(at.x,at.z)
  game.barrow_position=[at.x,at.y,at.z];game.barrow_yaw=player.rotation.y+PI
 barrow.position=Vector3(game.barrow_position[0],game.barrow_position[1],game.barrow_position[2]);barrow.rotation.y=game.barrow_yaw
 tool_motion=maxf(0,tool_motion-delta*2)
 scoop_tool.visible=tool==1 and tool_motion>.8
 scoop_tool.rotation=Vector3(-.9+sin(tool_motion*2)*.5,0,-.5)
 if tool==1 and settings.motion:pan.position.y=-.22-sin(minf(tool_motion,1)*PI)*.09
 frame_preview.visible=placement_mode and mode=="play"
 if placement_mode:
  frame_preview.global_position=frame_center()
  var reason=mine.support_check(frame_center())
  frame_preview_material.albedo_color=Color(.4,.8,.52,.35) if reason.is_empty() else Color(.9,.3,.2,.35)
  prompt.text="E install frame · B cancel\n"+("Valid ground, walls and roof" if reason.is_empty() else reason)
 pick.rotation.z=-.5-sin(tool_motion*PI)*.9
 detector.rotation.z=sin(elapsed_view*1.6)*.035 if settings.motion else 0.0
 if mode!="play":return
 if tool==2 and active_point.is_empty() and not placement_mode:
  var target=closest_target()
  var strength=target.get("signal",0.0)
  detector_readout.text="%02d"%int(strength*100)
  prompt.text="DETECTOR  ·  Signal %d%%  ·  E shallow dig\nSweep with your view; approach the strongest response."%int(strength*100)
  detector_beep-=delta
  if strength>.04 and detector_beep<=0:
   detector_beep=lerpf(.85,.09,strength);effect_type="signal";effect_hz=lerpf(230,1250,strength);effect_left=.07
 if player.position.z < -30 and not placement_mode:
  var status=mine.tick(delta,player.position)
  if status.state!=last_roof_state and status.state!="stable":play_effect("creak")
  last_roof_state=status.state
  prompt.text="%s\n3 pick · Click cut · B frame · H lagging · X remove · E clear rubble"%status.state
 for i in sample_points.size():
  if player.position.distance_to(sample_points[i]+Vector3.UP)<2 and game.owned.has("detector") and not game.samples.has(i) and (-camera.global_basis.z).dot((sample_points[i]+Vector3(0,.4,0)-camera.global_position).normalized())>.25 and (tool!=2 or closest_target().get("distance",99.0)>.55):prompt.text="Quartz trail  ·  E take sample %d / 3"%(i+1)

func make_workshop():
 workshop_root=Node3D.new();add_child(workshop_root)
 var spots={"sieve":Vector3(-7,0,6),"furnace":Vector3(-9,0,3),"casting":Vector3(-8,0,0),"polisher":Vector3(-6,.83,-2)}
 for station in spots:
  model(station,spots[station],workshop_root)
  if station=="polisher":model("bench",Vector3(-6,0,-2),workshop_root)
  var pos=spots[station]+Vector3(0,1,0)
  if station=="polisher":pos.y=1.0
  interactables.append({"type":"station","station":station,"pos":pos,"label":"E · "+station.capitalize(),"requires":"workshop"})
  var label=marker(station.to_upper(),pos+Vector3(0,.48,0),29);remove_child(label);workshop_root.add_child(label)
  cube(Vector3(pos.x,.4,pos.z),Vector3(.9,.8,.6),mats.wood,true,workshop_root).visible=false
 var glow=OmniLight3D.new();glow.position=Vector3(-9,.8,3);glow.light_color=Color("ff953e");glow.light_energy=.8;glow.omni_range=3;workshop_root.add_child(glow)
 var variants={"copper":"ingot_copper","tin":"ingot_tin","bronze":"ingot_bronze","refined_gold":"ingot_gold","gear":"gear","polished":"polished_stone","pendant":"pendant"}
 cube(Vector3(-8.45,.74,3),Vector3(.38,.06,.32),mats.wood,false,workshop_root)
 for recipe in variants:
  var station=State.RECIPES[recipe].station
  var at=Vector3(-8.45,.78,3) if station=="furnace" else (Vector3(-8,.98,0) if station=="casting" else Vector3(-6,1.07,-1.77))
  product_displays[recipe]=model(variants[recipe],at,workshop_root)
 casting_crucible=model("crucible",Vector3(-8.35,.87,0),workshop_root)
 var hot=material("working molten metal",Color(.93,.36,.07),.32,.55);hot.emission_enabled=true;hot.emission=Color(.65,.13,.015);hot.emission_energy_multiplier=.6
 var pool=CylinderMesh.new();pool.top_radius=.135;pool.bottom_radius=.135;pool.height=.012;pool.radial_segments=32
 furnace_melt=mesh_object(pool,Vector3(-9,.756,3),hot,workshop_root)
 var stream=CylinderMesh.new();stream.top_radius=.009;stream.bottom_radius=.014;stream.height=.17;stream.radial_segments=10
 casting_stream=mesh_object(stream,Vector3(-8.10,1.04,0),hot,workshop_root)
 polishing_rotor=Node3D.new();polishing_rotor.position=Vector3(-6,1.13,-1.965);workshop_root.add_child(polishing_rotor)
 cube(Vector3(.07,0,0),Vector3(.11,.009,.006),mats.rock,false,polishing_rotor)
 var rough=SphereMesh.new();rough.radius=.035;rough.height=.046;rough.radial_segments=7;rough.rings=4
 rough_workpiece=mesh_object(rough,Vector3(-6,1.075,-1.77),mats.rock,workshop_root)
 fine_screen_grid=Node3D.new();workshop_root.add_child(fine_screen_grid)
 var wires=MultiMeshInstance3D.new();wires.multimesh=MultiMesh.new();wires.multimesh.transform_format=MultiMesh.TRANSFORM_3D
 var wire=BoxMesh.new();wire.size=Vector3.ONE;wires.multimesh.mesh=wire;wires.multimesh.instance_count=80;wires.material_override=mats.rock;fine_screen_grid.add_child(wires)
 for i in range(80):
  var along=i<50;var size=Vector3(.0018,.0018,.62) if along else Vector3(1.04,.0018,.0018)
  var at=Vector3(-7.5+i*.02,.889,6) if along else Vector3(-7,.89,5.71+(i-50)*.02)
  wires.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(size),at))
 final_display=Node3D.new();add_child(final_display)
 model("bench",Vector3(-2,0,2),final_display)
 model("specimen",Vector3(-2.35,.84,2),final_display)
 var pendant=model("pendant",Vector3(-1.7,.85,2),final_display);pendant.scale=Vector3.ONE*2
 final_display.visible=false
func refresh_workshop():
 if workshop_root==null:return
 workshop_root.visible=game.owned.has("workshop")
 # Hidden upgrade stations must not have blocking collision before purchase.
 for child in workshop_root.find_children("*","CollisionShape3D",true,false):child.set_deferred("disabled",not game.owned.has("workshop"))
 final_display.visible=game.completed
 classifier_display.visible=game.owned.has("classifier")
 sample_tray.visible=game.owned.has("detector")
 for i in sample_displays.size():sample_displays[i].visible=game.samples.has(i)
 vial_fill.multimesh.visible_instance_count=mini(80,ceili(game.stock.gold*8))
 fine_screen_grid.visible=game.owned.has("fine_screen")
 for recipe in product_displays:product_displays[recipe].visible=not game.job.is_empty() and game.job.ready and game.job.recipe==recipe
 var casting=not game.job.is_empty() and not game.job.ready and State.RECIPES[game.job.recipe].station=="casting"
 casting_crucible.rotation.z=-sin((4.0-float(game.job.remaining))/4.0*PI)*.7 if casting else 0.0
 casting_stream.visible=casting and float(game.job.remaining)<3.2 and float(game.job.remaining)>.7
 var working=not game.job.is_empty() and not game.job.ready
 furnace_melt.visible=working and State.RECIPES[game.job.recipe].station=="furnace"
 rough_workpiece.visible=working and State.RECIPES[game.job.recipe].station=="polisher"
 if rough_workpiece.visible and mode=="play":polishing_rotor.rotation.z=elapsed_view*13
func show_station(station: String):
 mode="station";clear_panel(station.capitalize()+" workshop")
 if station=="sieve":
  text_line("Screen carried source batches. The material contents remain fixed; fine losses stay in labeled tailings for the improved screen.")
  var count=0
  for id_ in game.mine_batches:
   var b=game.mine_batches[id_]
   if not b.processed:
    count+=1
    var screen_button=button(("Bring barrow to camp · " if not game.batch_accessible(b) else "")+"Screen batch "+id_+"  "+material_summary(b.contents),func():
     if game.process_ore_batch(id_):play_effect("gravel");tool_motion=1;say("Batch screened. Fine remainder stored.")
     show_station(station))
    screen_button.disabled=not game.batch_accessible(b)
  if count==0:text_line("No unprocessed material. Bring a load from the working face.")
  if game.owned.has("fine_screen"):
   button("Recover all labeled fine tailings",func():
    var amount=0.0
    for id_ in game.tailings:amount+=game.reprocess(id_)
    for id_ in game.mine_batches:game.recover_ore_tailings(id_)
    say("Processed finite remaining fines; no batch rerolled.");show_station(station))
 else:
  if not game.job.is_empty():
   if game.job.ready:
    text_line("Ready: "+material_summary(game.job.output))
    button("Pick up finished work",func():
     if game.collect_job():play_effect("gold");say("Finished work placed in your inventory.");save_game()
     show_station(station))
   else:text_line("Working on "+game.job.recipe+" · %.1f seconds remain. Close this panel to let work continue."%game.job.remaining)
  for recipe in State.RECIPES:
   var r=State.RECIPES[recipe]
   if r.station!=station:continue
   var required=""
   for key in r.input:required+="%s %.1f / %s   "%[key,game.stock.get(key,0),str(r.input[key])]
   button(recipe.replace("_"," ").capitalize()+"  ·  "+required,func():
    if game.start_job(recipe):play_effect("pour" if station in ["furnace","casting"] else "rock");say("Inputs reserved. Watch the station work, then collect its output.");close_panel()
    else:say("Need all ingredients and an empty station output.",5))
 button("Close",close_panel)
func show_ending():
 mode="ending";clear_panel("YOUR FIRST CLAIM")
 text_line("The valley's signature commission is complete.\n\nYour recovered gold and quartz became a pendant. Your exceptional specimen has a place on the camp display. The river and mountain remain yours to explore.")
 text_line("This claim: %d pans · %d detector finds · %d rock cells\n%d crafted products · %d localized falls\nActive play %.1f minutes · C %.2f remaining"%[game.statistics.pans,game.statistics.targets,game.statistics.cells,game.statistics.products,game.statistics.falls,game.elapsed/60,game.money])
 text_line("Campaign complete. Optional continued prospecting is available. Fictional game geology, recipes and support mechanics.")
 button("Keep prospecting",close_panel);button("Save and title",func():save_game();show_title())

func apply_graphics():
 var quality=int(settings.quality)
 get_viewport().msaa_3d=Viewport.MSAA_DISABLED if quality==0 else Viewport.MSAA_2X if quality==1 else Viewport.MSAA_4X
 for light in find_children("*","DirectionalLight3D",true,false):light.shadow_enabled=quality>0
 DisplayServer.window_set_size(Vector2i(1280,720) if int(settings.resolution)==0 else Vector2i(1920,1080))

func toggle_barrow():
 if game.barrow_attached:
  game.barrow_attached=false;say("Barrow parked here with its load. E or 4 nearby picks up the handles.",5);return
 if player.position.distance_to(barrow.position+Vector3.UP)>2.4:
  say("Your barrow is where you left it. Stand by its handles to attach.",5);return
 game.barrow_attached=true;say("Pushing the barrow. Its width remains physical with every tool. 4 parks it.",5)

func _exit_tree():
 for voice in [sound,river_audio,forest_audio,wash_audio]+foley_players:
  if is_instance_valid(voice):voice.stop();voice.stream=null
 audio_playback=null
