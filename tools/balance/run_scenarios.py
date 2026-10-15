import importlib.util, pathlib, csv, json, statistics, collections
p=pathlib.Path(__file__).parent
spec=importlib.util.spec_from_file_location('astraea_v02',p/'astraea_demo_python_sim_v0_2.py')
m=importlib.util.module_from_spec(spec)
import sys
sys.modules[spec.name]=m;spec.loader.exec_module(m)
m.validate_v02()
policies=['balanced','aggressive','defensive','casting','break_first','exposed_combo','cast_support','last_early']
candidates=[
 ('baseline',3000,1.0,30,180),('lower_HP_2700',2700,1.0,30,180),
 ('hp2700_attack1_4',2700,1.4,30,180),('hp2700_attack1_7',2700,1.7,30,180),
 ('hp2700_attack2_0',2700,2.,30,180),('hp2500_attack1_4',2500,1.4,30,180),
 ('hp2500_attack1_7',2500,1.7,30,180),('hp2500_attack2_0',2500,2.,30,180),
 ('hp3000_attack1_7',3000,1.7,30,180),('hp3000_attack2_0',3000,2.,30,180),
 ('hp2600_attack1_7_break22',2600,1.7,22,180),
 ('hp2600_attack1_7_break18',2600,1.7,18,180),
 ('hp2700_attack1_7_break22',2700,1.7,22,180),
 ('hp2700_attack2_0_break22',2700,2.,22,180),
 ('hp2700_attack2_2_break22',2700,2.2,22,180),
]
rows=[]
for scen,hp,dmg,bg,barrier in candidates:
 for pol in policies:
  for seed in range(100):
   r=m.Fight(seed,pol,{'boss_hp':hp,'boss_attack_factor':dmg,'break_max':bg,'boss_barrier':barrier}).run()
   r.update(scenario=scen,boss_hp_config=hp,enemy_damage_factor=dmg,break_max=bg)
   rows.append(r)
with open(p/'all_scenarios_v0_2_12000_runs.csv','w',newline='',encoding='utf-8-sig') as h:
 w=csv.DictWriter(h,list(rows[0]));w.writeheader();w.writerows(rows)
summary=[]
for sc,_,_,_,_ in candidates:
 for pol in policies:
  r=[x for x in rows if x['scenario']==sc and x['policy']==pol]
  win=[x for x in r if x['won']]
  summary.append(dict(scenario=sc,policy=pol,completed=sum(x['won'] for x in r),mean_turns=round(statistics.mean(x['turns'] for x in r),2),median_win_turns=statistics.median(x['turns'] for x in win) if win else None,mean_party_hp=round(statistics.mean(x['party_hp_remaining'] for x in r)),mean_party_ko=round(statistics.mean(x['party_kos'] for x in r),3),any_ko_pct=round(sum(x['party_kos']>0 for x in r)/len(r)*100,1),mean_breaks=round(statistics.mean(x['breaks'] for x in r),2),mean_exposed=round(statistics.mean(x['exposed_used'] for x in r),2),mean_reaction_sp=round(statistics.mean(x['reaction_r05']+x['reaction_t05'] for x in r),2),mean_full_resolved=round(statistics.mean(x['full_resolved'] for x in r),2),mean_heal=round(statistics.mean(x['heal'] for x in r))))
with open(p/'balance_scenario_summary_v0_2.json','w',encoding='utf-8') as h:json.dump({'note':'INDIVIDUAL PYTHON PROTOTYPE; NOT GODOT','runs':len(rows),'scenarios':candidates,'summary':summary},h,ensure_ascii=False,indent=2)
for sc in [a[0] for a in candidates]:
 d=[x for x in summary if x['scenario']==sc]
 print(sc,' '.join(f"{x['policy'][:3]}:{x['completed']:03d}/{x['median_win_turns']},KO={x['any_ko_pct']}% Brk={x['mean_breaks']}" for x in d[:5]))