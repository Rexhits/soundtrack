<CsoundSynthesizer>
<CsOptions>
-o dac -M0
</CsOptions>
<CsInstruments>


; Initialize the global variables.
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1



giTable1	ftgen     1, 0, 4096, 10, 1, 0 , .33, 0, .2 , 0, .14, 0 , .11, 0, .09
giTable2	ftgen     2, 0, 4096, 10, 1, 0
giTable3	ftgen     3, 0, 4096, 10, 0.5, 0, .66, 0, .33, 0
giTable4    ftgen     4, 0, 4096, 10, 0.5, 0


instr 1

iCps    cpsmidi   ;get the frequency from the key pressed
iRel    init   0.01
iAmp    ampmidi   0dbfs * 0.4 ;get the amplitude
iRes    ampmidi   0dbfs
kVol    ctrl7     2, 7, 0, 0dbfs
aVol    ctrl7     2, 7, 0, 0dbfs
iSus    ctrl7     2, 64, iRel, 0.4
kScale  scale     iRes, 2000, 800
kScale  *=  kVol
aEnv    madsr     0.025, 0.1, 0, iSus
aEnv *= aVol
aOut    oscil     iAmp, iCps, giTable1 ;generate a sine tone
aOut    moogladder aOut, kScale, 0.4
aOut *= aEnv
outs      aOut, aOut
endin



</CsInstruments>

<CsScore>

</CsScore>
</CsoundSynthesizer>
