"""驗證八 Skill 結構、相對資源與規範副本；不驗證模型行為。"""
import json
from pathlib import Path
import re
import sys


def validate(root):
    errors = []
    skills = sorted((root/'skills').glob('*/SKILL.md'))
    if len(skills) != 8:
        errors.append('預期八個 Skills')
    for entry in skills:
        body = entry.read_text(encoding='utf-8')
        match = re.match(r'^---\nname: ([a-z0-9-]{1,63})\ndescription: "([^\n]+)"\n---\n', body)
        if not match or match[1] != entry.parent.name:
            errors.append(str(entry)+': frontmatter/name 不符')
        for target in re.findall(r'\]\(([^)]+)\)',body):
            if not re.match(r'\w+://',target) and not (entry.parent/target).is_file():
                errors.append(str(entry)+': 缺連結 '+target)
        for ref in (entry.parent/'references').glob('*.md'):
            canonical = root/'references'/ref.name
            if not canonical.is_file() or canonical.read_bytes() != ref.read_bytes():
                errors.append(str(ref)+': 主本與副本不一致')
        if not (entry.parent/'agents/openai.yaml').is_file():
            errors.append(str(entry)+': 缺 agents/openai.yaml')
    required = ['SPEC_GUARDIAN','GDSCRIPT_STANDARDS','GAME_ARCHITECTURE','CARD_COMBAT_STANDARDS',
                'RENDERING_2_5D','UIUX_STANDARDS','ASSET_PIPELINE','RESOURCE_LIBRARY_MANAGER','QA_CI_STANDARDS']
    for name in required:
        if not (root/'references'/(name+'.md')).is_file():
            errors.append('缺 reference '+name)
    return {'status':'PASS' if not errors else 'FAIL','skill_count':len(skills),'errors':errors,
            'limitations':'僅結構與同步檢查，不代表 trigger accuracy、遊戲或 CI 通過。'}


if __name__ == '__main__':
    result=validate(Path(__file__).resolve().parents[1])
    print(json.dumps(result,ensure_ascii=False,indent=2))
    sys.exit(0 if result['status']=='PASS' else 1)
