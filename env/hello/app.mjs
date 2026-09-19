import Lib from "./lib.bend";
const e = Lib.sample();
console.log(JSON.stringify(e, (k, v) => typeof v === "bigint" ? v.toString() + "n" : v));
console.log(Lib.show(e));
console.log(Lib.show({$: "Mul", a: {$: "Var"}, b: {$: "Lit", n: 7n}}));
