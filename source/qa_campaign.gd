extends "res://source/qa_detector.gd"
# Guided full campaign through ordinary input/actions. Uses authored route knowledge.
# Does not change player location, inventory, rewards, terrain or progression directly.
# This is not a human blind playtest and cannot establish first-player duration.
var stage=0
var stage_age=0.0
var route_index=0
var target_route=[2,4,6,8,10,12,13,11,9,7,5,3,1]
var route_sub=0
var campaign_tap=false
var sample_route=0
var mine_depth=0
var mine_x=0
var mine_y=0
var mine_phase=0
var phase_wait=0.0
var build_width=1
var mining_waypoint=Vector3.ZERO
var station_recipe=""
var recipe_route=["copper","copper","copper","tin","tin","bronze","bronze","bronze","gear","gear","gear","polished","polished","polished","polished"]
var recipe_index=0
var station_phase=0
var final_mining=false
var begin_position=Vector3.ZERO
var check_clearance=false
var last_capture=0
var purchase_index=0
var contract_action_index=0
var reload_step=0
var reload_expected={}
var reload_mesh_faces=0
var reload_wait=0
var workshop_reload_done=false
var resume_stage=-1
var is_continuation=false
var support_action=0
var fine_recovery_phase=0
var fine_before={}
var fine_after={}
func _ready():
 super._ready()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--qa-resume="):resume_stage=int(arg.get_slice("=",1))
 is_continuation=resume_stage>=0
 log_event("start",("GUIDED earned-save continuation" if resume_stage>=0 else "GUIDED fresh campaign")+" through standard input. Authored route knowledge; no state mutation or teleport. Not human duration.")
 if resume_stage>=0:log_event("resume-request","Debug continuation via normal Continue button from preserved earned save; not a fresh campaign proof. Stage "+str(resume_stage))
func finish_detector(ok: bool):
 if not ok:finish_run(8);return
 phase=18;stage=0;stage_age=0;campaign_tap=false
 log_event("milestone","Fresh river and detector route complete; continue uphill progression")
func advance(label_:String):
 log_event("campaign-stage",label_);stage+=1;stage_age=0;phase_wait=0;campaign_tap=false;route_sub=0;station_phase=0
 world.get_viewport().get_texture().get_image().save_png(run_dir+"/campaign-stage-%02d.png"%stage)
func single_interact():
 if not campaign_tap:tap(KEY_E);campaign_tap=true
