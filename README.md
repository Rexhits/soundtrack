# soundtrack

Soundtrack is an iOS musical social network APP which enables musician to post audio or MIDI clips at certain location, and let users/fans to collect those clips and mesh the clips up to compose their own pieces by using provided algorithms. This APP is written in Swift, the backend is written in Python with Django, it also features a dedicated software synthesizer I wriiten in JUCE called "STSynth".


Server's repo is found here: 
https://github.com/Rexhits/Soundtrack_Server

STSynth's repo:
https://github.com/Rexhits/STSynth


To Do:
* Improve the LSTM-based deep learning model for piece combining (MIDI Based)
* UI for user uploading/downloading blocks
* Test & evalueation

Done:
* Server side is all ready
* MIDI playback engine supporting sound fonts and third party audio units
* Dedicated software synthesizer “STSynth”
* Location related functionality (MapView on iOS, geographic info in database)
* Save/restore audio engine states to/from server
* Generating one new piece by combining features from 2 collected pieces. (MIDI Based)


