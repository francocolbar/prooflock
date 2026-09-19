import Base

# Interop route B: Bend writes the file itself. Bend has no argv, so the output
# path comes from the environment variable BEND_OUT (forward slashes).
def kernel_src() -> String:
  "import numpy as np\n" ++
  "def step(u, r):\n" ++
  "    return u[1:-1] + r * (u[:-2] - 2.0 * u[1:-1] + u[2:])\n" ++
  "print('hello from a Bend-written kernel file', step(np.array([0.0, 1.0, 0.0]), 0.25))\n"

# close the file after a write, dropping the write's Result
def finish(fr: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (f, r) = fr
  File.close(f)

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BEND_OUT"))
    f : File <- IO.try(File, File.open(path, "w"))
    fr : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, kernel_src())
    finish(fr)
    IO.print("written")