func reset_tap():campaign_tap=false;phase_wait=0
func _physics_process(delta):
 if resume_stage>=0:
  total+=delta
  if world.mode=="title":button_contains("Continue claim")
  elif world.mode=="play" and button_contains("Continue claim"):
   phase=18;stage=resume_stage;resume_stage=-1
   if stage==26:mine_depth=4;route_sub=12 if world.game.can_load_ore() else 10;final_mining=true;tap(KEY_3)
   log_event("resume-loaded","Loaded earned world through normal title control")
  return
 if phase<18:super._physics_process(delta);return
 total+=delta;stage_age+=delta;phase_wait+=delta;status_age+=delta
 if status_age>8:
  status_age=0;log_event("heartbeat","stage%d route%d sub%d depth%d cut%d,%d"%[stage,route_index,route_sub,mine_depth,mine_x,mine_y])
 if total>1500:log_event("FAIL","Full-route bounded timeout");finish_run(20);return
 match stage:
  0:gather_targets()
  1:
   tap(KEY_1)
   if route_sub==0:
    if walk(Vector3(12,1,6)):route_sub=1
   elif walk(Vector3(-1.3,1,5.8)):advance("Returned earned detector load to camp")
  2:sell_all()
  3:sample_hill()
  4:
   if walk(Vector3(-3.4,1,2.2)):advance("Returned three distinct samples")
  5:buy_workshop()
  6:
   if route_sub==0:
    if walk(Vector3(0,1,2)):route_sub=1
   elif route_sub==1:
    if walk(Vector3(0,1,8.6)):route_sub=2
   elif walk(Vector3(-4,1,8.6)):advance("Walked around camp bench to physical barrow handles")
  7:
   aim(world.barrow.position+Vector3.UP)
   if stage_age>.6 and not campaign_tap:tap(KEY_4);campaign_tap=true
   if world.game.barrow_attached:
    tap(KEY_3);advance("Attached real barrow; width stays active with pick equipped")
  8:
   if route_sub==0:
    if walk(Vector3(0,1,8)):route_sub=1
   elif walk(Vector3(.4,3.3,-31.6)):advance("Pushed barrow up actual hillside approach")
  9:
   if route_sub==0:
    if walk(Vector3(2.8,3.3,-31.5)):route_sub=1;reset_tap()
   elif route_sub==1:
    aim(Vector3(2.8,3.3,-36))
    if phase_wait>.6 and not campaign_tap:tap(KEY_4);campaign_tap=true
    if campaign_tap and not world.game.barrow_attached:route_sub=2;reset_tap()
   elif walk(Vector3(.4,3.3,-32.5)):
    build_width=1;mine_depth=0;mine_x=0;mine_y=0;advance("Parked barrow beside entrance and walked to clear working face")
  10:cut_narrow(delta)
  11:
   if walk(Vector3(.4,3.3,-34.4)):advance("Player walked into actual newly excavated narrow corridor")
  12:
   if walk(Vector3(2.8,3.3,-31.5)):advance("Returned to parked transport")
  13:
   aim(world.barrow.position+Vector3.UP)
   if route_sub==0 and stage_age>.6:tap(KEY_T);route_sub=1;phase_wait=0
   elif route_sub==1 and phase_wait>.5 and not campaign_tap:tap(KEY_4);campaign_tap=true
   if world.game.barrow_attached:
    if world.game.loaded_batches("barrow")==0:log_event("FAIL","Clearance test barrow is not loaded");finish_run(37);return
    advance("Transferred actual cut material and attached loaded barrow for clearance test")
  14:
   if route_sub==0:
    walk(Vector3(.4,3.3,-34.4))
    if stage_age>3:
     stop_move()
     if world.player.position.z< -34:log_event("FAIL","Barrow unexpectedly fit narrow .8m corridor");finish_run(21);return
     log_event("clearance","Barrow blocked at narrow cut; player previously passed")
     route_sub=1;phase_wait=0
   elif route_sub==1:
    key(KEY_S,true)
    if phase_wait>1.3:key(KEY_S,false);route_sub=2
   elif route_sub==2:
    if walk(Vector3(2.8,3.3,-30.0)):route_sub=3;reset_tap()
   elif route_sub==3:
    aim(Vector3(world.player.position.x,world.camera.global_position.y,-40))
    if phase_wait>.7:tap(KEY_4);route_sub=4;reset_tap()
   elif route_sub==4:
    if walk(Vector3(.4,3.3,-29)):
     mine_depth=0;mine_x=0;mine_y=0;advance("Parked barrow facing uphill and walked behind it to the center approach")
  15:cut_section(delta,4)
  16:
   if walk(Vector3(.4,3.3,-34.8)):advance("Walked inside widened section")
  17:install_support()
  18:
   if route_sub==0:
    if walk(Vector3(.4,3.3,-29)):route_sub=1
   elif walk(Vector3(2.8,3.3,-30)):advance("Returned behind parked barrow after support")
  19:
   aim(world.barrow.position+Vector3.UP)
   if stage_age>.6 and not campaign_tap:tap(KEY_4);campaign_tap=true
   if world.game.barrow_attached:advance("Reattached barrow for widened clearance")
  20:
   if route_sub==0:
    if walk(Vector3(.4,3.3,-31)):route_sub=1
   elif route_sub==1:
    if walk(Vector3(.4,3.3,-35.3)):route_sub=2
   elif native_checkpoint("tunnel"):advance("Loaded barrow passes widened supported corridor and native save/title/load reconstructs it")
  21:
   if route_sub==0:
    if walk(Vector3(.4,3.3,-31)):route_sub=1
   elif walk(Vector3(-5,1,5.2)):advance("Brought real transport back to workshop")
  22:screen_load()
  23:craft_route()
  24:deliver_milestones()
  25:
   tap(KEY_3)
   if route_sub==0:
    if walk(Vector3(.4,3.3,-31)):route_sub=1
   elif walk(Vector3(.4,3.3,-35.2)):mine_depth=4;mine_x=0;mine_y=0;final_mining=true;advance("Returned to working face under final seam lease")
  26:cut_section(delta,14)
  27:
   if route_sub==0:
    if walk(Vector3(.4,3.3,-31)):route_sub=1
   elif walk(Vector3(-5,1,5.2)):advance("Returned guaranteed final vein material to workshop")
  28:screen_load()
  29:
   recipe_route=["polished","polished","refined_gold","refined_gold","pendant"];recipe_index=0;advance("Prepare signature gold/quartz recipe")
  30:craft_route()
  31:deliver_signature()
  32:
   if stage_age>3 and button_contains("Keep prospecting"):advance("Completion summary offers continued normal play")
  33:
   if stage_age>.5 and not campaign_tap:tap(KEY_ESCAPE);campaign_tap=true
   if (world.mode=="pause" or pending_button_label=="Save and title") and button_contains("Save and title"):advance("Saved completed world and returned to title")
  34:
   if stage_age>.8 and button_contains("Continue claim"):advance("Loaded completed campaign")
  35:
   if stage_age>2:
    var ok=world.game.completed and world.game.stock.specimen==1 and world.game.excavated.size()>0 and world.game.contracts.signature.paid
    log_event("PASS" if ok else "FAIL",("GUIDED earned-save ending continuation" if is_continuation else "GUIDED fresh full campaign")+" and completion reload; %.1f simulated minutes for this run only. Not a blind human duration."%(total/60))
    world.get_viewport().get_texture().get_image().save_png(run_dir+"/campaign-complete.png")
    finish_run(0 if ok else 30)
