extends SceneTree
const State=preload("res://source/claim.gd")
var failures=0
func check(ok:bool,msg:String):
 print("PASS " if ok else "FAIL ",msg)
 if not ok:failures+=1
func roundtrip(s,label_):
 var path="user://test_"+label_+".json"
 check(s.save_to(path),label_+" writes")
 var result=State.new();check(result.restore(JSON.parse_string(FileAccess.get_file_as_string(path))),label_+" restores")
 return result
func _initialize():
 var s=State.new();s.scoop("river_4");s.batch.water=.4;s.batch.loose=.3;s.batch.agitation=.7
 s.view_yaw=1.2;s.view_pitch=-.35;s.equipped_tool=2
 s=roundtrip(s,"river")
 check(is_equal_approx(s.view_yaw,1.2) and is_equal_approx(s.view_pitch,-.35) and s.equipped_tool==2,"camera direction and equipped tool persist")
 check(is_equal_approx(s.batch.loose,.3) and not s.scoop("river_4"),"part washed source remains unchanged")
 s.recover_target(4,{"gold":2.25});s.samples=[0,1]
 s=roundtrip(s,"detector")
 check(not s.recover_target(4,{"gold":2.25}) and s.samples.has(1),"target and sample identities persist")
 s.excavated=["5,1,0","5,2,0"];s.supports=[{"x":.4,"y":.8,"z":-1.2,"width":2.4,"valid":true,"lagged":true}];s.rubble=["5,3,0"];s.instability={"6,3,0":13.2}
 s=roundtrip(s,"tunnel")
 check(s.excavated.has("5,2,0") and s.rubble.has("5,3,0") and is_equal_approx(s.instability["6,3,0"],13.2),"excavation rubble and instability persist")
 s.owned.workshop=true;s.stock.bronze=4;s.start_job("gear");s.tick_job(1.7)
 s=roundtrip(s,"workshop")
 check(is_equal_approx(s.job.remaining,2.3) and s.stock.bronze==2,"reserved input and remaining work persist")
 s.tick_job(10);check(s.collect_job() and not s.collect_job(),"pending output collects once after load")
 s.owned.final=true;s.stock.pendant=1;s.stock.specimen=1;s.accept("signature");s.fulfill("signature")
 s=roundtrip(s,"ending")
 check(s.completed and s.stock.specimen==1 and not s.fulfill("signature"),"ending display specimen and paid contract persist")
 print("RESULT failures=",failures);quit(failures)
