class_name ClaimMine
extends Node3D
# Fictional bounded cell model. No real-world structural engineering claims.
const CELL = 0.8
const WIDTH = 12
const HEIGHT = 6
const DEPTH = 16
var state
var solid: Dictionary = {}
var mesh_node: MeshInstance3D
var frames: Node3D
var debris: Node3D
var lamps: Node3D
var cracks: Node3D
var crack_signature=""
var stone: StandardMaterial3D
var timber: StandardMaterial3D
var warning_age: Dictionary = {}
var update_clock = 0.0
var message: Callable
var supports_dirty = false
var last_status = {"state":"stable","risk":0.0}

func setup(claim, notify: Callable):
 state=claim;message=notify
 stone=StandardMaterial3D.new();stone.albedo_color=Color(.82,.84,.80);stone.roughness=.92;stone.vertex_color_use_as_albedo=true
 var noise=FastNoiseLite.new();noise.seed=442;noise.frequency=.014
 var texture=NoiseTexture2D.new();texture.noise=noise;texture.width=512;texture.height=512;texture.seamless=true
 var gradient=Gradient.new();gradient.set_color(0,Color(.39,.40,.40));gradient.set_color(1,Color(.52,.53,.52));gradient.add_point(.66,Color(.44,.45,.45));gradient.add_point(.68,Color(.51,.52,.51));gradient.add_point(.695,Color(.58,.59,.57));gradient.add_point(.72,Color(.46,.47,.46));texture.color_ramp=gradient
 stone.albedo_texture=texture;stone.uv1_triplanar=true;stone.uv1_scale=Vector3.ONE*.45
 var relief_noise=FastNoiseLite.new();relief_noise.seed=337;relief_noise.frequency=.15
 var relief=NoiseTexture2D.new();relief.noise=relief_noise;relief.width=512;relief.height=512;relief.seamless=true;relief.as_normal_map=true;relief.bump_strength=2.0;stone.normal_enabled=true;stone.normal_texture=relief;stone.normal_scale=.55
 timber=StandardMaterial3D.new();timber.albedo_color=Color(.34,.21,.11);timber.roughness=.8;timber.albedo_color=Color(.85,.85,.85);timber.albedo_texture=load("res://assets/materials/warm-worn-ash-albedo.png");timber.normal_enabled=true;timber.normal_texture=load("res://assets/materials/warm-worn-ash-normal.png");timber.normal_scale=.4;timber.uv1_triplanar=true
 frames=Node3D.new();add_child(frames);debris=Node3D.new();add_child(debris);lamps=Node3D.new();add_child(lamps);cracks=Node3D.new();add_child(cracks)
 make_boundary_outcrop()
 rebuild_state()

func make_boundary_outcrop():
 var rng=RandomNumberGenerator.new();rng.seed=876
 for i in range(22):
  var top=i<12
  var at=Vector3(-5.5+i,4.85+rng.randf_range(-.2,.8),-.35) if top else Vector3(-5.05 if i%2==0 else 5.05,.5+float(i-12)/2*.9,-.15)
  var rock=SphereMesh.new();rock.radius=rng.randf_range(.65,1.05);rock.height=rock.radius*1.7;rock.radial_segments=7;rock.rings=4
  var piece=MeshInstance3D.new();piece.mesh=rock;piece.material_override=stone;piece.position=at+Vector3(rng.randf_range(-.12,.12),rng.randf_range(-.13,.13),rng.randf_range(-.18,.18));piece.rotation=Vector3(rng.randf(),rng.randf(),rng.randf());add_child(piece);piece.create_trimesh_collision()

func id(cell: Vector3i) -> String:return "%d,%d,%d" %[cell.x,cell.y,cell.z]
func coord(key: String) -> Vector3i:
 var p=key.split(",");return Vector3i(int(p[0]),int(p[1]),int(p[2]))
