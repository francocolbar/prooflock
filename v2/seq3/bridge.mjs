// bridge.mjs (seq3) - the redesigned model as a JSON service, with the same flat state
// shape as seq/bridge.mjs so prod/sequencer_prod.py needs no change.
//   node --import file:///C:/Users/<you>/.bend-src/bend2/main.ts bridge.mjs
import Seq from "./seq3.bend";
import readline from "node:readline";

const flat = (s) => ({ $: "St", phase: s.fin.phase, vac: s.fin.vac, tf: s.fin.tf, dens: s.fin.dens,
                       gas: s.fin.gas, cs: s.fin.cs, heat: s.fin.heat, t_flat: Number(s.t_flat), hb: Number(s.hb) });
const nest = (s) => ({ $: "St", fin: { $: "Fin", phase: s.phase, vac: s.vac, tf: s.tf, dens: s.dens, gas: s.gas, cs: s.cs, heat: s.heat },
                       t_flat: BigInt(s.t_flat), hb: BigInt(s.hb) });

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of rl) {
  if (!line.trim()) continue;
  const req = JSON.parse(line);
  if (req.trace) {
    let s = Seq.init();
    const states = [];
    const invs = [];
    for (const e of req.trace) {
      s = Seq.step(s, e);
      states.push(flat(s));
      invs.push(Seq.inv_all(s));
    }
    process.stdout.write(JSON.stringify({ states, invs }) + "\n");
  } else if (req.check) {
    const invs = req.check.map((st) => Seq.inv_all(nest(st)));
    process.stdout.write(JSON.stringify({ invs }) + "\n");
  } else if (req.init) {
    process.stdout.write(JSON.stringify({ state: flat(Seq.init()) }) + "\n");
  } else {
    process.stdout.write(JSON.stringify({ error: "unknown request" }) + "\n");
  }
}
