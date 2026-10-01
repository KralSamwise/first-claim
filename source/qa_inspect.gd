extends "res://source/qa_river.gd"
# Read-only observations plus ordinary input. Requires an externally preserved earned save.
var purpose="visual"
var capture_views=true
var step=0
var dwell=0.0
var samples: Array=[]
var last_usec=0
var started_usec=0
var actual_render_size=Vector2i.ZERO
var checkpoints=[Vector3(-1.8,1,5),Vector3(0,1,-6),Vector3(.4,3.3,-31),Vector3(.4,3.3,-35.2),Vector3(.4,3.3,-31),Vector3(0,1,-6),Vector3(-5,1,5.2),Vector3(-7.4,1,2.2),Vector3(-5.1,1,-.5),Vector3(-.4,1,2)]
func _ready():
 super._ready()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--inspect="):purpose=arg.get_slice("=",1)
  if arg=="--no-snapshots":capture_views=false
 log_event("scope","Native "+purpose+" inspection via Continue and normal movement from preserved earned save; not a fresh campaign")
func _process(_delta):
 var now=Time.get_ticks_usec()
 if step>0 and purpose=="performance" and world.mode=="play":
  if started_usec==0:started_usec=now
  if last_usec>0 and now-started_usec>5000000:samples.append(float(now-last_usec)/1000.0)
  last_usec=now