func valid(c: Vector3i) -> bool:return c.x>=0 and c.x<WIDTH and c.y>=0 and c.y<HEIGHT and c.z>=0 and c.z<DEPTH
func local_center(c: Vector3i) -> Vector3:return Vector3((c.x-WIDTH/2.0+.5)*CELL,(c.y+.5)*CELL,-(c.z+.5)*CELL)
func cell_at(point: Vector3) -> Vector3i:
 var local=to_local(point);return Vector3i(floori(local.x/CELL+WIDTH/2.0),floori(local.y/CELL),floori(-local.z/CELL))
func occupied(c: Vector3i) -> bool:return solid.has(id(c))
func rebuild_state():
 solid.clear()
 for x in WIDTH:
  for y in HEIGHT:
   for z in DEPTH:
    var key=id(Vector3i(x,y,z))
    if not state.excavated.has(key):solid[key]=true
 revalidate_supports();rebuild_mesh();rebuild_supports();rebuild_rubble();crack_signature="__rebuild__";rebuild_cracks()
func ore(c: Vector3i) -> Dictionary:
 if c.z>=12:
  if c.x==6 and c.y==2 and c.z==13:return {"gold":3.0,"quartz":2.0,"specimen":1.0}
  return {"gold":.28,"quartz":.4}
 if (c.x+c.z)%4==0:return {"tin_ore":1.2,"quartz":.2}
 if (c.x+c.z)%3==0:return {"copper_ore":1.5}
 return {"copper_ore":.4,"tin_ore":.2,"quartz":.3}
func dig(world: Vector3,normal: Vector3) -> Dictionary:
 var c=cell_at(world-normal*.04)
 if not valid(c) or not occupied(c):return {"ok":false,"reason":"Aim at solid rock within the working face."}
 if c.x==0 or c.x==WIDTH-1 or c.y==0 or c.y==HEIGHT-1 or c.z==DEPTH-1:return {"ok":false,"reason":"Dense boundary rock. Work inside the lighter seam."}
 if c.z>=12 and not state.owned.has("final"):return {"ok":false,"reason":"Final seam lease: finish the gear and polished-stone orders."}
 if not state.can_load_ore():return {"ok":false,"reason":"Carrier full. Return your load; an attached physical barrow carries forty batches."}
 solid.erase(id(c));state.excavated.append(id(c));state.statistics.cells+=1
 var contents=ore(c)
 state.add_ore_batch(id(c),contents)
 rebuild_mesh();revalidate_supports()
 return {"ok":true,"contents":contents,"cell":id(c)}
func rebuild_mesh():
 if is_instance_valid(mesh_node):remove_child(mesh_node);mesh_node.queue_free()
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var directions=[Vector3i(1,0,0),Vector3i(-1,0,0),Vector3i(0,1,0),Vector3i(0,-1,0),Vector3i(0,0,1),Vector3i(0,0,-1)]
 for key in solid:
  var c=coord(key);var center=local_center(c)
  for direction in directions:
   if occupied(c+direction):continue
   var n=Vector3(direction.x,direction.y,-direction.z)
   var u=Vector3.UP.cross(n).normalized() if abs(n.y)<.5 else Vector3.RIGHT
   var v=n.cross(u).normalized()
   var corners=[center+n*CELL*.5-u*CELL*.5-v*CELL*.5,center+n*CELL*.5+u*CELL*.5-v*CELL*.5,center+n*CELL*.5+u*CELL*.5+v*CELL*.5,center+n*CELL*.5-u*CELL*.5+v*CELL*.5]
   var tint=Color(.9,.93,.91) if (c.x+c.y+c.z)%3 else Color(.94,.93,.89)
   if c.x==0 or c.x==WIDTH-1 or c.y==0 or c.y==HEIGHT-1:tint=Color(.46,.53,.54)
   elif c.z>11:tint=Color(.99,.91,.72)
   elif (c.x+c.z)%4==0:tint=Color(.72,.79,.78)
   for i in [0,2,1,0,3,2]:
    st.set_normal(n);st.set_color(tint);st.set_uv(Vector2(corners[i].x+corners[i].z,corners[i].y));st.add_vertex(corners[i])
 mesh_node=MeshInstance3D.new();mesh_node.name="ExcavatedRock";mesh_node.mesh=st.commit();mesh_node.material_override=stone;add_child(mesh_node);mesh_node.create_trimesh_collision()
