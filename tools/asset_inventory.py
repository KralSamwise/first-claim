"""Reconcile all 28 brief groups with actual editable sources and evidence, no blanket signoff."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
models=json.loads((ROOT/'asset-manifest.json').read_text())['assets']
by_id={a['id']:a for a in models}
groups=[
('River terrain',[],['source/main.gd'],'Continuous authored ground, bank, camp terrace, ridge and physical collision'),
('Water',[],['source/main.gd'],'River current shader and independently bounded pan water; splash/ripple feedback pending'),
('Rock and gravel kit',[],['source/main.gd'],'Shared stone materials and batched gravel, boulders with collision'),
('Hero pan',['hero_pan'],['tools/model_opening.py'],'Interior/riffles/rim with actual batch contents'),
('Pan contents',[],['source/main.gd'],'Gravel/sediment/water/gold visibility follows finite batch'),
('Shovel',['shovel'],['tools/model_opening.py'],'Held scoop and camp tool'),
('Hands and gloves',['hero_pan','pickaxe','detector','support_hammer'],['tools/model_opening.py','tools/model_field.py'],'Connected gripping meshes, native pan view reviewed'),
('Gold vial',['vial'],['source/main.gd'],'Empty at start; actual gold stock drives visible flakes'),
('Gold kit',[],['source/main.gd'],'Flakes in pan/vial; recoverable nugget close feedback pending'),
('Scale and selling point',['scale','bench'],['source/main.gd'],'Explicit sale UI and stock/value'),
('Camp kit',['bench','board'],['source/main.gd'],'Supply crate and clear interaction routes'),
('Feedback and UI',[],['source/main.gd'],'Reticle, readable prompts, settings, journal, pause'),
('Detector',['detector'],['source/main.gd'],'Actual coil location governs finite target signal and recovery'),
('Trowel and targets',['trowel'],['source/main.gd'],'Trowel model exists; held recovery integration pending'),
('Sample kit',['sample_tray'],['source/main.gd'],'Three actual sample identities drive tray contents'),
('Surface vein',[],['source/main.gd','source/mine.gd'],'Quartz trail and mineral texture; irregular immutable boundary'),
('Excavatable terrain',[],['source/mine.gd'],'Bounded cells rebuild mesh/collision and persist'),
('Support kit',[],['source/mine.gd'],'Contact-valid posts/header, lagging, steel fasteners and collision'),
('Work lamp',[],['source/mine.gd','source/main.gd'],'Visible amber frame lamp and carried mine headlamp'),
('Wheelbarrow',['barrow'],['source/main.gd'],'Physical width, actual load/container, attached and parked states'),
('Pickaxe and hammer',['pickaxe','support_hammer'],['source/main.gd'],'Distinct rock/wood sound and action motion'),
('Rubble and stability',[],['source/mine.gd'],'Roof-local cracks, falling chips, clearable collision rubble'),
('Sieve and washer',['sieve','classifier'],['source/main.gd'],'Physical separation surface, source UI and fine mesh upgrade'),
('Furnace and crucible',['furnace','crucible'],['source/main.gd'],'Visible vessel, warm light and reserved-input processing'),
('Casting bench',['casting'],['source/main.gd'],'Crucible motion and correct ready output'),
('Metals and goods',['ingot_copper','ingot_tin','ingot_bronze','ingot_gold','gear','polished_stone','pendant'],['source/main.gd'],'Recipe-specific products tied to ready job'),
('Gem finishing',['polisher','polished_stone','specimen'],['source/main.gd'],'Rough and polished models with actual pickup state'),
('Contract and display',['bench','specimen','pendant'],['source/main.gd'],'Once-paid orders and persistent tangible ending display')]
records=[]
for n,(name,ids,sources,states) in enumerate(groups,1):
 records.append({'group':n,'name':name,'model_ids':ids,'functional_role':states,'source_license':'Original project code/meshes/materials; Godot engine MIT','editable_sources':[str(ROOT/x) for x in sources]+[by_id[x]['editable_source'] for x in ids if x in by_id],'game_exports':[by_id[x]['game_export'] for x in ids if x in by_id] or [str(ROOT/x) for x in sources if x.endswith('.gd')],'materials_textures':sorted(set(p for x in ids if x in by_id for p in by_id[x]['texture_paths'])),'scale':'metres; Godot metre coordinates','origin_sockets':'See per-model asset-manifest sockets or engine source coordinates','collision':'Engine-authored physical bodies; per-role mesh/bounds','animations_states':states,'preview_paths':[str(ROOT/'evidence/runs/art-pass03/preview.png')] if n in [1,2,3,4,7,12] else [],'verification':'Native opening view reviewed; final matched-view review pending' if n in [1,2,3,4,7,12] else 'Imported; individual native view/state review pending'})
review_path=ROOT/'docs/asset-native-review.json'
if review_path.exists():
 for record in records:
  review=json.loads(review_path.read_text()).get(str(record['group']))
  if review:record.update(review)
for record in records:
 if not record['materials_textures']:
  record['materials_textures']=[x for x in record['editable_sources'] if x.endswith('.gd')]
  record['material_note']='Engine-created shader/NoiseTexture/material definitions in listed source; no external bitmap is required.'
out={'schema':1,'required_groups':28,'mapped_groups':len(records),'exported_models':len(models),'missing_model_ids':sorted({x for _,ids,_,_ in groups for x in ids if x not in by_id}),'groups':records}
(ROOT/'asset-groups.json').write_text(json.dumps(out,indent=2)+'\n')
print('groups',len(records),'models',len(models),'missing',out['missing_model_ids'])
