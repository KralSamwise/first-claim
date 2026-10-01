extends SceneTree
const State=preload("res://source/claim.gd")
const Mine=preload("res://source/mine.gd")
var failures=0
func check(ok: bool,msg: String):
 print("PASS " if ok else "FAIL ",msg)
 if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
 var state=State.new();var mine=Mine.new();root.add_child(mine);mine.setup(state,func(_a,_b):pass)
 # Authored integration fixture: three-cell wide, three-cell high, four-cell deep excavation.
 for x in [5,6,7]:
  for y in [1,2,3]:
   for z in [0,1,2,3]:state.excavated.append(mine.id(Vector3i(x,y,z)))
 mine.rebuild_state()
 var center=Vector3(.4,.8,-1.2)
 check(mine.support_check(center)=="","grid-aligned frame has valid floor roof side contacts")
 check(not mine.support_check(center+Vector3(0,.8,0)).is_empty(),"floating frame refused")
 var wood=state.stock.timber
 var result=mine.place_support(center)
 check(state.supports.size()==1 and state.stock.timber==wood-1,"valid support placed atomically")
 check(mine.covered(center+Vector3(0,2,0)),"local roof covered")
 check(not mine.covered(center+Vector3(2,2,0)),"widened region outside frame stays unprotected")
 check(not mine.support_check(center).is_empty(),"overlapping frame refused")
 mine.lag_nearest(center)
 check(mine.covered(center+Vector3(0,2,.9)),"lagging extends local longitudinal coverage")
 mine.solid.erase(mine.id(mine.cell_at(center+Vector3(1.44,1.2,0))))
 mine.revalidate_supports()
 check(not state.supports[0].valid and not mine.covered(center),"excavated wall contact invalidates frame")
 state.supports=[]
 var status=mine.tick(5,Vector3(99,99,99))
 check("STRAINED" in status.state,"warning precedes failure")
 check(mine.tick(.01,Vector3(99,99,99))==status,"warning persists between evaluation ticks")
 mine.tick(20,Vector3(99,99,99))
 check(state.rubble.size()>0,"localized fall creates clearable rubble")
 var r=mine.coord(state.rubble[0]);var pos=mine.to_global(mine.local_center(r));pos.y=.9
 check(mine.clear_rubble(pos),"fallen rubble can be cleared")
 print("RESULT failures=",failures)
 mine.queue_free();quit(failures)