func gather_targets():
 if route_index>=target_route.size():advance("Completed authored bank search route with persistent recoveries");return
 var id_=target_route[route_index]
 var z=4.0-id_*2.0;var x=world.river_x(z)+(-4.4 if id_%2==0 else 4.3)
 if id_==7:x+=2
 if world.game.depleted.has(id_):route_index+=1;route_sub=0;campaign_tap=false;return
 if route_sub==0:
  # Keep the approach on its open bank; cross above the boulder cluster.
  var approach=Vector3(x,1,z+1.25)
  if route_index==6 and world.player.position.x<6:approach=Vector3(12,1,-24)
  if walk(approach):route_sub=1;reset_tap()
 elif route_sub==1:
  var pinpoint=Vector3(x+1.2,1,z+1.0) if id_==7 else Vector3(x-.28,1,z+1.35)
  if walk(pinpoint,.12):route_sub=2;reset_tap()
 else:
  aim(Vector3(x if id_==7 else world.player.position.x,world.camera.global_position.y,z if id_==7 else z-2))
  if phase_wait>.6:single_interact()
  if phase_wait>4 and not world.game.depleted.has(id_):log_event("FAIL","Authored target approach failed id%d"%id_);finish_run(31)
func sell_all():
 if pending_button_label=="Close":
  if button_contains("Close"):advance("Explicitly sold recovered raw detector materials")
  return
 if world.mode=="play":
  aim(Vector3(-3,1,5))
  if world.active_point.get("type","")=="sell":single_interact()
  return
 if world.mode=="sell":
  if button_contains("Sell "):return
  if button_contains("Close"):advance("Explicitly sold recovered raw detector materials")
func sample_hill():
 if sample_route>=3:advance("Sampled each distinct uphill quartz exposure");return
 var p=Vector3(-.6+float(sample_route%2),1,-15-sample_route*7)
 if route_sub==0:
  if walk(p+Vector3(0,0,1)):route_sub=1;reset_tap()
 else:
  aim(p+Vector3.UP)
  if phase_wait>.5:single_interact()
  if world.game.samples.has(sample_route):sample_route+=1;route_sub=0;reset_tap()
func buy_workshop():
 if route_sub==0:
  if world.mode=="play":
   aim(Vector3(-5,1.1,1))
   if world.active_point.get("type","")=="board":single_interact()
  if world.mode=="board":route_sub=1
 elif route_sub==1:
  var items=["mining","workshop","barrow","timber"]
  if purchase_index>=items.size():route_sub=2;return
  var item=items[purchase_index]
  if button_contains("Buy "+item):
   if (item!="timber" and not world.game.owned.has(item)) or (item=="timber" and world.game.stock.timber<7):log_event("FAIL","Insufficient earned funds for "+item);finish_run(32);return
   purchase_index+=1
 elif route_sub==2:
  if button_contains("Close"):advance("Bought mining kit, visible workshop and physical barrow using earned funds")

