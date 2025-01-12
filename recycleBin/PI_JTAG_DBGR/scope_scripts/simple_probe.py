from vds1022 import *

dev = VDS1022(debug=0)
dev.set_channel(CH1, range='10v', offset=1/10, probe='x10')

for frames in dev.fetch_iter(freq=2) :
    print('Vrms:%s     ' % frames.ch1.rms(), end='\r')