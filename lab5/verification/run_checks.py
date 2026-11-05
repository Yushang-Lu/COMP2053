"""Run Lab5 local checks; keep generated files outside the repository."""

import hashlib
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
CODE = ROOT / "code"
OFFICIAL_SHA256 = "f7e2fde78f12aa4450e13dcfbe60d5e829da5463e1414c33d88ee2d30570aa9f"


def run(command, log_path):
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=180)
    log_path.write_text(result.stdout)
    print(result.stdout, end="")
    if result.returncode:
        raise RuntimeError(f"Command failed: {command}; log: {log_path}")
    return result.stdout


def main():
    output = Path(tempfile.mkdtemp(prefix="lab5-check-"))
    print(f"Artifacts: {output}")
    digest = hashlib.sha256((CODE / "uart_send_tb.v").read_bytes()).hexdigest()
    if digest != OFFICIAL_SHA256:
        raise AssertionError("Official testbench has changed")
    constraints = (CODE / "pin.xdc").read_text()
    actual = re.findall(
        r"PACKAGE_PIN (\w+) IOSTANDARD LVCMOS33.*get_ports \{(\w+)\}", constraints)
    if sorted(actual) != sorted([("P17", "clk"), ("R17", "rst"), ("T4", "uart_tx")]):
        raise AssertionError("EGO1 constraints mismatch")
    ports = re.findall(r"\b(?:input|output)\s+(\w+)", (CODE / "uart_top.v").read_text())
    if set(ports) != {"clk", "rst", "uart_tx"}:
        raise AssertionError("Top ports mismatch")
    if "create_clock -name sys_clk -period 10.000 [get_ports {clk}]" not in constraints:
        raise AssertionError("Missing 100 MHz constraint")
    run(["iverilog", "-V"], output / "version.log")
    for top, bench in [
        ("uart_send_tb", CODE / "uart_send_tb.v"),
        ("uart_send_check", ROOT / "verification/uart_send_check.v"),
        ("uart_top_check", ROOT / "verification/uart_top_check.v"),
    ]:
        executable = output / top
        timing_args = ["-s", "official_timing"] if top == "uart_send_tb" else []
        timing_sources = ([str(ROOT / "verification/official_timing.v")]
                          if top == "uart_send_tb" else [])
        run(["iverilog", "-g2012", "-Wall", "-s", top, *timing_args, "-o", str(executable),
             str(CODE / "uart_send.v"), str(CODE / "uart_top.v"), str(bench), *timing_sources],
            output / f"{top}-compile.log")
        text = run(["vvp", str(executable)], output / f"{top}.log")
        if top == "uart_send_tb":
            if ("All tests passed successfully!" not in text or "Error" in text
                    or "failed" in text.lower()
                    or len(re.findall(r"Test case [0-9a-f]+ success", text)) != 5):
                raise AssertionError("Official tests did not all pass")
        elif "PASS:" not in text:
            raise AssertionError(f"{top} did not finish successfully")
    print("PASS: official source hash, EGO1 constraints, official and supplemental simulations")


if __name__ == "__main__":
    main()
