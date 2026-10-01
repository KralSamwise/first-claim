extends "res://source/qa_river.gd"
var pan_count=0
var pan_stage=0
var action_wait=0.0
var detector_phase=0
var detector_gold_before=0.0
var sample_index=0
var status_age=0.0
var recovery_captured=false
func _ready():
 super._ready()
 log_event("driver","Detector input driver loaded; run start and save lineage define scope.")
func _physics_process(delta):
 if phase<17:super._physics_process(delta);return
 total+=delta;age+=delta;action_wait+=delta;status_age+=delta
 if status_age>5:status_age=0;log_event("heartbeat","detector phase %d / pan stage %d"%[detector_phase,pan_stage])
 if total>240:log_event("FAIL","Detector test timeout");finish_run(3);return
 match detector_phase:
  0:
   if age>.5:
    tap(KEY_1);detector_phase=1;pan_stage=0;tapped=false;log_event("progression","Earn detector through two more pans")
  1:
   extra_pan(delta)
  2:
   if walk(Vector3(-1.3,1,5.8)):detector_phase=3;age=0;tapped=false
  3:
   aim(Vector3(-3,1,5))
   if world.mode=="sell":detector_phase=4
   elif age>.4 and not tapped:tap(KEY_E);tapped=true
  4:
   if button_contains("Sell "):detector_phase=5
  5:
   if button_contains("Close"):detector_phase=6
  6:
   if walk(Vector3(-3.4,1,2.2)):detector_phase=7;age=0;tapped=false
  7:
   aim(Vector3(-5,1.1,1))
   if world.mode=="board":detector_phase=8
   elif age>.4 and not tapped:tap(KEY_E);tapped=true
  8:
   if button_contains("Buy detector"):
    if world.game.owned.has("detector"):log_event("purchase","Detector earned through ordinary pans and sales");detector_phase=9
    else:log_event("FAIL","Earned money insufficient for detector");finish_run(4)
  9:
   if button_contains("Close"):tap(KEY_2);detector_phase=10
  10:
   # Walk the exposed bank; stop when actual coil signal appears, then narrow it.
   if walk(Vector3(2.7,1,5.5)):detector_phase=11;age=0
  11:
   var signal_=world.closest_target()
   if not signal_.is_empty():
    log_event("signal","Observed detector signal %.2f"%signal_.signal)
    detector_phase=12
   elif age>1:log_event("FAIL","No signal in authored first search area");finish_run(5)
  12:
   # Normal control route sweeps toward first bank marker; detector distance guards recovery.
   if walk(Vector3(2.83,1,4.85)):
    aim(Vector3(2.83,1.65,2.0));detector_phase=13;age=0;tapped=false;detector_gold_before=world.game.stock.gold
  13:
   if world.game.statistics.targets>0:
    log_event("target","Localized and dug persistent shallow target through E input")
    world.get_viewport().get_texture().get_image().save_png(run_dir+"/detector-found.png")
    detector_phase=14;age=0;tapped=false
   elif age>.5 and not tapped:tap(KEY_E);tapped=true
   elif age>3:log_event("FAIL","Target not within localization radius");finish_run(6)
  14:
   if age>.12 and not recovery_captured:
    world.get_viewport().get_texture().get_image().save_png(run_dir+"/trowel-recovery.png");recovery_captured=true
   if age>.4 and not tapped:tap(KEY_E);tapped=true
   if age>1:
    if world.game.statistics.targets!=1:log_event("FAIL","Second dig duplicated target");finish_run(7);return
    tap(KEY_ESCAPE);detector_phase=15
  15:
   if button_contains("Save and title"):detector_phase=16
  16:
   if button_contains("Continue claim"):detector_phase=17;age=0;tapped=false
  17:
   if age>.5 and not tapped:tap(KEY_E);tapped=true
   if age>1:
    var ok=world.game.depleted.has(0) and world.game.statistics.targets==1
    log_event("PASS" if ok else "FAIL","Detector earned, ordinary sweep/localization/dig, second dig refused before and after title/reload")
    world.get_viewport().get_texture().get_image().save_png(run_dir+"/detector-play-complete.png")
    finish_detector(ok)
func extra_pan(delta):
 match pan_stage:
  0:
   if walk(Vector3(3.6,1,5.8-pan_count*2.3)):pan_stage=1;action_wait=0;tapped=false
  1:
   if not world.game.batch.is_empty():pan_stage=2;action_wait=0;tapped=false
   elif action_wait>.3 and not tapped:tap(KEY_E);tapped=true
  2:
   if world.game.batch.get("water",0)>0:pan_stage=3;action_wait=0;tapped=false
   elif action_wait>.3 and not tapped:tap(KEY_E);tapped=true
  3:
   swirl_age+=delta
   if swirl_age>.22:swirl_age=0;tap(KEY_Q if reverse else KEY_R);reverse=not reverse
   key(KEY_F,true)
   if world.game.batch.get("loose",1)<=.01:key(KEY_F,false);pan_stage=4;action_wait=0;tapped=false
  4:
   if world.game.batch.is_empty():
    pan_count+=1;pan_stage=0
    log_event("pan","Completed additional upgraded pan %d"%pan_count)
    if pan_count>=2:detector_phase=2
   elif action_wait>.3 and not tapped:tap(KEY_E);tapped=true

func finish_detector(ok: bool):
 finish_run(0 if ok else 8)
