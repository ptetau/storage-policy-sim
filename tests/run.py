#!/usr/bin/env python3
"""Runs every test of the project and writes one junit report.

Usage: python3 tests/run.py --junit <file>

It builds the project with `lake build`. It builds and runs the test program of each slice
(`tests/slice/Sn.lean`, the program `slicetest_Sn`). It runs the older check files
(`tests/*.lean`, `tests/acceptance/*.lean`) with `lake env lean --run`.

A slice program runs with LEAN_ABORT_ON_PANIC, so a stub that panics with "not implemented"
stops it. The test that ran is then an error with the message "not implemented", and the
program starts again after that test.
"""
import concurrent.futures
import glob
import os
import re
import subprocess
import sys
from xml.sax.saxutils import escape, quoteattr

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = {**os.environ, "PATH": os.path.expanduser("~/.elan/bin") + os.pathsep + os.environ.get("PATH", "")}
NAME = re.compile(r'"(test_\d{3}_S\d+_R\d+_\w+)"')
LINE = re.compile(r"^(RUN|PASS|FAIL|ERROR) (\S+)(?:: (.*))?$")


def sh(args, timeout, env=None):
    try:
        p = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=timeout, env=env or ENV)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired as e:
        return 124, (e.stdout or b"").decode("utf-8", "replace") if isinstance(e.stdout, bytes) else (e.stdout or ""), "timeout after %d seconds" % timeout


def errors_of(text, limit=6):
    lines = [l for l in text.splitlines() if "error" in l]
    return " | ".join(lines[:limit])[:600] or text.strip()[-400:]


def run_slice(path):
    """Results of one slice file: a list of (name, status, message)."""
    sid = os.path.basename(path)[:-5]
    names = list(dict.fromkeys(NAME.findall(open(path, encoding="utf-8").read())))
    code, out, err = sh(["lake", "build", "slicetest_" + sid], 400)
    if code != 0:
        msg = "the test program does not compile: " + errors_of(out + err)
        return [(n, "error", msg) for n in names] or [("build_" + sid, "error", msg)]
    exe = os.path.join(ROOT, ".lake", "build", "bin", "slicetest_" + sid)
    env = {**ENV, "LEAN_ABORT_ON_PANIC": "1"}
    results, start = {}, 0
    for _ in range(len(names) + 2):
        if start >= len(names):
            break
        code, out, err = sh([exe, "--from", str(start)], 300, env)
        running, seen = None, 0
        for line in out.splitlines():
            m = LINE.match(line)
            if not m:
                continue
            kind, name, msg = m.group(1), m.group(2), m.group(3) or ""
            if kind == "RUN":
                running = name
                seen += 1
            else:
                results[name] = ({"PASS": "pass", "FAIL": "fail", "ERROR": "error"}[kind], msg)
                running = None
        if running is None and code in (0, 1):
            break
        # The program stopped inside a test, or before the first one.
        panic = next((l for l in err.splitlines() if l.startswith("PANIC")), "")
        text = "not implemented" if "not implemented" in err else (
            panic or err.strip()[-300:] or "the test program stopped with exit code %d" % code)
        if running is None:
            if seen == 0 and start < len(names):
                results[names[start]] = ("error", text)
                start += 1
                continue
            break
        results[running] = ("error", text)
        start = names.index(running) + 1 if running in names else len(names)
    return [(n,) + results.get(n, ("error", "the test did not run")) for n in names]


def run_legacy(path):
    rel = os.path.relpath(path, ROOT)
    label = "legacy " + re.sub(r"[^A-Za-z0-9./-]", "-", rel)
    code, out, err = sh(["lake", "env", "lean", "--run", rel], 500)
    results = []
    for line in out.splitlines():
        if line.startswith("FAIL "):
            name, _, msg = line[5:].partition(": ")
            results.append((label + " " + re.sub(r"(?<![0-9A-Za-z])[Ss](\d)", r"s-\1", name), "fail", msg[:300]))
    if not re.search(r"^\d+ checks, \d+ failed", out, re.M):
        results.append((label, "error", "the check file did not run: " + errors_of(out + err)))
    elif not results:
        results.append((label, "pass", ""))
    return results


def main(argv):
    junit = argv[argv.index("--junit") + 1] if "--junit" in argv else None
    results = []
    code, out, err = sh(["lake", "build"], 500)
    if code != 0:
        results.append(("build", "error", "lake build fails: " + errors_of(out + err)))
    else:
        for path in sorted(glob.glob(os.path.join(ROOT, "tests", "slice", "S*.lean")),
                           key=lambda p: int(re.sub(r"\D", "", os.path.basename(p)) or 0)):
            results += run_slice(path)
        legacy = sorted(glob.glob(os.path.join(ROOT, "tests", "*.lean")) +
                        glob.glob(os.path.join(ROOT, "tests", "acceptance", "*.lean")))
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            for part in pool.map(run_legacy, legacy):
                results += part
    bad = 0
    xml = ['<?xml version="1.0" encoding="utf-8"?>', '<testsuite name="storage-policy-sim" tests="%d">' % len(results)]
    for name, status, msg in results:
        if status == "pass":
            xml.append("  <testcase name=%s/>" % quoteattr(name))
            print("PASS " + name)
        else:
            bad += 1
            tag = "failure" if status == "fail" else "error"
            xml.append("  <testcase name=%s><%s message=%s/></testcase>" % (quoteattr(name), tag, quoteattr(msg)))
            print("%s %s: %s" % (tag.upper(), name, msg))
    xml.append("</testsuite>")
    if junit:
        with open(junit, "w", encoding="utf-8") as f:
            f.write("\n".join(xml) + "\n")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
