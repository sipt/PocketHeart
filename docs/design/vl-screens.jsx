// === Voice Ledger iOS Screens ===
// Reuses iOS frame styling vocabulary from PocketMind chat app:
// - Dark #000 background, purple #7B61FF primary
// - SF system font, 17pt nav, grouped 14r cards, 0.5px separators
// - Chat-style stream where each user input → grouped ledger result card

const VL_SF = '-apple-system, "SF Pro Text", "SF Pro Display", system-ui, sans-serif';
const VL_MONO = 'JetBrains Mono, "SF Mono", monospace';

// Generated avatar (deterministic blob)
function VLAvatar({ seed = 'Me', size = 28 }) {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) % 360;
  return (
    <div style={{
      width:size, height:size, flex:`0 0 ${size}px`, borderRadius:'50%',
      background:`linear-gradient(135deg, oklch(0.74 0.16 ${h}), oklch(0.55 0.18 ${(h+60)%360}))`,
      display:'flex', alignItems:'center', justifyContent:'center',
      color:'rgba(255,255,255,0.95)', fontSize: size * 0.4, fontWeight:600,
    }}>{seed[0].toUpperCase()}</div>
  );
}

// Category icon — colored rounded square w/ glyph (no emoji)
function CatIcon({ cat, size = 36 }) {
  const map = {
    food:    { c: 'oklch(0.72 0.16 30)',  g: <path d="M5 4v8a2 2 0 0 0 2 2v6h2v-6a2 2 0 0 0 2-2V4M9 4v5M14 4v6c0 1 1 2 2 2v8h-2"/> },
    transit: { c: 'oklch(0.7 0.15 240)',  g: <path d="M5 17V7a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v10M5 17h14M5 17l-1 3M19 17l1 3M8 12h8M8 8h8"/> },
    coffee:  { c: 'oklch(0.62 0.13 50)',  g: <path d="M3 8h13v6a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V8ZM16 10h2a2 2 0 0 1 0 4h-2"/> },
    grocery: { c: 'oklch(0.72 0.15 145)', g: <path d="M3 6h2l2 11h11l2-8H7M9 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2ZM17 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"/> },
    salary:  { c: 'oklch(0.72 0.15 280)', g: <path d="M12 4v16M9 7h5a2 2 0 0 1 0 4h-4a2 2 0 0 0 0 4h6"/> },
    other:   { c: 'oklch(0.65 0.05 280)', g: <circle cx="12" cy="12" r="6"/> },
  };
  const m = map[cat] || map.other;
  return (
    <div style={{
      width:size, height:size, borderRadius: size * 0.28,
      background:`color-mix(in oklch, ${m.c} 22%, #1C1C1E)`,
      display:'flex', alignItems:'center', justifyContent:'center', flex:`0 0 ${size}px`,
    }}>
      <svg width={size*0.55} height={size*0.55} viewBox="0 0 24 24" fill="none" stroke={m.c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">{m.g}</svg>
    </div>
  );
}

// === Screen 1: Record Stream (main) ===
function VLStream({ startAt = 'bottom' }){
  const streamRef = React.useRef(null);
  React.useEffect(() => {
    if (streamRef.current && startAt === 'bottom') streamRef.current.scrollTop = streamRef.current.scrollHeight;
    if (streamRef.current && startAt === 'top') streamRef.current.scrollTop = 0;
  }, [startAt]);
  const today = [
    { kind:'date', label:'Today' },
    { kind:'user', source:'voice', text:'今天午饭花了 38 块，公司楼下沙县小吃，微信支付', time:'12:42' },
    { kind:'group', input:'voice', summary:'1 expense · CNY 38', when:'12:42 PM',
      txns:[
        { amt:'38.00', cur:'¥', title:'Lunch at Shaxian', where:'Shaxian (Office)', cat:'food', sub:'Lunch', tags:['work'], pay:'WeChat Pay', t:'12:30 PM' },
      ]
    },
    { kind:'user', source:'text', text:'Coffee 28, snack for the team 92, both Apple Pay credit card, 4pm', time:'4:08' },
    { kind:'group', input:'text', summary:'2 expenses · CNY 120', when:'4:08 PM',
      txns:[
        { amt:'28.00', cur:'¥', title:'Latte', cat:'coffee', sub:'Coffee', tags:['afternoon'], pay:'CMB Credit · Apple Pay', t:'4:00 PM' },
        { amt:'92.00', cur:'¥', title:'Team snacks', cat:'food', sub:'Snacks', tags:['work','team'], pay:'CMB Credit · Apple Pay', t:'4:00 PM' },
      ]
    },
    { kind:'user', source:'voice', text:'昨天晚上打车回家 47 块，刚才地铁 6 块，还有 1500 块工资到账', time:'5:21' },
    { kind:'group', input:'voice', summary:'2 expenses · 1 income · CNY +1447', when:'5:21 PM',
      txns:[
        { amt:'47.00', cur:'¥', title:'DiDi home', cat:'transit', sub:'Ride-hail', tags:['late'], pay:'Alipay', t:'Yesterday 11:14 PM' },
        { amt:'6.00', cur:'¥', title:'Subway', cat:'transit', sub:'Metro', pay:'Transit Card', t:'5:08 PM' },
        { amt:'1500.00', cur:'¥', title:'Side project payout', cat:'salary', sub:'Freelance', pay:'CMB Bank', t:'4:30 PM', income:true },
      ],
      failed:[{ raw:'… 1500 块工资', reason:'low confidence on payer — confirm?' }],
    },
    { kind:'user', source:'voice', text:'Recording…', time:'now', live:true },
  ];

  return (
    <div style={vl.screen}>
      <IOSStatusBar dark={true}/>

      {/* nav */}
      <div style={vl.nav}>
        <button style={vl.navIconBtn}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M3 12 9 6v3h7l3 3-3 3v3H9v3l-6-6Z"/><path d="M14 4l3 3M19 9l1 1"/></svg>
        </button>
        <div style={{textAlign:'center'}}>
          <div style={{fontSize:11, color:'rgba(235,235,245,0.5)', fontWeight:500}}>April · Today</div>
          <div style={{fontSize:15, color:'white', fontWeight:600, display:'flex', alignItems:'center', gap:4, justifyContent:'center'}}>
            Ledger
            <span style={{color:'#7B61FF', fontSize:12, fontWeight:500, marginLeft:3, padding:'1px 6px', background:'rgba(123,97,255,0.16)', borderRadius:99}}>DeepSeek</span>
          </div>
        </div>
        <button style={vl.navIconBtn}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h13M3 12h13M3 18h9M19 6v12M16 9l3-3 3 3M16 15l3 3 3-3"/></svg>
        </button>
      </div>

      {/* mini summary chip */}
      <div style={vl.todayChip}>
        <div>
          <div style={{fontSize:10.5, color:'rgba(235,235,245,0.5)', textTransform:'uppercase', letterSpacing:0.3}}>Spent today</div>
          <div style={{fontSize:22, fontWeight:700, color:'white', fontFamily:VL_SF, letterSpacing:-0.5, marginTop:1}}>
            <span style={{fontSize:13, color:'rgba(235,235,245,0.55)', marginRight:2}}>¥</span>211.00
            <span style={{fontSize:11, color:'#30D158', fontWeight:500, marginLeft:8}}>+¥1,500 in</span>
          </div>
        </div>
        <button style={vl.statsBtn}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#7B61FF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 17l6-6 4 4 8-8"/><path d="M14 7h7v7"/></svg>
          Stats
        </button>
      </div>

      {/* stream */}
      <div ref={streamRef} style={vl.stream}>
        {today.map((m, i) => {
          if (m.kind === 'date') return <DayDivider key={i} label={m.label}/>;
          if (m.kind === 'user') return <UserBubble key={i} m={m}/>;
          if (m.kind === 'group') return <GroupCard key={i} g={m}/>;
          return null;
        })}
      </div>

      {/* input */}
      <VLInput live/>
      <IOSHomeBar/>
    </div>
  );
}

function DayDivider({ label }){
  return <div style={vl.dayDiv}><span style={vl.dayLine}/><span>{label}</span><span style={vl.dayLine}/></div>;
}

function UserBubble({ m }){
  const isVoice = m.source === 'voice';
  if (m.live) return (
    <div style={{display:'flex', justifyContent:'flex-end', marginBottom:10}}>
      <div style={{...vl.userBubble, background:'rgba(123,97,255,0.18)', boxShadow:'inset 0 0 0 1px rgba(123,97,255,0.45)', display:'flex', alignItems:'center', gap:8}}>
        <span style={{...vl.recDot, animation:'vlPulse 1.2s infinite'}}/>
        <div style={{display:'flex', alignItems:'center', gap:2, height:14}}>
          {[8,12,6,14,9,12,7,10,13,8,11].map((h, i) => (
            <span key={i} style={{width:2, borderRadius:2, height:h, background:'#B5A4FF', animation:`vlBar 0.9s ${i*0.05}s infinite ease-in-out`}}/>
          ))}
        </div>
        <span style={{fontSize:13, color:'#E0D8FF', fontFamily:VL_MONO}}>0:04</span>
      </div>
    </div>
  );
  return (
    <div style={{display:'flex', justifyContent:'flex-end', alignItems:'flex-end', gap:6, marginBottom:8}}>
      <div style={{display:'flex', flexDirection:'column', alignItems:'flex-end', maxWidth:'78%'}}>
        <div style={vl.userBubble}>
          {isVoice && <div style={{display:'flex', alignItems:'center', gap:6, marginBottom:6, color:'rgba(255,255,255,0.75)'}}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="white"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3" stroke="white" strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
            <span style={{fontSize:10.5, fontWeight:500, letterSpacing:0.3, textTransform:'uppercase'}}>Voice · 0:06</span>
          </div>}
          {m.text}
        </div>
        <div style={{fontSize:10, color:'rgba(235,235,245,0.4)', marginTop:3, marginRight:4}}>{m.time}</div>
      </div>
    </div>
  );
}

function GroupCard({ g }){
  return (
    <div style={vl.groupCard}>
      <div style={vl.groupHead}>
        <div style={{display:'flex', alignItems:'center', gap:7}}>
          <div style={vl.aiBadge}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M6 18l2.5-2.5M15.5 8.5 18 6"/></svg>
          </div>
          <span style={{fontSize:13, fontWeight:600, color:'white'}}>{g.summary}</span>
        </div>
        <span style={{fontSize:11, color:'rgba(235,235,245,0.4)', fontFamily:VL_MONO}}>{g.input} · {g.when}</span>
      </div>
      <div style={vl.txnList}>
        {g.txns.map((t, i) => <TxnRow key={i} t={t}/>)}
      </div>
      {g.failed && g.failed.map((f, i) => (
        <div key={i} style={vl.failedRow}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#F2C94C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 8v5M12 17h.01M3 18 12 3l9 15Z"/></svg>
          <div style={{flex:1, minWidth:0}}>
            <div style={{fontSize:12, color:'#F2C94C'}}>{f.reason}</div>
            <div style={{fontSize:11, color:'rgba(235,235,245,0.45)', marginTop:1}}>{f.raw}</div>
          </div>
          <button style={vl.miniBtn}>Fix</button>
        </div>
      ))}
    </div>
  );
}

function TxnRow({ t }){
  return (
    <div style={vl.txnRow}>
      <CatIcon cat={t.cat} size={36}/>
      <div style={{flex:1, minWidth:0}}>
        <div style={{display:'flex', alignItems:'baseline', gap:6}}>
          <span style={{fontSize:14.5, fontWeight:600, color:'white', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis'}}>{t.title}</span>
          {t.where && <span style={{fontSize:11, color:'rgba(235,235,245,0.4)', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis'}}>· {t.where}</span>}
        </div>
        <div style={{display:'flex', flexWrap:'wrap', gap:4, marginTop:5, alignItems:'center'}}>
          <span style={vl.metaPill}>{t.sub || t.cat}</span>
          <span style={vl.metaPillMute}>{t.pay}</span>
          {t.tags && t.tags.map(tag => <span key={tag} style={vl.tagPill}>#{tag}</span>)}
        </div>
        <div style={{fontSize:10.5, color:'rgba(235,235,245,0.4)', marginTop:5, fontFamily:VL_MONO}}>{t.t}</div>
      </div>
      <div style={{textAlign:'right', display:'flex', flexDirection:'column', alignItems:'flex-end', gap:3}}>
        <div style={{fontSize:16, fontWeight:700, color: t.income ? '#30D158' : 'white', letterSpacing:-0.3, fontFamily:VL_SF}}>
          <span style={{fontSize:11, opacity:0.6, marginRight:1}}>{t.income ? '+' : ''}{t.cur}</span>{t.amt}
        </div>
        <svg width="7" height="11" viewBox="0 0 8 14"><path d="M1 1l6 6-6 6" stroke="rgba(235,235,245,0.3)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </div>
    </div>
  );
}

// === Bottom input ===
function VLInput({ live }){
  return (
    <div style={vl.inputBar}>
      <button style={vl.inputIcon}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(235,235,245,0.7)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 11V6a3 3 0 0 1 6 0v5a3 3 0 1 1-6 0Z"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>
      </button>
      <div style={vl.inputField}>
        <span style={{color:'rgba(235,235,245,0.5)', fontSize:14}}>Tell me what you spent…</span>
      </div>
      {live ? (
        <button style={{...vl.recordBtn, background:'#FF453A'}}>
          <span style={{width:10, height:10, borderRadius:2, background:'white'}}/>
        </button>
      ) : (
        <button style={vl.recordBtn}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>
        </button>
      )}
    </div>
  );
}

// === Screen 2: Edit Transaction ===
function VLEdit(){
  return (
    <div style={vl.screen}>
      <IOSStatusBar dark={true}/>
      <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', padding:'4px 18px 8px'}}>
        <button style={{color:'#7B61FF', fontSize:17, background:'none', border:'none'}}>Cancel</button>
        <div style={{fontSize:15, fontWeight:600, color:'white'}}>Edit transaction</div>
        <button style={{color:'#7B61FF', fontSize:17, fontWeight:600, background:'none', border:'none'}}>Save</button>
      </div>

      <div style={{flex:1, overflowY:'auto', padding:'4px 0 16px'}}>
        {/* amount hero */}
        <div style={vl.amountHero}>
          <div style={{display:'flex', alignItems:'center', gap:6, marginBottom:8}}>
            <button style={vl.typePill}>– Expense</button>
            <button style={vl.typePillInactive}>+ Income</button>
          </div>
          <div style={{display:'flex', alignItems:'baseline', gap:6, justifyContent:'center'}}>
            <span style={{fontSize:18, color:'rgba(235,235,245,0.5)', fontWeight:500}}>CNY ¥</span>
            <span style={{fontSize:48, fontWeight:700, color:'white', letterSpacing:-1.5, fontFamily:VL_SF}}>92.00</span>
          </div>
          <div style={{fontSize:12, color:'rgba(235,235,245,0.4)', textAlign:'center', marginTop:4, fontFamily:VL_MONO}}>parsed from voice · DeepSeek</div>
        </div>

        <div style={{padding:'0 16px'}}>
          <div style={vl.formCard}>
            <FormRow label="Title" value="Team snacks"/>
            <FormRow label="Merchant" value="Bright Mart" muted/>
            <FormRow label="Time" value="Today 4:00 PM"/>
            <FormRow label="Currency" value="CNY ¥"/>
          </div>

          <div style={vl.sectionLabel}>CATEGORY</div>
          <div style={vl.formCard}>
            <FormRow label="Category" value="Food" icon={<CatIcon cat="food" size={26}/>}/>
            <FormRow label="Subcategory" value="Snacks"/>
          </div>

          <div style={vl.sectionLabel}>PAYMENT & TAGS</div>
          <div style={vl.formCard}>
            <FormRow label="Payment" value="CMB Credit · Apple Pay"/>
            <FormRow label="Tags" value={
              <div style={{display:'flex', gap:4, flexWrap:'wrap', justifyContent:'flex-end'}}>
                <span style={vl.tagPill}>#work</span>
                <span style={vl.tagPill}>#team</span>
                <span style={{...vl.tagPill, color:'#7B61FF', background:'rgba(123,97,255,0.12)'}}>+ add</span>
              </div>
            } isNode/>
          </div>

          <div style={vl.sectionLabel}>NOTES</div>
          <div style={{...vl.formCard, padding:'12px 14px'}}>
            <div style={{fontSize:14, color:'rgba(235,235,245,0.5)', minHeight:50, lineHeight:1.5}}>
              Friday afternoon snacks for the design review. Reimbursable.
            </div>
          </div>

          <div style={{...vl.formCard, marginTop:18, background:'transparent', boxShadow:'none'}}>
            <button style={{padding:'13px 16px', color:'#FF453A', fontSize:15, width:'100%', textAlign:'center', background:'#1C1C1E', borderRadius:14, border:'none', fontFamily:VL_SF}}>Delete transaction</button>
          </div>
        </div>
      </div>
      <IOSHomeBar/>
    </div>
  );
}

function FormRow({ label, value, muted, icon, isNode }){
  return (
    <div style={vl.formRow}>
      <div style={{flex:1, fontSize:14, color: muted ? 'rgba(235,235,245,0.55)' : 'white'}}>{label}</div>
      <div style={{display:'flex', alignItems:'center', gap:8, color: muted ? 'rgba(235,235,245,0.5)' : 'white', fontSize:14}}>
        {icon}
        {isNode ? value : <span>{value}</span>}
        <svg width="6" height="11" viewBox="0 0 8 14"><path d="M1 1l6 6-6 6" stroke="rgba(235,235,245,0.3)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </div>
    </div>
  );
}

// === Screen 3: Stats ===
function VLStats(){
  const cats = [
    { name:'Food', cat:'food',    amt:824, pct:42 },
    { name:'Transit', cat:'transit', amt:312, pct:16 },
    { name:'Coffee', cat:'coffee',  amt:218, pct:11 },
    { name:'Grocery', cat:'grocery', amt:412, pct:21 },
    { name:'Other', cat:'other',   amt:194, pct:10 },
  ];
  const trend = [12,28,18,42,34,52,30,48,38,72,28,44,30];
  const max = Math.max(...trend);
  return (
    <div style={vl.screen}>
      <IOSStatusBar dark={true}/>
      <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', padding:'4px 18px 0'}}>
        <button style={{color:'#7B61FF', fontSize:17, background:'none', border:'none'}}>‹ Ledger</button>
        <button style={{width:32, height:32, borderRadius:'50%', background:'rgba(118,118,128,0.18)', display:'flex', alignItems:'center', justifyContent:'center', border:'none'}}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 5h18l-7 9v6l-4-2v-4L3 5Z"/></svg>
        </button>
      </div>
      <div style={{padding:'4px 18px 14px'}}>
        <div style={{fontSize:34, fontWeight:700, color:'white', letterSpacing:-0.5}}>Stats</div>
      </div>

      {/* segmented period */}
      <div style={{padding:'0 16px 12px'}}>
        <div style={vl.segment}>
          {['Today','Week','Month','Year'].map((t, i) => (
            <button key={t} style={{...vl.segItem, ...(i === 2 ? vl.segItemActive : null)}}>{t}</button>
          ))}
        </div>
      </div>

      <div style={{flex:1, overflowY:'auto', padding:'0 16px 16px'}}>
        {/* hero totals */}
        <div style={vl.statHero}>
          <div style={{display:'flex', justifyContent:'space-between', alignItems:'flex-start'}}>
            <div>
              <div style={{fontSize:11, color:'rgba(235,235,245,0.5)', textTransform:'uppercase', letterSpacing:0.4}}>April spent</div>
              <div style={{fontSize:32, fontWeight:700, color:'white', letterSpacing:-0.8, marginTop:4, fontFamily:VL_SF}}>
                <span style={{fontSize:16, opacity:0.6, marginRight:2}}>¥</span>1,960<span style={{fontSize:18, opacity:0.55}}>.00</span>
              </div>
              <div style={{fontSize:12, color:'#FF6B6B', marginTop:4, fontWeight:500}}>↑ 12% vs March</div>
            </div>
            <div style={{textAlign:'right'}}>
              <div style={{fontSize:11, color:'rgba(235,235,245,0.5)', textTransform:'uppercase', letterSpacing:0.4}}>Income</div>
              <div style={{fontSize:18, fontWeight:600, color:'#30D158', marginTop:6, fontFamily:VL_SF}}>+¥1,500</div>
              <div style={{fontSize:11, color:'rgba(235,235,245,0.45)', marginTop:3}}>net –¥460</div>
            </div>
          </div>

          {/* trend bars */}
          <div style={{display:'flex', alignItems:'flex-end', gap:4, height:64, marginTop:18}}>
            {trend.map((v, i) => (
              <div key={i} style={{flex:1, height:`${(v/max)*100}%`, borderRadius:'3px 3px 1px 1px', background: i === 9 ? '#7B61FF' : 'rgba(123,97,255,0.32)'}}/>
            ))}
          </div>
          <div style={{display:'flex', justifyContent:'space-between', fontSize:10, color:'rgba(235,235,245,0.4)', marginTop:6, fontFamily:VL_MONO}}>
            <span>Apr 1</span><span>Apr 13</span><span>Today</span>
          </div>
        </div>

        <div style={vl.sectionLabel}>BY CATEGORY</div>
        <div style={vl.formCard}>
          {cats.map((c, i) => (
            <div key={c.cat} style={{...vl.txnRow, padding:'11px 14px', borderBottom: i === cats.length-1 ? 'none' : '0.5px solid rgba(235,235,245,0.1)'}}>
              <CatIcon cat={c.cat} size={32}/>
              <div style={{flex:1, minWidth:0}}>
                <div style={{display:'flex', justifyContent:'space-between', marginBottom:5}}>
                  <span style={{fontSize:14, fontWeight:500, color:'white'}}>{c.name}</span>
                  <span style={{fontSize:14, fontWeight:600, color:'white', fontFamily:VL_SF}}>¥{c.amt}</span>
                </div>
                <div style={{height:4, background:'rgba(235,235,245,0.08)', borderRadius:99, overflow:'hidden'}}>
                  <div style={{width:`${c.pct}%`, height:'100%', background:'#7B61FF', borderRadius:99}}/>
                </div>
                <div style={{fontSize:10.5, color:'rgba(235,235,245,0.45)', marginTop:3}}>{c.pct}%</div>
              </div>
            </div>
          ))}
        </div>

        <div style={vl.sectionLabel}>TOP TAGS</div>
        <div style={{...vl.formCard, padding:14, display:'flex', gap:6, flexWrap:'wrap'}}>
          {[['work',12],['lunch',8],['team',5],['late',4],['afternoon',3],['groceries',2]].map(([t, n]) => (
            <span key={t} style={{...vl.tagPill, padding:'5px 10px', fontSize:12}}>#{t} <span style={{opacity:0.55, marginLeft:2}}>{n}</span></span>
          ))}
        </div>
      </div>
      <IOSHomeBar/>
    </div>
  );
}

// === Screen 4: Settings — AI providers ===
function VLSettings(){
  const providers = [
    { name:'DeepSeek', model:'deepseek-chat', tag:'default', online:true, kw:'DS' },
    { name:'OpenAI', model:'gpt-4o-mini', online:true, kw:'OA' },
    { name:'Anthropic', model:'claude-haiku-4.5', online:false, kw:'AN' },
    { name:'Local · Ollama', model:'qwen2:7b', online:true, kw:'OL' },
  ];
  return (
    <div style={vl.screen}>
      <IOSStatusBar dark={true}/>
      <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', padding:'4px 18px 0'}}>
        <button style={{color:'#7B61FF', fontSize:17, background:'none', border:'none'}}>‹ Ledger</button>
        <button style={{color:'#7B61FF', fontSize:17, background:'none', border:'none'}}>+ Add</button>
      </div>
      <div style={{padding:'4px 18px 14px'}}>
        <div style={{fontSize:34, fontWeight:700, color:'white', letterSpacing:-0.5}}>Settings</div>
      </div>

      <div style={{flex:1, overflowY:'auto', padding:'0 16px 16px'}}>
        <div style={vl.sectionLabel}>AI PROVIDER</div>
        <div style={vl.formCard}>
          {providers.map((p, i) => (
            <div key={p.name} style={{...vl.providerRow, borderBottom: i === providers.length-1 ? 'none' : '0.5px solid rgba(235,235,245,0.1)'}}>
              <div style={vl.providerKw}>{p.kw}</div>
              <div style={{flex:1, minWidth:0}}>
                <div style={{display:'flex', alignItems:'center', gap:6}}>
                  <span style={{fontSize:14.5, fontWeight:600, color:'white'}}>{p.name}</span>
                  {p.tag && <span style={vl.defaultPill}>{p.tag}</span>}
                </div>
                <div style={{fontSize:11.5, color:'rgba(235,235,245,0.5)', marginTop:2, fontFamily:VL_MONO}}>{p.model}</div>
              </div>
              <span style={{...vl.statusDot, background: p.online ? '#30D158' : 'rgba(235,235,245,0.25)'}}/>
              <svg width="7" height="11" viewBox="0 0 8 14"><path d="M1 1l6 6-6 6" stroke="rgba(235,235,245,0.3)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
          ))}
        </div>
        <div style={{fontSize:11, color:'rgba(235,235,245,0.4)', padding:'6px 14px', lineHeight:1.5}}>
          You bring your own API key. Keys are stored in iOS Keychain and never leave the device.
        </div>

        <div style={vl.sectionLabel}>TAXONOMY</div>
        <div style={vl.formCard}>
          <NavRowVL label="Categories" right="14"/>
          <NavRowVL label="Tags" right="38"/>
          <NavRowVL label="Payment methods" right="9" last/>
        </div>

        <div style={vl.sectionLabel}>SYNC & PERMISSIONS</div>
        <div style={vl.formCard}>
          <div style={vl.formRow}>
            <div style={{display:'flex', alignItems:'center', gap:10}}>
              <div style={{width:26, height:26, borderRadius:7, background:'rgba(0,122,255,0.16)', display:'flex', alignItems:'center', justifyContent:'center'}}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#0A84FF" strokeWidth="1.8"><path d="M7 16a5 5 0 1 1 1-9.9A5 5 0 0 1 18 8a4 4 0 0 1 0 8H7Z"/></svg>
              </div>
              <span style={{fontSize:14, color:'white'}}>iCloud sync</span>
            </div>
            <span style={{color:'#30D158', fontSize:13, fontWeight:500}}>● Synced 2m ago</span>
          </div>
          <div style={{...vl.formRow, borderBottom:'none'}}>
            <div style={{display:'flex', alignItems:'center', gap:10}}>
              <div style={{width:26, height:26, borderRadius:7, background:'rgba(255,69,58,0.16)', display:'flex', alignItems:'center', justifyContent:'center'}}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#FF453A" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/></svg>
              </div>
              <span style={{fontSize:14, color:'white'}}>Mic & Speech</span>
            </div>
            <span style={{color:'rgba(235,235,245,0.5)', fontSize:13}}>Allowed</span>
          </div>
        </div>
      </div>
      <IOSHomeBar/>
    </div>
  );
}

function NavRowVL({ label, right, last }){
  return (
    <div style={{...vl.formRow, borderBottom: last ? 'none' : '0.5px solid rgba(235,235,245,0.1)'}}>
      <div style={{flex:1, fontSize:14, color:'white'}}>{label}</div>
      <div style={{color:'rgba(235,235,245,0.5)', fontSize:14, marginRight:6}}>{right}</div>
      <svg width="7" height="11" viewBox="0 0 8 14"><path d="M1 1l6 6-6 6" stroke="rgba(235,235,245,0.3)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
    </div>
  );
}

function IOSHomeBar(){
  return <div style={{position:'absolute', bottom:8, left:'50%', transform:'translateX(-50%)', width:134, height:5, borderRadius:99, background:'rgba(255,255,255,0.7)'}}/>;
}

// === Styles ===
const vl = {
  screen: { width:'100%', height:'100%', background:'#000', color:'white', display:'flex', flexDirection:'column', position:'relative', fontFamily: VL_SF, WebkitFontSmoothing:'antialiased', overflow:'hidden' },

  nav: { display:'flex', justifyContent:'space-between', alignItems:'center', padding:'4px 14px 8px' },
  navIconBtn: { width:34, height:34, borderRadius:'50%', background:'rgba(118,118,128,0.18)', display:'flex', alignItems:'center', justifyContent:'center', border:'none' },

  todayChip: {
    margin:'0 16px 10px', padding:'12px 16px',
    background:'linear-gradient(135deg, rgba(123,97,255,0.18), rgba(123,97,255,0.06))',
    borderRadius:14, display:'flex', justifyContent:'space-between', alignItems:'center',
    boxShadow:'inset 0 0 0 1px rgba(123,97,255,0.25)',
  },
  statsBtn: {
    display:'flex', alignItems:'center', gap:5, padding:'7px 11px',
    background:'rgba(123,97,255,0.18)', borderRadius:10, color:'#B5A4FF',
    fontSize:12.5, fontWeight:500, border:'none', fontFamily:VL_SF,
  },

  stream: { flex:1, overflowY:'auto', padding:'4px 14px 8px', display:'flex', flexDirection:'column' },
  dayDiv: { display:'flex', alignItems:'center', gap:10, color:'rgba(235,235,245,0.4)', fontSize:10.5, fontWeight:500, letterSpacing:0.4, textTransform:'uppercase', margin:'4px 0 8px' },
  dayLine: { flex:1, height:0.5, background:'rgba(235,235,245,0.1)' },

  userBubble: {
    background:'linear-gradient(180deg, #8B72FF, #7B61FF)', color:'white',
    padding:'9px 14px', borderRadius:18, fontSize:14, lineHeight:1.4,
  },
  recDot: { width:8, height:8, borderRadius:'50%', background:'#FF453A' },

  groupCard: {
    background:'#15151C', borderRadius:16, marginBottom:12, overflow:'hidden',
    boxShadow:'inset 0 0 0 1px rgba(235,235,245,0.06)',
  },
  groupHead: {
    display:'flex', justifyContent:'space-between', alignItems:'center',
    padding:'10px 14px', borderBottom:'0.5px solid rgba(235,235,245,0.08)',
  },
  aiBadge: {
    width:18, height:18, borderRadius:6, background:'linear-gradient(135deg, #8B72FF, #5C3FE0)',
    display:'flex', alignItems:'center', justifyContent:'center',
  },
  txnList: { display:'flex', flexDirection:'column' },
  txnRow: {
    display:'flex', gap:11, padding:'11px 14px', alignItems:'flex-start',
    borderBottom:'0.5px solid rgba(235,235,245,0.06)',
  },
  metaPill: {
    fontSize:10.5, padding:'2px 7px', borderRadius:99,
    background:'rgba(235,235,245,0.08)', color:'rgba(235,235,245,0.85)', fontWeight:500,
  },
  metaPillMute: {
    fontSize:10.5, padding:'2px 7px', borderRadius:99,
    background:'rgba(235,235,245,0.05)', color:'rgba(235,235,245,0.55)',
  },
  tagPill: {
    fontSize:10.5, padding:'2px 7px', borderRadius:99,
    background:'rgba(123,97,255,0.16)', color:'#B5A4FF', fontWeight:500,
  },
  failedRow: {
    display:'flex', gap:9, padding:'10px 14px', alignItems:'center',
    background:'rgba(242,201,76,0.06)', borderTop:'0.5px solid rgba(242,201,76,0.18)',
  },
  miniBtn: {
    fontSize:11.5, padding:'5px 10px', borderRadius:8, background:'rgba(242,201,76,0.18)',
    color:'#F2C94C', fontWeight:500, border:'none', fontFamily:VL_SF,
  },

  inputBar: {
    display:'flex', alignItems:'center', gap:8, padding:'8px 12px 10px',
    borderTop:'0.5px solid rgba(235,235,245,0.08)', background:'rgba(0,0,0,0.6)', backdropFilter:'blur(20px)',
  },
  inputIcon: { width:34, height:34, borderRadius:'50%', background:'rgba(118,118,128,0.18)', display:'flex', alignItems:'center', justifyContent:'center', border:'none' },
  inputField: { flex:1, padding:'9px 14px', background:'#1C1C1E', borderRadius:18, fontSize:14, border:'1px solid rgba(235,235,245,0.08)' },
  recordBtn: {
    width:38, height:38, borderRadius:'50%', background:'#7B61FF',
    display:'flex', alignItems:'center', justifyContent:'center', border:'none',
    boxShadow:'0 4px 14px rgba(123,97,255,0.45)',
  },

  // Edit
  amountHero: {
    margin:'8px 16px 16px', padding:'18px 16px 16px',
    background:'#15151C', borderRadius:16,
    boxShadow:'inset 0 0 0 1px rgba(235,235,245,0.06)',
    display:'flex', flexDirection:'column', alignItems:'center',
  },
  typePill: { padding:'5px 11px', borderRadius:99, fontSize:12, background:'rgba(255,69,58,0.16)', color:'#FF6B6B', border:'1px solid rgba(255,69,58,0.3)', fontWeight:500, fontFamily:VL_SF },
  typePillInactive: { padding:'5px 11px', borderRadius:99, fontSize:12, background:'transparent', color:'rgba(235,235,245,0.5)', border:'1px solid rgba(235,235,245,0.15)', fontFamily:VL_SF },

  formCard: { background:'#1C1C1E', borderRadius:14, marginBottom:6, overflow:'hidden' },
  formRow: { display:'flex', alignItems:'center', padding:'12px 14px', borderBottom:'0.5px solid rgba(235,235,245,0.1)', gap:8 },
  sectionLabel: { fontSize:11, color:'rgba(235,235,245,0.5)', padding:'14px 14px 6px', fontWeight:500, letterSpacing:0.4 },

  // Stats
  statHero: { background:'#15151C', borderRadius:16, padding:16, marginBottom:6, boxShadow:'inset 0 0 0 1px rgba(235,235,245,0.06)' },
  segment: { display:'flex', background:'rgba(118,118,128,0.18)', borderRadius:9, padding:2 },
  segItem: { flex:1, padding:'6px 0', borderRadius:7, fontSize:13, fontWeight:500, color:'rgba(235,235,245,0.6)', background:'none', border:'none', fontFamily:VL_SF },
  segItemActive: { background:'#1C1C1E', color:'white', boxShadow:'0 3px 8px rgba(0,0,0,0.3)' },

  // Settings
  providerRow: { display:'flex', alignItems:'center', gap:12, padding:'12px 14px' },
  providerKw: {
    width:34, height:34, borderRadius:9,
    background:'linear-gradient(135deg, rgba(123,97,255,0.3), rgba(123,97,255,0.12))',
    display:'flex', alignItems:'center', justifyContent:'center',
    fontFamily:VL_MONO, fontSize:11, fontWeight:600, color:'#B5A4FF',
    boxShadow:'inset 0 0 0 1px rgba(123,97,255,0.25)',
  },
  defaultPill: { fontSize:9.5, padding:'1px 6px', borderRadius:99, background:'rgba(123,97,255,0.2)', color:'#B5A4FF', fontWeight:600, textTransform:'uppercase', letterSpacing:0.4 },
  statusDot: { width:7, height:7, borderRadius:'50%' },
};

window.VLStream = VLStream;
window.VLEdit = VLEdit;
window.VLStats = VLStats;
window.VLSettings = VLSettings;
window.IOSHomeBar = IOSHomeBar;
