"""Original deterministic material maps. Blender source and GLB share explicit PNGs.
No downloaded textures. numpy ships with Blender. Pixel data generated from seeds.
"""
import numpy as np, hashlib

def material_maps(material,name,color,roughness):
 folder=ROOT/'assets'/'materials';folder.mkdir(exist_ok=True)
 size=512
 yy,xx=np.mgrid[0:size,0:size].astype(np.float32);u=xx/size;v=yy/size
 seed=int(hashlib.sha256(name.encode()).hexdigest()[:8],16)
 rng=np.random.default_rng(seed)
 grain=rng.random((size,size),dtype=np.float32)-.5
 broad=np.sin(u*23+np.sin(v*19))*np.cos(v*31+u*7)
 if 'ash' in name or 'wood' in name:
  pattern=np.sin(u*260+np.sin(v*13)*2+broad*3)*.045+broad*.025+grain*.026
  height=np.sin(u*260+np.sin(v*13)*2+broad*3)*.15+grain*.045
 elif 'canvas' in name or 'glove' in name:
  weave=np.sin(u*size*np.pi*.5)*np.sin(v*size*np.pi*.5)
  pattern=grain*.06+broad*.035+weave*.035; height=grain*.08+weave*.16
 elif 'steel' in name:
  brush=np.sin(u*620+v*.7)
  pattern=brush*.018+grain*.02; height=brush*.06+grain*.03
 elif 'polymer' in name:
  scratches=np.maximum(0,np.sin(u*530+v*17)-.992)*18
  pattern=broad*.026+grain*.025+scratches*.04; height=grain*.045-scratches*.04
 else:
  pattern=broad*.025+grain*.022;height=grain*.04
 base=np.asarray(color,dtype=np.float32)
 # Material scalar base values are linear; texture PNGs are tagged sRGB.
 srgb=np.where(base<=.0031308,base*12.92,1.055*np.power(base,1/2.4)-.055)
 rgb=np.clip(srgb[None,None,:]*(1+pattern[:,:,None]),0,1)
 rough=np.clip(roughness+pattern*.55,.05,1)
 dy,dx=np.gradient(height);normal=np.stack((-dx*1.2,-dy*1.2,np.ones_like(dx)),axis=-1)
 normal/=np.linalg.norm(normal,axis=-1,keepdims=True);normal=normal*.5+.5
 slug=name.replace(' ','-')
 def image_map(suffix,data,space):
  path=folder/(slug+'-'+suffix+'.png')
  image=bpy.data.images.load(str(path),check_existing=True) if path.exists() else bpy.data.images.new(slug+'-'+suffix,width=size,height=size)
  image.colorspace_settings.name=space
  rgba=np.ones((size,size,4),dtype=np.float32);rgba[:,:,:3]=data
  image.pixels.foreach_set(rgba.ravel());image.filepath_raw=str(path);image.file_format='PNG';image.save()
  return image
 nodes=material.node_tree.nodes;links=material.node_tree.links;p=nodes.get('Principled BSDF')
 for suffix,data,space in [('albedo',rgb,'sRGB'),('roughness',np.repeat(rough[:,:,None],3,axis=2),'Non-Color'),('normal',normal,'Non-Color')]:
  node=nodes.new('ShaderNodeTexImage');node.image=image_map(suffix,data,space);node.label='Original exported '+suffix
  if suffix=='albedo':links.new(node.outputs['Color'],p.inputs['Base Color'])
  elif suffix=='roughness':links.new(node.outputs['Color'],p.inputs['Roughness'])
  else:
   normal_node=nodes.new('ShaderNodeNormalMap');normal_node.inputs['Strength'].default_value=.55
   links.new(node.outputs['Color'],normal_node.inputs['Color']);links.new(normal_node.outputs['Normal'],p.inputs['Normal'])
