"""Original compact workshop kit and finished goods, metre-scaled."""
exec(open(__file__.replace('model_workshop.py','model_opening.py')).read().split('entries=[]')[0])
OUT=ROOT/'assets'/'workshop';OUT.mkdir(exist_ok=True)
entries=[a for a in json.loads((ROOT/'asset-manifest.json').read_text())['assets'] if '/workshop/' not in a['game_export']]
copper=mat('warm copper',(.57,.23,.11),.85,.29)
bronze=mat('cast bronze',(.46,.32,.12),.82,.33)
quartz=mat('polished cloudy quartz',(.69,.81,.8),.2,.17)
ceramic=mat('furnace refractory',(.35,.31,.26),0,.88)
begin()
for x in [-.5,.5]:
 for y in [-.3,.3]:box('screen leg',(x,y,.46),(.065,.065,.92),wood)
for y in [-.34,.34]:box('sieve long rim',(0,y,.91),(1.15,.065,.12),wood)
for x in [-.55,.55]:box('sieve end rim',(x,0,.91),(.065,.68,.12),wood)
for x in range(-10,11):rod('screen wire',(x*.05,-.31,.88),(x*.05,.31,.88),.0025,steel)
for y in range(-6,7):rod('screen wire',(-.52,y*.05,.88),(.52,y*.05,.88),.0025,steel)
box('collection tray',(0,0,.62),(.9,.52,.05),steel)
box('tailings crate',(.77,0,.25),(.4,.5,.5),wood)
save('sieve','Manual screening station with source batch and fines output',{'input':[0,0,.96],'output':[0,0,.64]})
begin()
lathe('refractory body',[(0,0),(.36,0),(.36,.68),(.23,.72),(.21,.68),(.21,.18),(0,.18)],ceramic,48)
for i in range(8):
 a=i*math.tau/8;box('brick seam',(.359*math.cos(a),.359*math.sin(a),.3),(.006,.009,.58),black)
lathe('crucible',[(0,.5),(.16,.5),(.18,.76),(.17,.78),(.15,.75),(.13,.54),(0,.54)],steel,48)
rod('pour handle',(.17,0,.68),(.56,0,.68),.015,steel)
box('furnace foot',(0,0,.04),(.9,.8,.08),steel)
save('furnace','Small refinery with crucible and visible pour point',{'pour':[.18,0,.77]})
begin()
box('casting top',(0,0,.82),(1.2,.7,.07),wood)
for x in [-.48,.48]:
 for y in [-.25,.25]:box('leg',(x,y,.4),(.075,.075,.8),wood)
box('mold block',(0,0,.9),(.43,.35,.08),black)
lathe('gear mold cavity',[(.09,.944),(.12,.944),(.12,.957),(.09,.957)],steel,40)
rod('tongs left',(.22,-.1,.88),(.44,.2,.89),.008,steel);rod('tongs right',(.24,-.1,.88),(.4,.2,.89),.008,steel)
save('casting','Casting bench with replaceable gear mold',{'output':[0,0,.98]})
begin()
box('polisher base',(0,0,.09),(.43,.31,.18),olive)
wheel=cyl('polishing wheel',(0,0,.3),.2,.06,black,48);wheel.rotation_euler[0]=math.pi/2
rod('axle',(-.0,-.15,.3),(0,.15,.3),.02,steel)
box('rest',(0,-.23,.19),(.24,.12,.04),steel)
save('polisher','Gem finishing wheel',{'output':[0,-.25,.22]})
begin()
lathe('gear web',[(.024,0),(.093,0),(.093,.018),(.024,.018),(.024,0)],bronze,64)
for i in range(14):
 a=i*math.tau/14;o=box('gear tooth',(.10*math.cos(a),.10*math.sin(a),.009),(.038,.023,.019),bronze);o.rotation_euler[2]=a
save('gear','Finished bronze gear',{'pickup':[0,0,0]})
begin()
lathe('gold pendant bezel',[(.020,0),(.026,0),(.026,.008),(.02,.009),(.02,0)],gold,64)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.022,location=(0,0,.006));o=bpy.context.object;o.name='quartz cabochon';o.scale.z=.45;o.data.materials.append(quartz)
lathe('pendant loop',[(.005,0),(.008,0),(.008,.004),(.005,.004),(.005,0)],gold,32).location=(0,.032,.002)
save('pendant','Signature gold and quartz commission',{'display':[0,0,0]})
begin()
for i in range(7):
 a=i*math.tau/7;h=random.uniform(.09,.22);o=cyl('quartz crystal',(.055*math.cos(a),.055*math.sin(a),h/2),.023,h,quartz,6)
 bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.023,radius2=0,depth=.044,location=(o.location.x,o.location.y,h+.022));bpy.context.object.data.materials.append(quartz)
save('specimen','Guaranteed exceptional vein specimen for display',{'display':[0,0,0]})
tin=mat('bright cast tin',(.47,.51,.54),.86,.28)
for name,metal in [('copper',copper),('tin',tin),('bronze',bronze),('gold',gold)]:
 begin()
 verts=[(-.075,-.033,0),(.075,-.033,0),(.075,.033,0),(-.075,.033,0),(-.06,-.025,.026),(.06,-.025,.026),(.06,.025,.026),(-.06,.025,.026)]
 bevel(mesh('cast '+name+' ingot',verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],metal),.004)
 save('ingot_'+name,'Visible finished '+name+' refinery output',{'pickup':[0,0,.015]})
begin()
bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=1,location=(0,0,.025));o=bpy.context.object;o.name='polished quartz cabochon';o.scale=(.055,.04,.025);o.data.materials.append(quartz)
for face in o.data.polygons:face.use_smooth=True
save('polished_stone','Visible polished quartz output',{'pickup':[0,0,.025]})
begin()
lathe('pouring crucible',[(0,0),(.10,0),(.13,.22),(.12,.235),(.11,.22),(.08,.025),(0,.025)],steel,48)
rod('crucible handle',(.11,0,.12),(.35,0,.12),.014,steel)
save('crucible','Tilting workshop casting vessel',{'pour':[.12,0,.23]})
for a in entries:
 if '/workshop/' in a['game_export']:a['stage']='workshop/ending'
(ROOT/'asset-manifest.json').write_text(json.dumps({'schema':1,'assets':entries},indent=2))
print('WORKSHOP_BATCH_EXPORTED')
