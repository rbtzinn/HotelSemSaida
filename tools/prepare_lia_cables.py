"""Prepare isolated Lia cable frames. Original ImageGen PNGs stay outside the project."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
RAW=Path(r"C:\Users\roberto.gabriel\.codex\generated_images\01a18266-e545-7961-acbe-c5c11886fcce")
OUT=ROOT/"art/future/cables"
SPECS={
"enter":("exec-8948cf4a-7063-4a7b-9af9-8281d598c297.png",2,2),
"descend":("exec-17821858-6722-42c7-9abf-0611b63ee52a.png",4,3),
"exit":("exec-5c57eb50-b653-47e9-b586-d9fa71fe53db.png",2,2)}
OUT.mkdir(exist_ok=True)
(OUT/"sheets").mkdir(exist_ok=True)
manifest={}
for name,(source,cols,rows) in SPECS.items():
    sheet=Image.open(RAW/source).convert("RGBA");sw,sh=sheet.size
    packed=Image.new("RGBA",(cols*512,rows*512))
    entries=[]
    for i in range(cols*rows):
        x,y=i%cols,i//cols
        im=sheet.crop((x*sw//cols,y*sh//rows,(x+1)*sw//cols,(y+1)*sh//rows))
        a=np.array(im);r,g,b=a[:,:,:3].astype(int).transpose(2,0,1)
        spill=((r>135)&(g<70)&(b<90))|((g>125)&(r<100)&(b<95))|((r>170)&(g>150)&(b<65))
        a[:,:,3][spill | (a[:,:,3]<32)]=0
        im=Image.fromarray(a);box=im.getchannel("A").getbbox()
        assert box, (name,i)
        im=im.crop(box);a=np.array(im);r,g,b=a[:,:,:3].astype(int).transpose(2,0,1)
        yy,xx=np.indices(a.shape[:2])
        hair=(a[:,:,3]>150)&(r>g*1.12)&(g>b*1.05)&(r<150)&(xx<im.width*.7)&(yy<im.height*.5)
        head_y=int(np.nonzero(hair)[0].min()) if hair.any() else 0
        scale=min(288/max(1,im.height-head_y),336/im.height,224/im.width)
        im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
        a=np.array(im);r,g,b=a[:,:,:3].astype(int).transpose(2,0,1);yy,xx=np.indices(a.shape[:2])
        skin=(a[:,:,3]>180)&(r>135)&(g>75)&(r>g*1.12)&(g>b*1.12)&(yy<im.height*.65)
        hand_x=int(np.percentile(np.nonzero(skin)[1],98)) if skin.any() else im.width-8
        left=176-hand_x;top=352-im.height
        assert left>=8 and left+im.width<=248 and top>=12,(name,i,left,top,im.size)
        frame=Image.new("RGBA",(256,384));frame.paste(im,(left,top))
        bbox=frame.getchannel("A").getbbox()
        assert bbox[0]>=8 and bbox[1]>=12 and bbox[2]<=248 and bbox[3]<=352
        path=OUT/(name+"_%02d.png"%i);frame.save(path)
        packed.paste(frame,(x*512+128,y*512+64))
        entries.append({"file":path.name,"cell":[x*512,y*512,512,512],
                        "bounds":list(bbox),"hand_axis":176,"feet":352,
                        "sha256":hashlib.sha256(frame.tobytes()).hexdigest()})
    assert len({e["sha256"] for e in entries})==len(entries)
    # Wide transparent gutters: each drawing has >=128px horizontal margin in its sheet cell.
    packed.save(OUT/"sheets"/(name+".png"));manifest[name]=entries
(OUT/"layout.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
resource=ROOT/"art/future/lia_animations.tres"
s=resource.read_text(encoding="utf-8")
resources=[];animations=[]
for name,entries in manifest.items():
    for i,e in enumerate(entries):
        resources.append('[ext_resource type="Texture2D" path="res://art/future/cables/%s" id="c_%s%d"]'%(e["file"],name,i))
    frames=',\n'.join('{"duration": 1.0, "texture": ExtResource("c_%s%d")}'%(name,i) for i in range(len(entries)))
    animations.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"cable_%s",\n"speed": %.1f\n}'%(frames,"true" if name=="descend" else "false",name,12 if name=="descend" else 8))
# Idempotent: keep the original idle/walk resource as the prefix.
s=s.split('[ext_resource type="Texture2D" path="res://art/future/cables/')[0] if False else s
assert '"cable_descend"' not in s,"Already prepared: do not append twice"
s=s.replace("load_steps=21","load_steps=41")
s=s.replace("[resource]","\n".join(resources)+"\n\n[resource]")
s=s.rstrip();assert s.endswith("}]")
s=s[:-1]+", "+", ".join(animations)+"]\n"
resource.write_text(s,encoding="utf-8")
# Repeatable straight strands, without repeating hooks or empty cropped columns.
cable=Image.open(ROOT/"art/future/cabos.png").convert("RGBA")
cable=cable.crop((0,0,cable.width,int(cable.height*.60))).resize((12,64),Image.Resampling.LANCZOS)
ca=np.array(cable);ca[-1]=ca[0];Image.fromarray(ca).save(OUT/"cable_tile.png")
scene=ROOT/"scenes/rooms/cozinha.tscn"
s=scene.read_text(encoding="utf-8").replace('path="res://art/future/cabos.png"','path="res://art/future/cables/cable_tile.png"')
start=s.index('[node name="Cabos"');end=s.index('[node name="DescerCabos"',start)
s=s[:start]+s[start:end].replace("offset_left = 594.0","offset_left = 599.0").replace("offset_right = 606.0","offset_right = 611.0")+s[end:]
scene.write_text(s,encoding="utf-8")
print(json.dumps({"frames":sum(len(v) for v in manifest.values()),"canvas":[256,384],"sheets":3,"isolated":True}))

