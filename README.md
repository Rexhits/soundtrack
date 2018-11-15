# soundtrack

<p>Soundtrack is an iOS musical social network APP which enables musician to post audio or MIDI clips at certain location, and let users/fans to collect those clips and mesh the clips up to compose their own pieces by using provided algorithms. This APP is written in Swift, the backend is written in Python with Django, it also features a dedicated software synthesizer I wriiten in JUCE called "STSynth".</p>
<br><br>
<p>
Server's repo is found here: <br>
https://github.com/Rexhits/Soundtrack_Server

STSynth's repo:<br>
https://github.com/Rexhits/STSynth


</p>
<br><br>
<p>
To Do:<br>
* Improve the LSTM-based deep learning model for piece combining (MIDI Based)<br>
* UI for user uploading/downloading blocks<br>
* Test & evalueation<br>
<br>
Done:<br>
* Server side is all ready<br>
* MIDI playback engine supporting sound fonts and third party audio units<br>
* Dedicated software synthesizer “STSynth”<br>
* Location related functionality (MapView on iOS, geographic info in database)<br>
* Save/restore audio engine states to/from server<br>
* Generating one new piece by combining features from 2 collected pieces. (MIDI Based)
* Render MIDI to mp3 for sharing <br>
 </p>


<p>
See the following paper for further details: <br>
https://github.com/Rexhits/soundtrack/blob/newBranch/Step%20into%20the%20Soundtrack.pdf
</p>
