"""Verify the two report VCD files produced by Icarus, without dependencies."""

from pathlib import Path
import re


def read_vcd(path, top):
    content = path.read_text()
    if not re.search(r"\$timescale\s+1ps\s+\$end", content):
        raise ValueError(f"{path}: expected 1 ps timescale")
    scope = []
    names = {}
    events = {}
    timestamp = 0
    for line in content.splitlines():
        fields = line.split()
        if not fields:
            continue
        if fields[0] == "$scope":
            scope.append(fields[2])
        elif fields[0] == "$upscope":
            scope.pop()
        elif fields[0] == "$var" and scope == [top]:
            names[fields[3]] = fields[4]
            events[fields[4]] = {}
        elif line.startswith("#"):
            timestamp = int(line[1:])
        elif line[0] in "01xz":
            identifier = line[1:]
            if identifier in names:
                events[names[identifier]][timestamp] = line[0]
        elif line[0] == "b":
            value, identifier = fields
            if identifier in names:
                events[names[identifier]][timestamp] = value[1:]
    normalized = {}
    for name, changes in events.items():
        sequence = []
        for timestamp_value, bits in sorted(changes.items()):
            value = bits if re.search("[xz]", bits) else int(bits, 2)
            if not sequence or value != sequence[-1][1]:
                sequence.append((timestamp_value, value))
        normalized[name] = sequence
    return timestamp, normalized


def verify(filename, top, expected):
    path = Path(__file__).resolve().parent / "build" / filename
    end_time, actual = read_vcd(path, top)
    if end_time != 100000:
        raise AssertionError(f"{filename}: expected end at 100 ns, got {end_time} ps")
    expected["clk"] = [(timestamp, (timestamp // 5000) % 2)
                       for timestamp in range(0, 100001, 5000)]
    for name, sequence in expected.items():
        if actual.get(name) != sequence:
            raise AssertionError(f"{filename}: {name}: expected {sequence}, got {actual.get(name)}")
    print(f"PASS: {filename}, all {len(expected)} report signals, exact transitions, 100 ns.")


if __name__ == "__main__":
    verify("dff_sim.vcd", "dff_sim", {
        "clr": [(0, 1), (10000, 0), (50000, 1)],
        "en": [(0, 0), (10000, 1), (40000, 0)],
        "d": [(0, 0), (10000, 1), (20000, 0), (30000, 1), (40000, 0)],
        "q": [(0, 0), (15000, 1), (25000, 0), (35000, 1), (50000, 0)],
    })
    verify("reg8file_sim.vcd", "testbench", {
        "clr": [(0, 1), (10000, 0), (62000, 1), (70000, 0)],
        "en": [(0, 0), (10000, 1), (20000, 0), (30000, 1), (40000, 0)],
        "d": [(0, 0), (10000, 0x3c), (20000, 0), (30000, 0xa5), (40000, 0)],
        "wsel": [(0, 0), (10000, 1), (30000, 6), (40000, 0)],
        "rsel": [(0, 0), (42000, 1), (52000, 6), (72000, 1), (82000, 6)],
        "q": [(0, 0), (42000, 0x3c), (52000, 0xa5), (62000, 0)],
    })
