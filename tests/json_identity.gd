extends SceneTree
func _initialize():
 var before={"depleted":[0],"gold":2.00000001}
 var after=JSON.parse_string(JSON.stringify(before))
 print("Original target type: ",typeof(before.depleted[0])," restored type: ",typeof(after.depleted[0]))
 print("Restored array.has(integer 0): ",after.depleted.has(0))
 print("Whole-array comparison: ",before.depleted==after.depleted)
 print("Gold before %.12f after %.12f difference %.12f" %[before.gold,after.gold,abs(before.gold-after.gold)])
 quit()
