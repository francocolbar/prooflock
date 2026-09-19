// bridge.mjs - exposes the Bend golden model (seq.bend) to Python for differential
// testing. Run with the Bend JS loader:
//   node --import file:///C:/Users/<you>/.bend-src/bend2/main.ts bridge.mjs
// Protocol: one JSON object per stdin line; one JSON object per stdout line.
//   {"trace": [ {"$":"Tick"}, {"$":"Vac","ok":true}, ... ]}
//     -> {"states": [state after each event], "invs": [inv_all after each event]}
//   {"check": [state, state, ...]}          (states produced by another implementation)
//     -> {"invs": [inv_all(state) ...]}
// A state is the Bend record {"$":"St","phase":{"$":"FlatTop"},"vac":true,...,"t_flat":2,"hb":0}.
import Seq from "./seq.bend";
import readline from "node:readline";

const fromBend = (v) => JSON.parse(JSON.stringify(v, (k, x) => (typeof x === "bigint" ? Number(x) : x)));
const toBend = (s) => ({ ...s, t_flat: BigInt(s.t_flat), hb: BigInt(s.hb) });

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
      states.push(fromBend(s));
      invs.push(Seq.inv_all(s));
    }
    process.stdout.write(JSON.stringify({ states, invs }) + "\n");
  } else if (req.check) {
    const invs = req.check.map((st) => Seq.inv_all(toBend(st)));
    process.stdout.write(JSON.stringify({ invs }) + "\n");
  } else if (req.init) {
    process.stdout.write(JSON.stringify({ state: fromBend(Seq.init()) }) + "\n");
  } else {
    process.stdout.write(JSON.stringify({ error: "unknown request" }) + "\n");
  }
}
