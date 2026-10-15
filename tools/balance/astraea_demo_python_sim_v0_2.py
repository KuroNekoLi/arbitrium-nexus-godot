"""Astraea Lv40 Demo — Python Balance Prototype v0.2 (NOT GODOT COMBAT DOMAIN).
Independent fidelity improvements versus 0.1, deterministic fixed seeds; only provides directional balance.
Known remaining gaps: comprehensive event queue / all status rules / full casting-counter and advanced reaction queue.
"""
import random, math, csv, json, hashlib, statistics, collections
from dataclasses import dataclass, field

BASE_STATS = {
    'ren': (1500,8,135,70,110,90,105,95,.10),
    'akane': (950,14,60,175,65,85,95,90,.08),
    'tsumugi': (1200,12,55,105,80,110,95,95,.05),
}
DECKS = {
    'ren':'U01 U02 U03 U04 U05 R01 R02 R03 R05 R06 R07 R08'.split(),
    'akane':'U01 U02 U03 U04 U05 A01 A02 A03 A04 A05 A06 A07'.split(),
    'tsumugi':'U01 U02 U03 U04 U05 T01 T03 T04 T05 T06 T09 T10'.split(),
}
# AP, MP, kind, multiplier or amount; reaction-only cards have no active effect in this pilot.
CARDS = {
 'U01':(1,2,'magic',.85),'U02':(1,2,'shield',140),'U03':(1,1,'ward',8),
 'U04':(1,0,'mp',3),'U05':(1,2,'heal',150),
 'R01':(1,0,'phys',1.00),'R02':(2,0,'phys2',.72), 'R03':(1,1,'phys',1.15),
 'R05':(0,1,'reaction',0),'R06':(2,2,'phys',1.75),'R07':(1,1,'phys',.75),
 'R08':(1,2,'teamshield',90),
 'A01':(1,2,'fire',1.00),'A02':(2,4,'fire',.68),'A03':(1,1,'boost',.20),
 'A04':(2,5,'fire',1.45),'A05':(1,2,'disrupt',8),'A06':(2,5,'fire',1.55),
 'A07':(1,3,'fire',.65),
 'T01':(1,2,'heal',200),'T03':(2,4,'teamheal',140),'T04':(1,2,'shield',190),
 'T05':(0,2,'reaction',0),'T06':(2,4,'healshield',380),'T09':(1,2,'magic',.90),
 'T10':(1,3,'damageheal',.80),
}

@dataclass
class Actor:
    name: str
    hpmax: int
    mpmax: int
    patk: int
    matk: int
    pdef: int
    mdef: int
    acc: int
    eva: int
    crit: float
    hp: int=0
    mp: int=0
    barrier: float=0
    hand: list=field(default_factory=list)
    draw: list=field(default_factory=list)
    discard: list=field(default_factory=list)
    casting: dict|None=None
    exhausted: bool=False
    ls_used: bool=False
    mp_attack_used: bool=False
    heal_bonus_used: bool=False
    break_bonus_used: bool=False
    boost: float=0
    def __post_init__(self): self.hp,self.mp=self.hpmax,self.mpmax
    @property
    def alive(self): return self.hp>0
    @property
    def active(self): return self.alive and not self.exhausted and self.casting is None

