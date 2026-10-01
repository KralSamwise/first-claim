"""Original detector, field/mining tools and transport; shared opening materials."""
exec(open(__file__.replace('model_field.py','model_opening.py')).read().split('entries=[]')[0])
OUT=ROOT/'assets'/'field';OUT.mkdir(exist_ok=True)
entries=[a for a in json.loads((ROOT/'asset-manifest.json').read_text())['assets'] if '/field/' not in a['game_export']]
def grip_hand(origin,cam_dir=1):
 def pad(name,offset,scale,material=glove):
  bpy.ops.mesh.primitive_uv_sphere_add(segments=18,ring_count=10,radius=1,location=Vector(origin)+Vector(offset))
  obj=bpy.context.object;obj.name=name;obj.scale=scale;obj.data.materials.append(material)
  for face in obj.data.polygons:face.use_smooth=True
 pad('gloved palm',(0,.035*cam_dir,0),(.047,.025,.046))
 for j in range(4):
  pad('curled grip finger',(.008,-.007*cam_dir,-.031+j*.021),(.038,.015,.01))
 pad('opposing thumb',(-.038,.012*cam_dir,.022),(.014,.028,.027))
 pad('glove cuff',(0,.09*cam_dir,-.01),(.043,.04,.031),black)
 pad('canvas sleeve',(0,.17*cam_dir,-.02),(.046,.085,.038),canvas)
begin()
# Detector laid in Blender XY; exported Y-up. Shaft runs from coil to grip.
lathe('coil outer hoop',[(.13,-.005),(.155,-.005),(.155,.013),(.13,.013),(.13,-.005)],black,64)
for a in [0,math.pi/2]:rod('coil spoke',(-.13*math.cos(a),-.13*math.sin(a),.003),(.13*math.cos(a),.13*math.sin(a),.003),.011,black)
rod('lower shaft',(0,0,.02),(0,.33,.48),.013,steel)
rod('upper shaft',(0,.30,.45),(0,.82,1.29),.017,olive)
rod('grip',(0,.62,1.07),(0,.62,1.25),.024,black)
box('angled display',(0,.50,1.31),(.14,.09,.065),olive)
box('screen glass',(0,.487,1.35),(.11,.065,.004),glass)
for x in [-.035,0,.035]:cyl('control button',(x,.54,1.35),.006,.003,black,12)
lathe('arm cuff',[(.065,0),(.07,0),(.07,.085),(.065,.085)],olive,32,0,math.pi*1.4)
cuff=bpy.context.scene.objects.get('arm cuff');cuff.location=(0,.84,1.29);cuff.rotation_euler[0]=math.pi/2
vs=[]
for i in range(240):
 t=i/239;vs.append((.022*math.cos(t*math.tau*11),.04+t*.53,.08+t*.88+.022*math.sin(t*math.tau*11)))
curve=bpy.data.curves.new('coil cable','CURVE');curve.dimensions='3D';curve.bevel_depth=.003;curve.bevel_resolution=2
spline=curve.splines.new('POLY');spline.points.add(len(vs)-1)
for point,v in zip(spline.points,vs):point.co=(*v,1)
ob=bpy.data.objects.new('coil cable',curve);bpy.context.collection.objects.link(ob);ob.data.materials.append(black)
grip_hand((0,.62,1.185),1)
save('detector','Metal detector with true coil, cable, grip, cuff and display',{'coil':[0,0,0],'grip':[0,.62,1.185]})
begin()
rod('pick haft',(0,0,0),(0,0,.73),.022,wood)
# Curved tapered pick head.
vs=[];faces=[]
for x,z,w in [(-.32,.58,.003),(-.22,.70,.013),(0,.74,.032),(.20,.70,.022),(.29,.65,.013)]:
 vs.extend([(x,-w,z-w),(x,w,z-w),(x,w,z+w),(x,-w,z+w)])
for j in range(4):
 for k in range(4):a=j*4+k;b=j*4+(k+1)%4;faces.append((a,b,b+4,a+4))
faces.extend([(0,3,2,1),(16,17,18,19)]);bevel(mesh('forged pick',vs,faces,steel),.004)
grip_hand((0,0,.26),-1)
save('pickaxe','Rock cutting tool',{'grip':[0,0,.25],'strike':[-.3,0,.6]})
begin()
rod('trowel handle',(0,.05,0),(0,.23,.03),.021,wood)
bevel(mesh('trowel blade',[(-.05,.06,0),(.05,.06,0),(.065,-.07,0),(0,-.17,.025),(-.065,-.07,0),(-.05,.06,-.004),(.05,.06,-.004),(.065,-.07,-.004),(0,-.17,.021),(-.065,-.07,-.004)],[(0,1,2,3,4),(9,8,7,6,5),(0,5,6,1),(1,6,7,2),(2,7,8,3),(3,8,9,4),(4,9,5,0)],steel),.002)
grip_hand((0,.15,.025),1)
save('trowel','Shallow target excavation',{'grip':[0,.15,0]})
begin()
# Wheelbarrow sheet metal tray, frame and a rotating wheel component.
verts=[(-.34,-.40,.5),(.34,-.40,.5),(.29,.39,.5),(-.29,.39,.5),(-.47,-.47,.77),(.47,-.47,.77),(.39,.47,.77),(-.39,.47,.77)]
faces=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
o=mesh('barrow tray',verts,faces,olive);sol=o.modifiers.new('sheet thickness','SOLIDIFY');sol.thickness=.012;bevel(o,.025)
for side in [-1,1]:
 rod('handle rail',(side*.3,-.52,.40),(side*.4,1.13,.57),.025,steel)
 rod('rubber handle',(side*.4,.93,.55),(side*.4,1.16,.58),.035,black)
 rod('standing leg',(side*.31,.38,.48),(side*.31,.45,.07),.022,steel)
wheel=cyl('wheel',(0,-.56,.25),.25,.13,black,40);wheel.rotation_euler[1]=math.pi/2
axle=rod('axle',(-.35,-.56,.25),(.35,-.56,.25),.021,steel)
save('barrow','Physical width transport upgrade',{'handles':[0,1.1,.58],'load':[0,0,.6]})
begin()
rod('hammer ash haft',(0,0,0),(0,0,.34),.02,wood)
box('forged hammer head',(0,0,.355),(.20,.072,.065),steel)
cyl('striking face',(.103,0,.355),.037,.014,steel,24).rotation_euler[1]=math.pi/2
box('handle wedge',(0,0,.393),(.037,.034,.008),black)
grip_hand((0,0,.135),-1)
save('support_hammer','Held timber assembly and lagging hammer',{'grip':[0,0,.135],'strike':[.1,0,.355]})
for a in entries:
 if '/field/' in a['game_export']:a['stage']='detector/mine'
(ROOT/'asset-manifest.json').write_text(json.dumps({'schema':1,'assets':entries},indent=2))
print('FIELD_BATCH_EXPORTED')