func click_pick(at:Vector3):
 aim(at)
 if phase_wait<.4:return
 var ev=InputEventMouseButton.new();ev.button_index=MOUSE_BUTTON_LEFT;ev.pressed=true;Input.parse_input_event(ev)
 ev=InputEventMouseButton.new();ev.button_index=MOUSE_BUTTON_LEFT;ev.pressed=false;Input.parse_input_event(ev)
 phase_wait=0
func cut_narrow(delta):
 if mine_depth>=2:advance("Cut one-cell-wide physical passage");return
 var c=Vector3i(6,mine_y+1,mine_depth);var key_=world.mine.id(c)
 if world.game.excavated.has(key_):mine_y+=1;phase_wait=0
 if mine_y>=3:mine_y=0;mine_depth+=1;return
 var target=world.mine.to_global(world.mine.local_center(Vector3i(6,mine_y+1,mine_depth)))
 click_pick(target)
func cut_section(delta,until_depth:int):
 if mine_depth>0 and mine_depth%2==0 and mine_depth<=until_depth:
  if not support_completed_section(mine_depth):return
 if mine_depth>=until_depth:advance("Excavated requested section with actual pick/collision");return
 if route_sub>=10 or not world.game.can_load_ore():
  # Return a full physical load through the real corridor and process, then resume.
  if route_sub<10:route_sub=10;reset_tap()
  if route_sub==10:
   if walk(Vector3(.4,3.3,-31)):route_sub=14;reset_tap()
  elif route_sub==14:
   if walk(Vector3(-5,1,5.2)):route_sub=11;reset_tap()
  elif route_sub==11:
   if process_at_sieve():route_sub=12;reset_tap()
  elif route_sub==12:
   if walk(Vector3(.4,3.3,-31)):route_sub=13;reset_tap()
  elif route_sub==13:
   if walk(Vector3(.4,3.3,-32.2-mine_depth*.8)):route_sub=0;reset_tap()
  return
 # Keep the player just behind the current cut, never teleport into it.
 var waypoint=Vector3(.4,3.3,-32.6-mine_depth*.8)
 if Vector2(world.player.position.x-waypoint.x,world.player.position.z-waypoint.z).length()>.6:
  walk(waypoint);return
 stop_move()
 var c=Vector3i(5+mine_x,1+mine_y,mine_depth);var key_=world.mine.id(c)
 if world.game.excavated.has(key_):
  mine_y+=1;phase_wait=0
  if mine_y>=3:mine_y=0;mine_x+=1
  if mine_x>=3:mine_x=0;mine_depth+=1
  return
 click_pick(world.mine.to_global(world.mine.local_center(c)))
func support_completed_section(depth: int) -> bool:
 var center=Vector3(.4,2.4,-34.0-(depth-1.5)*.8)
 for frame in world.game.supports:
  if Vector3(frame.x,frame.y,frame.z).distance_to(center)<.15 and frame.valid and frame.lagged:
   if support_action>0:log_event("support-complete","Ordinary preview/E/H installed valid lagged frame at "+str(center))
   support_action=0;return true
 if support_action==0:
  if walk(center+Vector3(0,.9,1.15),.12):support_action=1;reset_tap()
 elif support_action==1:
  aim(center+Vector3(0,1.4,-4))
  if phase_wait>.6 and not campaign_tap:tap(KEY_B);campaign_tap=true
  if world.placement_mode:support_action=2;reset_tap()
 elif support_action==2:
  if phase_wait>.4:single_interact()
  if campaign_tap and not world.placement_mode:support_action=3;reset_tap()
 elif support_action==3:
  var found=false
  for frame in world.game.supports:
   if Vector3(frame.x,frame.y,frame.z).distance_to(center)<.15 and frame.valid:found=true
  if not found:log_event("FAIL","Frame contact/placement failed at "+str(center)+": "+world.toast);finish_run(45);return false
  tap(KEY_H);support_action=4;phase_wait=0
 elif support_action==4 and phase_wait>1:
  log_event("FAIL","Lagging did not complete: "+world.toast);finish_run(46)
 return false
