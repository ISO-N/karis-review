#!/usr/bin/env python3
"""Compare raw JSON and gzip sizes for the benchmark sample."""

import gzip
import json
import pathlib

SAMPLE = pathlib.Path(__file__).parent / "sample-bootstrap.json"


def expand_sample() -> dict:
    sample = json.loads(SAMPLE.read_text(encoding="utf-8"))
    deck = sample["decks"][0]
    deck["cards"] = [
        {
            **deck["cards"][0],
            "id": f"00000000-0000-0000-0000-{i:012d}",
            "review_version": i,
        }
        for i in range(1000)
    ]
    return sample


def main() -> None:
    data = expand_sample()
    raw = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    compressed = gzip.compress(raw, compresslevel=6)
    print(f"raw bytes: {len(raw)}")
    print(f"gzip bytes: {len(compressed)}")
    print(f"reduction: {(1 - len(compressed) / len(raw)) * 100:.1f}%")


if __name__ == "__main__":
    main()