func support_check(center: Vector3, width: float=2.4) -> String:
 var local=to_local(center)
 if abs(local.y-CELL)>.15:return "Both feet must rest on the solid mine floor."
 var c=cell_at(center+Vector3(0,.08,0))
 if not valid(c):return "Place a frame inside the working face."
 var half=width*.5
 for dx in [-half,half]:
  var foot=cell_at(center+Vector3(dx,-.12,0))
  if not occupied(foot):return "A frame foot has no firm ground."
  var side=cell_at(center+Vector3(dx+signf(dx)*.24,1.2,0))
  if not occupied(side):return "Walls are too far away for this frame. Use a narrower working span."
 for y in [.35,1.2,2.0]:
  for dx in [-half+.12,0.0,half-.12]:
   if occupied(cell_at(center+Vector3(dx,y,0))):return "Rock blocks the frame. Excavate its full opening."
 var roof=cell_at(center+Vector3(0,2.48,0))
 if not occupied(roof):return "Crossbeam needs rock overhead. No floating frames."
 for existing in state.supports:
  if Vector3(existing.x,existing.y,existing.z).distance_to(center)<.9:return "Another frame already occupies this position."
 return ""
func place_support(center: Vector3) -> String:
 var reason=support_check(center)
 if not reason.is_empty():return reason
 if state.stock.timber<1:return "Need timber. Four timbers cost C 6 at camp."
 state.stock.timber-=1
 state.supports.append({"x":center.x,"y":center.y,"z":center.z,"width":2.4,"valid":true,"lagged":false})
 rebuild_supports();return "Frame installed. Coverage is local; widening can expose fresh risk."
func support_contact(s: Dictionary) -> bool:
 var center=Vector3(s.x,s.y,s.z)
 return occupied(cell_at(center+Vector3(-1.2,-.12,0))) and occupied(cell_at(center+Vector3(1.2,-.12,0))) and occupied(cell_at(center+Vector3(0,2.48,0))) and occupied(cell_at(center+Vector3(-1.44,1.2,0))) and occupied(cell_at(center+Vector3(1.44,1.2,0)))
func revalidate_supports():
 for s in state.supports:s.valid=support_contact(s)
func covered(world: Vector3) -> bool:
 for s in state.supports:
  if not s.valid:continue
  var c=Vector3(s.x,s.y,s.z)
  if absf(world.x-c.x)<1.26 and absf(world.z-c.z)<(1.2 if s.lagged else .65):return true
 return false
func beam(at: Vector3,size: Vector3,parent: Node3D):
 var mesh=BoxMesh.new();mesh.size=size
 var body=MeshInstance3D.new();body.mesh=mesh;body.position=at;body.material_override=timber;parent.add_child(body);body.create_trimesh_collision()
