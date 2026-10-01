extends SceneTree
const State = preload("res://source/claim.gd")
var failures = 0
var assertions = 0
func check(condition: bool, message: String):
 assertions+=1
 if not condition:failures+=1;printerr("FAIL ",message)
 else:print("PASS ",message)
func _initialize():
 var s=State.new()
 check(s.scoop("river_0"),"fresh batch can be scooped")
 var original=float(s.batch.gold)+float(s.batch.fine)
 check(not s.scoop("river_0"),"cannot replace loaded batch")
 check(s.collect()==0,"cannot collect unwashed batch")
 s.batch.loose=0
 var recovered=s.collect()
 check(recovered>0,"washed batch recovers gold")
 check(s.collect()==0,"second collect cannot duplicate reward")
 check(not s.scoop("river_0"),"depleted patch stays depleted")
 check(is_equal_approx(recovered+float(s.tailings.river_0.gold),original),"gold conservation across recovery and tailings")
 check(s.reprocess("river_0")==0,"fine tailings require upgrade")
 s.owned.fine_screen=true
 var fine=s.reprocess("river_0")
 check(is_equal_approx(fine+recovered,original),"fine upgrade recovers remainder exactly")
 check(s.reprocess("river_0")==0,"tailings cannot be processed twice")
 check(s.sell("gold",-3)==0,"negative sale refused")
 check(s.sell("gold",100)==0,"oversale refused")
 check(not s.buy("detector"),"unaffordable purchase refused")
 var revenue=s.sell("gold",s.stock.gold)
 check(revenue>24 and s.buy("classifier"),"first pan affords meaningful upgrade")
 check(not s.buy("classifier"),"duplicate equipment refused")
 check(s.recover_target(0,{"gold":2}),"target recovered")
 check(not s.recover_target(0,{"gold":2}),"depleted target cannot pay twice")
 s.owned.workshop=true
 s.stock.copper_ore=9;s.stock.tin_ore=6
 for i in 3:check(s.craft("copper"),"copper batch %d"%i)
 for i in 2:check(s.craft("tin"),"tin batch %d"%i)
 for i in 3:check(s.craft("bronze"),"bronze batch %d"%i)
 for i in 3:check(s.craft("gear"),"gear cast %d"%i)
 check(s.stock.copper==0 and s.stock.tin==1 and s.stock.bronze==3 and s.stock.gear==3,"recipe input output accounting exact")
 check(s.accept("gears"),"achievable unlocked order accepted")
 var prior=s.money
 check(s.fulfill("gears") and is_equal_approx(s.money-prior,170),"gear contract pays full bonus once")
 check(not s.fulfill("gears") and s.money==prior+170,"double contract payout refused")
 s.excavated=["1,1,2"];s.supports=[{"cell":"1,0,2"}];s.instability={"2,1,2":4};s.player=[1,2,3]
 check(s.save_to("user://test-accounting.json"),"atomic save writes")
 var loaded=State.new();var parsed=JSON.parse_string(FileAccess.get_file_as_string("user://test-accounting.json"))
 check(loaded.restore(parsed),"saved version restores")
 for key in ["excavated","contracts","tailings"]:
  check(JSON.stringify(loaded.get(key))==JSON.stringify(s.get(key)),"serialized roundtrip "+key)
 check(loaded.depleted.has(0) and not loaded.recover_target(0,{"gold":2}),"reload retains integer target identity and prevents duplicate reward")
 for key in s.stock:check(is_equal_approx(loaded.stock[key],s.stock[key]),"stock roundtrip "+key)
 var bad=s.serialize().duplicate(true);bad.stock.gold=-1
 check(not State.new().restore(bad),"negative corrupt inventory rejected")
 var survey=State.new();survey.owned.detector=true;survey.money=1000;survey.samples=[0]
 for i in 3:
  var next=State.new();check(next.restore(JSON.parse_string(JSON.stringify(survey.serialize()))),"survey reload %d"%i)
  survey=next
  if not survey.samples.has(0):survey.samples.append(0)
 check(survey.samples.size()==1 and not survey.buy("mining"),"one sampled site across repeated loads cannot unlock mining")
 survey.samples=[0,0,0];check(not survey.buy("mining"),"duplicate IDs cannot satisfy distinct-site purchase gate")
 survey.samples=[0,1,2];check(survey.buy("mining"),"three distinct authored samples unlock mining")
 var batches=State.new();batches.owned.workshop=true
 check(batches.add_ore_batch("cell",{"copper_ore":3.5,"tin_ore":1.2,"quartz":.7}),"source ore batch accepted")
 check(not batches.add_ore_batch("cell",{"gold":999}),"source ore identity cannot reroll")
 check(batches.process_ore_batch("cell"),"source batch screens once")
 check(not batches.process_ore_batch("cell"),"screen batch duplication refused")
 check(is_equal_approx(batches.stock.copper_ore+batches.mine_batches.cell.tailings.copper_ore,3.5),"ore recovery conservation")
 batches.owned.fine_screen=true
 check(batches.recover_ore_tailings("cell") and is_equal_approx(batches.stock.copper_ore,3.5),"fine screen recovers finite remainder")
 check(not batches.recover_ore_tailings("cell"),"ore tailings duplicate refused")
 check(batches.start_job("copper"),"station reserves recipe inputs")
 check(not batches.start_job("copper"),"busy station cannot double reserve")
 var pending=State.new();pending.restore(JSON.parse_string(JSON.stringify(batches.serialize())))
 pending.tick_job(4)
 check(pending.collect_job() and is_equal_approx(pending.stock.copper,2),"in-progress job reload finishes exact output")
 check(not pending.collect_job(),"finished output cannot collect twice")
 var transport=State.new();transport.owned.barrow=true
 for i in 12:transport.add_ore_batch("pack"+str(i),{"copper_ore":1.0})
 check(not transport.can_load_ore(),"barrow ownership alone does not enlarge backpack")
 transport.barrow_attached=true;transport.barrow_position=[0,2.4,-35]
 check(transport.can_load_ore() and transport.add_ore_batch("barrow-load",{"tin_ore":2.0}),"attached barrow gets its own load")
 transport.barrow_attached=false;transport.owned.workshop=true
 check(not transport.can_load_ore(),"parking full barrow cannot enlarge full backpack")
 check(not transport.process_ore_batch("barrow-load") and transport.sell_ore_batch("barrow-load")==0,"remote parked load cannot process or sell at camp")
 var transported=State.new();transported.restore(JSON.parse_string(JSON.stringify(transport.serialize())))
 check(transported.mine_batches["barrow-load"].container=="barrow" and transported.barrow_position[2]==-35 and not transported.barrow_attached,"barrow location load and attachment survive reload")
 transported.barrow_position=[-5,0,4]
 check(transported.process_ore_batch("barrow-load"),"physically returned barrow load available at camp")
 print("RESULT assertions=",assertions," failures=",failures)
 quit(1 if failures else 0)
