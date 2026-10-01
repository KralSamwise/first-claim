"""Import + actual startup check; reject Godot's sometimes-zero exit on parser errors."""
import pathlib,subprocess,sys
root=pathlib.Path(__file__).resolve().parents[1]
(root/'evidence').mkdir(exist_ok=True)
for name,args in [('import',['--headless','--editor','--import']),('startup',['--headless','--quit-after','3'])]:
 p=subprocess.run([str(root/'tools/godot'),*args],cwd=root,capture_output=True,text=True,timeout=90)
 output=p.stdout+p.stderr;(root/'evidence'/('check-'+name+'.log')).write_text(output)
 if p.returncode or 'SCRIPT ERROR' in output or '\nERROR:' in output:
  print(output);sys.exit(1)
 if name=='startup' and 'FIRST_CLAIM_READY' not in output:print('No ready marker');sys.exit(1)
print('PASS import and actual scene ready')
