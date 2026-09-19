// bridge.mjs - the Bend model of the JET protection chain as a JSON service, for the
// differential testing (run.py) and the independent re-check (recheck.py).
//   node --import file:///C:/Users/<you>/.bend-src/bend2/main.ts bridge.mjs
// One request per line on stdin, one JSON answer per line on stdout.
import Seq from "./jetprot.bend";
import readline from "node:readline";

const C = (name, fields = {}) => ({ $: name, ...fields });
const tag = (v) => (v && typeof v === "object" && "$" in v ? v.$ : v);

// --- state <-> flat JSON ---
const flat = (s) => ({
  phase: tag(s.fin.phase), level: tag(s.fin.level), dms: tag(s.fin.dms), plasma: s.fin.plasma,
  nb: tag(s.fin.nb), rf: tag(s.fin.rf), hb: Number(s.hb), tack: Number(s.tack),
});
const fin = (x) => C("Fin", { phase: C(x.phase), level: C(x.level), dms: C(x.dms), plasma: x.plasma, nb: C(x.nb), rf: C(x.rf) });
const finFlat = (f) => ({ phase: tag(f.phase), level: tag(f.level), dms: tag(f.dms), plasma: f.plasma, nb: tag(f.nb), rf: tag(f.rf) });
const nest = (x) => C("St", { fin: fin(x), hb: BigInt(x.hb), tack: BigInt(x.tack) });
const inst = (i) => C(i === 2 ? "Inst2" : "Inst1");
const ord = (o) => C(o === 2 ? "Ord2" : "Ord1");

// --- events from flat JSON: concrete {$:"XAlarm", t:"Dhs"} / abstract {$:"Stop", req:"LPtn", dms:true} ---
const cev = (e) => {
  switch (e.$) {
    case "XAlarm": return C("XAlarm", { t: C(e.t) });
    case "XLocal": case "XHeatOn": case "XHeatOff": return C(e.$, { u: C(e.u) });
    case "XPlasma": return C("XPlasma", { ok: e.ok });
    default: return C(e.$);
  }
};
const aev = (e) => {
  switch (e.$) {
    case "Stop": return C("Stop", { req: C(e.req), dms: e.dms });
    case "Local": case "HeatOn": case "HeatOff": return C(e.$, { u: C(e.u) });
    case "Plasma": return C("Plasma", { ok: e.ok });
    case "CommFault": case "Tick": return C(e.$, { dms: e.dms });
    default: return C(e.$);
  }
};
const aevFlat = (e) => {
  const o = { $: e.$ };
  for (const k of ["req", "u"]) if (k in e) o[k] = tag(e[k]);
  for (const k of ["dms", "ok"]) if (k in e) o[k] = e[k];
  return o;
};

// --- the abstract alphabet (24 variants) and the control domain (2688 states) ---
const PHASES = ["Breakdown", "IpRise", "Limiter", "Xpoint", "Heating1", "Heating2", "Termination"];
const LEVELS = ["LNone", "LJtt", "LRtps", "LPtn"];
const DMSS = ["DmsIdle", "DmsArmed", "DmsFired"];
const HEATS = ["Off", "Inhibited", "Ramping", "On"];
const EVENTS = [];
EVENTS.push({ $: "Advance" }, { $: "Heartbeat" }, { $: "HeatAck" }, { $: "Reset" });
for (const u of ["Nb", "Rf"]) EVENTS.push({ $: "Local", u }, { $: "HeatOn", u }, { $: "HeatOff", u });
for (const b of [true, false]) EVENTS.push({ $: "Plasma", ok: b }, { $: "CommFault", dms: b }, { $: "Tick", dms: b });
for (const req of LEVELS) for (const b of [true, false]) EVENTS.push({ $: "Stop", req, dms: b });

function* states(phase) {
  for (const level of LEVELS) for (const dms of DMSS) for (const plasma of [true, false])
    for (const nb of HEATS) for (const rf of HEATS) yield { phase, level, dms, plasma, nb, rf };
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of rl) {
  if (!line.trim()) continue;
  const req = JSON.parse(line);
  let out;
  if (req.init) {
    out = { state: flat(Seq.init()) };
  } else if (req.trace) {
    // a concrete trace through an instance: the trajectory and inv_all at every step
    const i = inst(req.inst || 1);
    let s = Seq.init();
    const states_ = [], invs = [];
    for (const e of req.trace) { s = Seq.step_c(i, s, cev(e)); states_.push(flat(s)); invs.push(Seq.inv_all(s)); }
    out = { states: states_, invs };
  } else if (req.check) {
    out = { invs: req.check.map((st) => Seq.inv_all(nest(st))) };
  } else if (req.cells) {
    // every cell of one phase under one order: the next control state and both commands
    const o = ord(req.cells.ord || 1);
    const rows = [];
    for (const f of states(req.cells.phase)) {
      const F = fin(f);
      for (const e of EVENTS) {
        const E = aev(e);
        // same five widened columns as enum_jetprot.bend (39 columns per state)
        const wide = e.$ === "Tick" || e.$ === "Reset" || (e.$ === "CommFault" && e.dms) || (e.$ === "Stop" && e.req === "LPtn" && e.dms);
        const verdicts = wide ? [[true, true], [true, false], [false, true], [false, false]] : [[true, true]];
        for (const [bt, bh] of verdicts) {
          const f2 = Seq.step_fin(o, F, E, bt, bh);
          rows.push({ f, e, bt, bh, f2: finFlat(f2), hb: tag(Seq.upd_hb(F, E, bh)), tack: tag(Seq.upd_tack(F, E, bt, bh)),
                      inv: Seq.inv_fin(F), inv2: Seq.inv_fin(f2) });
        }
      }
    }
    out = { rows };
  } else if (req.concretize) {
    const { inst: i, phase, cev: e } = req.concretize;
    out = { ev: aevFlat(Seq.concretize(inst(i), C(phase), cev(e))) };
  } else if (req.step_abs) {
    const { ord: o, f, e, bt, bh } = req.step_abs;
    out = { f2: finFlat(Seq.step_fin(ord(o), fin(f), aev(e), bt, bh)) };
  } else {
    out = { error: "unknown request" };
  }
  process.stdout.write(JSON.stringify(out) + "\n");
}
