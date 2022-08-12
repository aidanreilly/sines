--thank you zebra: https://github.com/catfact/z_tuning

local tu = {}

tu.LOG2 = math.log(2)

function tu.log2(x) 
    return math.log(x) / tu.LOG2
end

function tu.ratio_st(ratio)
    return tu.log2(ratio)*12
end

function tu.hz_midi(hz)
    return ratio_st(hz/440)+69
end

function tu.midi_hz(midi)
    return 440 * (2.0^((midi-69)/12.0))
end

return tu