func rebuild_supports():
 for child in frames.get_children():frames.remove_child(child);child.queue_free()
 for s in state.supports:
  var c=to_local(Vector3(s.x,s.y,s.z));var root=Node3D.new();frames.add_child(root)
  for dx in [-1.2,1.2]:beam(c+Vector3(dx,1.15,0),Vector3(.16,2.3,.18),root)
  beam(c+Vector3(0,2.35,0),Vector3(2.56,.18,.2),root)
  for side in [-1,1]:
   var brace_mesh=BoxMesh.new();brace_mesh.size=Vector3(.10,.55,.12)
   var brace=MeshInstance3D.new();brace.mesh=brace_mesh;brace.material_override=timber;brace.position=c+Vector3(side*.98,2.10,0);brace.rotation.z=side*PI/4;root.add_child(brace)
  var iron=StandardMaterial3D.new();iron.albedo_color=Color(.12,.14,.13) if s.valid else Color(.65,.22,.08);iron.metallic=.7;iron.roughness=.5
  for side in [-1,1]:
   var plate=BoxMesh.new();plate.size=Vector3(.24,.34,.025)
   var join=MeshInstance3D.new();join.mesh=plate;join.position=c+Vector3(side*1.16,2.15,.115);join.material_override=iron;root.add_child(join)
   for offset in [-.09,.09]:
    var bolt=CylinderMesh.new();bolt.top_radius=.025;bolt.bottom_radius=.025;bolt.height=.028;bolt.radial_segments=6
    var head=MeshInstance3D.new();head.mesh=bolt;head.rotation.x=PI/2;head.position=join.position+Vector3(0,offset,.026);head.material_override=iron;root.add_child(head)
  if s.lagged:
   for dz in [-.7,-.35,0,.35,.7]:beam(c+Vector3(0,2.46,dz),Vector3(2.48,.06,.25),root)
  var light=OmniLight3D.new();light.position=c+Vector3(.92,1.95,0);light.light_color=Color("ffbf71");light.light_energy=.65;light.omni_range=4.5;root.add_child(light)
  var housing=CylinderMesh.new();housing.top_radius=.075;housing.bottom_radius=.075;housing.height=.18;housing.radial_segments=12
  var lantern=MeshInstance3D.new();lantern.mesh=housing;lantern.position=light.position;root.add_child(lantern)
  var amber=StandardMaterial3D.new();amber.albedo_color=Color("ffbc62");amber.emission_enabled=true;amber.emission=Color("ffb04b");amber.emission_energy_multiplier=.7;lantern.material_override=amber
  for offset in [-.11,.11]:
   var cap=CylinderMesh.new();cap.top_radius=.084;cap.bottom_radius=.084;cap.height=.025;cap.radial_segments=12
   var rim=MeshInstance3D.new();rim.mesh=cap;rim.position=light.position+Vector3(0,offset,0);rim.material_override=iron;root.add_child(rim)
  for side in [-1,1]:
   for front in [-1,1]:
    var guard=CylinderMesh.new();guard.top_radius=.005;guard.bottom_radius=.005;guard.height=.22;guard.radial_segments=6
    var bar=MeshInstance3D.new();bar.mesh=guard;bar.position=light.position+Vector3(side*.055,0,front*.055);bar.material_override=iron;root.add_child(bar)
func lag_nearest(world: Vector3) -> String:
 for s in state.supports:
  if Vector3(s.x,s.y,s.z).distance_to(world)<3 and not s.lagged:
   if state.stock.timber<1:return "Need one timber for lagging."
   state.stock.timber-=1;s.lagged=true;rebuild_supports();return "Roof lagging fitted; coverage extends along the frame."
 return "Stand near an unlagged frame."
func remove_nearest(world: Vector3,confirmed=false) -> String:
 for i in state.supports.size():
  var s=state.supports[i]
  if Vector3(s.x,s.y,s.z).distance_to(world)<3:
   if not confirmed:return "Removing a loaded frame can expose unstable roof. Press X again to confirm."
   state.supports.remove_at(i);state.stock.timber+=1;rebuild_supports();return "Frame removed. Check the roof warning."
 return "No frame close enough."
func unsupported_span(c: Vector3i) -> int:
 var span=0
 for dx in range(-2,3):
  var q=c+Vector3i(dx,0,0)
  if valid(q) and not occupied(q):span+=1
 return span
