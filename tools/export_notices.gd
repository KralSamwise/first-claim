extends SceneTree
func _initialize():
 var file=FileAccess.open("res://GODOT-NOTICES.txt",FileAccess.WRITE)
 file.store_string(Engine.get_license_text()+"\n\nTHIRD-PARTY COMPONENTS\n")
 for component in Engine.get_copyright_info():file.store_string(JSON.stringify(component,"  ")+"\n")
 file.store_string("\nTHIRD-PARTY LICENSE TEXTS\n"+JSON.stringify(Engine.get_license_info(),"  "))
 file.close();quit()