class Fight:
 def __init__(self, seed, policy, config=None):
    self.cfg={"boss_hp":3000,"boss_attack_factor":1.,"break_max":30,"boss_barrier":180,"boss_defence_factor":1.,"player_attack_factor":1.}
    if config:self.cfg.update(config)
    self.rng=random.Random(seed)
    self.seed=seed; self.policy=policy; self.turn=0; self.ap=6; self.rp=0
    self.party={name:Actor(name,*values) for name,values in BASE_STATS.items()}
    for name, p in self.party.items():
        p.draw=list(enumerate(DECKS[name]))
        self.rng.shuffle(p.draw); self.draw_cards(p,4)
    self.bhp=self.cfg["boss_hp"];self.bbarrier=0;self.breakg=self.cfg["break_max"];self.break_pending=False
    self.phase=1;self.p2shield=False;self.indices={1:1,2:0,3:0}
    self.pending_boss_cast=None;self.core_open=False;self.burn_ticks=0;self.exposed=False
    self.exposed_until=0; self.ren_setup=False
    self.intent={'skill':'B01','target':'ren'}
    self.stats=collections.Counter();self.logs=[];self.actor_damage=collections.Counter();self.card_count=collections.Counter()
    self.ap_spent=collections.Counter(); self.healing=collections.Counter();self.ls_started=collections.Counter(); self.ls_resolved=collections.Counter()
    self.won=False;self.trace=False;self.reaction_used=set();self.swap_used=set();self.intent_attacks=0;self.damage_taken=collections.Counter();self.player_ko=0;self.boss_actions=collections.Counter();self.counter_queued=False
 def log(self,*xs):
    if (self.seed==0 or self.trace) and len(self.logs)<350:self.logs.append(' | '.join(map(str,xs)))
 def draw_cards(self,a,n):
    for _ in range(n):
        if len(a.hand)>=8:break
        if not a.draw:
            if not a.discard:break
            a.draw=a.discard; a.discard=[];self.rng.shuffle(a.draw)
        a.hand.append(a.draw.pop())
 def damage(self, actor, atk, mult, dtype, element=None, hit_check=True, crit=False, bonus=1.0, is_enemy=False):
    # v0.1 defect corrected: player attacks use *BOSS* defense, enemy attacks use *TARGET* defense.
    if is_enemy:
        tgt=self.party[actor]
        defence=tgt.pdef if dtype=='p' else tgt.mdef
        accuracy=105; evasion=tgt.eva
    else:
        defence=(90 if dtype=='p' else 85)*self.cfg['boss_defence_factor']
        accuracy=self.party[actor].acc; evasion=90
    if hit_check:
        prob=max(.05,min(.95,.85+.002*(accuracy-evasion)))
        if self.rng.random()>=prob:return 0
    atk_scaled=atk*(self.cfg['boss_attack_factor'] if is_enemy else self.cfg['player_attack_factor'])
    raw=atk_scaled*mult*200/(200+defence)*bonus
    if not is_enemy:raw*=1.15 if element=='fire' else .90 if element=='arcane' else 1.
    if crit and not is_enemy and self.rng.random()<self.party[actor].crit:raw*=1.5
    raw*=self.rng.uniform(.95,1.05)
    return max(0,math.floor(raw))
 def boss_take(self,amount,who):
    blocked=min(self.bbarrier,amount);self.bbarrier-=blocked
    applied=min(self.bhp,amount-blocked)
    self.bhp-=applied;self.actor_damage[who]+=applied
    return applied
 def break_damage(self,x,p):
    if not self.break_pending:
        if p.name=='ren' and not p.break_bonus_used:
            x+=2;p.break_bonus_used=True
        self.breakg=max(0,self.breakg-x)
        if self.breakg==0:self.break_pending=True;self.stats['break']+=1
 def take(self,name,amount,guard=False):
    p=self.party[name]
    if not p.alive:return 0
    if guard:amount=math.floor(amount*.60)
    shield=min(p.barrier,amount);p.barrier-=shield
    hit=min(p.hp,amount-shield);p.hp-=hit
    self.stats['boss_hp_damage']+=hit;self.damage_taken[name]+=hit
    if p.hp==0:
        self.stats['ko_'+name]+=1;self.player_ko+=1
        if p.casting:
            if p.casting['last']:self.stats['last_invalidated']+=1
            else: p.discard.append(p.casting['inst'])
            p.casting=None
    return hit
 def basic(self,p):
    self.ap-=1;self.ap_spent[p.name]+=1;self.stats['basic']+=1
    dmg=self.damage(p.name,p.patk,.75,'p',hit_check=True,crit=True)
    self.boss_take(dmg,p.name)
    if not p.mp_attack_used:
        p.mp=min(p.mpmax,p.mp+2);p.mp_attack_used=True
    self.log(self.turn,p.name,'basic',dmg,'boss',self.bhp)
 def play(self,p,card,mode='instant'):
    ap,mp,kind,val=CARDS[card]
    assert p.active and p.mp>=mp and self.ap>=ap and card in [v for i,v in p.hand]
    idx=next(i for i,(_,v) in enumerate(p.hand) if v==card)
    inst=p.hand.pop(idx);p.mp-=mp;self.ap-=ap;self.ap_spent[p.name]+=ap
    self.card_count[card]+=1
    if mode=='full':
        p.casting={'last':False,'card':card,'due':self.turn+1,'value':1.65 if card=='A01' else 2.35 if card=='A06' else 1.45 if card=='U01' else 1.40 if card=='T09' else 1.15 if card=='A02' else 2.15 if card=='A04' else val,
                   'inst':inst,'stability':max(1,round(12 * (.9 if p.name=='akane' else 1.2 if p.name=='tsumugi' else 1))), 'focus_ward':0 }
        self.stats['full_started']+=1
        self.log(self.turn,p.name,card,'FULL_started')
        return
    p.discard.append(inst)
    if kind in ('phys','phys2','magic','fire','damageheal'):
        if kind=='phys2':
            amount=sum(self.damage(p.name,p.patk,val,'p',crit=True) for i in range(2))
        elif kind=='phys': amount=self.damage(p.name,p.patk,val,'p',crit=True)
        else:
            el='fire' if kind=='fire' else 'arcane' if card=='U01' else None
            amount=self.damage(p.name,p.matk,val,'m',element=el,hit_check=False,bonus=1+p.boost)
            p.boost=0
        if amount and self.exposed and (card in ('R03','A06')):
            amount=math.floor(amount*(1.25 if card=='R03' else 1.2));self.exposed=False;self.stats['exposed_used']+=1
            if card=='A06' and self.ren_setup:self.stats['combo']+=1
        applied=self.boss_take(amount,p.name)
        if card=='T10' and applied>0:
            candidates=[q for q in self.party.values() if q.alive and q.hp<q.hpmax]
            if candidates:self.heal(candidates and min(candidates,key=lambda x:(x.hp/x.hpmax,list(self.party).index(x.name))),80,p)
        if card in ('R01','R06') and amount:self.break_damage(6 if card=='R01' else 5,p)
        if card in ('R01','R07') and amount and self.core_open and not self.exposed:
            self.exposed=True;self.exposed_until=self.turn+1;self.ren_setup=True;self.stats['exposed_created']+=1
        if card=='A07' and applied:
            self.burn_ticks=2;self.stats['burn_applied']+=1
        self.log(self.turn,p.name,card,amount,'boss',self.bhp)
    elif kind=='heal':
        self.heal(self.low_hp(),val,p)
    elif kind=='teamheal':
        for tgt in self.party.values():
            if tgt.alive:self.heal(tgt,val,p)
    elif kind=='healshield':
        tgt=self.low_hp();self.heal(tgt,val,p);tgt.barrier=max(tgt.barrier,100)
    elif kind=='shield':
        tgt=min((q for q in self.party.values() if q.alive),key=lambda q:(q.barrier,-(q.hp/q.hpmax)))
        tgt.barrier=max(tgt.barrier,val)
    elif kind=='teamshield':
        targets=[p]+sorted([q for q in self.party.values() if q.alive and q.name!=p.name],key=lambda q:q.hp/q.hpmax)[:1]
        for q in targets:q.barrier=max(q.barrier,val)
    elif kind=='mp':
        tgt=min((q for q in self.party.values() if q.alive),key=lambda q:q.mp/q.mpmax)
        tgt.mp=min(tgt.mpmax,tgt.mp+val)
    elif kind=='ward':
        targets=[q for q in self.party.values() if q.casting]
        if targets:targets[0].casting['focus_ward']=targets[0].casting.get('focus_ward',0)+val
    elif kind=='boost':p.boost=val
    elif kind=='disrupt':
        if self.pending_boss_cast:
            self.pending_boss_cast['stability']-=math.floor(8*1.15)
            if self.pending_boss_cast['stability']<=0:
                self.pending_boss_cast=None;self.core_open=False;self.stats['boss_cast_interrupted']+=1
    self.log(self.turn,p.name,card,kind)
 def heal(self,tgt,val,by):
    if not tgt or not tgt.alive:return
    if by.name=='tsumugi' and not by.heal_bonus_used:
        val+=60;by.heal_bonus_used=True
    amt=min(tgt.hpmax-tgt.hp,val);tgt.hp+=amt
    self.healing[by.name]+=amt
 def low_hp(self):
    eligible=[p for p in self.party.values() if p.alive and p.hp<p.hpmax]
    return min(eligible,key=lambda x:(x.hp/x.hpmax,x.name)) if eligible else None
 def valid(self,p,card):
    ap,mp,kind,v=CARDS[card]
    if not p.active or ap>self.ap or mp>p.mp or kind=='reaction':return False
    if kind in ('heal','healshield','teamheal') and not self.low_hp():return False
    if kind=='mp' and all(a.mp==a.mpmax or not a.alive for a in self.party.values()):return False
    if kind=='ward' and not any(q.casting for q in self.party.values()):return False
    if kind=='disrupt' and not self.pending_boss_cast:return False
    return True
 def priority(self,p,card):
    ap,mp,kind,v=CARDS[card]
    hp_missing=max((q.hpmax-q.hp)/q.hpmax for q in self.party.values() if q.alive)
    if kind=='disrupt':return 120 if self.pending_boss_cast and self.pending_boss_cast['stability']<=9 else (62 if self.pending_boss_cast else -100)
    if kind=='ward':return 95 if self.policy in ('casting','cast_support') else 20
    if kind in ('heal','healshield','teamheal'):
        values={'balanced':(100 if hp_missing>.42 else 62 if hp_missing>.25 else 5),
                'aggressive':(77 if hp_missing>.7 else 4),'defensive':(115 if hp_missing>.30 else 45),
                'casting':(85 if hp_missing>.5 else 10)}
        return values.get(self.policy,values['balanced'] if self.policy!='survival' else values['defensive'])+(8 if kind=='healshield' else 0)
    if kind in ('shield','teamshield'):
        val={'balanced':32,'aggressive':-10,'defensive':72,'casting':61,'break_first':24,'exposed_combo':23,'cast_support':61,'damage_rush':-10,'survival':75,'last_early':32}[self.policy]
        if self.intent['skill'] in ('B06','B09','B03'):val+=25
        return val
    if kind=='mp':return 45 if p.mp/p.mpmax<.45 else 4
    if kind=='boost':return 5 if self.policy!='aggressive' else 15
    if kind in ('magic','fire','phys','phys2','damageheal'):
        base={ 'ren':(65 if card=='R01' else 60), 'akane':75, 'tsumugi':48}[p.name]
        if card in ('A06','A04'):base+=12
        if self.policy in ('aggressive','damage_rush'):base+=30
        if self.policy in ('defensive','survival'):base-=12
        if card=='R01' and (self.core_open or not self.break_pending):base+=19
        if self.policy=='break_first' and card in ('R01','R06'):base+=60
        if self.policy=='exposed_combo' and card in ('R01','R07') and self.core_open:base+=70
        if self.policy=='exposed_combo' and card=='A06' and self.exposed:base+=90
        if card=='A06' and self.exposed:base+=26
        if card=='T10' and hp_missing>.15:base+=9
        if card=='U01':base-=15
        return base / (1 if ap==1 else 1.30)
    return -5
 def ai_turn(self):
    self.turn+=1;self.ap=6;self.rp=0;self.swap_used.clear()
    for p in self.party.values():
        p.mp_attack_used=False;p.heal_bonus_used=False;p.break_bonus_used=False
        if p.casting and p.casting['due']<=self.turn:
            cast=p.casting;p.casting=None
            if cast['last']:
                if p.alive:
                    self.resolve_last(p);p.exhausted=True;self.ls_resolved[p.name]+=1
            else:
                if p.alive:
                    card=cast['card'];value=cast['value']
                    el='fire' if card.startswith('A') else 'arcane' if card=='U01' else None
                    damage=self.damage(p.name,p.matk,value,'m',element=el,hit_check=False,bonus=(1.1 if p.name=='akane' else 1.))
                    self.boss_take(damage,p.name);p.discard.append(cast['inst'])
                    self.stats['full_resolved']+=1;self.log(self.turn,p.name,card,'full_damage',damage)
        if p.active:self.draw_cards(p,max(0,4-len(p.hand)))
    if self.bhp<=0:return
    self._perform_swaps()
    self.log(self.turn,'TURN','bossHP',self.bhp,'bossintent',self.intent['skill'])
    # Policies that prefer Last Spell may commit near finisher thresholds.
    if self.policy in ('casting','cast_support') and self.bhp<=2000:
        a=self.party['akane']
        if a.active and not a.ls_used and a.mp>=9 and self.ap>=3:
            self.start_last(a)
    if self.policy=='last_early' and self.turn==1:
        a=self.party['akane']
        if a.active and not a.ls_used and a.mp>=9 and self.ap>=3:self.start_last(a)
    if self.policy in ('balanced','exposed_combo') and self.bhp<=960:
        a=self.party['akane']
        if a.active and not a.ls_used and a.mp>=9 and self.ap>=3:
            self.start_last(a)
    # Each action consumes actual shared AP; some policies reserve resources for RP.
    reserve={'balanced':1,'aggressive':0,'defensive':2,'casting':2,'break_first':1,'exposed_combo':1,'cast_support':2,'damage_rush':0,'survival':3,'last_early':1}[self.policy]
    for it in range(14):
        if self.bhp<=0 or self.ap<=reserve:break
        opts=[]
        for p in self.party.values():
            if not p.active:continue
            for inst,card in p.hand:
                if self.valid(p,card) and self.ap-CARDS[card][0]>=reserve:
                    opts.append((self.priority(p,card)+self.rng.uniform(-4,4),p,card))
            # Basic Attack recovery can be preferred even when regular SP is in hand.
            base=52 if not p.mp_attack_used and p.mp<=(p.mpmax-2) else 13
            if self.policy in ('aggressive','damage_rush'):base+=23
            if self.policy in ('defensive','survival'):base-=7
            if self.ap-1>=reserve:opts.append((base+self.rng.uniform(-3,3),p,'BASIC'))
        if not opts:break
        val,p,card=max(opts,key=lambda x:x[0])
        if card=='BASIC':self.basic(p)
        else:
            # Prefer some Full Chant in a casting plan only when it can finish before battle.
            mode='instant'
            if self.policy in ('casting','cast_support') and card in ('A01','A04','A06','T09') and self.bhp>1100 and self.rng.random()<.65:
                mode='full'
            self.play(p,card,mode)
    self.rp=min(6,self.ap);self.ap=0
 def start_last(self,p):
    self.ap-=3;p.mp-=9 if p.name=='akane' else 5 if p.name=='ren' else 7
    self.ap_spent[p.name]+=3;p.ls_used=True
    p.casting={'last':True,'due':self.turn+2,'stability':11,'card':'LAST'}
    self.ls_started[p.name]+=1;self.log(self.turn,p.name,'LS_START')
 def resolve_last(self,p):
    if p.name=='akane':
        damage=self.damage('akane',p.matk,6.80,'m',element='fire',hit_check=False)
        self.boss_take(damage,p.name);self.log(self.turn,p.name,'LS_RESOLVE',damage)
    elif p.name=='ren':
        damage=self.damage('ren',p.patk,6.5,'p',hit_check=True)
        if damage:self.break_damage(24,p)
        self.boss_take(damage,p.name)
    else:
        for q in self.party.values():
            if q.alive:self.heal(q,round(q.hpmax*.35),p);q.barrier=max(q.barrier,260)
 def next_phase_intent(self):
    # Choose next intent ONLY after previous action resolved; committed intent unchanged by player damage.
    self.phase=1 if self.bhp>1950 else 2 if self.bhp>900 else 3
    if self.phase==2 and not self.p2shield:
        self.p2shield=True;return {'skill':'B07','target':None}
    cycles={1:['B01','B05','B04'],2:['B02','B03','B04'],3:['B08','B01','B04']}
    cyc=cycles[self.phase];skill=cyc[self.indices[self.phase]%len(cyc)];self.indices[self.phase]+=1
    if self.break_pending and skill in ('B01','B02','B03','B04'):
        skill='B11'
    if skill=='B01':target='ren' if self.party['ren'].alive else next((x for x in self.party if self.party[x].alive),None)
    elif skill=='B02':
        q=min((p for p in self.party.values() if p.alive),key=lambda a:(a.hp/a.hpmax,list(self.party).index(a.name)),default=None);target=q.name if q else None
    elif skill=='B03':
        p=next((p for p in self.party.values() if p.alive and p.casting),None)
        target=p.name if p else next((x for x in ['akane','ren','tsumugi'] if self.party[x].alive),None)
    elif skill=='B11':target=next((x for x in ('ren','akane','tsumugi') if self.party[x].alive),None)
    else:target=None
    return {'skill':skill,'target':target}
 def enemy_turn(self):
    if self.bhp<=0:return
    self.reaction_used=set();self.counter_queued=False
    s=self.intent['skill'];t=self.intent.get('target')
    self.boss_actions[s]+=1
    self.log(self.turn,'ENEMY',s,t)
    if s=='B07':self.bbarrier=max(self.bbarrier,self.cfg['boss_barrier'])
    elif s in ('B05','B08'):
        self.pending_boss_cast={'stability':9 if s=='B05' else 15,'type':'beam' if s=='B05' else 'nova'}
        self.core_open=True
        self.intent={'skill':'B06' if s=='B05' else 'B09','target':'akane' if s=='B05' else None}
        return
    elif s in ('B06','B09'):
        if self.pending_boss_cast:
            if s=='B06':self.enemy_attack('B06','akane',2.35,'m',True)
            else:
                for target in self.party:self.enemy_attack('B09',target,1.50,'m',False)
        else:self.stats['cooldown']+=1
        self.pending_boss_cast=None;self.core_open=False
    elif s in ('B01','B11'):
        self.enemy_attack(s,t,1.35 if s=='B01' else .60,'p',True)
        if s=='B11':self.break_pending=False;self.breakg=self.cfg['break_max'];self.stats['fallback']+=1
    elif s=='B02':
        self.enemy_multi_hit(t)
    elif s=='B03':self.enemy_attack(s,t,1.35,'m',True,disrupt=5)
    elif s=='B04':
        for target in self.party:self.enemy_attack(s,target,1.05,'m',False)
    if self.counter_queued and self.bhp>0 and self.party['ren'].alive:
        counter_damage=self.damage('ren',self.party['ren'].patk,.55,'p',crit=False)
        self.boss_take(counter_damage,'ren');self.stats['reaction_counter_done']+=1
        self.log(self.turn,'R05_COUNTER',counter_damage)
    if self.burn_ticks and self.bhp>0:
        self.boss_take(45,'akane');self.burn_ticks-=1;self.stats['burn_ticks']+=1
    self.intent=self.next_phase_intent()
    self.exposed=self.exposed and self.turn<self.exposed_until
    for p in self.party.values():p.barrier=0 # Encounter's one-enemy-phase barrier lifetime.
 def _reaction_card(self,actor,card):
    p=self.party[actor]
    if not p.active or p.name in self.reaction_used or not any(v==card for _,v in p.hand):return False
    rp,mp=('2','1') if card=='R05' else ('1','2')
    rp=int(rp);mp=int(mp)
    if self.rp<rp or p.mp<mp:return False
    inst=next(c for c in p.hand if c[1]==card)
    p.hand.remove(inst);p.discard.append(inst);p.mp-=mp;self.rp-=rp
    self.reaction_used.add(actor);self.card_count[card]+=1;self.stats['reaction_card_'+card]+=1
    return True
 def _defense_window(self,skill,target,protectable,forecast):
    # The enemy's ONE action defines ONE window; RP committed only when actor and legal target rechecked.
    if not target or not self.party[target].alive:return target,False
    defensive=self.policy in ('balanced','defensive','casting','break_first','exposed_combo')
    if defensive and protectable and target=='akane' and self.party['ren'].active:
        if self._reaction_card('ren','R05'):
            target='ren';self.party['ren'].barrier=max(80,self.party['ren'].barrier);self.stats['protect']+=1
            self.stats['reaction_counter_pending']+=1;self.counter_queued=True
        elif self.rp>=2 and self.party['ren'].hp>400:
            target='ren';self.rp-=2;self.stats['protect']+=1;self.reaction_used.add('ren')
    if defensive and forecast>145 and self.party['tsumugi'].active and self.rp>=1 and target!='tsumugi':
        if self._reaction_card('tsumugi','T05'):
            self.party[target].barrier=max(self.party[target].barrier,130)
    guard=False
    if defensive and self.rp>=1 and target not in self.reaction_used and (forecast>175 or self.party[target].hp<.65*self.party[target].hpmax):
        if self.party[target].active:
            self.rp-=1;guard=True;self.stats['guard']+=1;self.reaction_used.add(target)
    return target,guard
 def enemy_multi_hit(self,target):
    if not target or not self.party[target].alive:return
    target,guard=self._defense_window('B02',target,True,260)
    for _ in range(2):
        if not self.party[target].alive:break
        raw=self.damage(target,245,.8,'p',hit_check=True,is_enemy=True)
        if raw:
            taken=self.take(target,raw,guard=guard)
            self.log(self.turn,'BOSS','B02',target,'hp_damage',taken)
 def enemy_attack(self,skill,target,mult,dtype,protectable,disrupt=0):
    if not target or not self.party[target].alive:return
    forecast=200 if mult<=1.5 else 420
    target,guard=self._defense_window(skill,target,protectable,forecast)
    raw=self.damage(target,245 if dtype=='p' else 255,mult,dtype,hit_check=(dtype=='p'),is_enemy=True)
    if raw<=0:return
    taken=self.take(target,raw,guard=guard)
    p=self.party[target]
    if disrupt and taken>0 and p.casting:
        cast=p.casting
        absorbed=min(disrupt,cast.get('focus_ward',0));cast['focus_ward']=cast.get('focus_ward',0)-absorbed
        cast['stability']-=disrupt-absorbed
        if cast['stability']<=0 and not cast['last']:
            p.casting=None;p.discard.append(cast['inst']);p.mp=min(p.mpmax,p.mp+math.floor(CARDS[cast['card']][1]*.5))
            self.stats['player_full_interrupt']+=1
    self.log(self.turn,'BOSS',skill,target,'hp_damage',taken,'remaining',p.hp)
 def _perform_swaps(self):
    # One per actor/phase, fail without consumption if no possible replacement; cannot redraw same instance.
    for p in self.party.values():
        if not p.active or p.name in self.swap_used or not p.hand:continue
        alt_available=bool(p.draw or p.discard)
        if not alt_available:continue
        # If there is a legal cast, protect useful future cards; swap at most one worst unplayable card.
        candidates=[]
        for i,card in p.hand:
            if card=='R05' and self.intent.get('target')=='akane' and self.intent['skill'] in ('B01','B02','B03','B06'):
                score=55
            elif card=='T05' and self.intent['skill'] in ('B01','B02','B03','B04','B06','B09'):
                score=42
            else:score=self.priority(p,card) if self.valid(p,card) else -90
            candidates.append((score,i,card))
        score,i,card=min(candidates)
        # Only swap clearly inferior card, not every turn's least attractive useful card.
        if score>20:continue
        inst=p.hand.pop(next(j for j,el in enumerate(p.hand) if el[0]==i))
        # Exclude discarded card until drawing a different CardInstance.
        oldhand=len(p.hand)
        self.draw_cards(p,1)
        if len(p.hand)==oldhand:
            p.hand.append(inst);continue
        p.discard.append(inst);self.swap_used.add(p.name);self.stats['free_swap']+=1
        self.log(self.turn,p.name,'FREE_SWAP',card,'to',p.hand[-1][1])
 def run(self,max_turn=24):
    for _ in range(max_turn):
        if self.bhp<=0 or not any(x.alive for x in self.party.values()):break
        self.ai_turn()
        if self.bhp<=0:break
        self.enemy_turn()
    win=self.bhp<=0
    d={'seed':self.seed,'policy':self.policy,'won':int(win),'turns':self.turn,
       'boss_hp_remaining':self.bhp,'party_hp_remaining':sum(p.hp for p in self.party.values()),
       'active_party':sum(p.alive for p in self.party.values()),
       'ren_damage':self.actor_damage['ren'],'akane_damage':self.actor_damage['akane'],'tsumugi_damage':self.actor_damage['tsumugi'],
       'heal':sum(self.healing.values()),'guards':self.stats['guard'],'protects':self.stats['protect'],
       'breaks':self.stats['break'],'fallbacks':self.stats['fallback'],
       'exposed_created':self.stats['exposed_created'],'exposed_used':self.stats['exposed_used'],
       'boss_interrupts':self.stats['boss_cast_interrupted'],
       'full_started':self.stats['full_started'],'full_resolved':self.stats['full_resolved'],
       'last_started':sum(self.ls_started.values()),'combos':self.stats['combo'], 'last_resolved':sum(self.ls_resolved.values()),
       'basic_attacks':self.stats['basic'], 'free_swaps':self.stats['free_swap'],
       'reaction_r05':self.stats['reaction_card_R05'],'reaction_t05':self.stats['reaction_card_T05'],
       'boss_damage_to_party':self.stats['boss_hp_damage'],'party_kos':self.player_ko,'boss_attacks':sum(self.boss_actions.values()),'boss_phase':self.phase,'counter_done':self.stats['reaction_counter_done']}
    return d

