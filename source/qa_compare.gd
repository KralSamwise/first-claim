extends "res://source/qa_river.gd"
# Twin exact earned pre-purchase saves; upgrades purchased normally. No stock injection.
var variant="starter"
var step=0
var wait_=0.0
var batch_before={}
var wash_started=0.0
var wash_seconds=0.0
func _ready():
 super._ready()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--compare="):variant=arg.get_slice("=",1)
 log_event("scope","Matched earned-source input comparison: "+variant)
func _physics_process(delta):
 total+=delta;wait_+=delta
 if step==0:
  if button_contains("Continue claim"):step=1;wait_=0
 elif step==1:
  if variant!="classifier":step=3;return
  aim(Vector3(-5,1.1,1))
  if wait_>.5 and world.mode=="play":tap(KEY_E)
  if world.mode=="board":step=2
 elif step==2:
  if button_contains("Buy classifier"):step=21
 elif step==21:
  if button_contains("Close"):step=3
 elif step==3:
  if walk(Vector3(3.2,1,5.6)):step=4;wait_=0
 elif step==4:
  aim(Vector3(world.river_x(world.player.position.z),.1,world.player.position.z))
  if wait_>.7:
   tap(KEY_E);step=5;wait_=0
 elif step==5:
  if wait_<.2:return
  if world.game.batch.is_empty():log_event("FAIL","No source batch scooped");finish_run(66);return
  batch_before=world.game.batch.duplicate(true)
  tap(KEY_E);step=6;wait_=0;wash_started=total
 elif step==6:
  swirl_age+=delta
  if variant=="simple":key(KEY_Q,true)
  elif swirl_age>.15:
   swirl_age=0;reverse=not reverse;tap(KEY_Q if reverse else KEY_R)
  key(KEY_F,true)
  if world.game.batch.loose<=.01:
   key(KEY_F,false);key(KEY_Q,false);wash_seconds=total-wash_started
   world.get_viewport().get_texture().get_image().save_png(run_dir+"/reveal.png");step=7;wait_=0
  elif wait_>45:log_event("FAIL","Wash timeout");finish_run(67)
 elif step==7 and wait_>2:tap(KEY_E);step=8;wait_=0
 elif step==8 and wait_>1:
  var result={"variant":variant,"initial_batch":batch_before,"wash_seconds":wash_seconds,"gold_collected":world.game.stock.gold,"tailings":world.game.tailings.get(batch_before.id,{}),"simple_input":world.settings.simple,"owned":world.game.owned,"scope":"Exact earned pre-classifier snapshot in separate slots. Classifier purchased via normal board UI. Same source and manual wash inputs; simple variant uses ordinary held Q setting."}
  var file=FileAccess.open(run_dir+"/comparison.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
  log_event("PASS","Native matched-batch wash complete; "+str(wash_seconds)+"seconds, gold="+str(world.game.stock.gold));finish_run()
