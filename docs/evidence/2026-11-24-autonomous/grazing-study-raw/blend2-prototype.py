import math
from pathlib import Path

def estimate(cut,slope,n):
    length=math.sqrt(1+slope*slope+16*cut*cut);hx=.5/n;hy=.3/n;total=0
    for j in range(n):
        y=(j+.5)*.6/n-.3
        for i in range(n):
            x=(i+.5)/n-.5;c=x+slope*y-cut;a=hx;b=slope*hy;span=abs(a)+abs(b)
            if c<=-span:continue
            def value(u,v,w):
                xx=x+u*hx;yy=y+v*hy;r2=xx*xx+yy*yy+.25**2
                return w*1000/(n*n)*.25*max(0,xx+slope*yy-cut)/length/(r2*r2)
            if c>=span:total+=value(0,0,1);continue
            poly=[(-1,-1),(1,-1),(1,1),(-1,1)];out=[]
            prev=poly[-1];pd=c+a*prev[0]+b*prev[1]
            for cur in poly:
                cd=c+a*cur[0]+b*cur[1]
                if (cd>0)!=(pd>0):
                    t=pd/(pd-cd);out.append((prev[0]+t*(cur[0]-prev[0]),prev[1]+t*(cur[1]-prev[1])))
                if cd>0:out.append(cur)
                prev=cur;pd=cd
            area=0;mx=0;my=0
            for k in range(1,len(out)-1):
                p,q,r=out[0],out[k],out[k+1]
                cross=abs((q[0]-p[0])*(r[1]-p[1])-(q[1]-p[1])*(r[0]-p[0]))
                area+=cross;mx+=cross*(p[0]+q[0]+r[0])/3;my+=cross*(p[1]+q[1]+r[1])/3
            coverage=area/8
            blend=coverage**2
            if area>0:total+=value(mx/area,my/area,coverage*blend)
            for k in range(1,len(out)-1):
                p,q,r=out[0],out[k],out[k+1];weight=abs((q[0]-p[0])*(r[1]-p[1])-(q[1]-p[1])*(r[0]-p[0]))/24*(1-blend)
                for v1,v2,v3 in [(p,q,r),(q,p,r),(r,p,q)]:total+=value((4*v1[0]+v2[0]+v3[0])/6,(4*v1[1]+v2[1]+v3[1])/6,weight)
    return total
for line in Path('verification/baseline/grazing-regressions.log').read_text().splitlines():
    if not line.startswith('CASE'):continue
    fields=line.split();quality=fields[1];kv=dict(x.split('=',1) for x in fields[2:-1])
    actual=estimate(float(kv['cut']),float(kv['slope']),8 if quality=='interactive' else 32)
    expected=float(kv['expected']);print(quality,kv['slope'],kv['cut'],'estimated error',abs(actual-expected)/expected)
