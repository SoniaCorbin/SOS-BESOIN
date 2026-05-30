// All section components for SOS-BESOIN homepage
const { useState, useEffect, useRef } = React;

/* ===================== NAV ===================== */
function Nav() {
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
          <a href="#how">Comment ça marche</a>
          <a href="#categories">Catégories</a>
          <a href="#live">Demandes en direct</a>
          <a href="#pros">Pour les pros</a>
          <a href="#faq">FAQ</a>
        </div>
        <div className="nav-cta">
          <a href="#" className="btn btn-ghost btn-sm">Connexion</a>
          <a href="#" className="btn btn-primary btn-sm">
            <Icon.Alert size={14} />
            Lancer un SOS
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

function Hero({ accent }) {
  return (
    <section className="hero" data-screen-label="01 Hero">
      <div className="shell hero-grid">
        <div>
          <span className="eyebrow">
            <span className="dot"></span>
            ALERTE · 1 247 PROS EN LIGNE MAINTENANT
          </span>
          <h1 className="hero-title">
            Un pro <span className="crossout">disponible</span><br/>
            <span className="accent">en 30 minutes</span>,<br/>
            quand c'est urgent.
          </h1>
          <p className="hero-sub">
            Décrivez votre besoin. Les pros disponibles près de chez vous répondent en direct.
            Paiement séquestré jusqu'à validation — vous ne payez que si tout s'est bien passé.
          </p>
          <div className="hero-actions">
            <a className="btn btn-primary btn-lg" href="#">
              <Icon.Alert size={18} />
              Lancer un SOS
              <Icon.Arrow size={16} />
            </a>
            <a className="btn btn-ghost btn-lg" href="#pros">
              <Icon.Users size={16} />
              Devenir prestataire
            </a>
          </div>
          <div className="hero-trust">
            <span className="pip"><Icon.Shield size={14} />Paiement séquestré Stripe</span>
            <span className="pip"><Icon.Check size={14} />Pros vérifiés (KYC)</span>
            <span className="pip"><Icon.Clock size={14} />Support 7j/7</span>
          </div>
        </div>
        <HeroFeed />
      </div>
    </section>
  );
}

/* ===================== STATS ===================== */
function Stats() {
  return (
    <section className="shell" data-screen-label="02 Stats">
      <div className="stats-strip">
        <div className="stat-cell">
          <div className="num amber">2 047</div>
          <div className="lbl">Missions complétées</div>
          <Icon.Trend size={20} className="arrow" />
        </div>
        <div className="stat-cell">
          <div className="num cyan">28 min</div>
          <div className="lbl">Délai moyen de réponse</div>
          <Icon.Clock size={20} className="arrow" />
        </div>
        <div className="stat-cell">
          <div className="num amber">512</div>
          <div className="lbl">Pros vérifiés actifs</div>
          <Icon.Shield size={20} className="arrow" />
        </div>
        <div className="stat-cell">
          <div className="num cyan">4.84</div>
          <div className="lbl">Note moyenne / 5</div>
          <Icon.Star size={20} className="arrow" />
        </div>
      </div>
    </section>
  );
}

/* ===================== CATEGORIES ===================== */
const CATS = [
  { name: "Tech & IT", icon: "Cpu", count: "37 demandes ouvertes", accent: "cyan" },
  { name: "Musique & Événements", icon: "Music", count: "12 demandes ouvertes", accent: "amber" },
  { name: "Réparations", icon: "Wrench", count: "21 demandes ouvertes", accent: "cyan" },
  { name: "Transport & Livraison", icon: "Truck", count: "18 demandes ouvertes", accent: "amber" },
  { name: "Cours & Formation", icon: "Book", count: "9 demandes ouvertes", accent: "cyan" },
  { name: "Design & Création", icon: "Pen", count: "14 demandes ouvertes", accent: "amber" },
  { name: "Traduction", icon: "Globe", count: "6 demandes ouvertes", accent: "cyan" },
  { name: "Juridique & Admin", icon: "Gavel", count: "4 demandes ouvertes", accent: "amber" },
];

function Categories() {
  return (
    <section className="section" id="categories" data-screen-label="03 Categories">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">·CAT_LIST·</span>
          <h2 className="section-title">Toutes les urgences,<br/>au même endroit.</h2>
          <p className="section-sub">Du serveur planté au DJ qui annule la veille — il y a un pro pour ça.</p>
        </div>
        <div className="cats-grid">
          {CATS.map(c => {
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
const STEPS_CLIENT = [
  { icon: "Send", t: "Publiez", d: "Décrivez votre besoin, choisissez une ou plusieurs catégories, indiquez quand." },
  { icon: "Eye", t: "Recevez des offres", d: "Les pros disponibles vous envoient leur prix et leur dispo en direct." },
  { icon: "Check", t: "Acceptez & payez", d: "Sélectionnez la meilleure offre. Paiement séquestré, sécurisé." },
  { icon: "Star", t: "Validez", d: "Une fois la mission terminée, validez et notez le prestataire." },
];
const STEPS_PRO = [
  { icon: "Search", t: "Trouvez", d: "Parcourez les demandes ouvertes filtrées par catégorie et localisation." },
  { icon: "Tag", t: "Soumettez votre offre", d: "Proposez votre prix et un court message au client." },
  { icon: "Bolt", t: "Réalisez", d: "Si le client accepte, vous êtes notifié et la mission démarre." },
  { icon: "Heart", t: "Encaissez", d: "Paiement transféré automatiquement après validation. Commission 10%." },
];

function HowItWorks() {
  const [tab, setTab] = useState("client");
  const steps = tab === "client" ? STEPS_CLIENT : STEPS_PRO;
  return (
    <section className="section" id="how" data-screen-label="04 How it works" style={{ paddingTop: 60 }}>
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">·WORKFLOW·</span>
          <h2 className="section-title">Quatre étapes.<br/><span style={{ color: tab === 'client' ? 'var(--amber)' : 'var(--cyan-2)', transition: 'color .2s' }}>Pas une de plus.</span></h2>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 28 }}>
            <div className="how-tabs">
              <button className={"how-tab client" + (tab === 'client' ? " active" : "")} onClick={() => setTab('client')}>
                <Icon.Alert size={14} /> Pour les clients
              </button>
              <button className={"how-tab pro" + (tab === 'pro' ? " active" : "")} onClick={() => setTab('pro')}>
                <Icon.Users size={14} /> Pour les prestataires
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
                <div className="step-title">{s.t}</div>
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

const LIVE_FILTERS = [
  { k: "all", label: "Toutes", n: 121 },
  { k: "tech", label: "Tech & IT", n: 37 },
  { k: "musique", label: "Musique", n: 12 },
  { k: "transport", label: "Transport", n: 18 },
  { k: "réparation", label: "Réparation", n: 21 },
  { k: "cours", label: "Cours", n: 9 },
];

function LiveBoard() {
  const [filter, setFilter] = useState("all");
  const rows = filter === "all" ? LIVE_REQUESTS : LIVE_REQUESTS.filter(r => r.tag === filter);
  return (
    <section className="section" id="live" data-screen-label="05 Live board">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">·LIVE_FEED·</span>
          <h2 className="section-title">Ce qui s'est lancé<br/>dans les dernières minutes.</h2>
          <p className="section-sub">Aperçu en temps réel des demandes ouvertes. Connectez-vous pour soumettre une offre.</p>
        </div>
        <div className="live-board">
          <aside className="lb-sidebar">
            <div className="lbl">Filtres</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              {LIVE_FILTERS.map(f => (
                <button key={f.k} className={"lb-filter" + (filter === f.k ? " active" : "")} onClick={() => setFilter(f.k)}>
                  <span>{f.label}</span>
                  <span className="count">{f.n}</span>
                </button>
              ))}
            </div>
            <div style={{ marginTop: 28, padding: 16, borderRadius: 12, border: '1px dashed var(--line-2)', fontSize: 13, color: 'var(--text-dim)' }}>
              <Icon.Bolt size={16} style={{ color: 'var(--amber)', marginBottom: 8 }} />
              <div style={{ fontWeight: 600, color: 'var(--text)' }}>Mode pro</div>
              <div style={{ marginTop: 4 }}>Recevez les nouvelles demandes par notification.</div>
              <a href="#pros" style={{ color: 'var(--cyan-2)', fontSize: 13, fontWeight: 500, marginTop: 8, display: 'inline-block' }}>Devenir prestataire →</a>
            </div>
          </aside>
          <div className="lb-feed">
            <div className="lb-feed-head">
              <div className="lb-status"><span className="pulse"></span>Direct · mise à jour il y a quelques secondes</div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-mute)' }}>{rows.length} résultats</span>
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

window.Nav = Nav;
window.Hero = Hero;
window.Stats = Stats;
window.Categories = Categories;
window.HowItWorks = HowItWorks;
window.LiveBoard = LiveBoard;
