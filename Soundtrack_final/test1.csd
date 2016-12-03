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



aEnv    madsr     0.025, 0.1, 0, 0.5
aOut    oscil     p4, p5, giTable1 ;generate a sine tone
aOut *= aEnv
outs      aOut, aOut
endin



</CsInstruments>

<CsScore>

</CsScore>
</CsoundSynthesizer>