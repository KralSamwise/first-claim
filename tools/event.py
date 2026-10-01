import json,datetime,pathlib,sys,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
def event(kind,summary,evidence=(),build=None):
 if build is None:
  result=subprocess.run(['git','rev-parse','--short','HEAD'],cwd=ROOT,capture_output=True,text=True)
  build=result.stdout.strip() or 'unversioned'
 data=dict(timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),type=kind,summary=summary,build=build,evidence=[str(pathlib.Path(p).resolve()) for p in evidence])
 for path in (ROOT/'build-log.jsonl',):
  with path.open('a') as f:f.write(json.dumps(data)+'\n')
if __name__=='__main__':event(sys.argv[1],sys.argv[2],sys.argv[3:])
