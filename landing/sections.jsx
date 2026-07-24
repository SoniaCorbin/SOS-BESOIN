// All section components for SOS-BESOIN homepage
const { useState, useEffect, useRef } = React;

/* ===================== NAV ===================== */
function Nav({ t, lang, setLang }) {
  return (
    <nav className="nav" data-screen-label="Nav">
      <div className="shell nav-inner">
        <a className="brand" href="#">
          <div className="brand-mark">
            <Icon.Alert size={20} />
          </div>
          <span className="brand-name">SOS<b>·BESOIN</b></span>
        </a>
        <div className="nav-links">
          <a href="#how">{t.how_it_works}</a>
          <a href="#categories">{t.categories}</a>
          <a href="#live">{t.live}</a>
          <a href="#pros">{t.providers}</a>
          <a href="#faq">{t.faq}</a>
        </div>
        <div className="nav-cta">
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginRight: 8 }}>
            <button onClick={() => setLang('fr')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: 13, fontWeight: 700, color: lang === 'fr' ? 'var(--amber)' : 'var(--text-mute)', padding: '4px 2px' }}>FR</button>
            <span style={{ color: 'var(--text-mute)', fontSize: 13 }}>|</span>
            <button onClick={() => setLang('en')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit', fontSize: 13, fontWeight: 700, color: lang === 'en' ? 'var(--amber)' : 'var(--text-mute)', padding: '4px 2px' }}>EN</button>
          </div>
          <a href="https://app.sosbesoin.ca/login" className="btn btn-ghost btn-sm">{t.login}</a>
          <a href="https://app.sosbesoin.ca/requests/new" className="btn btn-primary btn-sm">
            <Icon.Alert size={14} />
            {t.sos_btn}
          </a>
        </div>
      </div>
    </nav>
  );
}

/* ===================== HERO ===================== */
const SAMPLE_FEED = [
  { cat: "TECH", title: "Récupérer données disque dur SSD endommagé", loc: "Montréal · 2 km", price: "180$" },
  { cat: "MUSIQUE", title: "DJ pour mariage samedi soir, 18h-1h", loc: "Laval · 12 km", price: "650$" },
  { cat: "TRANSPORT", title: "Déménagement 2½ urgent ce dimanche", loc: "Plateau · 3 km", price: "320$" },
  { cat: "RÉPARATION", title: "Lave-vaisselle Bosch qui fuit, urgent", loc: "Verdun · 6 km", price: "140$" },
  { cat: "COURS", title: "Aide examen calcul intégral demain matin", loc: "En ligne", price: "60$/h" },
  { cat: "TECH", title: "Mise en route serveur Plex + NAS Synology", loc: "Outremont · 4 km", price: "220$" },
];

