extends Node
# Explicit automated integration play: UI button and ordinary keyboard/mouse inputs only.
# No inventory, progression, position, batch or target state mutation.
var world
var phase=0
var age=0.0
var total=0.0
var swirl_age=0.0
var reverse=false
var tapped=false
var run_dir=""
var log_file
var keys: Dictionary={}
var pending_button_label=""
var pending_button_tick=-1
var pending_button_activated=false
var pointer_misses=0
var pointer_context={}
var pointer_phase=0
var pointer_at=Vector2.ZERO
var hold_button=""
var hold_reported=false
var keyboard_navigation=false
var keyboard_steps=0
var walking_target=Vector3.INF
var walking_best=INF
var walking_progress_tick=0
var last_rubble_input=0
func _ready():
 world=get_parent()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--qa-hold="):hold_button=arg.get_slice("=",1)
 run_dir="res://evidence/runs/"+world.slot
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--evidence-dir="):run_dir=arg.trim_prefix("--evidence-dir=")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(run_dir))
 log_file=FileAccess.open(run_dir+"/actions.jsonl",FileAccess.WRITE)
 log_event("driver","Ordinary keyboard/mouse integration driver; guided authored route, not human play. Run start/lineage defines fresh versus resumed state.")
func log_event(action: String,detail: String):
 log_file.store_line(JSON.stringify({"time":total,"process_frame":Engine.get_process_frames(),"drawn_frame":Engine.get_frames_drawn(),"wall_msec":Time.get_ticks_msec(),"phase":phase,"action":action,"detail":detail,"position":[world.player.position.x,world.player.position.y,world.player.position.z],"money":world.game.money,"gold":world.game.stock.gold}));log_file.flush()
func key(code: int,down: bool):
 if keys.get(code,false)==down:return
 keys[code]=down
 var e=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down;Input.parse_input_event(e)
func tap(code: int):
 if code==KEY_4:log_event("input","4 toggle barrow; before attached="+str(world.game.barrow_attached))
 key(code,true);key(code,false)
func stop_move():
 for code in [KEY_W,KEY_A,KEY_S,KEY_D]:key(code,false)
func aim(point: Vector3):
 var delta=point-world.camera.global_position
 var yaw=atan2(-delta.x,-delta.z)
 var pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
 var e=InputEventMouseMotion.new();e.relative=Vector2(wrapf(world.player.rotation.y-yaw,-PI,PI)/world.settings.sensitivity,(world.camera.rotation.x-pitch)/world.settings.sensitivity);e.relative*=.4*input_scale();Input.parse_input_event(e)
func walk(point: Vector3, tolerance: float=.45) -> bool:
 if world.player.position.z < -30 and world.mode=="play" and not world.placement_mode and Engine.get_physics_frames()-last_rubble_input>30:
  if world.game.barrow_attached or world.player.position.distance_to(world.barrow.position+Vector3.UP)>2.4:
   for rubble_key in world.game.rubble:
    var rubble_at=world.mine.to_global(world.mine.local_center(world.mine.coord(rubble_key)));rubble_at.y=world.mine.global_position.y+.8+.3
    if world.player.position.distance_to(rubble_at)<2.3:
     log_event("rubble-clear-input","E clears nearby fallen rubble through normal interaction: "+rubble_key)
     tap(KEY_E);last_rubble_input=Engine.get_physics_frames();break
 var delta=point-world.player.position;delta.y=0
 if delta.length()<tolerance:stop_move();walking_target=Vector3.INF;return true
 if walking_target.distance_to(point)>.1:
  walking_target=point;walking_best=delta.length();walking_progress_tick=Engine.get_physics_frames()
 if delta.length()<walking_best-.15:
  walking_best=delta.length();walking_progress_tick=Engine.get_physics_frames()
 if Engine.get_physics_frames()-walking_progress_tick>900:
  stop_move()
  var collisions=[]
  for i in world.player.get_slide_collision_count():
   var hit=world.player.get_slide_collision(i)
   collisions.append({"point":str(hit.get_position()),"normal":str(hit.get_normal()),"collider":str(hit.get_collider())})
  log_event("FAIL","Walking stalled for 15 seconds: "+JSON.stringify({"target":str(point),"distance":delta.length(),"mode":world.mode,"yaw":world.player.rotation.y,"collisions":collisions}))
  finish_run(41);return false
 aim(Vector3(point.x,world.camera.global_position.y,point.z));key(KEY_W,true);return false