def validate_v02():
    assert all(len(v)==12 for v in DECKS.values())
    assert all(c in CARDS for vals in DECKS.values() for c in vals)
    assert all(sum(len(a.hand)+len(a.draw)+len(a.discard)+(1 if a.casting and not a.casting['last'] else 0) for a in [p])==12 for p in Fight(3,'balanced').party.values())
    for pol in ('balanced','aggressive','defensive','casting','break_first','exposed_combo','cast_support','last_early'):
        assert Fight(25,pol).run()==Fight(25,pol).run()
    # Strict legal invariant: special reaction SP MUST be in actor's hand, and no RP overdraft.
    f=Fight(9,'balanced');f.rp=0
    assert not f._reaction_card('ren','R05')
    assert f.rp==0
    # New damage formula must target the boss, not the attacker's personal armor.
    f=Fight(9,'balanced');f.party['ren'].pdef=9999
    # Formula must not depend on own PDef; test fixed-seed RNG on two otherwise identical fights
    g=Fight(9,'balanced')
    assert f.damage('ren',135,1,'p',hit_check=False)==g.damage('ren',135,1,'p',hit_check=False)
    return True

if __name__=='__main__':
    import argparse
    arg=argparse.ArgumentParser();arg.add_argument('--seeds',type=int,default=100);arg.add_argument('--out',default='/mnt/data/astraea_balance_v0_2')
    args=arg.parse_args();validate_v02()
    policies=['balanced','aggressive','defensive','casting','break_first','exposed_combo','cast_support','last_early']
    rows=[Fight(seed,policy).run() for policy in policies for seed in range(args.seeds)]
    import os
    os.makedirs(args.out,exist_ok=True)
    with open(os.path.join(args.out,'baseline_v0_2_7_policies.csv'),'w',newline='',encoding='utf-8-sig') as fh:
        w=csv.DictWriter(fh,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    print('executed',len(rows),'runs, validated')