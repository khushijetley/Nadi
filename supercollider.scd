
(
s.options.numInputBusChannels = 0;
s.options.outDevice = "External Headphones";

s.waitForBoot {

	~root = 60;

	SynthDef(\sitar, {
		arg out=0, freq=440, amp=0.45, dec=2.0;
		var sig, sig2, sig3, env;
		env  = EnvGen.kr(Env.perc(0.005, dec, amp, -3.0), doneAction:2);
		sig  = Pluck.ar(WhiteNoise.ar(0.3),  Impulse.ar(0), 1/freq, 1/freq, dec*1.4, 0.25);
		sig2 = Pluck.ar(WhiteNoise.ar(0.12), Impulse.ar(0), 1/(freq*1.004), 1/(freq*1.004), dec*0.85, 0.22);
		sig3 = Pluck.ar(WhiteNoise.ar(0.05), Impulse.ar(0), 1/(freq*2.003), 1/(freq*2.003), dec*0.6, 0.18);
		sig  = ((sig + (sig2*0.38) + (sig3*0.18)) * env).tanh * 0.7;
		sig  = LPF.ar(sig, 2900 + (freq*1.8));
		sig  = HPF.ar(sig, 55);
		Out.ar(out, Pan2.ar(sig, 0));
	}).add;

	SynthDef(\meend, {
		arg out=0, freqStart=400, freqEnd=440, amp=0.45, dec=2.0;
		var freq, sig, sig2, env;
		env  = EnvGen.kr(Env.perc(0.005, dec, amp, -3.0), doneAction:2);
		freq = XLine.kr(freqStart, freqEnd, 0.20, doneAction:0);
		sig  = Pluck.ar(WhiteNoise.ar(0.3),  Impulse.ar(0), 1/freq, 1/freq, dec*1.3, 0.25);
		sig2 = Pluck.ar(WhiteNoise.ar(0.10), Impulse.ar(0), 1/(freq*1.004), 1/(freq*1.004), dec*0.8, 0.22);
		sig  = (((sig + (sig2*0.38)) * env).tanh * 0.7);
		sig  = LPF.ar(sig, 2900);
		Out.ar(out, Pan2.ar(sig, 0));
	}).add;

	SynthDef(\gamaka, {
		arg out=0, freq=440, amp=0.45, dec=2.0, rate=7.0, width=0.032;
		var mf, sig, sig2, env;
		env  = EnvGen.kr(Env.perc(0.005, dec, amp, -3.0), doneAction:2);
		mf   = freq * SinOsc.kr(rate, 0, width, 1);
		sig  = Pluck.ar(WhiteNoise.ar(0.3),  Impulse.ar(0), 1/mf, 1/mf, dec*1.3, 0.25);
		sig2 = Pluck.ar(WhiteNoise.ar(0.10), Impulse.ar(0), 1/(mf*1.003), 1/(mf*1.003), dec*0.8, 0.22);
		sig  = (((sig + (sig2*0.38)) * env).tanh * 0.7);
		sig  = LPF.ar(sig, 2900);
		Out.ar(out, Pan2.ar(sig, 0));
	}).add;

	SynthDef(\tanpura, {
		arg out=0, root=60, amp=0.10;
		var freqs, sigs, trig;
		freqs = [root.midicps*1.5, root.midicps*1.5, root.midicps*1.333, root.midicps];
		trig  = Impulse.kr(0.42);
		sigs  = freqs.collect { arg f, i;
			Pluck.ar(WhiteNoise.ar(0.08), DelayN.kr(trig,2,(i*0.52)+0.08), 1/f, 1/f, 6.0, 0.42)
			* SinOsc.kr(0.08+(i*0.018), i*1.2).range(0.65, 1.0)
		};
		Out.ar(out, Pan2.ar(Mix(sigs)*amp, 0));
	}).add;

	SynthDef(\bayan, {
		arg out=0, amp=0.18;
		var env = EnvGen.kr(Env.perc(0.001, 0.38, amp, -4), doneAction:2);
		Out.ar(out, Pan2.ar(HPF.ar(
			BPF.ar(WhiteNoise.ar, 80, 0.9)*env + BPF.ar(WhiteNoise.ar, 160, 0.4)*env*0.3,
		40), -0.2));
	}).add;

	SynthDef(\dayan, {
		arg out=0, amp=0.12;
		var env = EnvGen.kr(Env.perc(0.001, 0.08, amp, -7), doneAction:2);
		Out.ar(out, Pan2.ar(HPF.ar(
			BPF.ar(WhiteNoise.ar, 900, 0.5)*env + BPF.ar(WhiteNoise.ar, 350, 0.6)*env*0.35,
		200), 0.2));
	}).add;

	s.sync;

	~drone = Synth(\tanpura, [root: ~root]);

	// Visual relay
	~visualAddr = NetAddr("127.0.0.1", 57200);

	// HR input
	~hrSmoothed    = 70;
	~hrHistory     = Array.fill(20, { 70.0 });
	~hrVariability = 0;
	~hrBus         = Bus.control(s, 1);
	~hrBus.set(70);
	~lastHRTime    = Main.elapsedTime;
	~fingerOn      = false;

	OSCdef(\heartRate, { arg msg;
		var raw = msg[1].asFloat;
		if((raw > 30) && (raw < 200), {
			~hrBus.set(raw);
			~lastHRTime = Main.elapsedTime;
			~fingerOn   = true;
			~visualAddr.sendMsg('/hr', raw);
		});
	}, '/hr');

	// Session state
	~sessionDuration = 90;
	~sessionStart    = 0;
	~autonomy        = 0.0;
	~phase           = \waiting;
	~sessionActive   = false;
	~userCount       = 0;
	~machineDesire   = \bhimpalasi;
	~machineTimer    = 0;
	~currentRaga     = \bhimpalasi;
	~rageDwellTime   = 0;
	~agentMood       = 0.5;

	~freePool = [
		[0,1,4,5,7,8,11,12],
		[0,3,5,7,9,10,12],
		[0,2,4,7,9,12,14]
	];

	~ragaIndex = [\bhairav, \bhimpalasi, \bhupali];

	~ragaSettings = Dictionary.new;
	~ragaSettings[\bhairav]    = (bd: 1.8,  amp: 0.52, decMult: 4.5, tablaVol: 0.06, varyProb: 0.15, octave: 0,  silenceProb: 0.40);
	~ragaSettings[\bhimpalasi] = (bd: 0.76, amp: 0.46, decMult: 2.2, tablaVol: 0.15, varyProb: 0.35, octave: 0,  silenceProb: 0.18);
	~ragaSettings[\bhupali]    = (bd: 0.38, amp: 0.40, decMult: 0.9, tablaVol: 0.28, varyProb: 0.55, octave: 12, silenceProb: 0.05);

	~bhairavComp = [
		[0,3,\plain],[1,1,\gamaka],[4,2,\meend],[5,4,\gamaka],
		[5,1,\plain],[7,1,\plain],[8,2,\gamaka],[7,1,\plain],[5,3,\gamaka],
		[11,1,\meend],[12,2,\plain],[13,1,\gamaka],[12,1,\plain],
		[11,1,\plain],[8,2,\gamaka],[7,4,\plain],
		[5,1,\plain],[4,1,\plain],[1,2,\gamaka],[0,5,\plain],
	];

	~bhimpalasiComp = [
		[0,2,\plain],[3,1,\meend],[5,2,\plain],[7,1,\plain],[9,3,\gamaka],
		[9,1,\plain],[10,1,\plain],[9,2,\gamaka],[7,1,\plain],
		[5,2,\plain],[3,3,\gamaka],[3,1,\plain],[5,1,\plain],
		[7,1,\plain],[9,1,\plain],[10,1,\plain],[12,3,\plain],
		[10,1,\plain],[9,2,\gamaka],[7,1,\plain],
		[5,1,\plain],[3,1,\meend],[2,1,\plain],[0,5,\plain],
	];

	~bhupaliComp = [
		[0,1,\plain],[2,1,\meend],[4,2,\plain],[7,1,\plain],[9,2,\gamaka],
		[4,1,\plain],[7,1,\plain],[4,1,\plain],[2,1,\plain],[0,2,\plain],
		[7,1,\plain],[9,1,\plain],[12,2,\meend],[14,1,\plain],[12,1,\plain],
		[9,2,\gamaka],[7,1,\plain],[4,1,\plain],[2,1,\plain],[0,3,\plain],
		[4,1,\kan],[7,1,\plain],[9,1,\plain],[7,1,\plain],[4,2,\gamaka],[0,3,\plain],
	];

	~currentComp = ~bhimpalasiComp;

	// Reset for new user
	~resetForNewUser = {
		~sessionActive  = false;
		~fingerOn       = false;
		~hrSmoothed     = 70;
		~agentMood      = 0.5;
		~rageDwellTime  = 0;
		~currentRaga    = \bhimpalasi;
		~currentComp    = ~bhimpalasiComp;
		~hrHistory      = Array.fill(20, { 70.0 });
		~hrVariability  = 0;
		~autonomy       = 0.0;
		~phase          = \waiting;
		~machineDesire  = \bhimpalasi;
		~machineTimer   = 0;
		~userCount      = ~userCount + 1;
		~visualAddr.sendMsg('/reset');
		"".postln;
		("=== USER " ++ ~userCount ++ " COMPLETE — waiting for next ===").postln;
		"".postln;
	};

	// Transition matrices
	~transLow = Dictionary.new;
	~transLow[\bhairav]    = [0.75, 0.22, 0.03];
	~transLow[\bhimpalasi] = [0.35, 0.58, 0.07];
	~transLow[\bhupali]    = [0.15, 0.55, 0.30];

	~transMid = Dictionary.new;
	~transMid[\bhairav]    = [0.40, 0.50, 0.10];
	~transMid[\bhimpalasi] = [0.20, 0.62, 0.18];
	~transMid[\bhupali]    = [0.08, 0.42, 0.50];

	~transHigh = Dictionary.new;
	~transHigh[\bhairav]    = [0.30, 0.45, 0.25];
	~transHigh[\bhimpalasi] = [0.10, 0.45, 0.45];
	~transHigh[\bhupali]    = [0.05, 0.20, 0.75];

	~getTimeModifier = {
		var hour = Date.getDate.hour;
		if((hour >= 5)  && (hour < 9),  { [0.15, 0.0,  -0.10] },
		if((hour >= 9)  && (hour < 12), { [0.05, 0.05, -0.05] },
		if((hour >= 12) && (hour < 17), { [0.0,  0.08,  0.0]  },
		if((hour >= 17) && (hour < 22), { [-0.08, 0.0,  0.12] },
		                                { [0.10,  0.0, -0.08]  }))))
	};

	~agentDecide = {
		var hrZone, baseProbs, timeMod, finalProbs, roll, cumulative, chosen, total;
		hrZone = if(~hrSmoothed < 65,
			{ \low },
			{ if(~hrSmoothed < 85, { \mid }, { \high }) }
		);
		baseProbs = switch(hrZone)
			{ \low  } { ~transLow[~currentRaga]  }
			{ \mid  } { ~transMid[~currentRaga]  }
			{ \high } { ~transHigh[~currentRaga] };
		timeMod    = ~getTimeModifier.value;
		finalProbs = baseProbs.collect { arg p, i; (p + timeMod[i]).max(0.01) };
		total      = finalProbs.sum;
		finalProbs = finalProbs.collect { arg p; p / total };
		roll       = rrand(0.0, 1.0);
		cumulative = 0;
		chosen     = ~currentRaga;
		finalProbs.size.do { arg i;
			cumulative = cumulative + finalProbs[i];
			if((roll <= cumulative) && (chosen == ~currentRaga), {
				chosen = ~ragaIndex[i];
			});
		};
		chosen
	};

	~getAutonomyPhase = {
		var a = ~autonomy;
		if(a < 0.2, { \listening },
		if(a < 0.5, { \negotiating },
		if(a < 0.8, { \asserting  },
		            { \free        })))
	};

	~generateFreePhrase = {
		var wildness, pool, len, phrase, note, beats, orn;
		wildness = (~autonomy - 0.8) / 0.2;
		pool     = if(wildness < 0.5, { ~freePool.choose }, { (0..16) });
		len      = rrand(4, 10);
		phrase   = Array.new(len);
		len.do {
			note   = pool.choose;
			beats  = [0.5, 1, 1, 2, 3].choose;
			orn    = [\plain, \plain, \meend, \gamaka].choose;
			phrase = phrase.add([note, beats, orn]);
		};
		phrase
	};

	~playNote = { arg midi, dec, amp, orn, octave;
		var freq;
		octave = octave ? 0;
		freq   = (~root + midi + octave).midicps;
		switch(orn)
		{ \plain  } { Synth(\sitar,  [freq: freq, amp: amp, dec: dec]) }
		{ \meend  } { Synth(\meend,  [freqStart: freq * 0.944, freqEnd: freq, amp: amp, dec: dec]) }
		{ \gamaka } { Synth(\gamaka, [freq: freq, amp: amp, dec: dec, rate: rrand(6.0,8.5), width: rrand(0.025,0.04)]) }
		{ \kan    } {
			Synth(\sitar, [freq: freq * 1.059, amp: amp*0.4, dec: 0.1]);
			{ Synth(\sitar, [freq: freq, amp: amp, dec: dec]) }.defer(0.07);
		};
	};

	~ornChoice = { arg preferred, varyProb;
		if(varyProb.coin,
			{ [\plain, \plain, \meend, \gamaka].choose },
			{ preferred }
		)
	};

	// Melody routine
	~melodyRoutine = Routine({
		var set, comp, midi, beats, orn, dec, amp, bd, octave;
		loop {
			if((~autonomy > 0.8) && ~sessionActive, {
				comp   = ~generateFreePhrase.value;
				set    = ~ragaSettings[~machineDesire];
				bd     = set[\bd] * rrand(0.7, 1.4);
				amp    = set[\amp];
				octave = [0, 0, 12, -12].choose;
			}, {
				set    = ~ragaSettings[~currentRaga];
				comp   = ~currentComp;
				bd     = set[\bd];
				amp    = set[\amp];
				octave = set[\octave];
			});

			comp.do { arg entry;
				if((~autonomy > 0.8) && ~sessionActive, {
					set    = ~ragaSettings[~machineDesire];
					bd     = set[\bd] * rrand(0.7, 1.4);
					amp    = set[\amp];
					octave = [0, 0, 12, -12].choose;
				}, {
					set    = ~ragaSettings[~currentRaga];
					bd     = set[\bd];
					amp    = set[\amp];
					octave = set[\octave];
					comp   = ~currentComp;
				});
				midi  = entry[0];
				beats = entry[1];
				orn   = entry[2];
				dec   = bd * beats * set[\decMult];
				orn   = ~ornChoice.(orn, set[\varyProb]);
				if(set[\silenceProb].coin.not, {
					if(~sessionActive, { ~playNote.(midi, dec, amp, orn, octave) });
				});
				(bd * beats).wait;
			};
			if(~sessionActive,
				{ (set[\bd] * rrand(1.0, 3.0)).wait },
				{ 1.0.wait }
			);
		}
	}).play;

	// Tabla routine
	~tablaRoutine = Routine({
		var beat, set, vol, bd, extraHit;
		beat = 0;
		loop {
			set      = ~ragaSettings[~currentRaga];
			vol      = set[\tablaVol];
			bd       = set[\bd];
			if(~autonomy > 0.8, {
				vol = vol * rrand(0.5, 2.0);
				bd  = bd  * rrand(0.6, 1.5);
			});
			if(~sessionActive, {
				case
				{ beat == 0  } { Synth(\bayan,[amp:vol*1.3]); Synth(\dayan,[amp:vol]) }
				{ beat == 4  } { Synth(\dayan,[amp:vol*0.9]) }
				{ beat == 8  } { Synth(\bayan,[amp:vol*1.1]); Synth(\dayan,[amp:vol*0.75]) }
				{ beat == 12 } { Synth(\dayan,[amp:vol*0.85]) }
				{ [2,6,10,14].includes(beat) } {
					extraHit = (~currentRaga != \bhairav) || (~autonomy > 0.6);
					if(extraHit, { Synth(\dayan,[amp:vol*0.4]) });
				};
			});
			beat = (beat+1) % 16;
			bd.wait;
		}
	}).play;

	// Agent + autonomy routine
	~agentRoutine = Routine({
		var raw, newRaga, targetMood, elapsed, newPhase, reason;
		loop {
			raw         = ~hrBus.getSynchronous;
			~hrSmoothed = (~hrSmoothed * 0.88) + (raw * 0.12);
			~hrHistory.removeAt(0);
			~hrHistory  = ~hrHistory.add(raw);
			~hrVariability = 0;
			targetMood  = ~hrSmoothed.linlin(50, 110, 0.0, 1.0).clip(0, 1);
			~agentMood  = (~agentMood * 0.95) + (targetMood * 0.05);

			if(~sessionActive, {
				elapsed   = Main.elapsedTime - ~sessionStart;
				~autonomy = (elapsed / ~sessionDuration).clip(0.0, 1.0);
				newPhase  = ~getAutonomyPhase.value;

				~visualAddr.sendMsg('/autonomy', ~autonomy.asFloat);

				if(newPhase != ~phase, {
					~phase = newPhase;
					~visualAddr.sendMsg('/phase', ~phase.asString);
					"".postln;
					("=== PHASE: " ++ ~phase.asString.toUpper ++ " (autonomy: " ++ ~autonomy.round(0.01) ++ ") ===").postln;
					"".postln;
				});

				~machineTimer = ~machineTimer + 1;
				if(~machineTimer > 4, {
					~machineDesire = ~ragaIndex.choose;
					~machineTimer  = 0;
				});

				if(~autonomy < 0.8, {
					newRaga = if((~autonomy > 0.5) && 0.4.coin,
						{ ~machineDesire },
						{ ~agentDecide.value }
					);
					if(newRaga != ~currentRaga, {
						reason = if(~autonomy > 0.5, { " [machine]" }, { "" });
						(">>> " ++ newRaga ++ reason).postln;
						~currentRaga   = newRaga;
						~currentComp   = switch(newRaga)
							{\bhairav}    { ~bhairavComp }
							{\bhimpalasi} { ~bhimpalasiComp }
							{\bhupali}    { ~bhupaliComp };
						~rageDwellTime = 0;
						~visualAddr.sendMsg('/raga', newRaga.asString);
					}, {
						~rageDwellTime = ~rageDwellTime + 1;
					});
				}, {
					if(~machineDesire != ~currentRaga, {
						(">>> " ++ ~machineDesire ++ " [FREE]").postln;
						~currentRaga = ~machineDesire;
						~currentComp = switch(~machineDesire)
							{\bhairav}    { ~bhairavComp }
							{\bhimpalasi} { ~bhimpalasiComp }
							{\bhupali}    { ~bhupaliComp };
						~visualAddr.sendMsg('/raga', ~machineDesire.asString);
					});
				});
			});
			3.wait;
		}
	}).play;

	// Finger detection
	~fingerRoutine = Routine({
		loop {
			var elapsed = Main.elapsedTime - ~lastHRTime;
			if(~fingerOn && (elapsed > 5.0), {
				~fingerOn = false;
				~resetForNewUser.value;
			});
			if(~fingerOn && ~sessionActive.not, {
				~sessionActive = true;
				~sessionStart  = Main.elapsedTime;
				~autonomy      = 0.0;
				~phase         = \listening;
				~hrSmoothed    = 70;
				~agentMood     = 0.5;
				~rageDwellTime = 0;
				~currentRaga   = \bhimpalasi;
				~currentComp   = ~bhimpalasiComp;
				~machineTimer  = 0;
				~machineDesire = \bhimpalasi;
				~visualAddr.sendMsg('/raga', 'bhimpalasi');
				~visualAddr.sendMsg('/phase', 'listening');
				~visualAddr.sendMsg('/autonomy', 0.0);
				"".postln;
				"=== NEW USER — session starting ===".postln;
				"PHASE: LISTENING".postln;
				"".postln;
			});
			2.wait;
		}
	}).play;

	// Status
	~statusRoutine = Routine({
		var name, elapsed;
		loop {
			if(~sessionActive, {
				elapsed = (Main.elapsedTime - ~sessionStart).round(1);
				name = switch(~currentRaga)
					{\bhairav}    { "Bhairav" }
					{\bhimpalasi} { "Bhimpalasi" }
					{\bhupali}    { "Bhupali" };
				("t:"++elapsed++"s  HR:"++~hrSmoothed.round(1)
					++"  auto:"++~autonomy.round(0.01)
					++"  "++~phase++"  → "++name).postln;
			});
			3.wait;
		}
	}).play;

	~cleanup = {
		~melodyRoutine.stop;
		~tablaRoutine.stop;
		~agentRoutine.stop;
		~fingerRoutine.stop;
		~statusRoutine.stop;
		OSCdef(\heartRate).free;
		~drone.free;
		"Stopped.".postln;
	};

	"==============================================".postln;
	"NADI: THE BODY KNOWS — final".postln;
	"90 second arc. Finger on = start. Off 5s = reset.".postln;
	"Stop: ~cleanup.value".postln;
	"==============================================".postln;
};
)