func input_scale() -> Vector2:
 return Vector2(DisplayServer.window_get_size())/world.get_viewport().get_visible_rect().size
func button_contains(text_: String) -> bool:
 if text_==hold_button:
  if not hold_reported:log_event("manual-hold","Synthetic inputs paused before "+text_+" for independent native pointer test");hold_reported=true
  return false
 if not pending_button_label.is_empty():
  if text_!=pending_button_label:return false
  if world.ticks<=pending_button_tick:return false
  if keyboard_navigation:
   var focused=world.get_viewport().gui_get_focus_owner()
   if focused is Button and text_ in focused.text and focused.is_visible_in_tree() and not focused.disabled:
    log_event("keyboard-button","Normal Tab navigation reached "+focused.text+"; Enter activates")
    tap(KEY_ENTER);keyboard_navigation=false;pending_button_tick=world.ticks;return false
   if keyboard_steps>=20:log_event("FAIL","Keyboard navigation could not reach "+text_);finish_run(44);return false
   tap(KEY_TAB);keyboard_steps+=1;pending_button_tick=world.ticks;return false
  if pointer_phase<2:
   var e=InputEventMouseButton.new();e.position=pointer_at*input_scale();e.global_position=e.position;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pointer_phase==0;e.button_mask=MOUSE_BUTTON_MASK_LEFT if e.pressed else 0
   Input.parse_input_event(e);pointer_phase+=1;pending_button_tick=world.ticks;return false
  if not pending_button_activated:
   if world.ticks-pending_button_tick<4:return false
   log_event("pointer-miss",pending_button_label+" did not emit pressed; retry without advancing")
   pointer_misses+=1
   var hover=world.get_viewport().gui_get_hovered_control()
   var focus=world.get_viewport().gui_get_focus_owner()
   log_event("pointer-diagnostic",JSON.stringify({"context":pointer_context,"hover":str(hover),"hover_text":hover.text if hover is Button else "","focus":focus.text if focus is Button else str(focus),"mouse_mode":Input.mouse_mode,"mouse":str(world.get_viewport().get_mouse_position()),"scroll":world.panel_box.get_parent().scroll_vertical}))
   if pointer_misses>=5:finish_run(43);return false
   if focus is Button and text_ in focus.text and focus.is_visible_in_tree() and not focus.disabled:
    log_event("keyboard-button","Enter activates naturally focused visible control: "+focus.text)
    tap(KEY_ENTER);pending_button_tick=world.ticks;return false
   keyboard_navigation=true;keyboard_steps=0;pending_button_tick=world.ticks;return false
  else:
   var matches=pending_button_label==text_
   pending_button_label=""
   pointer_misses=0
   if matches:return true
 if world.ticks-world.panel_open_tick<3:return false
 for child in world.panel_box.get_children():
  if not child is Button or not text_ in child.text:continue
  if child.disabled or not child.is_visible_in_tree():
   log_event("unavailable-control",child.text);continue
  var scroll=world.panel_box.get_parent() as ScrollContainer
  var rect=child.get_global_rect();var view=scroll.get_global_rect()
  if rect.size.x<20 or rect.size.y<30:return false
  if not view.encloses(rect):
   # Ordinary wheel input reveals the control; never activate a clipped button.
   var e=InputEventMouseButton.new();e.position=view.get_center()*input_scale();e.global_position=e.position;e.button_index=MOUSE_BUTTON_WHEEL_DOWN if rect.get_center().y>view.get_center().y else MOUSE_BUTTON_WHEEL_UP;e.pressed=true;Input.parse_input_event(e)
   return false
  pending_button_label=text_;pending_button_tick=world.ticks;pending_button_activated=false;pointer_phase=0
  child.pressed.connect(func():pending_button_activated=true,CONNECT_ONE_SHOT)
  var at=rect.get_center()
  pointer_at=at
  pointer_context={"label":child.text,"rect":str(rect),"view":str(view),"point":str(at),"viewport":str(world.get_viewport().get_visible_rect())}
  var motion=InputEventMouseMotion.new();motion.position=at*input_scale();motion.global_position=motion.position;Input.parse_input_event(motion)
  log_event("pointer-button",child.text)
  return false
 return false

