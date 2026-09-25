import zlib, struct, os
import os as _os
A = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "assets", "1x")

def decode(path):
    d = open(path,'rb').read(); pos=8; idat=b''; w=h=0
    while pos < len(d):
        ln = struct.unpack('>I', d[pos:pos+4])[0]; tag=d[pos+4:pos+8]; data=d[pos+8:pos+8+ln]
        if tag==b'IHDR': w,h,bd,ct = struct.unpack('>IIBB', data[:10])
        elif tag==b'IDAT': idat += data
        pos += 12+ln
    raw = zlib.decompress(idat); stride=w*4; out=bytearray(w*h*4); prev=bytearray(stride); p=0
    for y in range(h):
        f=raw[p]; p+=1; line=bytearray(raw[p:p+stride]); p+=stride
        for i in range(stride):
            a=line[i-4] if i>=4 else 0; b=prev[i]; c=prev[i-4] if i>=4 else 0
            if f==1: line[i]=(line[i]+a)&255
            elif f==2: line[i]=(line[i]+b)&255
            elif f==3: line[i]=(line[i]+(a+b)//2)&255
            elif f==4:
                pa,pb,pc=abs(b-c),abs(a-c),abs(a+b-2*c)
                pr=a if (pa<=pb and pa<=pc) else (b if pb<=pc else c)
                line[i]=(line[i]+pr)&255
        out[y*stride:(y+1)*stride]=line; prev=line
    return w,h,out

def crop(w,h,px,cx,cy,cw,ch):
    out=bytearray(cw*ch*4)
    for y in range(ch):
        si=((cy+y)*w+cx)*4; out[y*cw*4:(y+1)*cw*4]=px[si:si+cw*4]
    return out

def scale_up(px,cw,ch,f):
    out=bytearray(cw*f*ch*f*4)
    for y in range(ch*f):
        for x in range(cw*f):
            si=((y//f)*cw+(x//f))*4
            di=(y*cw*f+x)*4
            out[di:di+4]=px[si:si+4]
    return out

def write_png(path,w,h,px):
    raw=bytearray()
    for y in range(h): raw.append(0); raw+=px[y*w*4:(y+1)*w*4]
    def chunk(t,d): return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
    png=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(bytes(raw),9))+chunk(b"IEND",b"")
    open(path,'wb').write(png)

F=4
items=[]
def add(sheet, cx, cy, cw=71, ch=95):
    w,h,px=decode(f"{A}/{sheet}.png")
    c=crop(w,h,px,cx,cy,cw,ch)
    items.append((cw*F, ch*F, scale_up(c,cw,ch,F)))

add('blh_joker',0,0); add('blh_joker',71,95); add('blh_joker',142,190)
add('blh_tarot',0,0); add('blh_tarot',71,0)
add('blh_spectral',0,0); add('blh_voucher',0,0)
add('blh_seal',0,0); add('blh_sticker',0,0)
add('blh_tag',0,0,34,34); add('blh_tag',34,0,34,34); add('blh_tag',102,0,34,34)
add('blh_blind',0,0,34,34); add('blh_blind',0,102,34,34); add('blh_blind',0,204,34,34)

cw,ch=71*F,95*F
cols=min(6,len(items)); rows=(len(items)+cols-1)//cols
sw,sh=cols*cw,rows*ch
out=bytearray(sw*sh*4)
for i,(iw,ih,it) in enumerate(items):
    x0,y0=(i%cols)*cw+(cw-iw)//2,(i//cols)*ch+(ch-ih)//2
    for y in range(ih):
        di=((y0+y)*sw+x0)*4; si=y*iw*4
        out[di:di+iw*4]=it[si:si+iw*4]
OUT = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), 'contact.png')
write_png(OUT, sw, sh, out)
print('contact sheet ->', OUT, sw, sh)