func install_support():
 if world.game.supports.size()>=2:
  if stage_age<2:return
  var valid=true
  for frame in world.game.supports:valid=valid and frame.valid and frame.lagged
  if not valid or world.mine.last_status.state!="stable":log_event("FAIL","Supported opening did not become stable");finish_run(47);return
  world.game.save_to(run_dir+"/stable-supported-save.json")
  advance("Two contact-valid lagged frames stabilize the widened opening; settled geometry and state verified")
  return
 if route_sub==0:
  aim(Vector3(.4,world.camera.global_position.y,-42))
  if phase_wait>.6 and not campaign_tap:tap(KEY_B);campaign_tap=true;phase_wait=0
  if world.placement_mode:route_sub=1;reset_tap()
 elif route_sub==1:
  if phase_wait>1:single_interact()
  if not world.placement_mode:
   if world.game.supports.size()==0:log_event("FAIL","Ordinary frame placement refused: "+world.toast);finish_run(33);return
   tap(KEY_H);advance("Installed contact-valid physical frame and lagging via preview")
func process_at_sieve() -> bool:
 if pending_button_label=="Close":return button_contains("Close")
 if world.mode=="play":
  aim(Vector3(-7,1,6))
  if world.active_point.get("type","")=="station":single_interact()
  return false
 if world.mode=="station":
  if button_contains("Screen batch"):return false
  if world.game.owned.has("fine_screen") and fine_recovery_phase<3:
   if fine_recovery_phase==0:
    if fine_before.is_empty():fine_before=world.game.stock.duplicate(true)
    if button_contains("Recover all labeled fine tailings"):fine_recovery_phase=1;phase_wait=0
   elif fine_recovery_phase==1 and phase_wait>.5:
    if fine_after.is_empty():
     fine_after=world.game.stock.duplicate(true)
     log_event("fine-screen-recovery","Same preserved source tailings: before "+JSON.stringify(fine_before)+" after "+JSON.stringify(fine_after))
     world.get_viewport().get_texture().get_image().save_png(run_dir+"/fine-screen-recovery.png")
    if button_contains("Recover all labeled fine tailings"):fine_recovery_phase=2;phase_wait=0
   elif fine_recovery_phase==2 and phase_wait>.5:
    if world.game.stock!=fine_after:log_event("FAIL","Fine tailings paid twice");finish_run(65);return false
    log_event("PASS","Improved screen recovered finite held fines; repeated input paid nothing")
    fine_recovery_phase=3
   return false
  if button_contains("Close"):return true
 return false
func screen_load():
 if process_at_sieve():advance("Screened source-labeled carried ore at physical workshop")
func craft_route():
 if recipe_index>=recipe_route.size():advance("Completed recipe chain with reserved inputs and physical output pickups");return
 var recipe=recipe_route[recipe_index];var station=ClaimState.RECIPES[recipe].station
 var pos={"furnace":Vector3(-9,1,3),"casting":Vector3(-8,1,0),"polisher":Vector3(-6,1,-2)}[station]
 if station_phase==0:
  if walk(pos+Vector3(1.6,0,1.3)):station_phase=1;reset_tap()
 elif station_phase==1:
  aim(pos)
  if phase_wait>.5:single_interact()
  if world.mode=="station":station_phase=2;reset_tap()
 elif station_phase==2:
  var label=recipe.replace("_"," ").capitalize()+"  ·"
  if button_contains(label):
   if world.game.job.is_empty():log_event("FAIL","Recipe ingredients missing: "+recipe);finish_run(34);return
   station_phase=3;reset_tap()
 elif station_phase==3:
  if not workshop_reload_done:
   if native_checkpoint("workshop"):workshop_reload_done=true
   return
  if world.game.job.get("ready",false):station_phase=4;reset_tap()
 elif station_phase==4:
  aim(pos)
  if phase_wait>.5:single_interact()
  if world.mode=="station":station_phase=5
 elif station_phase==5:
  if button_contains("Pick up finished"):station_phase=6
 elif station_phase==6:
  if button_contains("Close"):recipe_index+=1;station_phase=0;reset_tap()
