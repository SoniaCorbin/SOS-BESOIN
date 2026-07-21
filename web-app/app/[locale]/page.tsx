import { getTranslations } from 'next-intl/server'
import Nav from '@/components/Nav'
import Stats from '@/components/Stats'
import Categories from '@/components/Categories'
import HowItWorks from '@/components/HowItWorks'
import Providers from '@/components/Providers'
import LiveBoard from '@/components/LiveBoard'
import Footer from '@/components/Footer'
import Testimonials from '@/components/Testimonials'
import FAQ from '@/components/FAQ'

export default async function Home() {
  const t = await getTranslations('home')

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64 }}>
        <section style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          padding: '0 24px',
        }}>
          <div>
            <span style={{
              fontFamily: 'var(--font-mono)',
              fontSize: 11,
              color: 'var(--amber)',
              letterSpacing: '0.1em',
              textTransform: 'uppercase',
            }}>·SOS_BESOIN·</span>
            <h1 style={{
              fontSize: 'clamp(40px, 6vw, 80px)',
              fontWeight: 700,
              lineHeight: 1.1,
              letterSpacing: '-0.03em',
              marginTop: 16,
            }}>
              {t('title')}<br />
              <span style={{ color: 'var(--amber)' }}>{t('title_accent')}</span>
            </h1>
            <p style={{
              marginTop: 24,
              fontSize: 18,
              color: 'var(--text-dim)',
              maxWidth: 480,
              margin: '24px auto 0',
            }}>
              {t('subtitle')}
            </p>
          </div>
        </section>
        <Stats />
        <Categories />
        <HowItWorks />
        <Providers />
        <Testimonials />
        <FAQ />
        <LiveBoard />
        <Footer />
      </main>
    </>
  )
}