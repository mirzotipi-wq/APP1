# Scalar reference (independent of production normal helper)
Subject S=(0,0,0) m; source L=(0,0,2) m; intensity I=400 cd.
Distance squared = (0-0)^2+(0-0)^2+(2-0)^2=4 m².
Front camera C=(0,0,3): receiver unit normal=(0,0,1); source unit direction=(0,0,1); dot=1; E=400/4*max(0,1)=100 lx.
Back camera C=(0,0,-3): receiver unit normal=(0,0,-1); dot=-1; E=400/4*max(0,-1)=0 lx.
Coincident camera C=S: zero vector has no normalized direction; expected unsupported nil rather than an illuminance number.
Directional emitter uses the default subject target: emitting normal=(0,0,-1), source-to-subject direction=(0,0,-1); emission cosine=1. The same front/back values therefore apply.
For the valid back-facing sample, zero lux yields zero incident XYZ, zero signal, and RGB=(0,0,0). Coincident-camera card construction must fail before summing lights.
