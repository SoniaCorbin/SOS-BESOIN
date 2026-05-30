// Main App — composes all sections
const { useState: _useState } = React;
const { Nav, Hero, Stats, Categories, HowItWorks, LiveBoard } = window;

/* ===================== PROVIDERS ===================== */
function ProvidersSection() {
  return (
    <section className="section" id="pros" data-screen-label="06 Providers">
      <div className="shell prov-grid">
        <div className="prov-copy">
          <span className="section-tag" style={{ marginBottom: 16 }}>·POUR_LES_PROS·</span>
          <h2>De l'urgence,<br/><span className="accent" style={{ color: '#84cc16' }}>du revenu prévisible.</span></h2>
          <p>Rejoignez le réseau de pros qui captent les meilleures missions urgentes près de chez eux. Vous fixez vos prix. Vous choisissez ce que vous prenez.</p>
          <ul className="prov-bullets">
            <li><Icon.Check size={18} /><span><b>10% de commission, tout inclus.</b> Paiement transféré 24h après validation.</span></li>
            <li><Icon.Check size={18} /><span><b>Notifications ciblées.</b> Recevez uniquement les demandes dans vos catégories.</span></li>
            <li><Icon.Check size={18} /><span><b>Argent sécurisé.</b> Le client a déjà déposé les fonds — vous êtes payé.</span></li>
            <li><Icon.Check size={18} /><span><b>Statut KYC vérifié.</b> Une fois validé, badge visible sur toutes vos offres.</span></li>
          </ul>
          <div style={{ marginTop: 36, display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            <a className="btn btn-outline btn-lg" href="#">
              <Icon.Users size={16} />
              Postuler comme pro
              <Icon.Arrow size={14} />
            </a>
            <a className="btn btn-ghost btn-lg" href="#">Voir la grille tarifaire</a>
          </div>
        </div>

        <div className="prov-card">
          <div className="prov-card-head">
            <div className="prov-avatar">MD</div>
            <div>
              <h4>Maxime D. <span style={{ color: 'var(--cyan-2)', fontSize: 13, marginLeft: 8 }}>● vérifié</span></h4>
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
const TESTIMONIALS = [
  {
    quote: "Mon DJ a annulé 4h avant le mariage. J'ai posté à 14h, accepté une offre à 14h32, le pro était là à 17h. Ça a sauvé la soirée.",
    name: "Élodie L.", role: "Cliente · Mariage", initial: "EL", color: "var(--amber)",
  },
  {
    quote: "En tant que technicien à mon compte, j'avais des trous dans mon agenda. SOS-BESOIN me remplit les créneaux libres avec des missions claires et payantes.",
    name: "Karim B.", role: "Prestataire · Tech", initial: "KB", color: "var(--cyan)",
  },
  {
    quote: "Lave-vaisselle qui inonde la cuisine un dimanche soir. Trois offres reçues en 15 min. Réparé le lendemain matin. Payé seulement après vérif.",
    name: "Sophie M.", role: "Cliente · Réparation", initial: "SM", color: "var(--violet)",
  },
];

function Testimonials() {
  return (
    <section className="section" data-screen-label="07 Testimonials">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">·SOCIAL_PROOF·</span>
          <h2 className="section-title">Quand <span style={{ color: 'var(--amber)' }}>chaque minute compte</span>,<br/>les gens reviennent.</h2>
        </div>
        <div className="testi-grid">
          {TESTIMONIALS.map((t, i) => (
            <div key={i} className="testi-card">
              <div className="testi-stars">
                {[0,1,2,3,4].map(s => <Icon.Star key={s} size={14} />)}
              </div>
              <div className="testi-quote">« {t.quote} »</div>
              <div className="testi-meta">
                <div className="testi-avatar" style={{ background: t.color }}>{t.initial}</div>
                <div>
                  <div className="testi-name">{t.name}</div>
                  <div className="testi-role">{t.role}</div>
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
const FAQ = [
  { q: "Combien de temps avant de recevoir une offre ?", a: "Le délai médian est de 28 minutes. Sur les catégories Tech, Musique et Transport, la majorité des demandes reçoivent au moins 2 offres en moins de 15 minutes en journée." },
  { q: "Comment fonctionne le paiement séquestré ?", a: "Quand vous acceptez une offre, votre carte est débitée mais l'argent reste bloqué chez Stripe. Le prestataire ne reçoit le paiement qu'après votre validation. Si rien ne va, on rembourse." },
  { q: "Que se passe-t-il si je dois annuler ma demande ?", a: "Tant qu'aucune offre n'est acceptée, vous pouvez annuler sans frais. Une fois une offre acceptée, des conditions s'appliquent selon le délai et la catégorie." },
  { q: "Les pros sont-ils vérifiés ?", a: "Tous les prestataires passent un KYC (identité + adresse) avant de pouvoir soumettre des offres. Les pros notés moins de 3,5/5 après 10 missions sont suspendus automatiquement." },
  { q: "Quelle est la commission de la plateforme ?", a: "10 % du montant de la mission, retenue automatiquement sur le paiement du prestataire. Aucun frais caché côté client : le prix affiché par le pro est le prix que vous payez." },
  { q: "Puis-je utiliser un code promo ?", a: "Oui — un code promo valide peut être appliqué à l'étape du paiement avant d'accepter l'offre." },
];

function FAQSection() {
  const [open, setOpen] = _useState(0);
  return (
    <section className="section" id="faq" data-screen-label="08 FAQ">
      <div className="shell">
        <div className="section-head">
          <span className="section-tag">·QUESTIONS·</span>
          <h2 className="section-title">Les choses qu'on<br/>nous demande le plus.</h2>
        </div>
        <div className="faq-wrap">
          {FAQ.map((item, i) => (
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
function FinalCTA() {
  return (
    <section className="section" data-screen-label="09 Final CTA" style={{ paddingBottom: 60 }}>
      <div className="shell">
        <div className="cta-block">
          <div className="cta-ticker">
            <div className="row"><span>Pros en ligne</span><span className="v">1 247</span></div>
            <div className="row"><span>Demandes ouvertes</span><span className="v">121</span></div>
            <div className="row"><span>Délai médian</span><span className="v">28 min</span></div>
          </div>
          <div className="cta-inner">
            <div className="eyebrow" style={{ marginBottom: 24 }}>
              <span className="dot"></span>
              C'EST URGENT ? ON EST DESSUS.
            </div>
            <h2>Décrivez ce qu'il vous faut.<br/><span className="accent">Un pro répond.</span></h2>
            <p>Ça prend moins de 90 secondes pour publier une demande. Vous ne payez que si vous acceptez une offre.</p>
            <div className="cta-actions">
              <a className="btn btn-primary btn-lg" href="#">
                <Icon.Alert size={18} />
                Lancer un SOS maintenant
                <Icon.Arrow size={16} />
              </a>
              <a className="btn btn-ghost btn-lg" href="#pros">
                Devenir prestataire
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ===================== FOOTER ===================== */
function Footer() {
  return (
    <footer className="footer" data-screen-label="10 Footer">
      <div className="shell">
        <div className="footer-grid">
          <div>
            <div className="brand">
              <div className="brand-mark"><Icon.Alert size={20} /></div>
              <span className="brand-name">SOS<b>·BESOIN</b></span>
            </div>
            <p>La place de marché pour vos besoins urgents. Pros vérifiés. Paiement séquestré. Aucune mauvaise surprise.</p>
            <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
              {[Icon.Twitter, Icon.Linked, Icon.Insta].map((I, i) => (
                <a key={i} href="#" style={{ width: 36, height: 36, borderRadius: 10, border: '1px solid var(--line-2)', display: 'grid', placeItems: 'center', color: 'var(--text-dim)' }}>
                  <I size={16} />
                </a>
              ))}
            </div>
          </div>
          <div>
            <h5>Plateforme</h5>
            <ul>
              <li><a href="#how">Comment ça marche</a></li>
              <li><a href="#categories">Catégories</a></li>
              <li><a href="#live">Demandes en direct</a></li>
              <li><a href="#pros">Devenir prestataire</a></li>
              <li><a href="#">Tarifs & commission</a></li>
            </ul>
          </div>
          <div>
            <h5>Support</h5>
            <ul>
              <li><a href="#">Centre d'aide</a></li>
              <li><a href="#">Contacter le support</a></li>
              <li><a href="#faq">FAQ</a></li>
              <li><a href="#">Statut système</a></li>
            </ul>
          </div>
          <div>
            <h5>Légal</h5>
            <ul>
              <li><a href="#">Conditions générales</a></li>
              <li><a href="#">Politique de confidentialité</a></li>
              <li><a href="#">Mentions légales</a></li>
              <li><a href="#">Cookies</a></li>
            </ul>
          </div>
        </div>
        <div className="footer-bottom">
          <span>© 2026 SOS-BESOIN · Tous droits réservés</span>
          <span>v3.2 · build 20260519 · status: ALL SYSTEMS OK</span>
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

      <Nav />
      <Hero accent={t.accent} />
      <Stats />
      <Categories />
      <HowItWorks />
      <LiveBoard />
      <ProvidersSection />
      <Testimonials />
      <FAQSection />
      <FinalCTA />
      <Footer />

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
