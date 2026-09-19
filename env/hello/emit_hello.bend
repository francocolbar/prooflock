import Base

# Interop route A: Bend builds Python source as a String and prints it to
# stdout; the driver (shell / Python subprocess) redirects it into a .py file.
def kernel_src() -> String:
  "import numpy as np\n" ++
  "def step(u, r):\n" ++
  "    return u[1:-1] + r * (u[:-2] - 2.0 * u[1:-1] + u[2:])\n" ++
  "print('hello from a Bend-emitted kernel', step(np.array([0.0, 1.0, 0.0]), 0.25))\n"

def main() -> IO(Unit):
  IO.write(kernel_src())
