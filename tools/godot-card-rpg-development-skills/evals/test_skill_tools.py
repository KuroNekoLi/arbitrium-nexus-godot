import os
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

BUNDLE=Path(__file__).resolve().parents[1]
ROOT=Path(os.environ.get('GODOT_SKILL_TEST_WORKSPACE', str(BUNDLE.parents[1])))
def module(name):
    spec=importlib.util.spec_from_file_location(name,BUNDLE/'scripts'/(name+'.py'))
    result=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

scan,check,validate=map(module,['scan_project','check_godot','validate_bundle'])

class ToolsTest(unittest.TestCase):
    @unittest.skipUnless((ROOT/'work/project/project.godot').is_file(), '需設定GODOT_SKILL_TEST_WORKSPACE至含work/project的研究工作區')
    def test_real_project_scan_is_read_only(self):
        project=ROOT/'work/project'
        before=scan.git(project,'status','--porcelain=v1')
        report=scan.scan(project)
        self.assertFalse(report['specified_baseline_exists'])
        self.assertTrue(any('00_README' in n for n in report['baseline_candidates']))
        self.assertEqual(before,scan.git(project,'status','--porcelain=v1'))

    def test_missing_project(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError,'MISSING_GODOT_PROJECT'):
                scan.scan(folder)

    def test_resource_escape(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)/'project'
            root.mkdir()
            (root.parent/'outside.gd').touch()
            with self.assertRaises(ValueError):
                check.resource(root,'res://../outside.gd')

    def test_runtime_error_with_zero_exit_fails(self):
        result={'exit_code':0,'stdout':'PASS one\n','stderr':'SCRIPT ERROR: Invalid call','timed_out':False}
        self.assertFalse(check.passed(result))

    def test_nonzero_fails(self):
        result={'exit_code':1,'stdout':'PASS all','stderr':'','timed_out':False}
        self.assertFalse(check.passed(result))

    def test_probe_requires_code_and_marker(self):
        result={'exit_code':17,'stdout':'','stderr':'','timed_out':False}
        self.assertFalse(check.passed(result,17,'G0_PROBE_EXPECTED_FAILURE'))
        result['stdout']='G0_PROBE_EXPECTED_FAILURE'
        self.assertTrue(check.passed(result,17,'G0_PROBE_EXPECTED_FAILURE'))
        result['exit_code']=0
        self.assertFalse(check.passed(result,17,'G0_PROBE_EXPECTED_FAILURE'))

    def test_timeout_preserves_output(self):
        with patch.object(check.subprocess,'run',side_effect=subprocess.TimeoutExpired(['fake'],1,output=b'partial')):
            result=check.invoke(['fake'],1)
        self.assertEqual(result['stdout'],'partial')
        self.assertTrue(result['timed_out'])
        self.assertFalse(check.passed(result))

    def test_missing_binary_is_not_pass(self):
        result=check.invoke([str(ROOT/'work/does-not-exist-godot.exe')],1)
        self.assertIsNone(result['exit_code'])
        self.assertFalse(check.passed(result))

    def test_success_does_not_claim_oracle(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)/'project'
            root.mkdir()
            (root/'project.godot').write_text('config_version=5')
            (root/'test.gd').touch()
            binary=Path(folder)/'fake.exe'
            binary.touch()
            out=Path(folder)/'logs'
            results=[{'stdout':'4.7.2.stable.official.test\n','stderr':'','exit_code':0,'timed_out':False},
                     {'stdout':'','stderr':'','exit_code':0,'timed_out':False},
                     {'stdout':'REPORT failed=0','stderr':'','exit_code':0,'timed_out':False}]
            def invoke(cmd,timeout):
                return dict(results.pop(0),command=cmd)
            args=['check','--project',str(root),'--godot',str(binary),'--output',str(out),'--runner','res://test.gd']
            with patch('sys.argv',args),patch.object(check,'invoke',side_effect=invoke):
                self.assertEqual(check.main(),0)
            report=json.loads((out/'execution.json').read_text(encoding='utf-8'))
            self.assertEqual(report['status'],'EXECUTED_REQUIRES_ORACLE_REVIEW')
            self.assertEqual(report['oracle_review'],'NOT_PERFORMED')
            self.assertEqual(len(report['steps']),3)

    def test_wrong_version_stops_before_import(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)/'project'
            root.mkdir()
            (root/'project.godot').touch()
            (root/'test.gd').touch()
            binary=Path(folder)/'fake.exe'
            binary.touch()
            out=Path(folder)/'logs'
            result={'command':['fake','--version'],'stdout':'4.6.stable\n','stderr':'','exit_code':0,'timed_out':False}
            args=['check','--project',str(root),'--godot',str(binary),'--output',str(out),'--runner','res://test.gd']
            with patch('sys.argv',args),patch.object(check,'invoke',return_value=result) as invoked:
                self.assertEqual(check.main(),1)
                self.assertEqual(invoked.call_count,1)
            self.assertEqual(json.loads((out/'execution.json').read_text(encoding='utf-8'))['status'],'FAILED_PROCESS_GATE')

    def test_reference_drift_detected(self):
        import shutil
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)/'bundle'
            shutil.copytree(BUNDLE,root)
            ref=next((root/'skills').glob('*/references/SPEC_GUARDIAN.md'))
            ref.write_text('drift',encoding='utf-8')
            self.assertEqual(validate.validate(root)['status'],'FAIL')

if __name__=='__main__':
    unittest.main(verbosity=2)
