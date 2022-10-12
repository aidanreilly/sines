# Sines

A simple FM sine drone synth with 16 independant sine waves. Each sine wave is FM modulated with configurable carrier - modulator FM index. Sample rate and bit depth can be changed for each voice. 

![sines](sines.png)

## Installation

Ensure you are up to date with the latest norns OS. Visit http://norns.local/ in a browser, and install `sines` from the maiden project manager.

Then, `SYSTEM => RESET` on norns to pick up the new SuperCollider engine. Restart for good measure.

Optional: install @catfact's z_tuning norns mod to enable microtuning support in norns. Run `;install https://github.com/catfact/z_tuning` in the maiden console, and then enable it in `SYSTEM => MODS`. Reset + restart norns.

Sines uses the z_tuning mod when it is active. To switch to standard 12-tet tuning, disable z_tuning from the mods menu and restart norns.

## Play

Select a root note and scale from the norns parameters menu. 16 frequencies based on the selected scale are applied. You can also tune the sine waves by hand on norns.

### Controls

**norns**
* `E2` - active sine
* `E3` - sine volume
* `K2` - toggle sines/ctrl
* `K3` - toggle env/follow

**16n**
* `n` - sine volume

**crow**
* `E1` - select crow config

**z_tuning mod**
* Change `z_tuning` options in parameters > edit > Z_TUNING

### Midi control

The 16n midi controller is mapped by default. You can use other midi controllers too.

Control individual sine amplitudes, envelopes, bit depth, sample rate, and FM index with a midi controller. Controls are mapped from the norns parameters page.

