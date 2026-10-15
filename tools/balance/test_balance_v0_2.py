"""Regression smoke tests for independent Python balance model; not authoritative Godot tests."""
import unittest,importlib.util,sys,pathlib
p=pathlib.Path(__file__).parent
spec=importlib.util.spec_from_file_location('astraea_v02',p/'astraea_demo_python_sim_v0_2.py')
m=importlib.util.module_from_spec(spec);sys.modules[spec.name]=m;spec.loader.exec_module(m)

class ModelSmoke(unittest.TestCase):
 def test_loadouts_and_card_instances(self):
  self.assertTrue(m.validate_v02())
  for seed in range(20):
   f=m.Fight(seed,'balanced',{'boss_hp':2700,'boss_attack_factor':1.7,'break_max':22})
   f.run()
   for a in f.party.values():
    cards=a.hand+a.draw+a.discard+([a.casting['inst']] if a.casting and not a.casting['last'] else [])
    self.assertEqual(len(cards),12,(seed,a.name,cards))
    self.assertEqual(len({i for i,c in cards}),12)
    self.assertTrue(0<=a.hp<=a.hpmax)
    self.assertTrue(0<=a.mp<=a.mpmax)
   self.assertTrue(0<=f.bhp<=2700)
   self.assertTrue(0<=f.rp<=6)
 def test_seed_repeatability(self):
  for policy in ['balanced','aggressive','defensive','casting','break_first','exposed_combo','cast_support','last_early']:
   for seed in [0,1,17,43,99]:
    kw={'boss_hp':2700,'boss_attack_factor':1.7,'break_max':22}
    self.assertEqual(m.Fight(seed,policy,kw).run(),m.Fight(seed,policy,kw).run())
 def test_own_defense_not_applied_when_attacking(self):
  a=m.Fight(34,'balanced');b=m.Fight(34,'balanced')
  a.party['ren'].pdef=99999
  self.assertEqual(a.damage('ren',135,1.0,'p',hit_check=False),b.damage('ren',135,1.0,'p',hit_check=False))
 def test_boss_uses_target_defense(self):
  a=m.Fight(34,'balanced');b=m.Fight(34,'balanced')
  b.party['ren'].pdef=99999
  x=a.damage('ren',245,1.35,'p',hit_check=False,is_enemy=True)
  y=b.damage('ren',245,1.35,'p',hit_check=False,is_enemy=True)
  self.assertGreater(x,y)
 def test_swap_excludes_same_instance(self):
  f=m.Fight(0,'balanced');a=f.party['ren']
  old=list(a.hand)
  f._perform_swaps()
  new=list(a.hand)
  removed={i for i,c in old}-{i for i,c in new}
  added={i for i,c in new}-{i for i,c in old}
  self.assertTrue(not removed or removed.isdisjoint(added))
  self.assertLessEqual(f.stats['free_swap'],3)
 def test_last_spell_no_dead_caster_release(self):
  f=m.Fight(0,'balanced')
  a=f.party['akane'];f.start_last(a)
  f.take('akane',a.hp)
  self.assertIsNone(a.casting)
  self.assertEqual(f.stats['last_invalidated'],1)
  f.turn=2;f.ai_turn()
  self.assertEqual(f.ls_resolved['akane'],0)
 def test_focus_ward_absorbs_disruption_not_hp(self):
  f=m.Fight(0,'aggressive')
  a=f.party['akane']
  inst=a.hand.pop(0)
  a.casting={'last':False,'card':'A01','inst':inst,'stability':10,'focus_ward':8,'due':4}
  f.enemy_attack('B03','akane',1.35,'m',True,disrupt=5)
  self.assertEqual(a.casting['focus_ward'],3)
  self.assertEqual(a.casting['stability'],10)
  self.assertLess(a.hp,a.hpmax)
 def test_reaction_sp_requires_hand_and_rp(self):
  f=m.Fight(2,'balanced');f.rp=0
  self.assertFalse(f._reaction_card('ren','R05'))
  self.assertFalse(f._reaction_card('tsumugi','T05'))
 def test_reaction_sp_r05_legal_window(self):
  f=m.Fight(3,'balanced');f.rp=4
  ren=f.party['ren']
  if not any(c=='R05' for i,c in ren.hand):
   ix=next(i for i,v in enumerate(ren.draw) if v=='R05')
   ren.hand.append(ren.draw.pop(ix))
  f.intent={'skill':'B03','target':'akane'}
  f.enemy_turn()
  self.assertEqual(f.stats['reaction_card_R05'],1)
  self.assertEqual(f.stats['reaction_counter_done'],1)
  self.assertEqual(f.stats['protect'],1)
 def test_boss_charge_no_same_action_hit(self):
  f=m.Fight(3,'aggressive')
  f.intent={'skill':'B05','target':None}
  hp=[a.hp for a in f.party.values()]
  f.enemy_turn()
  self.assertEqual(hp,[a.hp for a in f.party.values()])
  self.assertEqual(f.intent['skill'],'B06')
 def test_break_fallback_not_skipped(self):
  f=m.Fight(3,'balanced')
  f.break_pending=True;f.intent={'skill':'B11','target':'ren'}
  f.enemy_turn()
  self.assertEqual(f.stats['fallback'],1)
  self.assertFalse(f.break_pending)
  self.assertEqual(f.breakg,f.cfg['break_max'])

if __name__=='__main__':unittest.main(verbosity=2)