func tick(delta: float,world: Vector3) -> Dictionary:
 update_clock+=delta
 if update_clock<.5:return last_status
 var step=update_clock;update_clock=0
 var worst=0.0;var risky=""
 for key in state.excavated:
  var c=coord(key)
  if c.y!=3 or occupied(c-Vector3i(0,1,0)) or not occupied(c+Vector3i(0,1,0)):continue
  var center=to_global(local_center(c))
  if covered(center):state.instability[key]=0;continue
  var span=unsupported_span(c)
  if span<2:continue
  var age=float(state.instability.get(key,0))+step*(.7 if span==2 else 1.2)
  state.instability[key]=age
  if age>worst:worst=age;risky=key
 if worst>22 and not risky.is_empty():
  var c=coord(risky);var point=to_global(local_center(c))
  # Falls only drop a small clearable obstruction, never replace excavation or delete rewards.
  if point.distance_to(world)>1.2 and not state.rubble.has(risky):
   state.rubble.append(risky);state.statistics.falls+=1;state.instability[risky]=0;rebuild_rubble();fall_particles(point);message.call("A small roof fall. E clears rubble; your finds are safe.",6)
 if worst>12:last_status={"state":"FAILING — clear the area / add frame","risk":worst}
 elif worst>3:last_status={"state":"STRAINED — unsupported roof","risk":worst}
 else:last_status={"state":"stable","risk":worst}
 rebuild_cracks()
 return last_status
func rebuild_cracks():
 var wanted=[]
 for key in state.instability:
  if state.instability[key]>3 and not covered(to_global(local_center(coord(key)))):wanted.append(key)
 var signature="|".join(wanted)
 if signature==crack_signature:return
 crack_signature=signature
 for child in cracks.get_children():cracks.remove_child(child);child.queue_free()
 var dark=StandardMaterial3D.new();dark.albedo_color=Color(.045,.055,.04);dark.roughness=1
 for key in wanted:
  var at=local_center(coord(key));at.y=CELL*4-.012
  var rng=RandomNumberGenerator.new();rng.seed=key.hash()
  for i in 4:
   var line=BoxMesh.new();line.size=Vector3(.012,.008,.21)
   var mark=MeshInstance3D.new();mark.mesh=line;mark.position=at+Vector3(rng.randf_range(-.18,.18),0,rng.randf_range(-.18,.18));mark.rotation.y=rng.randf()*TAU;mark.material_override=dark;cracks.add_child(mark)
func fall_particles(world: Vector3):
 var particles=CPUParticles3D.new();particles.position=to_local(world)+Vector3.UP*.2;particles.amount=28;particles.lifetime=1.1;particles.one_shot=true;particles.explosiveness=.9;particles.direction=Vector3.DOWN;particles.spread=65;particles.initial_velocity_min=.4;particles.initial_velocity_max=1.5;particles.gravity=Vector3(0,-5,0)
 particles.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;particles.emission_sphere_radius=.35
 var chip=SphereMesh.new();chip.radius=.035;chip.height=.07;chip.radial_segments=6;chip.rings=3;particles.mesh=chip;particles.material_override=stone;add_child(particles);particles.finished.connect(particles.queue_free);particles.emitting=true
func rebuild_rubble():
 for child in debris.get_children():debris.remove_child(child);child.queue_free()
 for key in state.rubble:
  var c=coord(key);var pos=local_center(c);pos.y=CELL+.25
  var shape=SphereMesh.new();shape.radius=.47;shape.height=.6;shape.radial_segments=7;shape.rings=4
  var body=MeshInstance3D.new();body.mesh=shape;body.position=pos;body.material_override=stone;debris.add_child(body);body.create_trimesh_collision()
func clear_rubble(world: Vector3) -> bool:
 for i in state.rubble.size():
  var c=coord(state.rubble[i]);var pos=to_global(local_center(c));pos.y=global_position.y+CELL+.3
  if pos.distance_to(world)<2.4:state.rubble.remove_at(i);rebuild_rubble();return true
 return false
