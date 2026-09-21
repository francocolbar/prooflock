"""bridge_client.py - a persistent node process running the Bend model through the JS loader
(bridge.mjs), shared by run.py and recheck.py."""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BEND_SRC = os.environ.get("BEND_SRC", os.path.expanduser("~/.bend-src"))   # the checkout env/bend.sh pins
LOADER = "file:///" + os.path.join(BEND_SRC, "bend2", "main.ts").replace(os.sep, "/").lstrip("/")


class Bridge:
    def __init__(self):
        self.p = subprocess.Popen(["node", "--import", LOADER, "bridge.mjs"], cwd=HERE, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1,
                                  encoding="utf-8")
        self.calls = 0

    def ask(self, req):
        self.p.stdin.write(json.dumps(req) + "\n")
        self.p.stdin.flush()
        line = self.p.stdout.readline()
        if not line:
            sys.exit("bridge died: " + self.p.stderr.read())
        self.calls += 1
        return json.loads(line)

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=10)
