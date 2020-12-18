//16 sines
//thank you zebra

Engine_16sines : CroneEngine {
	classvar num;
	var <synth;

	*initClass {  num = 16; }

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		var server = Crone.server;
		var def = SynthDef.new(\fm1, { arg out, sine_freq = 440, carPartial = 1, modPartial = 1, fm_index = 3.0, sine_vol = 1.0, sine_pan = 0, begin = 0, middle = 1, end = 0, attack_time = 0.01, decay_time = 0.1;
		// index values usually are between 0 and 24
		// carPartial :: modPartial => car/mod ratio

		var mod;
		var car;
		var sig;
		var amp;
		var env;

		mod = SinOsc.ar(
			sine_freq * modPartial,
			0,
			sine_freq * fm_index * LFNoise1.kr(5.reciprocal).abs
		);
		car = SinOsc.ar(
			sine_freq * carPartial + mod,
			0,
			sine_vol
		);
		//Looping AD envelope
		env = Env([0, begin, middle, end], [attack_time, decay_time, 0.1], releaseNode: 2, loopNode: 0);			
		//amp and out
		amp = EnvGen.kr(env);
		sig = Pan2.ar(car * amp, sine_pan, 1);			
		sig = LeakDC.ar(sig);
		
		Out.ar(out, sig)			
	});
		def.send(server); 
		server.sync;
		
		synth = Array.fill(num, { Synth.new(\fm1, [\out, context.out_b], target: context.xg) });

		#[\sine_freq, \fm_index, \sine_vol, \sine_pan, \begin, \middle, \end, \attack_time, \decay_time].do({
			arg name;
			this.addCommand(name, "if", {
				arg msg;
				var i = msg[1] -1;
				if(i<num && i >= 0, { 
					synth[i].set(name, msg[2]);
				});
			});
		});
	}

	free {
		synth.do({ |syn| syn.free; });
	}
}