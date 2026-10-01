class_name ClaimState
extends RefCounted

const VERSION = 1
const PRICES = {"gold":18.0,"copper_ore":1.5,"tin_ore":2.0,"scrap":3.0,"copper":4.0,"tin":5.0,"quartz":4.0,"bronze":12.0,"gear":38.0,"polished":16.0,"refined_gold":24.0,"pendant":180.0}
const SHOP = {"classifier":24.0,"detector":95.0,"mining":130.0,"workshop":160.0,"barrow":65.0,"fine_screen":90.0,"timber":6.0}
const RECIPES = {
 "copper":{"input":{"copper_ore":3},"output":{"copper":2},"station":"furnace"},
 "tin":{"input":{"tin_ore":3},"output":{"tin":2},"station":"furnace"},
 "bronze":{"input":{"copper":2,"tin":1},"output":{"bronze":3},"station":"furnace"},
 "gear":{"input":{"bronze":2},"output":{"gear":1},"station":"casting"},
 "polished":{"input":{"quartz":1},"output":{"polished":1},"station":"polisher"},
 "refined_gold":{"input":{"gold":2},"output":{"refined_gold":2},"station":"furnace"},
 "pendant":{"input":{"refined_gold":3,"polished":2},"output":{"pendant":1},"station":"casting"}}
var money = 0.0
var stock = {"gold":0.0,"scrap":0.0,"copper_ore":0.0,"tin_ore":0.0,"copper":0.0,"tin":0.0,"quartz":0.0,"bronze":0.0,"gear":0.0,"polished":0.0,"refined_gold":0.0,"pendant":0.0,"timber":3.0,"specimen":0.0}
var owned = {"pan":true}
var batches: Dictionary = {}
var mine_batches: Dictionary = {}
var job: Dictionary = {}
var barrow_position=[-4.0,0.0,7.0]
var barrow_yaw=0.0
var barrow_attached=false
var tailings: Dictionary = {}
var depleted: Array = []
var excavated: Array = []
var supports: Array = []
var rubble: Array = []
var instability: Dictionary = {}
var contracts: Dictionary = {}
var samples: Array = []
var batch: Dictionary = {}
var player = [0.0,1.7,8.0]
var view_yaw=-.38
var view_pitch=0.0
var equipped_tool=1
var completed = false
var elapsed = 0.0
var statistics = {"pans":0,"sales":0,"targets":0,"cells":0,"products":0,"falls":0}

func scoop(id: String) -> bool:
 if not batch.is_empty() or batches.has(id): return false
 var n = int(id.trim_prefix("river_"))
 batch = {"id":id,"gold":1.7 + float(n % 5)*0.19,"fine":0.55,"water":0.0,"loose":1.0,"agitation":0.0,"collected":false}
 batches[id] = true
 return true

func collect() -> float:
 if batch.is_empty() or batch.loose > 0.01 or batch.collected: return 0.0
 var recovery = 0.9 if owned.has("classifier") else 0.65
 var amount = float(batch.gold) + float(batch.fine)*recovery
 stock.gold += amount
 tailings[batch.id] = {"gold":float(batch.fine)*(1.0-recovery),"processed":false}
 batch.collected = true
 statistics.pans += 1
 batch = {}
 return amount

func reprocess(id: String) -> float:
 if not owned.has("fine_screen") or not tailings.has(id) or tailings[id].processed:return 0.0
 var amount = float(tailings[id].gold)
 stock.gold += amount
 tailings[id].gold = 0.0
 tailings[id].processed = true
 return amount

func sell(material: String, quantity: float) -> float:
 if quantity <= 0 or not PRICES.has(material) or stock.get(material,0.0)+0.00001 < quantity:return 0.0
 var value = snappedf(quantity * PRICES[material],0.01)
 stock[material] -= quantity
 money += value
 statistics.sales += 1
 return value

