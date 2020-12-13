//16 FM modulated sine waves
Engine_Sines : CroneEngine {

	var <synths;

	*new { arg context, doneCallback;
	^super.new(context, doneCallback);
}

alloc {
	//https://depts.washington.edu/dxscdoc/Help/Tutorials/Mark_Polishook_tutorial/18_Frequency_modulation.html
	SynthDef.new(\fm1, { arg out, sine_freq = 440, carPartial = 1, modPartial = 1, fm_index = 3, fm_mul = 0.00, sine_pan = 0.0, begin = 0, middle = 1, end = 0, attack_time = 0.01, decay_time = 0.1;
		// index values usually are between 0 and 24
		// carPartial :: modPartial => car/mod ratio

		var mod;
		var car;
		var sig;
		var amp;
		var sine_env;

		mod = SinOsc.ar(
			sine_freq * modPartial,
			0,
			sine_freq * fm_index * LFNoise1.kr(5.reciprocal).abs
		);
		car = SinOsc.ar(
			sine_freq * carPartial + mod,
			0,
			fm_mul
		);
		//Looping AD envelope
		sine_env = Env([0, begin, middle, end], [attack_time, decay_time, 0.1], releaseNode: 2, loopNode: 0);			
		//amp and out
		amp = EnvGen.kr(sine_env, doneAction: Done.freeSelf);
		sig = Pan2.ar(car * amp, sine_pan, 1);			

		Out.ar(out, sig)			
	}).add;

	// make 16 synths, each using the def
	synths = Array.fill(16, {
		var out;
		var sine_freq;
		var fm_index;
		var fm_mul;
		var sine_pan;
		var attack_time; 
		var decay_time;
		var begin;
		var middle;
		var end; 
		var params = [out, \sine_freq, sine_freq, \fm_index, fm_index, \fm_mul, fm_mul, \sine_pan, sine_pan, \begin, begin, \middle, middle, \end, end, \attack_time, attack_time, \decay_time, decay_time];
		//params.postln;
		// this is where we supply the name of the def we made
		Synth.new(\fm1, params, target: context.og);
	});

	context.server.sync;

	//pan settings
	this.addCommand(\sine_pan, "ii", {
		arg msg;
		synths[msg[1]].set(\sine_pan, msg[2]);
	});
	//index settings
	this.addCommand(\fm_index, "ii", {
		arg msg;
		synths[msg[1]].set(\fm_index, msg[2]);
	});
	//amp settings
	this.addCommand(\fm_mul, "if", {
		arg msg;
		synths[msg[1]].set(\fm_mul, msg[2]);
	});
	//freq settings
	this.addCommand(\sine_freq, "ii", { 
		arg msg;
		synths[msg[1]].set(\sine_freq, msg[2]);
	});
	//envelope settings
	this.addCommand(\sine_env, "iiiiii", { 
		arg msg;
		synths[msg[1]].set(\begin, msg[2]);
		synths[msg[1]].set(\middle, msg[3]);
		synths[msg[1]].set(\end, msg[4]);
		synths[msg[1]].set(\attack_time, msg[5]);
		synths[msg[1]].set(\decay_time, msg[6]);
	});

}

//free the synths
free {
	synths[0].free;
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
}

}

