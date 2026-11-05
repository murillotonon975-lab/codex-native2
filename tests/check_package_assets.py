from pathlib import Path
from zipfile import ZipFile
import json

root = Path(__file__).resolve().parents[1]
version = json.loads((root / "plugin.json").read_text(encoding="utf-8-sig"))["version"]
archive = root / "dist" / f"Codex-Native2-v{version}.zip"
assert archive.is_file(), "Missing packaged ZIP"
with ZipFile(archive) as package:
    names = set(package.namelist())
    required = {
        "codex-native2/Iniciar.cmd",
        "codex-native2/Vincular-ChatGPT.cmd",
        "codex-native2/scripts/Vincular-ChatGPT.ps1",
        "codex-native2/Controlar-Cadastro-MCP.cmd",
        "codex-native2/Controlar-Cadastro-MCP.ps1",
        "codex-native2/Selecionar-Transporte.cmd",
        "codex-native2/scripts/Selecionar-Transporte.ps1",
        "codex-native2/Inventariar-Integracoes.cmd",
        "codex-native2/Verificar-Catalogo-MCP.cmd",
        "codex-native2/scripts/Configurar-Native2-GUI.ps1",
        "codex-native2/scripts/Inventariar-Integracoes.mjs",
        "codex-native2/scripts/Verificar-Catalogo-MCP.mjs",
        "codex-native2/skills/integracoes/SKILL.md",
        "codex-native2/docs/CATALOGO-FERRAMENTAS.md",
    }
    missing = required - names
    assert not missing, f"Release package missing runtime assets: {sorted(missing)}"
    assert not any("/tests/" in name or "/.github/" in name for name in names)
    assert not any(name.endswith("/mcp.json") or name.endswith("/.mcp.json") for name in names)
print("Release archive contains safe UI, scripts, integration skill and docs")