func buy(item: String) -> bool:
 if not SHOP.has(item) or money < SHOP[item] or (owned.has(item) and item != "timber"):return false
 if item == "mining" and (not owned.has("detector") or not (samples.has(0) and samples.has(1) and samples.has(2))):return false
 if item == "workshop" and not owned.has("mining"):return false
 money -= SHOP[item]
 if item == "timber":stock.timber += 4
 else:owned[item] = true
 return true

func craft(recipe: String) -> bool:
 if not owned.has("workshop") or not RECIPES.has(recipe):return false
 var r = RECIPES[recipe]
 for key in r.input:
  if stock.get(key,0.0) < r.input[key]:return false
 for key in r.input:stock[key] -= r.input[key]
 for key in r.output:stock[key] = stock.get(key,0.0)+r.output[key]
 statistics.products += 1
 return true

func recover_target(id: int, contents: Dictionary) -> bool:
 if depleted.has(id):return false
 depleted.append(id)
 for key in contents:stock[key] = stock.get(key,0.0) + contents[key]
 statistics.targets += 1
 return true

func orders() -> Array:
 var result = [{"id":"river","title":"River assay","need":{"gold":3},"pay":72.0,"requires":"pan"},
 {"id":"metal","title":"Salvage survey","need":{"scrap":3},"pay":30.0,"requires":"detector"},
 {"id":"gears","title":"Millwright's order","need":{"gear":3},"pay":170.0,"requires":"workshop"},
 {"id":"stones","title":"Valley lapidary","need":{"polished":4},"pay":95.0,"requires":"workshop"},
 {"id":"signature","title":"First Claim commission","need":{"pendant":1,"specimen":1},"pay":280.0,"requires":"final"}]
 return result

func eligible(order: Dictionary) -> bool:
 return owned.has(order.requires) and not contracts.get(order.id,{}).get("paid",false)

func accept(id: String) -> bool:
 for order in orders():
  if order.id == id and eligible(order) and not contracts.has(id):
   contracts[id] = {"accepted":true,"paid":false}
   return true
 return false

func fulfill(id: String) -> bool:
 if not contracts.has(id) or contracts[id].paid:return false
 for order in orders():
  if order.id != id:continue
  for key in order.need:
   if stock.get(key,0) < order.need[key]:return false
  for key in order.need:
   if key != "specimen":stock[key] -= order.need[key]
  money += order.pay
  contracts[id].paid = true
  if id == "gears" and contracts.get("stones",{}).get("paid",false):owned.final=true
  if id == "stones" and contracts.get("gears",{}).get("paid",false):owned.final=true
  if id == "signature":completed=true
  return true
 return false

func serialize() -> Dictionary:
 return {"version":VERSION,"money":money,"stock":stock,"owned":owned,"batches":batches,"mine_batches":mine_batches,"job":job,"barrow_position":barrow_position,"barrow_yaw":barrow_yaw,"barrow_attached":barrow_attached,"tailings":tailings,"depleted":depleted,"excavated":excavated,"supports":supports,"rubble":rubble,"instability":instability,"contracts":contracts,"samples":samples,"batch":batch,"player":player,"view_yaw":view_yaw,"view_pitch":view_pitch,"equipped_tool":equipped_tool,"completed":completed,"elapsed":elapsed,"statistics":statistics}

func restore(data: Dictionary) -> bool:
 if data.get("version",0) != VERSION:return false
 if float(data.get("money",-1)) < 0:return false
 for key in stock:
  if float(data.get("stock",{}).get(key,-1)) < 0:return false
 for key in serialize():
  if key != "version" and data.has(key):set(key,data[key])
 depleted = unique_ids(depleted)
 samples = unique_ids(samples)
 view_yaw=float(data.get("view_yaw",-.38));view_pitch=clampf(float(data.get("view_pitch",0)),-1.4,1.3);equipped_tool=int(data.get("equipped_tool",1))
 for key in stock:stock[key]=float(stock[key])
 return true

