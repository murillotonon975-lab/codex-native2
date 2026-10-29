from pathlib import Path
import json,zipfile,hashlib,subprocess,sys
root=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(root/'scripts/validate.py')],check=True)
version=json.loads((root/'plugin.json').read_text())['version']
dest=root/'dist';dest.mkdir(exist_ok=True)
archive=dest/f'Codex-Native2-v{version}.zip'
exclude={'.git','.github','dist','dados','logs','releases','tests','scripts','__pycache__'}
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(root.rglob('*')):
        rel=p.relative_to(root)
        if p.is_file() and not any(x in exclude for x in rel.parts) and p.name not in {'.gitignore','Publicar-GitHub.ps1'}:
            info=zipfile.ZipInfo('codex-native2/'+rel.as_posix(),(2026,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
            z.writestr(info,p.read_bytes())
(dest/'SHA256SUMS').write_text(hashlib.sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
print(archive)