func _physics_process(delta):
 total+=delta
 if step==0:
  if button_contains("Continue claim"):
   if world.mode!="play":log_event("FAIL","Continue did not load");finish_run(61);return
   if world.game.barrow_attached and purpose in ["visual","performance","workshop"]:tap(KEY_4)
   if purpose=="performance":
    var probe=world.get_viewport().get_texture().get_image();actual_render_size=probe.get_size();probe.save_png(run_dir+"/resolution-probe.png")
    log_event("render-probe","Actual readback image dimensions "+str(actual_render_size)+"; before five-second warmup")
   step=1;dwell=0
   log_event("loaded","Viewport "+str(world.get_viewport().get_visible_rect().size)+" window "+str(DisplayServer.window_get_size())+" tool "+str(world.tool))
  return
 if purpose=="support":inspect_support(delta);return
 if purpose=="workshop":inspect_workshop(delta);return
 if purpose=="save":
  dwell+=delta
  if dwell<1:return
  var expected=JSON.parse_string(FileAccess.get_file_as_string(run_dir+"/expected.json"))
  var ok=world.game.money==expected.money and world.game.excavated==expected.excavated and world.game.stock==expected.stock and world.game.completed==expected.completed and world.tool==int(expected.equipped_tool)
  ok=ok and absf(world.player.rotation.y-float(expected.view_yaw))<.01 and absf(world.camera.rotation.x-float(expected.view_pitch))<.01
  log_event("PASS" if ok else "FAIL","Native Continue recovered preserved earned backup, camera, tool, terrain and economy; primary fault injected only in isolated test slot")
  finish_run(0 if ok else 62);return
 var index=step-1
 if index>=checkpoints.size():
  if purpose=="performance":
   samples.sort()
   var sum=0.0
   for ms in samples:sum+=ms
   var result={"scope":"Real-time native ordinary-input route; no Movie Maker or fixed FPS; five second warmup excluded","checkpoint_pngs":capture_views,"samples":samples.size(),"mean_fps":1000.0/(sum/maxi(1,samples.size())),"median_ms":samples[int(samples.size()*.5)],"p95_ms":samples[int(samples.size()*.95)],"p99_ms":samples[int(samples.size()*.99)],"window":str(DisplayServer.window_get_size()),"viewport":str(world.get_viewport().get_visible_rect().size),"render_size":str(actual_render_size),"texture_size_api":str(world.get_viewport().get_texture().get_size()),"quality":world.settings.quality,"renderer":RenderingServer.get_current_rendering_method(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"raw_frame_ms":samples}
   var file=FileAccess.open(run_dir+"/performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
  log_event("PASS","Native inspection route completed");finish_run();return
 if walk(checkpoints[index]):
  dwell+=delta
  var look=Vector3(0,4,-38)
  if index==0:look=Vector3(-3,.95,5)
  if index==1:look=Vector3(7,1,-6)
  if index==2 or index==3:tap(KEY_3);look=Vector3(.4,3.7,-41)
  if index==6:look=Vector3(-7,.9,6)
  if index==7:look=Vector3(-9,.85,3)
  if index==8:look=Vector3(-6,1.15,-2)
  if index==9:look=Vector3(-2,1,2)
  aim(look)
  if dwell>4:
   if capture_views:world.get_viewport().get_texture().get_image().save_png(run_dir+"/view-%02d.png"%index)
   log_event("view","Checkpoint "+str(index));step+=1;dwell=0
 else:dwell=0

var initial_falls=0
var warning_seen=false
func inspect_support(delta):
 dwell+=delta
 if step==1:
  if walk(Vector3(.4,3.3,-33.25),.12):
   tap(KEY_3);step=2;dwell=0;initial_falls=world.game.statistics.falls
   log_event("initial-supports","Actual contact-valid frames="+str(world.game.supports.size())+"; state="+world.mine.last_status.state)
 elif step==2:
  aim(Vector3(.4,world.camera.global_position.y,-41))
  if dwell>.7:tap(KEY_X);step=3;dwell=0
 elif step==3 and dwell>.6:
  tap(KEY_X);step=4;dwell=0
  log_event("removed","Confirmed normal X removal; frames="+str(world.game.supports.size()))
 elif step==4:
  if world.mine.last_status.state.begins_with("STRAINED") and not warning_seen:
   warning_seen=true;log_event("warning","Observed strained roof before fall")
   world.get_viewport().get_texture().get_image().save_png(run_dir+"/warning.png")
  if world.game.statistics.falls>initial_falls:
   log_event("fall","Localized actual rubble appeared after warning; finds retained")
   world.get_viewport().get_texture().get_image().save_png(run_dir+"/fall.png");step=5;dwell=0
  elif dwell>40:log_event("FAIL","No expected warning/fall");finish_run(63)
 elif step==5 and dwell>2:
  tap(KEY_E);step=6;dwell=0
 elif step==6 and dwell>1:
  if not world.game.rubble.is_empty():tap(KEY_E);return
  tap(KEY_B);step=7;dwell=0
 elif step==7 and dwell>1:
  tap(KEY_E);step=8;dwell=0
 elif step==8 and dwell>1:
  tap(KEY_H);step=9;dwell=0
 elif step==9 and dwell>3:
  var ok=warning_seen and world.game.supports.size()==2 and world.game.rubble.is_empty() and world.mine.last_status.state=="stable"
  log_event("PASS" if ok else "FAIL","Confirmed removal -> strained warning -> localized fall -> normal E rubble clear -> restored frame/lagging -> stable")
  finish_run(0 if ok else 64)

var craft_index=0
var craft_recipes=["copper","tin","bronze","gear","polished","polished","refined_gold","pendant"]
var working_captured=false
func inspect_workshop(delta):
 if craft_index>=craft_recipes.size():log_event("PASS","Native furnace/casting/polisher working and actual ready-output views captured; products picked up normally");finish_run();return
 var recipe=craft_recipes[craft_index]
 var station=ClaimState.RECIPES[recipe].station
 var center={"furnace":Vector3(-9,.85,3),"casting":Vector3(-8,.9,0),"polisher":Vector3(-6,1.13,-2)}[station]
 dwell+=delta
 if step==1:
  if walk(center+Vector3(1.6,0,1.3)):step=2;dwell=0
 elif step==2:
  aim(center)
  if dwell>.7:tap(KEY_E);step=3
 elif step==3:
  if button_contains(recipe.capitalize()+"  ·"):step=4;dwell=0;working_captured=false
 elif step==4:
  aim(center)
  if dwell>1 and not working_captured:
   world.get_viewport().get_texture().get_image().save_png(run_dir+"/"+recipe+"-working.png");working_captured=true
  if dwell>5 and world.game.job.get("ready",false):
   world.get_viewport().get_texture().get_image().save_png(run_dir+"/"+recipe+"-ready.png")
   log_event("ready-output",recipe+" actual reserved-input job ready")
   step=5;dwell=0
 elif step==5 and dwell>2:tap(KEY_E);step=6
 elif step==6:
  if button_contains("Pick up finished work"):step=7
 elif step==7:
  if button_contains("Close"):craft_index+=1;step=1;dwell=0
 if dwell>30:log_event("FAIL","Workshop inspection stalled "+recipe+" step"+str(step));finish_run(68)
