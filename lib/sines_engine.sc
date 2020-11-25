//16 FM modulated sine waves
Engine_Sines : CroneEngine {

	var <synths;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		//https://depts.washington.edu/dxscdoc/Help/Tutorials/Mark_Polishook_tutorial/18_Frequency_modulation.html
		SynthDef.new(\fm1, { arg out, freq = 440, carPartial = 1, modPartial = 1, index = 3, mul = 0.05, pan = 0;
			// index values usually are between 0 and 24
			// carPartial :: modPartial => car/mod ratio

			var mod;
			var car;
			var sig;
			var env_hummingbird;
			var env_drone;
			var env_pulse;
			var env_ping;
			var env_static;
			var amp;

			mod = SinOsc.ar(
				freq * modPartial,
				0,
				freq * index * LFNoise1.kr(5.reciprocal).abs
			);
			car = SinOsc.ar(
				freq * carPartial + mod,
				0,
				mul
			);
			//basic bitch
			//sig = Pan2.ar(car, pan);

			//looping decay env			
			//env = Env([0, 1, 0, 0.2, 0, 0.5, 0.8, 0], [0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01], releaseNode: 5, loopNode: 1);
			//amp = EnvGen.kr(env, doneAction: Done.freeSelf);
			//sig = Decay.ar(Impulse.ar(amp), 1.0, Pan2.ar(car, pan), 0);


			//static
			env_static = Env([0,1,0],[0.5,2], releaseNode: 1, loopNode: 0);
			//hummingbird
			env_hummingbird = Env([0, 1, 0, 0.2, 0, 0.5, 0.8, 0], [0.01, 0.02, 0.01, 0.07, 0.01, 0.01, 0.01], releaseNode: 5, loopNode: 1);
			//pulse
			env_pulse = Env([0, 1, 0, 0.2, 0, 0.5, 0.8, 0], [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1], releaseNode: 5, loopNode: 1);
			//ping
			env_ping = Env([0, 1, 0, 1, 0, 1, 0], [0.01, 0.1, 0.01, 0.1, 0.01, 0.1], releaseNode: 4, loopNode: 1);			
			//drone
			env_drone = Env([0, 1, 0, 0.2, 0, 0.5, 0.8, 0], [3, 5, 3, 2, 3, 1, 0.8], releaseNode: 5, loopNode: 1);
			//amp and out
			amp = EnvGen.kr(env_pulse, doneAction: Done.freeSelf);
			sig = Pan2.ar(car * amp, pan);			

			//SHITTY BOUNCING BALL
			//sig = Decay.ar(Impulse.ar(XLine.kr(1,50,20), 0.25), 0.2, Pan2.ar(car, pan), 0);
			Out.ar(out, sig)			
		}).add;

		// make 16 synths, each using the def
		synths = Array.fill(16, {
			var out;
			var freq;
			var carPartial;
			var modPartial;
			var index;
			var mul;
			var pan;
			var params = [out, \freq, freq, \carPartial, carPartial, \modPartial, modPartial, \index, index, \mul, mul, \pan, pan];
			params.postln;
			// this is where we supply the name of the def we made
			Synth.new(\fm1, params, target: context.og);
		});

		context.server.sync;

		(1..16).do({ |i|
			//pan settings
			this.addCommand(\pan ++ i, "f", {
				arg msg;
				synths[i].set(\pan, msg[1]);
			});
			//index settings
			this.addCommand(\index ++ i, "f", {
				arg msg;
				synths[i].set(\index, msg[1]);
			});
			//amp settings
			this.addCommand(\mul ++ i, "f", {
				arg msg;
				synths[i].set(\mul, msg[1]);
			});
			//carPartial settings
			this.addCommand(\carPartial ++ i, "f", {
				arg msg;
				synths[i].set(\carPartial, msg[1]);
			});
			//modPartial settings
			this.addCommand(\modPartial ++ i, "f", {
				arg msg;
				synths[i].set(\modPartial, msg[1]);
			});
			//freq settings
			this.addCommand(\freq ++ i, "f", {
				arg msg;
				synths[i].set(\freq, msg[1]);
			});
		});

	}

	//free the synths
	free {
		synths[1].free;
		synths[2].free;
		synths[3].free;
		synths[4].free;
		synths[5].free;
		synths[6].free;
		synths[7].free;
		synths[8].free;
		synths[9].free;
		synths[10].free;
		synths[11].free;
		synths[12].free;
		synths[13].free;
		synths[14].free;
		synths[15].free;
		synths[16].free;
	}

}

