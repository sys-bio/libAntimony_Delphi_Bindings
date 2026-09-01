"""Minimal reproduction for: libantimony emits Antimony it cannot parse.

Loads each affected SBML Test Suite case, renders it back to Antimony with
getAntimonyString, and feeds that straight to loadAntimonyString. No consumer
code is involved -- the three calls are the whole reproduction.

    python repro_unparseable.py <suite>/semantic <path-to-libantimony.dll>

Tested against libantimony v3.2.0 on Windows x64.
"""

import ctypes
import os
import sys

# Shapes 1-3: the rendering does not parse. Shape 4: it parses but is empty.
UNPARSEABLE = {
    "reaction with no reactants or products":
        "01245 01246 01300 01301 01302 01303 01304 01305 01306".split(),
    "negative stoichiometry":
        "01422 01426 01427 01432 01433".split(),
    "event with no assignments":
        ["01240"],
}
# Shape 4. The first two are one parameter and one empty rule, and expect
# p = 3 throughout; the rest reach the same shape through a speciesReference.
EMPTY_RULE = "01234 01235 01465 01552 01554 01657".split()


def load_library(path):
    lib = ctypes.CDLL(path)
    lib.loadSBMLFile.restype = ctypes.c_long
    lib.loadAntimonyString.restype = ctypes.c_long
    for name in ("getVersionStr", "getMainModuleName",
                 "getAntimonyString", "getSBMLString", "getLastError"):
        getattr(lib, name).restype = ctypes.c_char_p
    return lib


def case_file(suite, cid):
    """The suite ships l3v2 for most of these and l3v1 for the rest."""
    for level in ("l3v2", "l3v1"):
        p = os.path.join(suite, cid, "%s-sbml-%s.xml" % (cid, level))
        if os.path.exists(p):
            return p
    return None


def render(lib, path):
    """SBML file -> Antimony text, or None if the SBML itself would not load."""
    if lib.loadSBMLFile(path.encode()) == -1:
        return None
    return lib.getAntimonyString(lib.getMainModuleName()).decode()


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    suite, dll = argv[1], argv[2]

    lib = load_library(dll)
    print("libantimony %s" % lib.getVersionStr().decode())
    print()

    failures = 0
    for shape, cids in UNPARSEABLE.items():
        print("--- %s ---" % shape)
        for cid in cids:
            path = case_file(suite, cid)
            if path is None:
                print("  %s  (not found under %s)" % (cid, suite))
                continue

            ant = render(lib, path)
            if ant is None:
                print("  %s  SBML would not load: %s"
                      % (cid, lib.getLastError().decode()[:60]))
                continue

            if lib.loadAntimonyString(ant.encode()) == -1:
                err = lib.getLastError().decode().strip()
                # The line number in the error indexes the rendered text.
                lineno = 0
                if "line " in err:
                    try:
                        lineno = int(err.split("line ")[1].split(":")[0])
                    except (IndexError, ValueError):
                        pass
                lines = ant.splitlines()
                offending = lines[lineno - 1].strip() if 0 < lineno <= len(lines) else "?"
                print("  %s  RE-READ FAILS" % cid)
                print("        emitted: %s" % offending)
                print("        error:   %s" % err.replace("\n", " ")[:90])
                failures += 1
            else:
                print("  %s  re-reads ok (fixed?)" % cid)
        print()

    print("--- rule with an empty body (parses; declared value discarded) ---")
    lost = 0
    for cid in EMPTY_RULE:
        path = case_file(suite, cid)
        if path is None:
            print("  %s  (not found under %s)" % (cid, suite))
            continue
        ant = render(lib, path)
        if ant is None:
            continue
        empty = [l.strip() for l in ant.splitlines()
                 if l.strip().endswith(":= ;") or l.strip().endswith("= ;")]
        # The SBML declares a value; if antimony's own export no longer carries
        # one, the value is unreachable by any route.
        sbml = lib.getSBMLString(lib.getMainModuleName()).decode()
        kept = "value=" in sbml
        if not kept:
            lost += 1
        print("  %s  emitted: %-16s declared value survives export: %s"
              % (cid, (empty or ["none (fixed?)"])[0], kept))
    print()
    print("%d of %d lost the declared value." % (lost, len(EMPTY_RULE)))

    print("%d of %d re-read failures reproduced."
          % (failures, sum(len(v) for v in UNPARSEABLE.values())))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