function HeroFeed() {
  const [feed, setFeed] = useState(SAMPLE_FEED);
  const [stamp, setStamp] = useState("");
  const idxRef = useRef(0);

  useEffect(() => {
    const tick = () => {
      const now = new Date();
      const hh = String(now.getHours()).padStart(2, '0');
      const mm = String(now.getMinutes()).padStart(2, '0');
      const ss = String(now.getSeconds()).padStart(2, '0');
      setStamp(`${hh}:${mm}:${ss} EDT`);
    };
    tick();
    const stampInt = setInterval(tick, 1000);

    const rotateInt = setInterval(() => {
      idxRef.current = (idxRef.current + 1) % SAMPLE_FEED.length;
      const next = SAMPLE_FEED[idxRef.current];
      setFeed(prev => [{ ...next, fresh: true, _k: Date.now() }, ...prev.slice(0, 4)]);
    }, 4200);

    return () => { clearInterval(stampInt); clearInterval(rotateInt); };
  }, []);

  return (
    <div className="dispatch">
      <div className="dispatch-head">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div className="lights">
            <span className="light on"></span>
            <span className="light on"></span>
            <span className="light"></span>
          </div>
          <span className="label">Dispatch · Live</span>
        </div>
        <span className="stamp">{stamp}</span>
      </div>
      <div className="dispatch-body">
        {feed.slice(0, 5).map((r, i) => (
          <div className={"feed-row" + (i === 0 && r.fresh ? " fresh" : "")} key={r._k || i}>
            <div className="feed-cat">{r.cat}</div>
            <div>
              <div className="feed-title">{r.title}</div>
              <div className="feed-meta">{r.loc}<span className="sep">·</span>il y a {i === 0 ? "1 min" : `${i * 4 + 3} min`}</div>
            </div>
            <div className="feed-price">{r.price}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function Hero({ t, lang, accent }) {
  return (
    <section className="hero" data-screen-label="01 Hero">
      <div className="shell hero-grid">
        <div>
          <span className="eyebrow">
            <span className="dot"></span>
            ALERTE · 1 247 PROS EN LIGNE MAINTENANT
          </span>
          <h1 className="hero-title">
            {t.title} <span className="crossout">{t.title_cross ?? "disponible"}</span><br/>
            <span className="accent">{t.title_accent}</span>,<br/>
            {t.title_end}
          </h1>
          <p className="hero-sub">
            {t.subtitle}
          </p>
          <div className="hero-actions">
            <a className="btn btn-primary btn-lg" href="#">
              <Icon.Alert size={18} />
              {t.cta_primary}
              <Icon.Arrow size={16} />
            </a>
            <a className="btn btn-ghost btn-lg" href="#pros">
              <Icon.Users size={16} />
              {t.cta_secondary}
            </a>
          </div>
          <div className="hero-trust">
            <span className="pip"><Icon.Shield size={14} />{t.trust_1}</span>
            <span className="pip"><Icon.Check size={14} />{t.trust_2}</span>
            <span className="pip"><Icon.Clock size={14} />{t.trust_3}</span>
          </div>
        </div>
        <HeroFeed />
      </div>
    </section>
  );
}

/* ===================== STATS ===================== */
function Stats({ t }) {
  return (
    <section className="shell" data-screen-label="02 Stats">
      <div className="stats-strip">
        <div className="stat-cell">
          <div className="num amber">2 047</div>
          <div className="lbl">{t.completed}</div>
          <Icon.Trend size={20} className="arrow" />
        </div>
        <div className="stat-cell">
          <div className="num cyan">28 min</div>
          <div className="lbl">{t.response}</div>
          <Icon.Clock size={20} className="arrow" />
        </div>
        <div className="stat-cell">
          <div className="num amber">512</div>
          <div className="lbl">{t.providers}</div>
          <Icon.Shield size={20} className="arrow" />
        </div>
        <div className="stat-cell">
          <div className="num cyan">4.84</div>
          <div className="lbl">{t.rating}</div>
          <Icon.Star size={20} className="arrow" />
        </div>
      </div>
    </section>
  );
}

/* ===================== CATEGORIES ===================== */
const CATS = (t) => [
  { name: t.cat_tech, icon: "Cpu", count: "37", accent: "cyan" },
  { name: t.cat_music, icon: "Music", count: "12", accent: "amber" },
  { name: t.cat_repair, icon: "Wrench", count: "21", accent: "cyan" },
  { name: t.cat_transport, icon: "Truck", count: "18", accent: "amber" },
  { name: t.cat_courses, icon: "Book", count: "9", accent: "cyan" },
  { name: t.cat_design, icon: "Pen", count: "14", accent: "amber" },
  { name: t.cat_translate, icon: "Globe", count: "6", accent: "cyan" },
  { name: t.cat_legal, icon: "Gavel", count: "4", accent: "amber" },
];

function Categories({ t }) {
  return (
    <section className="section" id="categories" data-screen-label="03 Categories">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">{t.tag}</span>
          <h2 className="section-title">{t.title}<br/>{t.title_accent}</h2>
          <p className="section-sub">{t.subtitle}</p>
        </div>
        <div className="cats-grid">
          {CATS(t).map(c => {
            const I = Icon[c.icon];
            return (
              <div key={c.name} className={"cat-card " + c.accent}>
                <div className="icon-wrap"><I size={22} /></div>
                <div>
                  <div className="cat-name">{c.name}</div>
                  <div className="cat-meta"><span className="live-dot"></span>{c.count}</div>
                </div>
                <Icon.ArrowUR size={16} className="arrow" />
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

/* ===================== HOW IT WORKS ===================== */
const STEPS_CLIENT = (t) => [
  { icon: "Send", title: t.client_step1_title, d: t.client_step1_desc },
  { icon: "Eye", title: t.client_step2_title, d: t.client_step2_desc },
  { icon: "Check", title: t.client_step3_title, d: t.client_step3_desc },
  { icon: "Star", title: t.client_step4_title, d: t.client_step4_desc },
];
const STEPS_PRO = (t) => [
  { icon: "Search", title: t.pro_step1_title, d: t.pro_step1_desc },
  { icon: "Tag", title: t.pro_step2_title, d: t.pro_step2_desc },
  { icon: "Bolt", title: t.pro_step3_title, d: t.pro_step3_desc },
  { icon: "Heart", title: t.pro_step4_title, d: t.pro_step4_desc },
];

function HowItWorks({ t }) {
  const [tab, setTab] = useState("client");
  const steps = tab === "client" ? STEPS_CLIENT(t) : STEPS_PRO(t);
  return (
    <section className="section" id="how" data-screen-label="04 How it works" style={{ paddingTop: 60 }}>
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">{t.tag}</span>
          <h2 className="section-title">{t.title}<br/><span style={{ color: tab === 'client' ? 'var(--amber)' : 'var(--cyan-2)', transition: 'color .2s' }}>{t.title_accent}</span></h2>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 28 }}>
            <div className="how-tabs">
              <button className={"how-tab client" + (tab === 'client' ? " active" : "")} onClick={() => setTab('client')}>
                <Icon.Alert size={14} /> {t.tab_client}
              </button>
              <button className={"how-tab pro" + (tab === 'pro' ? " active" : "")} onClick={() => setTab('pro')}>
                <Icon.Users size={14} /> {t.tab_pro}
              </button>
            </div>
          </div>
        </div>

        <div className="how-grid">
          {steps.map((s, i) => {
            const I = Icon[s.icon];
            return (
              <div key={i} className={"step-card" + (tab === 'pro' ? ' pro' : '')}>
                <div className="step-num">{i + 1}</div>
                <div className="step-icon"><I size={18} /></div>
                <div className="step-title">{s.title}</div>
                <div className="step-desc">{s.d}</div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

/* ===================== LIVE BOARD ===================== */
const LIVE_REQUESTS = [
  { time: "il y a 1 min", title: "Récupérer données disque dur endommagé", loc: "Montréal · Plateau", tag: "tech", cat: "Tech", price: 180, urg: "Aujourd'hui" },
  { time: "il y a 4 min", title: "Backline batterie + ampli pour show ce soir", loc: "Mile End · 2 km", tag: "musique", cat: "Musique", price: 420, urg: "20h ce soir" },
  { time: "il y a 7 min", title: "Camion + 2 personnes pour déménagement", loc: "Verdun → Rosemont", tag: "transport", cat: "Transport", price: 320, urg: "Demain 9h" },
  { time: "il y a 12 min", title: "Réparation lave-vaisselle Bosch qui fuit", loc: "Outremont · 1 km", tag: "réparation", cat: "Réparation", price: 140, urg: "Sous 24h" },
  { time: "il y a 18 min", title: "Tuteur prêt examen calcul intégral", loc: "En ligne", tag: "cours", cat: "Cours", price: 60, urg: "Demain matin" },
  { time: "il y a 22 min", title: "Configuration serveur Plex + NAS Synology", loc: "Westmount · 4 km", tag: "tech", cat: "Tech", price: 220, urg: "Cette semaine" },
  { time: "il y a 27 min", title: "DJ disponible mariage samedi soir 18h-1h", loc: "Laval · 12 km", tag: "musique", cat: "Musique", price: 650, urg: "Samedi" },
  { time: "il y a 31 min", title: "Photographe événement corporatif vendredi", loc: "Centre-ville · 1 km", tag: "musique", cat: "Création", price: 480, urg: "Vendredi" },
];

const LIVE_FILTERS = (t) => [
  { k: "all", label: t.filter_all, n: 121 },
  { k: "tech", label: t.filter_tech, n: 37 },
  { k: "musique", label: t.filter_music, n: 12 },
  { k: "transport", label: t.filter_transport, n: 18 },
  { k: "réparation", label: t.filter_repair, n: 21 },
  { k: "cours", label: t.filter_courses, n: 9 },
];

function LiveBoard({ t }) {
  const [filter, setFilter] = useState("all");
  const rows = filter === "all" ? LIVE_REQUESTS : LIVE_REQUESTS.filter(r => r.tag === filter);
  return (
    <section className="section" id="live" data-screen-label="05 Live board">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">{t.tag}</span>
          <h2 className="section-title">{t.title}<br/>{t.title_accent}</h2>
          <p className="section-sub">{t.subtitle}</p>
        </div>
        <div className="live-board">
          <aside className="lb-sidebar">
            <div className="lbl">{t.filters}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {LIVE_FILTERS(t).map(f => (
                <button key={f.k} className={"lb-filter" + (filter === f.k ? " active" : "")} onClick={() => setFilter(f.k)}>
                  <span>{f.label}</span>
                  <span className="count">{f.n}</span>
                </button>
              ))}
            </div>
            <div style={{ marginTop: 28, padding: 16, borderRadius: 12, border: '1px dashed var(--line-2)', fontSize: 13, color: 'var(--text-dim)' }}>
              <Icon.Bolt size={16} style={{ color: 'var(--amber)', marginBottom: 8 }} />
              <div style={{ fontWeight: 600, color: 'var(--text)' }}>{t.pro_mode}</div>
              <div style={{ marginTop: 4 }}>{t.pro_mode_desc}</div>
              <a href="#pros" style={{ color: 'var(--cyan-2)', fontSize: 13, fontWeight: 500, marginTop: 8, display: 'inline-block' }}>{t.become_provider}</a>
            </div>
          </aside>
          <div className="lb-feed">
            <div className="lb-feed-head">
              <div className="lb-status"><span className="pulse"></span>{t.live_status}</div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-mute)' }}>{rows.length} {t.results}</span>
            </div>
            <div>
              {rows.map((r, i) => (
                <div key={i} className="lb-row">
                  <span className="time">{r.time}</span>
                  <div>
                    <div className="title">{r.title}</div>
                    <div className="meta">{r.loc} · {r.urg}</div>
                  </div>
                  <span className={"tag " + r.tag}>{r.cat}</span>
                  <span className="price">{r.price}$<small>budget</small></span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
/* ===================== WAITLIST ===================== */
function WaitlistSection({ t }) {
  const [email, setEmail]   = React.useState('');
  const [name, setName]     = React.useState('');
  const [role, setRole]     = React.useState('client');
  const [status, setStatus] = React.useState('idle');
  const [count, setCount]   = React.useState(null);

  React.useEffect(() => {
    fetch('https://dxnsfsqbgywssjloievn.supabase.co/rest/v1/waitlist?select=id', {
      headers: {
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4bnNmc3FiZ3l3c3NqbG9pZXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODcwNDYsImV4cCI6MjA5NDg2MzA0Nn0.A71jh1_8F9GhwwQeaT6PEr_ojCqNftfizxy1pBIpStU',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4bnNmc3FiZ3l3c3NqbG9pZXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODcwNDYsImV4cCI6MjA5NDg2MzA0Nn0.A71jh1_8F9GhwwQeaT6PEr_ojCqNftfizxy1pBIpStU',
        'Prefer': 'count=exact',
      },
    })
    .then(res => {
      const range = res.headers.get('content-range');
      if (range) setCount(parseInt(range.split('/')[1]));
    })
    .catch(() => {});
  }, [status]);

  async function handleSubmit(e) {
    e.preventDefault();
    if (!email) return;
    setStatus('loading');
    try {
      const res = await fetch('https://dxnsfsqbgywssjloievn.supabase.co/rest/v1/waitlist', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4bnNmc3FiZ3l3c3NqbG9pZXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODcwNDYsImV4cCI6MjA5NDg2MzA0Nn0.A71jh1_8F9GhwwQeaT6PEr_ojCqNftfizxy1pBIpStU',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4bnNmc3FiZ3l3c3NqbG9pZXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyODcwNDYsImV4cCI6MjA5NDg2MzA0Nn0.A71jh1_8F9GhwwQeaT6PEr_ojCqNftfizxy1pBIpStU',
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify({ email, name, role }),
      });
      if (res.ok) {
        setStatus('success');
        setEmail('');
        setName('');
      } else if (res.status === 409) {
        setStatus('duplicate');
      } else {
        setStatus('error');
      }
    } catch {
      setStatus('error');
    }
  }

  return (
    <section className="section" id="waitlist" style={{ paddingBottom: 60 }}>
      <div className="shell">
        <div style={{
          maxWidth: 560,
          margin: '0 auto',
          background: 'var(--surface)',
          border: '1px solid var(--line-2)',
          borderRadius: 20,
          padding: '48px 40px',
          textAlign: 'center',
        }}>
          <span className="section-tag" style={{ marginBottom: 16 }}>{t.tag}</span>
          <h2 style={{ fontSize: 32, marginBottom: 12 }}>
            {t.title}<span style={{ color: 'var(--amber)' }}>{t.title_accent}</span>
          </h2>
          <p style={{ color: 'var(--text-dim)', marginBottom: 32, lineHeight: 1.6 }}>
            {t.subtitle}
          </p>

          {count !== null && count > 0 && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              marginBottom: 24,
              padding: '10px 16px',
              background: 'rgba(245,158,11,0.08)',
              border: '1px solid rgba(245,158,11,0.2)',
              borderRadius: 10,
            }}>
              <span style={{ fontSize: 18 }}>🔥</span>
              <span style={{
                color: 'var(--amber)',
                fontFamily: 'var(--font-mono)',
                fontSize: 14,
                fontWeight: 600,
              }}>
                {count} {t.count_label}
              </span>
            </div>
          )}


          {status === 'success' ? (
            <div style={{
              background: 'rgba(34,197,94,0.1)',
              border: '1px solid rgba(34,197,94,0.3)',
              borderRadius: 12,
              padding: '20px 24px',
              color: '#22c55e',
              fontFamily: 'var(--font-mono)',
              fontSize: 14,
            }}>
              {t.success} On vous contacte dès le lancement.
            </div>
          ) : status === 'duplicate' ? (
            <div style={{
              background: 'rgba(245,158,11,0.1)',
              border: '1px solid rgba(245,158,11,0.3)',
              borderRadius: 12,
              padding: '20px 24px',
              color: 'var(--amber)',
              fontSize: 14,
            }}>
              ⚠️ Ce courriel est déjà inscrit !
            </div>
          ) : (
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <input
                type="text"
                placeholder={t.name_placeholder}
                value={name}
                onChange={e => setName(e.target.value)}
                style={{
                  background: 'var(--surface-2)',
                  border: '1px solid var(--line-2)',
                  borderRadius: 10,
                  padding: '12px 16px',
                  color: 'var(--text)',
                  fontSize: 15,
                  outline: 'none',
                }}
              />
              <input
                type="email"
                placeholder={t.email_placeholder}
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
                style={{
                  background: 'var(--surface-2)',
                  border: '1px solid var(--line-2)',
                  borderRadius: 10,
                  padding: '12px 16px',
                  color: 'var(--text)',
                  fontSize: 15,
                  outline: 'none',
                }}
              />
              <div style={{ display: 'flex', gap: 8 }}>
                {['client', 'prestataire'].map(r => (
                  <button
                    key={r}
                    type="button"
                    onClick={() => setRole(r)}
                    style={{
                      flex: 1,
                      padding: '10px 16px',
                      borderRadius: 10,
                      border: `1px solid ${role === r ? 'var(--amber)' : 'var(--line-2)'}`,
                      background: role === r ? 'var(--amber-soft)' : 'var(--surface-2)',
                      color: role === r ? 'var(--amber)' : 'var(--text-dim)',
                      fontSize: 14,
                      fontWeight: 600,
                      cursor: 'pointer',
                    }}
                  >
                    {r === 'client' ? `🔍 ${t.role_client}` : `💼 ${t.role_provider}`}
                  </button>
                ))}
              </div>
              <button
                type="submit"
                disabled={status === 'loading'}
                className="btn btn-primary"
                style={{ marginTop: 8, height: 48, fontSize: 15, fontWeight: 700 }}
              >
                {status === 'loading' ? (t.loading ?? 'Inscription...') : t.submit_btn}
              </button>
              {status === 'error' && (
                <p style={{ color: 'var(--red)', fontSize: 13 }}>
                  Une erreur est survenue. Réessayez.
                </p>
              )}
            </form>
          )}
        </div>
      </div>
    </section>
  );
}

window.WaitlistSection = WaitlistSection;
window.Nav = Nav;
window.Hero = Hero;
window.Stats = Stats;
window.Categories = Categories;
window.HowItWorks = HowItWorks;
window.LiveBoard = LiveBoard;
window.WaitlistSection = WaitlistSection;
