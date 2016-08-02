<CsoundSynthesizer>
<CsOptions>
-o dac -+rtmidi=NULL -+rtaudio=NULL -d -+msg_color=0 -MA -mA
</CsOptions>
<CsInstruments>

; Initialize the global variables.
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

gaDelOut init  0
gaRevOut init  0

massign 1,1
massign 2,2

giTable1	ftgen     1, 0, 4096, 10, 1, 0 , .33, 0, .2 , 0, .14, 0 , .11, 0, .09
giTable2	ftgen     2, 0, 4096, 10, 1, 0
giTable3	ftgen     3, 0, 4096, 10, 0.5, 0, .66, 0, .33, 0
giTable4    ftgen     4, 0, 4096, 10, 0.5, 0

instr 1

iCps    cpsmidi   ;get the frequency from the key pressed
iAmp    ampmidi   0dbfs * 0.3 ;get the amplitude
iRes    ampmidi   0dbfs
kScale  scale     iRes, 2000, 800
aEnv    madsr     0.025, 1, 0.01, 0.1
aOut    oscil     iAmp, iCps, giTable1 ;generate a sine tone
aOut    moogladder aOut, kScale, 0.4
aOut *= aEnv
outs      aOut, aOut * 0
vincr gaRevOut, aOut
endin


instr 2

iCps    cpsmidi   ;get the frequency from the key pressed
iAmp    ampmidi   0dbfs * 0.5 ;get the amplitude
iRes    ampmidi   0dbfs
kScale  scale     iRes, 3000, 500
aEnv    madsr     0.1, 1.5, 0.3, 0.1
aOut    oscil     iAmp, iCps, giTable2 ;generate a sine tone
aOut    moogladder aOut, kScale, 0.2
aOut *= aEnv
outs      aOut * 0, aOut
vincr gaDelOut, aOut
vincr gaRevOut, aOut
endin



instr 98
a2	delayr	1
aL	deltap	.1
delayw	gaDelOut + (aL * 0.3)
a3	delayr	1
aR	deltap	.2
delayw	gaDelOut + (aR * 0.3)
out	aL, aR		;volume of reverb

clear gaDelOut
endin

instr 99

a2	nreverb	gaRevOut, 2, .3
out	a2*.15, a2*.15		;volume of reverb

clear gaRevOut
endin

</CsInstruments>

<CsScore>
i 99 0 100000
i 98 0 100000
</CsScore>
</CsoundSynthesizer>
