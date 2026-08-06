// Main App — composes all sections
const { useState: _useState } = React;
const { Nav, Hero, Stats, Categories, HowItWorks, LiveBoard, WaitlistSection } = window;

/* ===================== PROVIDERS ===================== */
function ProvidersSection({ t }) {
  return (
    <section className="section" id="pros" data-screen-label="06 Providers">
      <div className="shell prov-grid">
        <div className="prov-copy">
          <span className="section-tag" style={{ marginBottom: 16 }}>{t.tag}</span>
          <h2>{t.title}<br/><span className="accent" style={{ color: '#84cc16' }}>{t.title_accent}</span></h2>
          <p>{t.subtitle}</p>
          <ul className="prov-bullets">
            <li><Icon.Check size={18} /><span><b>{t.bullet1_bold}</b>{t.bullet1}</span></li>
            <li><Icon.Check size={18} /><span><b>{t.bullet2_bold}</b>{t.bullet2}</span></li>
            <li><Icon.Check size={18} /><span><b>{t.bullet3_bold}</b>{t.bullet3}</span></li>
            <li><Icon.Check size={18} /><span><b>{t.bullet4_bold}</b>{t.bullet4}</span></li>
          </ul>
          <div style={{ marginTop: 36, display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            <a className="btn btn-outline btn-lg" href="#">
              <Icon.Users size={16} />
              {t.apply_btn}
              <Icon.Arrow size={14} />
            </a>
            <a className="btn btn-ghost btn-lg" href="#">{t.pricing_btn}</a>
          </div>
        </div>

        <div className="prov-card">
          <div className="prov-card-head">
            <div className="prov-avatar">MD</div>
            <div>
              <h4>Maxime D. <span style={{ color: 'var(--cyan-2)', fontSize: 13, marginLeft: 8 }}>● {t.verified}</span></h4>
              <div className="role">Tech · Réseau · Mac/PC</div>
            </div>
            <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 4, color: 'var(--amber)', fontFamily: 'var(--font-mono)', fontSize: 13 }}>
              <Icon.Star size={14} />4.9
            </div>
          </div>

          <div className="prov-stats">
            <div className="prov-stat"><div className="v">147</div><div className="l">Missions</div></div>
            <div className="prov-stat"><div className="v">12 min</div><div className="l">Réponse moy.</div></div>
            <div className="prov-stat"><div className="v">8 420$</div><div className="l">Ce mois-ci</div></div>
          </div>

          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-mute)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
            Missions récentes
          </div>

          <div className="prov-job">
            <div>
              <div className="tj">Récupérer données SSD endommagé</div>
              <div className="tm">il y a 2h · Plateau</div>
            </div>
            <span className="badge">Validée · 180$</span>
          </div>
          <div className="prov-job">
            <div>
              <div className="tj">Configuration NAS Synology + Plex</div>
              <div className="tm">hier · Outremont</div>
            </div>
            <span className="badge">Validée · 220$</span>
          </div>
          <div className="prov-job">
            <div>
              <div className="tj">Migration boîte mail entreprise</div>
              <div className="tm">en cours · Mile End</div>
            </div>
            <span className="badge pending">En cours · 340$</span>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ===================== TESTIMONIALS ===================== */
const TESTIMONIALS = (t) => [
  {
    quote: t.q1,
    name: "Élodie L.", role: "Cliente · Mariage", initial: "EL", color: "var(--amber)",
  },
  {
    quote: t.q2,
    name: "Karim B.", role: "Prestataire · Tech", initial: "KB", color: "var(--cyan)",
  },
  {
    quote: t.q3,
    name: "Sophie M.", role: "Cliente · Réparation", initial: "SM", color: "var(--violet)",
  },
];

function Testimonials({ t }) {
  return (
    <section className="section" data-screen-label="07 Testimonials">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">{t.tag}</span>
          <h2 className="section-title">{t.title}<span style={{ color: 'var(--amber)' }}>{t.title_accent}</span>{t.title_end}</h2>
        </div>
        <div className="testi-grid">
          {TESTIMONIALS(t).map((item, i) => (
            <div key={i} className="testi-card">
              <div className="testi-stars">
                {[0,1,2,3,4].map(s => <Icon.Star key={s} size={14} />)}
              </div>
              <div className="testi-quote">« {item.quote} »</div>
              <div className="testi-meta">
                <div className="testi-avatar" style={{ background: item.color }}>{item.initial}</div>
                <div>
                  <div className="testi-name">{item.name}</div>
                  <div className="testi-role">{item.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ===================== FAQ ===================== */
const FAQ = (t) => [
  { q: t.q1, a: t.a1 },
  { q: t.q2, a: t.a2 },
  { q: t.q3, a: t.a3 },
  { q: t.q4, a: t.a4 },
  { q: t.q5, a: t.a5 },
  { q: t.q6, a: t.a6 },
];

function FAQSection({ t }) {
  const [open, setOpen] = _useState(0);
  return (
    <section className="section" id="faq" data-screen-label="08 FAQ">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">{t.tag}</span>
          <h2 className="section-title">{t.title}</h2>
        </div>
        <div className="faq-wrap">
          {FAQ(t).map((item, i) => (
            <div key={i} className={"faq-item" + (open === i ? " open" : "")}>
              <button className="faq-q" onClick={() => setOpen(open === i ? -1 : i)}>
                <span>{item.q}</span>
                <span className="faq-toggle"><Icon.Plus size={14} /></span>
              </button>
              <div className="faq-a">{item.a}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ===================== FINAL CTA ===================== */
function FinalCTA({ t }) {
  return (
    <section className="section" data-screen-label="09 Final CTA" style={{ paddingBottom: 60 }}>
      <div className="shell">
        <div className="cta-block">
          <div className="cta-ticker">
            <div className="row"><span>{t.pros_online}</span><span className="v">1 247</span></div>
            <div className="row"><span>{t.open_requests}</span><span className="v">121</span></div>
            <div className="row"><span>{t.median_delay}</span><span className="v">28 min</span></div>
          </div>
          <div className="cta-inner">
            <div className="eyebrow" style={{ marginBottom: 24 }}>
              <span className="dot"></span>
              {t.tag}
            </div>
            <h2>{t.title}<br/><span className="accent">{t.title_accent}</span></h2>
            <p>{t.subtitle1} {t.subtitle2}</p>
            <div className="cta-actions">
              <a className="btn btn-primary btn-lg" href="#">
                <Icon.Alert size={18} />
                {t.btn_primary}
                <Icon.Arrow size={16} />
              </a>
              <a className="btn btn-ghost btn-lg" href="#pros">
                {t.btn_secondary}
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ===================== FOOTER ===================== */
function Footer({ t }) {
  return (
    <footer className="footer" data-screen-label="10 Footer">
      <div className="shell">
        <div className="footer-grid">
          <div>
            <div className="brand">
              <div className="brand-mark"><Icon.Alert size={20} /></div>
              <span className="brand-name">SOS<b>·BESOIN</b></span>
            </div>
            <p>{t.tagline}</p>
            <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
              <a href="https://www.tiktok.com/@sosbesoin.ca" target="_blank" style={{ width: 36, height: 36, borderRadius: 10, border: '1px solid var(--line-2)', display: 'grid', placeItems: 'center', color: 'var(--text-dim)' }}>
                <Icon.Twitter size={16} />
              </a>
              <a href="https://www.linkedin.com/company/sosbesoinapp" target="_blank" style={{ width: 36, height: 36, borderRadius: 10, border: '1px solid var(--line-2)', display: 'grid', placeItems: 'center', color: 'var(--text-dim)' }}>
                <Icon.Linked size={16} />
              </a>
              <a href="https://www.instagram.com/sosbesoinapp" target="_blank" style={{ width: 36, height: 36, borderRadius: 10, border: '1px solid var(--line-2)', display: 'grid', placeItems: 'center', color: 'var(--text-dim)' }}>
                <Icon.Insta size={16} />
              </a>
            </div>
          </div>
          <div>
            <h5>{t.platform}</h5>
            <ul>
              <li><a href="#how">{t.how_it_works}</a></li>
              <li><a href="#categories">{t.categories}</a></li>
              <li><a href="#live">{t.live}</a></li>
              <li><a href="#pros">{t.become_provider}</a></li>
              <li><a href="https://app.sosbesoin.ca">{t.send_sos}</a></li>
            </ul>
          </div>
          <div>
            <h5>{t.support}</h5>
            <ul>
              <li><a href="mailto:{t.support_email}">{t.contact}</a></li>
              <li><a href="#faq">{t.faq}</a></li>
              <li><a href="https://app.sosbesoin.ca">{t.access_app}</a></li>
            </ul>
          </div>
          <div>
            <h5>{t.legal}</h5>
            <ul>
              <li><a href="#">{t.terms}</a></li>
              <li><a href="#">{t.privacy}</a></li>
              <li><a href="#">{t.refund}</a></li>
              <li><a href="#">{t.cookies}</a></li>
            </ul>
          </div>
        </div>
        <div className="footer-bottom">
          <span>{t.copyright}</span>
          <span>support@sosbesoin.ca · app.sosbesoin.ca</span>
        </div>
      </div>
    </footer>
  );
}

/* ===================== APP ===================== */
const DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#f59e0b",
  "showGrid": true,
  "rounded": true
}/*EDITMODE-END*/;

const ACCENT_MAP = {
  '#f59e0b': { a: '#f59e0b', a2: '#fbbf24', soft: 'rgba(245,158,11,0.12)' },
  '#06b6d4': { a: '#06b6d4', a2: '#22d3ee', soft: 'rgba(6,182,212,0.12)' },
  '#ef4444': { a: '#ef4444', a2: '#f87171', soft: 'rgba(239,68,68,0.12)' },
  '#84cc16': { a: '#84cc16', a2: '#a3e635', soft: 'rgba(132,204,22,0.12)' },
};

function App() {
  const [lang, setLang] = React.useState("fr");
  const tr = translations[lang];
  const hasTweaks = typeof useTweaks === 'function';
  const [t, setTweak] = hasTweaks ? useTweaks(DEFAULTS) : [DEFAULTS, () => {}];

  React.useEffect(() => {
    const root = document.documentElement;
    const c = ACCENT_MAP[t.accent] || ACCENT_MAP['#f59e0b'];
    root.style.setProperty('--amber', c.a);
    root.style.setProperty('--amber-2', c.a2);
    root.style.setProperty('--amber-soft', c.soft);
  }, [t.accent]);

  React.useEffect(() => {
    const grid = document.querySelector('.bg-grid');
    if (grid) grid.style.display = t.showGrid ? 'block' : 'none';
  }, [t.showGrid]);

  return (
    <>
      <div className="bg-grid"></div>
      <div className="bg-glow-a"></div>
      <div className="bg-glow-b"></div>

      <Nav t={tr.nav} lang={lang} setLang={setLang} />
      <div className="sticky-banner" style={{
        position: 'sticky', top: 64, zIndex: 90, borderRadius: 8,
        background: 'rgba(132,204,22,0.12)',
        backdropFilter: 'blur(8px)',
        borderBottom: '1px solid rgba(132,204,22,0.3)',
        padding: '10px 24px',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
        fontSize: 13, color: 'var(--text-dim)',
        margin: '8px 20px',
      }}>
        <span>{tr.banner.text}</span>
        <a href="#waitlist" style={{
          color: '#84cc16', fontWeight: 700,
          textDecoration: 'none', fontSize: 13,
        }}>{tr.banner.cta}</a>
      </div>
      <Hero t={tr.hero} lang={lang} accent={t.accent} />
      <Stats t={tr.stats} />
      <Categories t={tr.categories} />
      <HowItWorks t={tr.how} />
      <LiveBoard t={tr.liveboard} />
      <ProvidersSection t={tr.providers} />
      <Testimonials t={tr.testimonials} />
      <FAQSection t={tr.faq} />
      <FinalCTA t={tr.cta} />
      <WaitlistSection t={tr.waitlist_section} />
      <Footer t={tr.footer} />

      {typeof TweaksPanel === 'function' && (
        <TweaksPanel title="Tweaks">
          <TweakSection title="Apparence">
            <TweakColor
              label="Couleur d'accent"
              value={t.accent}
              onChange={(v) => setTweak('accent', v)}
              options={['#f59e0b', '#06b6d4', '#ef4444', '#84cc16']}
            />
            <TweakToggle
              label="Grille de fond"
              value={t.showGrid}
              onChange={(v) => setTweak('showGrid', v)}
            />
          </TweakSection>
        </TweaksPanel>
      )}
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);