func save_to(path: String) -> bool:
 var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file == null:return false
 file.store_string(JSON.stringify(serialize()))
 file.flush()
 file.close()
 if FileAccess.file_exists(path):DirAccess.copy_absolute(path,path+".bak")
 return DirAccess.rename_absolute(path+".tmp",path) == OK

func loaded_batches(container_: String="all") -> int:
 var count=0
 for key in mine_batches:
  if not mine_batches[key].processed and (container_=="all" or mine_batches[key].get("container","pack")==container_):count+=1
 return count
func add_ore_batch(id_: String, contents: Dictionary) -> bool:
 if mine_batches.has(id_):return false
 mine_batches[id_] = {"contents":contents.duplicate(true),"processed":false,"tailings":{},"sold":false,"container":"barrow" if barrow_attached else "pack"}
 return true
func process_ore_batch(id_: String) -> bool:
 if not owned.has("workshop") or not mine_batches.has(id_):return false
 var b=mine_batches[id_]
 if b.processed or not batch_accessible(b):return false
 for key in b.contents:
  var recovery=1.0 if key=="specimen" else (.98 if owned.has("fine_screen") else .85)
  var amount=float(b.contents[key])*recovery
  stock[key]=stock.get(key,0.0)+amount
  b.tailings[key]=float(b.contents[key])-amount
 b.processed=true
 return true
func recover_ore_tailings(id_: String) -> bool:
 if not owned.has("fine_screen") or not mine_batches.has(id_):return false
 var b=mine_batches[id_]
 if not b.processed or b.sold:return false
 var recovered=false
 for key in b.tailings:
  if b.tailings[key]>0:stock[key]=stock.get(key,0.0)+b.tailings[key];b.tailings[key]=0.0;recovered=true
 return recovered
func sell_ore_batch(id_: String) -> float:
 if not mine_batches.has(id_):return 0.0
 var b=mine_batches[id_]
 if b.processed or not batch_accessible(b):return 0.0
 var value=0.0
 for key in b.contents:
  if key=="specimen":return 0.0
  value+=float(b.contents[key])*PRICES.get(key,0)
 value=snappedf(value,.01)
 money+=value;b.processed=true;b.sold=true;b.tailings={}
 return value
func start_job(recipe: String) -> bool:
 if not owned.has("workshop") or not job.is_empty() or not RECIPES.has(recipe):return false
 var r=RECIPES[recipe]
 for key in r.input:
  if stock.get(key,0.0)<r.input[key]:return false
 for key in r.input:stock[key]-=r.input[key]
 job={"recipe":recipe,"remaining":4.0,"ready":false,"output":r.output.duplicate(true)}
 return true
func tick_job(delta: float):
 if job.is_empty() or job.ready:return
 job.remaining=maxf(0,float(job.remaining)-delta)
 if job.remaining==0:job.ready=true
func collect_job() -> bool:
 if job.is_empty() or not job.ready:return false
 for key in job.output:stock[key]=stock.get(key,0.0)+job.output[key]
 statistics.products+=1;job={}
 return true

func unique_ids(values: Array) -> Array:
 var result: Array=[]
 for value in values:
  var number=int(value)
  if not result.has(number):result.append(number)
 return result

func can_load_ore() -> bool:
 if barrow_attached:return loaded_batches("barrow")<40
 return loaded_batches("pack")<12
func batch_accessible(b: Dictionary) -> bool:
 if b.get("container","pack")!="barrow":return true
 var pos=Vector3(barrow_position[0],barrow_position[1],barrow_position[2])
 return Vector2(pos.x+5,pos.z-4).length()<7.0

func transfer_pack_to_barrow() -> int:
 if not owned.has("barrow"):return 0
 var count=loaded_batches("barrow");var moved=0
 for key in mine_batches:
  var b=mine_batches[key]
  if count>=40:break
  if not b.processed and b.get("container","pack")=="pack":
   b.container="barrow";count+=1;moved+=1
 return moved
