# Soundtrack v0.14

1. Migrated the entire audio system from AVFoundation to AudioKit 3
2. Fixed the annoying "loop interval" when play midi in background
3. Enabled integration of chuck,stk and csound code, THANK TO AuidoKit 3!
4. Implemented step detection and mapped the step to piano note, brutal detection algorithm for now, but still kinda cool. (Only works on real devices, remember to click "load midi file" first)
5. Written some global functions and extensions (e.g. delayFunc, random)

# Soundtrack v0.13

1. Implemented multitrack midi playback (AVAudioEngine + AVAudioUnitSampler + AVAudioSequence)
2. Implemented some intelligent playback control (Time & Beat based)
3. Implemented user static tracking (CMMotionActivityManager)
4. Allowed play in background (I noticed that midi isn't runing as smooth as in foregound, luckily, all the intelligent controlling worked in background)
5. Get a start point for using Apple Map Kit
