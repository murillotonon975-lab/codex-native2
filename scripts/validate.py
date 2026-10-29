from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'plugin.json').read_text(encoding='utf-8-sig'))
assert p['name']=='codex-native2' and re.fullmatch(r'\d+\.\d+\.\d+',p['version'])
for name in ['Iniciar.cmd','Configurar-Conexao.ps1','Instalar-Native2.ps1','README.md','painel/index.html']:
    assert (root/name).is_file(),name
assert not (root/'mcp.json').exists(),'Public source must not contain account binding'
for path in root.rglob('*'):
    if not path.is_file() or any(x in path.parts for x in ['.git','dist','__pycache__']):continue
    text=path.read_text(encoding='utf-8-sig')
    assert not re.search(r'tunnel_[a-f0-9]{32}',text),f'Personal tunnel: {path}'
    assert not re.search(r'sk-[A-Za-z0-9]{24,}',text),f'Possible credential: {path}'
print('Manifest, required files and personal binding checks passed')