func next(detail: String):
 log_event("phase-complete",detail);phase+=1;age=0;tapped=false
 var file=run_dir+"/river-phase-%02d.png"%phase
 world.get_viewport().get_texture().get_image().save_png(file)
func _physics_process(delta):
 total+=delta;age+=delta
 if total>160:
  log_event("FAIL","Timed out without completion");finish_run(2);return
 match phase:
  0:
   if age>.6 and button_contains("Start a new"):next("Selected new claim through title button")
  1:
   if walk(Vector3(3.8,1,8.3)):next("Walked from camp to first gravel patch")
  2:
   if age>.3:
    if not world.game.batch.is_empty():next("Scooped real patch")
    elif not tapped:tap(KEY_E);tapped=true
  3:
   if age>.3:
    if world.game.batch.get("water",0)>0:next("Immersed pan")
    elif not tapped:tap(KEY_E);tapped=true
  4:
   swirl_age+=delta
   if swirl_age>.22:
    swirl_age=0;tap(KEY_Q if reverse else KEY_R);reverse=not reverse
   key(KEY_F,true)
   if world.game.batch.get("loose",1)<=.01:key(KEY_F,false);next("Player-controlled wash reached reveal")
  5:
   if age>.5:
    if world.game.stock.gold>0:next("Collected gold into vial")
    elif not tapped:tap(KEY_E);tapped=true
  6:
   if walk(Vector3(-1.3,1,5.8)):next("Returned on foot to camp scale")
  7:
   aim(Vector3(-3,1,5))
   if age>.4 and not tapped:tap(KEY_E);tapped=true
   if world.mode=="sell":next("Opened explicit sale UI")
  8:
   if age>.3 and button_contains("Sell "):next("Sold recovered gold")
  9:
   if age>.4 and button_contains("Close"):next("Closed scale")
  10:
   if walk(Vector3(-3.4,1,2.2)):next("Walked to supply board")
  11:
   aim(Vector3(-5,1.1,1))
   if age>.4 and not tapped:tap(KEY_E);tapped=true
   if world.mode=="board":next("Opened supplies")
  12:
   if not FileAccess.file_exists(run_dir+"/before-classifier.json"):world.game.save_to(run_dir+"/before-classifier.json")
   if age>.4 and button_contains("Buy classifier"):next("Purchased classifier using earned money")
  13:
   if age>.4 and button_contains("Close"):
    tap(KEY_ESCAPE)
    next("Paused after purchase")
  14:
   if age>.4 and button_contains("Save claim"):next("Saved through pause UI")
  15:
   if age>.4 and button_contains("Save and title"):next("Returned to title")
  16:
   if age>.4 and button_contains("Continue claim"):next("Loaded saved claim")
  17:
   if age>1:
    var ok=world.game.owned.has("classifier") and world.game.stock.gold==0 and world.game.batches.size()==1 and world.game.money>=0
    log_event("PASS" if ok else "FAIL","Fresh title -> walk -> scoop -> immerse -> manual wash -> reveal -> collect -> walk -> sale -> upgrade -> save -> load; elapsed %.2fs"%total)
    world.get_viewport().get_texture().get_image().save_png(run_dir+"/river-play-complete.png")
    finish_run(0 if ok else 1)

func finish_run(code: int=0):
 var controls=[]
 for child in world.panel_box.get_children():
  if child is Button:
   var rect=child.get_global_rect()
   controls.append({"text":child.text,"disabled":child.disabled,"visible":child.is_visible_in_tree(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
 var info={"exit_code":code,"simulation_seconds":total,"phase":phase,"mode":world.mode,"panel_title":world.title.text if is_instance_valid(world.title) else "","panel_open_tick":world.panel_open_tick,"tick":world.ticks,"pending_button":pending_button_label,"pending_activated":pending_button_activated,"controls":controls,"player":[world.player.position.x,world.player.position.y,world.player.position.z]}
 var file=FileAccess.open(run_dir+"/exit-diagnostics.json",FileAccess.WRITE);file.store_string(JSON.stringify(info,"  "));file.close()
 world.get_viewport().get_texture().get_image().save_png(run_dir+("/pass.png" if code==0 else "/failure.png"))
 world.game.save_to(run_dir+"/final-save.json")
 get_tree().quit(code)
