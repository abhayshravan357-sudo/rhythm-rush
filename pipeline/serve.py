"""
Module: serve.py
Scans charts/ directory, compiles manifest.json, and launches a LAN HTTP server.

Manifest schema:
{
  "songs": [
    {
      "id": "<stem of chart filename>",
      "name": "<songName from metaData>",
      "chart": "<chart filename>",
      "audio": "<audioFile from metaData>",
      "bpm": <number>,
      "duration": <number>
    }
  ]
}

Usage:
    python serve.py [--port 8000]
"""
import argparse
import json
import os
from http.server import SimpleHTTPRequestHandler
import socketserver
from pathlib import Path

DIRECTORY_TARGET = "./charts"


class ChartDistributionHandler(SimpleHTTPRequestHandler):
    """Serves files from the charts/ directory with CORS headers for LAN clients."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY_TARGET, **kwargs)

    def end_headers(self) -> None:
        # Allow Godot HTTPRequest nodes on the LAN to fetch without CORS issues
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def log_message(self, fmt: str, *args) -> None:  # type: ignore[override]
        print(f"[HTTP] {self.address_string()} - {fmt % args}")


def compile_network_manifest() -> int:
    """Scans charts/ for *_chart.json files and writes manifest.json.

    Returns the number of songs indexed.
    """
    root_path = Path(DIRECTORY_TARGET)
    root_path.mkdir(exist_ok=True)

    songs = []

    for target_json in sorted(root_path.glob("*_chart.json")):
        try:
            with open(target_json, "r") as f:
                data = json.load(f)
            meta = data.get("metaData", {})
            song_id = target_json.stem  # e.g. "my_song_chart"
            songs.append(
                {
                    "id": song_id,
                    "name": meta.get("songName", target_json.stem),
                    "chart": target_json.name,
                    "audio": meta.get("audioFile", f"{song_id}.ogg"),
                    "bpm": meta.get("bpm", 120.0),
                    "duration": meta.get("totalDuration", 0.0),
                }
            )
        except Exception as ex:
            print(f"[Manifest] Skipping {target_json.name}: {ex}")

    manifest = {"songs": songs}
    manifest_path = root_path / "manifest.json"
    with open(manifest_path, "w") as out:
        json.dump(manifest, out, indent=2)

    print(f"[Manifest] Indexed {len(songs)} song(s) → {manifest_path}")
    return len(songs)


def main() -> None:
    parser = argparse.ArgumentParser(description="Hexa-Rhythm LAN chart distribution server")
    parser.add_argument("--port", type=int, default=8000, help="TCP port (default: 8000)")
    args = parser.parse_args()

    # Change working directory to the script's location so relative paths resolve
    os.chdir(Path(__file__).parent)

    compile_network_manifest()

    print(f"[Server] Serving charts/ on http://0.0.0.0:{args.port}")
    print("[Server] Press Ctrl+C to stop.\n")

    with socketserver.TCPServer(("", args.port), ChartDistributionHandler) as httpd:
        httpd.allow_reuse_address = True
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[Server] Shutdown complete.")


if __name__ == "__main__":
    main()
