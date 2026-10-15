"""執行明確選定的 Godot runners，保留程序證據；不推論玩法驗收。"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess

ERRORS = re.compile(r'(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FAIL(?:ED)?(?:\s|:|$))')


def invoke(command, timeout):
    try:
        result = subprocess.run(command, capture_output=True, text=True,
                                encoding='utf-8', errors='replace', timeout=timeout)
        return {'command': command, 'exit_code': result.returncode,
                'stdout': result.stdout, 'stderr': result.stderr, 'timed_out': False}
    except subprocess.TimeoutExpired as exc:
        def decode(value):
            return value.decode('utf-8', errors='replace') if isinstance(value, bytes) else (value or '')
        return {'command': command, 'exit_code': None, 'stdout': decode(exc.stdout),
                'stderr': decode(exc.stderr), 'timed_out': True}
    except OSError as exc:
        return {'command': command, 'exit_code': None, 'stdout': '',
                'stderr': str(exc), 'timed_out': False}


def passed(result, code=0, marker=None):
    combined = result['stdout'] + '\n' + result['stderr']
    return (not result['timed_out'] and result['exit_code'] == code
            and (code != 0 or not ERRORS.search(combined))
            and (marker is None or marker in combined))


def resource(root, value):
    if not value.startswith('res://'):
        raise ValueError('runner 必須為 res:// 路徑')
    path = (root / value[6:]).resolve()
    if not path.is_relative_to(root) or not path.is_file() or path.suffix != '.gd':
        raise ValueError('runner 不存在或超出專案：' + value)
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', required=True)
    parser.add_argument('--godot', required=True, help='實際 binary 路徑')
    parser.add_argument('--output', required=True, help='專案外的新證據目錄')
    parser.add_argument('--runner', action='append', required=True)
    parser.add_argument('--expected-version', default='4.7.2.stable')
    parser.add_argument('--timeout', type=int, default=60)
    parser.add_argument('--probe', action='store_true', help='執行專案既有 exit17 probe')
    args = parser.parse_args()
    root, binary, out = Path(args.project).resolve(), Path(args.godot).resolve(), Path(args.output).resolve()
    if args.timeout <= 0 or not (root/'project.godot').is_file() or not binary.is_file():
        parser.error('需要有效專案、binary 與正數 timeout')
    if out.is_relative_to(root) or out.exists():
        parser.error('output 必須為專案外尚未存在的目錄，避免覆寫或污染')
    try:
        runners = [resource(root, r) for r in args.runner]
        if args.probe:
            resource(root, 'res://tests/ci_failure_probe.gd')
    except ValueError as exc:
        parser.error(str(exc))
    out.mkdir(parents=True)
    report = {'status': 'RUNNING', 'timestamp_utc': datetime.now(timezone.utc).isoformat(),
              'project': str(root), 'expected_version': args.expected_version,
              'steps': [], 'oracle_review': 'NOT_PERFORMED',
              'limitations': '程序成功仍須審查 assertion 摘要、requirement 覆蓋與 fixture scope。'}
    def record(label, result, ok):
        log = result['stdout']+'\n--- stderr ---\n'+result['stderr']
        path = out/(label+'.log')
        path.write_text(log, encoding='utf-8')
        summary = {k:v for k,v in result.items() if k not in {'stdout','stderr'}}
        summary.update(label=label, passed_process_gate=ok, log=str(path),
                       log_sha256=hashlib.sha256(log.encode()).hexdigest())
        report['steps'].append(summary)
        report['status'] = 'EXECUTED_REQUIRES_ORACLE_REVIEW' if ok else 'FAILED_PROCESS_GATE'
        (out/'execution.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
        return ok
    version = invoke([str(binary), '--version'], args.timeout)
    pattern = r'^'+re.escape(args.expected_version)+r'(?:\.|$)'
    version_ok = passed(version) and bool(re.match(pattern, version['stdout'].strip()))
    report['actual_version'] = version['stdout'].strip()
    if not record('version', version, version_ok):
        return 1
    base = [str(binary), '--headless', '--path', str(root)]
    imported = invoke(base+['--editor','--import','--quit'], args.timeout)
    if not record('import', imported, passed(imported)):
        return 1
    if args.probe:
        probe = invoke(base+['--script','res://tests/ci_failure_probe.gd'], args.timeout)
        if not record('probe', probe, passed(probe,17,'G0_PROBE_EXPECTED_FAILURE')):
            return 1
    for i, runner in enumerate(runners):
        result = invoke(base+['--script',runner], args.timeout)
        if not record(f'runner_{i+1}',result,passed(result)):
            return 1
    print(json.dumps({'status':report['status'],'evidence':str(out/'execution.json')},ensure_ascii=False))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
