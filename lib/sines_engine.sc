// a few sines
// https://github.com/catfact/zebra/blob/master/lib/Engine_Zsins.sc
// thank you zebra

Engine_Sines : CroneEngine {
  classvar num;
  var <synth;

  *initClass {  num = 16; }

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    var server = Crone.server;
    var def = SynthDef.new(\sin, {
      arg out, hz=220, hz_lag=0.005,
        env_bias=0.0, amp_atk=0.001, amp_rel=0.05,
        pan=0, pan_lag=0.005, mul=1, modPartial=1, carPartial=1, fm_index=1;
      var mod, car, amp_, hz_, pan_;
      amp_ = EnvGen.ar(Env.circle([0, 1, 0], [amp_atk, amp_rel, 0.001]), levelBias: env_bias);
      hz_ = Lag.ar(K2A.ar(hz), hz_lag);
      pan_ = Lag.ar(K2A.ar(pan), pan_lag);
      //could also try replacing with https://doc.sccode.org/Classes/PMOsc.html
      mod = SinOsc.ar(hz_ * modPartial, 0, hz_ * fm_index * LFNoise1.kr(5.reciprocal).abs);
      car = SinOsc.ar(hz_ * carPartial + mod, 0, mul);
      Out.ar(out, Pan2.ar(car * amp_, pan));
    });
    def.send(server);
    server.sync;

    synth = Array.fill(num, { Synth.new(\sin, [\out, context.out_b], target: context.xg) });

    #[\hz, \env_bias, \pan, \amp_atk, \amp_rel, \hz_lag, \pan_lag, \fm_index].do({
      arg name;
      this.addCommand(name, "if", {
        arg msg;
        var i = msg[1];
        synth[i].set(name, msg[2]);
      });
    });

  }

  free {
    synth.do({ |syn| syn.free; });
  }
}