func deliver_milestones():
 if route_sub==0:
  if walk(Vector3(-3.4,1,2.2)):route_sub=1;reset_tap()
 elif route_sub==1:
  aim(Vector3(-5,1.1,1))
  if world.active_point.get("type","")=="board":single_interact()
  if world.mode=="board":route_sub=2
 elif route_sub==2:
  if button_contains("Custom orders"):route_sub=3
 elif route_sub==3:
  var actions=["Accept Millwright","Deliver Millwright","Accept Valley","Deliver Valley"]
  if pending_button_label.is_empty():
   if contract_action_index<2 and world.game.contracts.get("gears",{}).get("paid",false):contract_action_index=2
   if contract_action_index<4 and world.game.contracts.get("stones",{}).get("paid",false):contract_action_index=4
  if contract_action_index<actions.size():
   if button_contains(actions[contract_action_index]):
    if contract_action_index==1 and not world.game.contracts.get("gears",{}).get("paid",false):log_event("FAIL","Gear delivery requirements not met");finish_run(35);return
    if contract_action_index==3 and not world.game.contracts.get("stones",{}).get("paid",false):log_event("FAIL","Stone delivery requirements not met");finish_run(35);return
    contract_action_index+=1
   return
  if not world.game.owned.has("final"):log_event("FAIL","Milestone lease not unlocked");finish_run(35);return
  # Back has an independent native mouse proof. Leave this nested panel using
  # the game's ordinary Esc control, then reopen the board with E.
  tap(KEY_ESCAPE);route_sub=31
 elif route_sub==31:
  if world.mode=="play":route_sub=30;reset_tap()
 elif route_sub==30:
  aim(Vector3(-5,1.1,1))
  if world.active_point.get("type","")=="board":single_interact()
  if world.mode=="board":route_sub=4;reset_tap()
 elif route_sub==4:
  if not world.game.owned.has("fine_screen") or pending_button_label=="Buy fine screen":
   if button_contains("Buy fine screen"):
    if not world.game.owned.has("fine_screen"):log_event("FAIL","Fine screen purchase unavailable");finish_run(38);return
   return
  route_sub=5
 elif route_sub==5:
  if world.game.stock.timber<15 or pending_button_label=="Buy timber":button_contains("Buy timber");return
  if button_contains("Close"):advance("Both manufactured orders paid once; final seam, fine screen and support supplies ready")

func deliver_signature():
 if route_sub==0:
  if walk(Vector3(-3.4,1,2.2)):route_sub=1;reset_tap()
 elif route_sub==1:
  aim(Vector3(-5,1.1,1))
  if world.active_point.get("type","")=="board":single_interact()
  if world.mode=="board":route_sub=2
 elif route_sub==2:
  if button_contains("Custom orders"):route_sub=3
 elif route_sub==3:
  if button_contains("Accept First Claim"):return
  if button_contains("Deliver First Claim"):
   if world.game.completed:advance("Signature gold/quartz pendant and guaranteed specimen commission fulfilled")
   else:log_event("FAIL","Signature requirements missing");finish_run(36)

func native_checkpoint(kind: String) -> bool:
 if reload_step==0:
  stop_move();reload_expected=world.game.serialize().duplicate(true)
  reload_mesh_faces=world.mine.mesh_node.mesh.get_faces().size()
  world.get_viewport().get_texture().get_image().save_png(run_dir+"/reload-"+kind+"-before.png")
  tap(KEY_ESCAPE);reload_step=1;return false
 if reload_step==1:
  if button_contains("Save and title"):reload_step=2
  return false
 if reload_step==2:
  if button_contains("Continue claim"):reload_step=3;reload_wait=world.ticks
  return false
 if world.ticks-reload_wait<3:return false
 var data=world.game.serialize()
 for key_ in ["excavated","supports","rubble","mine_batches","stock","owned","barrow_attached","equipped_tool"]:
  var before=JSON.stringify(JSON.parse_string(JSON.stringify(reload_expected[key_])))
  var after=JSON.stringify(JSON.parse_string(JSON.stringify(data[key_])))
  if before!=after:
   log_event("FAIL","Native "+kind+" reload mismatch: "+key_);finish_run(40);return false
 if absf(wrapf(data.view_yaw-reload_expected.view_yaw,-PI,PI))>.05 or absf(data.view_pitch-reload_expected.view_pitch)>.05:
  log_event("FAIL","Native camera orientation changed on reload");finish_run(48);return false
 if world.mine.mesh_node.mesh.get_faces().size()!=reload_mesh_faces:
  log_event("FAIL","Native tunnel mesh face count changed on reload");finish_run(41);return false
 if kind=="workshop":
  if world.game.job.is_empty() or world.game.job.recipe!=reload_expected.job.recipe or absf(world.game.job.remaining-reload_expected.job.remaining)>.25:
   log_event("FAIL","Pending station job changed on native reload");finish_run(42);return false
 world.get_viewport().get_texture().get_image().save_png(run_dir+"/reload-"+kind+"-after.png")
 log_event("native-reload","Verified "+kind+" terrain/frames/load/inventory and pending work through actual menu save/title/load")
 reload_step=0;return true
