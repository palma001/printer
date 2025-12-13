from pathlib import Path

TMP_DIR = (Path(__file__).parent / ".." / "tmp").resolve()
CUIT_FILE = (Path(__file__).parent / ".." / ".." / "cuit.json").resolve()
ASSET_DIR = (Path(__file__).parent / ".." / "assets").resolve()
IMG_DIR = (ASSET_DIR / "images").resolve()
TEMPLATE_DIR = (Path(__file__).parent / ".." / "assets" / "templates" / "receipt").resolve()
