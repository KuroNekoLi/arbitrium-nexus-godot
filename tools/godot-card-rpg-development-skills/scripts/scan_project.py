"""唯讀盤點 Godot 工作區；輸出來源位置，不推論規格效力。"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def git(root, *args):
    try:
        result = subprocess.run(['git', '-C', str(root), *args], capture_output=True,
                                text=True, encoding='utf-8', errors='replace', timeout=20)
        return {'exit_code': result.returncode, 'output': result.stdout.strip(),
                'error': result.stderr.strip()}
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {'exit_code': None, 'error': str(exc)}


def scan(project):
    root = Path(project).resolve()
    config = root / 'project.godot'
    if not config.is_file():
        raise ValueError('MISSING_GODOT_PROJECT: ' + str(root))
    entries = []
    skipped = {'.git', '.godot', 'node_modules', '.venv'}
    for path in sorted(root.rglob('*')):
        rel = path.relative_to(root)
        if set(rel.parts) & skipped or path.is_symlink() or not path.is_file():
            continue
        selected = (path.name in {'AGENTS.md', 'project.godot', 'export_presets.cfg'}
                    or rel.parts[:2] in {('docs', 'combat'), ('docs', 'verification')}
                    or rel.parts[:2] == ('.github', 'workflows')
                    or (rel.parts[0] == 'tests' and path.suffix == '.gd'))
        if selected:
            data = path.read_bytes()
            entries.append({'path': rel.as_posix(), 'bytes': len(data),
                            'sha256': hashlib.sha256(data).hexdigest()})
    ancestor_agents = [str(p / 'AGENTS.md') for p in reversed(root.parents)
                       if (p / 'AGENTS.md').is_file()]
    names = [e['path'] for e in entries]
    return {'status': 'INVENTORIED_NOT_VERIFIED', 'project': str(root),
            'commit': git(root, 'rev-parse', 'HEAD'),
            'branch': git(root, 'branch', '--show-current'),
            'working_tree': git(root, 'status', '--porcelain=v1'),
            'ancestor_agents': ancestor_agents,
            'agents': [n for n in names if n.endswith('AGENTS.md')],
            'specified_baseline_exists': 'docs/combat/COMBAT_RULES_BASELINE_V0_8.md' in names,
            'baseline_candidates': [n for n in names if 'BASELINE' in n.upper()],
            'project_configuration': config.read_text(encoding='utf-8-sig'),
            'files': entries,
            'limitations': ['未執行 Godot、CI、實玩或 export。',
                            '來源效力須閱讀批准與 supersession 紀錄；日期與檔名不代表權威。']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('project')
    args = parser.parse_args()
    try:
        print(json.dumps(scan(args.project), ensure_ascii=False, indent=2))
        return 0
    except (ValueError, OSError) as exc:
        print(json.dumps({'status': 'BLOCKED', 'error': str(exc)}, ensure_ascii=False))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
