import math
w=192; h=w*2//3; f=14.0; x=191; y=63
half_w=18/f; half_h=12/f
px=(2*(x+.5)/w-1)*half_w
py=(1-2*(y+.5)/h)*half_h
s=px*px+py*py
wanted_s=s-1e-12
float_shell=32*2**-23
D=.22/(math.sqrt(wanted_s/(1+wanted_s))-float_shell)
a=9e-13
origin=(a*D,D,0.0)
forward=(-a,-1.0,0.0); right=(-1.0,0.0,0.0); up=(0.0,0.0,1.0)
vec=tuple(forward[i]+right[i]*px+up[i]*py for i in range(3))
norm=math.sqrt(sum(q*q for q in vec))
ray=tuple(q/norm for q in vec)
b=sum(origin[i]*ray[i] for i in range(3))
inner=.22-float_shell*D; outer=.22+float_shell*D
outer_s=outer*outer/(D*D-outer*outer)
inner_s=inner*inner/(D*D-inner*inner)
slope_pad=32*2**-52*max(outer_s,py*py)
outer_x=math.sqrt(max(0,outer_s-py*py+slope_pad))
inner_x=math.sqrt(max(0,inner_s-py*py-slope_pad))
index_pad=32*2**-52*w
first_index=math.nextafter(w*(inner_x/half_w+1)/2-.5,-math.inf)
last_index=math.nextafter(w*(outer_x/half_w+1)/2-.5,math.inf)
first=max(0,math.ceil(first_index-index_pad)); last=min(w-1,math.floor(last_index+index_pad))
offset_sq=sum(q*q for q in origin)
outer_disc=b*b-(offset_sq-outer*outer)
inner_disc=b*b-(offset_sq-inner*inner)
for k,v in dict(width=w,height=h,focal_length=f,pixel=(x,y),distance=D,origin=origin,forward_dot_right=a,horizontal=a,sensor_squared=s,outer_squared_slope=outer_s,slope_pad=slope_pad,index_pad=index_pad,positive_interval=(first,last),outer_discriminant=outer_disc,inner_discriminant=inner_disc,counted=first<=x<=last).items():
 print(f'{k}: {v!r}')
