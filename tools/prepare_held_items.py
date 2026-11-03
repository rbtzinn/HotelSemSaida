from pathlib import Path
from PIL import Image
import numpy as np,json,shutil
ROOT=Path(__file__).resolve().parents[1]
RAW=Path(r"C:\Users\roberto.gabriel\.codex\generated_images\01a18266-e545-7961-acbe-c5c11886fcce")
OUT=ROOT/"art/held"
OUT.mkdir(exist_ok=True)
(OUT/"source").mkdir(exist_ok=True)
sources={"fermento":"exec-5f49518b-77a8-4c27-a4fe-1529ef10e61c.png","gelo":"exec-520db184-a692-4093-a192-e553c1e6df6b.png"}
manifest={};refs=[];animations=[]
for item,file in sources.items():
    sheet=Image.open(RAW/file).convert("RGBA")
    shutil.copy2(RAW/file,OUT/"source"/(item+".png"))
    crops=[]
    for i in range(16):
        x,y=i%4,i//4
        crop=sheet.crop((x*sheet.width//4,y*sheet.height//4,(x+1)*sheet.width//4,(y+1)*sheet.height//4))
        a=np.array(crop);r,g,b=a[:,:,:3].astype(int).transpose(2,0,1)
        spill=((r>135)&(g<70)&(b<90))|((g>125)&(r<100)&(b<95))|((r>175)&(g>155)&(b<65))
        a[:,:,3][spill|(a[:,:,3]<40)]=0
        crop=Image.fromarray(a);box=crop.getchannel("A").getbbox()
        assert box
        crops.append(crop.crop(box))
    scale=48/float(np.median([im.height for im in crops[:4]]))
    packed=Image.new("RGBA",(4*256,4*256));entries=[]
    for i,crop in enumerate(crops):
        crop=crop.resize((max(1,round(crop.width*scale)),max(1,round(crop.height*scale))),Image.Resampling.NEAREST)
        alpha=crop.getchannel("A").point(lambda a:255 if a>=128 else 0)
        rgb=crop.convert("RGB").quantize(colors=48,dither=Image.Dither.NONE).convert("RGBA")
        rgb.putalpha(alpha)
        yy,xx=np.nonzero(np.array(alpha)[:max(2,round(crop.height*.18))]>0)
        head=int(round(xx.mean())) if len(xx) else crop.width//2
        left=24-head;top=52-crop.height
        assert left>=1 and left+crop.width<=47 and top>=1,(item,i,left,top,crop.size)
        frame=Image.new("RGBA",(48,56));frame.paste(rgb,(left,top))
        path=OUT/("%s_%02d.png"%(item,i));frame.save(path)
        refs.append('[ext_resource type="Texture2D" path="res://art/held/%s" id="%s%d"]'%(path.name,item,i))
        packed.paste(frame,((i%4)*256+104,(i//4)*256+100))
        entries.append({"file":path.name,"bbox":list(frame.getchannel("A").getbbox()),"feet":52,"head_x":24})
    packed.save(OUT/(item+"_sheet.png"))
    manifest[item]=entries
    for name,indices,speed,loop in [("idle",range(4),4,True),("walk",range(4,12),8,True),("use",range(12,16),8,False)]:
        frames=',\n'.join('{"duration":1.0,"texture":ExtResource("%s%d")}'%(item,i) for i in indices)
        animations.append('{"frames":[%s],"loop":%s,"name":&"%s_%s","speed":%.1f}'%(frames,str(loop).lower(),item,name,speed))
text='[gd_resource type="SpriteFrames" load_steps=33 format=3]\n\n'+'\n'.join(refs)+'\n\n[resource]\nanimations = ['+',\n'.join(animations)+']\n'
(OUT/"helena_items.tres").write_text(text,encoding="utf-8")
(OUT/"layout.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
scene=ROOT/"scenes/rooms/cozinha.tscn";s=scene.read_text(encoding="utf-8")
if 'id="held_animations"' not in s:
    s=s.replace('[sub_resource type="RectangleShape2D" id="RectangleShape2D_icebox"]','[ext_resource type="SpriteFrames" path="res://art/held/helena_items.tres" id="held_animations"]\n\n[sub_resource type="RectangleShape2D" id="RectangleShape2D_icebox"]',1)
    s=s.replace('sprite_sheet = ExtResource("t_helena")','sprite_sheet = ExtResource("t_helena")\nitem_animations = ExtResource("held_animations")')
scene.write_text(s,encoding="utf-8")
print("32frames,6animations, isolated crops48x56 with feet52")

