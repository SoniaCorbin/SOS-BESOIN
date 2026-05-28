import { AlertCircle, ArrowRight, CheckCircle2, Clock, Shield, Users, Zap, Sparkles, TrendingUp, Award } from "lucide-react";
import { Button } from "./components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./components/ui/card";
import { Badge } from "./components/ui/badge";

export default function App() {
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b border-secondary/20 bg-card/80 backdrop-blur-md sticky top-0 z-50 shadow-lg shadow-black/50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="size-10 rounded-full bg-primary flex items-center justify-center shadow-lg shadow-primary/50">
                <AlertCircle className="size-6 text-primary-foreground" />
              </div>
              <div className="absolute -top-1 -right-1 size-3 rounded-full bg-secondary animate-pulse"></div>
            </div>
            <span className="font-bold text-2xl text-foreground">SOS<span className="text-primary">-BESOIN</span></span>
          </div>
          <div className="flex items-center gap-4">
            <Button variant="ghost" className="text-foreground hover:text-primary hover:bg-primary/10">Connexion</Button>
            <Button className="bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/50">S'inscrire</Button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 text-center relative overflow-hidden">
        {/* Decorative elements */}
        <div className="absolute top-10 left-10 size-96 bg-primary/20 rounded-full blur-3xl"></div>
        <div className="absolute bottom-10 right-10 size-96 bg-secondary/20 rounded-full blur-3xl"></div>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 size-[600px] bg-accent/10 rounded-full blur-3xl"></div>

        <div className="relative z-10">
          <Badge className="mb-6 bg-primary text-primary-foreground border-0 px-6 py-3 shadow-xl shadow-primary/50 animate-pulse text-base" variant="default">
            <Zap className="size-4 mr-2" />
            Réponse en moins de 30 minutes
          </Badge>
          <h1 className="mb-6 max-w-4xl mx-auto text-foreground">
            Un pro disponible rapidement,
            <br />
            <span className="text-primary">quand c'est urgent</span>
          </h1>
          <p className="text-muted-foreground mb-10 max-w-2xl mx-auto text-lg">
            Publiez votre besoin urgent en quelques clics. Des professionnels qualifiés vous
            proposent leurs services rapidement. Paiement sécurisé et satisfaction garantie.
          </p>
          <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
            <Button size="lg" className="gap-2 bg-primary text-primary-foreground hover:bg-primary/90 shadow-2xl shadow-primary/50 hover:shadow-primary/70 transition-all text-lg px-8 py-6 h-auto font-bold">
              <AlertCircle className="size-6" />
              Lancer une alerte SOS
              <ArrowRight className="size-5" />
            </Button>
            <Button size="lg" variant="outline" className="border-2 border-secondary text-secondary hover:bg-secondary hover:text-secondary-foreground shadow-xl shadow-secondary/30 hover:shadow-secondary/50 transition-all text-lg px-8 py-6 h-auto">
              Devenir prestataire
            </Button>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-20 max-w-5xl mx-auto relative z-10">
          <div className="bg-card backdrop-blur-sm rounded-2xl p-8 shadow-2xl border-2 border-primary/30 hover:border-primary hover:shadow-primary/30 hover:scale-105 transition-all">
            <div className="flex flex-col items-center text-center">
              <TrendingUp className="size-12 text-primary mb-4" />
              <div className="font-bold text-5xl text-primary mb-2">2000+</div>
              <div className="text-sm text-muted-foreground uppercase tracking-wider">Interventions réussies</div>
            </div>
          </div>
          <div className="bg-card backdrop-blur-sm rounded-2xl p-8 shadow-2xl border-2 border-secondary/30 hover:border-secondary hover:shadow-secondary/30 hover:scale-105 transition-all">
            <div className="flex flex-col items-center text-center">
              <Users className="size-12 text-secondary mb-4" />
              <div className="font-bold text-5xl text-secondary mb-2">500+</div>
              <div className="text-sm text-muted-foreground uppercase tracking-wider">Pros vérifiés</div>
            </div>
          </div>
          <div className="bg-card backdrop-blur-sm rounded-2xl p-8 shadow-2xl border-2 border-accent/30 hover:border-accent hover:shadow-accent/30 hover:scale-105 transition-all">
            <div className="flex flex-col items-center text-center">
              <Award className="size-12 text-accent mb-4" />
              <div className="font-bold text-5xl text-accent mb-2">4.8/5</div>
              <div className="text-sm text-muted-foreground uppercase tracking-wider">Satisfaction client</div>
            </div>
          </div>
        </div>
      </section>

      {/* Why SOS-BESOIN */}
      <section className="bg-background py-20 relative overflow-hidden border-y border-secondary/20">
        <div className="absolute top-0 right-0 size-96 bg-primary/10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 left-0 size-96 bg-secondary/10 rounded-full blur-3xl"></div>
        <div className="container mx-auto px-4 relative z-10">
          <div className="text-center mb-16">
            <h2 className="mb-4 text-foreground">Pourquoi <span className="text-primary">SOS-BESOIN</span>?</h2>
            <p className="text-muted-foreground max-w-2xl mx-auto text-lg">
              Une plateforme pensée pour vos urgences, avec des garanties solides
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <Card className="border-2 border-primary/30 shadow-2xl hover:shadow-primary/40 hover:-translate-y-2 hover:border-primary transition-all bg-card/50 backdrop-blur-sm">
              <CardHeader className="text-center">
                <div className="size-16 rounded-2xl bg-primary/20 border-2 border-primary flex items-center justify-center mb-6 shadow-xl shadow-primary/30 mx-auto">
                  <Clock className="size-8 text-primary" />
                </div>
                <CardTitle className="text-primary text-xl">Réponse ultra-rapide</CardTitle>
                <CardDescription className="text-muted-foreground text-base">
                  Des professionnels disponibles répondent à votre besoin en moins de 30 minutes
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="border-2 border-secondary/30 shadow-2xl hover:shadow-secondary/40 hover:-translate-y-2 hover:border-secondary transition-all bg-card/50 backdrop-blur-sm">
              <CardHeader className="text-center">
                <div className="size-16 rounded-2xl bg-secondary/20 border-2 border-secondary flex items-center justify-center mb-6 shadow-xl shadow-secondary/30 mx-auto">
                  <Shield className="size-8 text-secondary" />
                </div>
                <CardTitle className="text-secondary text-xl">Paiement sécurisé</CardTitle>
                <CardDescription className="text-muted-foreground text-base">
                  Votre argent est protégé jusqu'à la validation du service via Stripe
                </CardDescription>
              </CardHeader>
            </Card>

            <Card className="border-2 border-accent/30 shadow-2xl hover:shadow-accent/40 hover:-translate-y-2 hover:border-accent transition-all bg-card/50 backdrop-blur-sm">
              <CardHeader className="text-center">
                <div className="size-16 rounded-2xl bg-accent/20 border-2 border-accent flex items-center justify-center mb-6 shadow-xl shadow-accent/30 mx-auto">
                  <Users className="size-8 text-accent" />
                </div>
                <CardTitle className="text-accent text-xl">Professionnels vérifiés</CardTitle>
                <CardDescription className="text-muted-foreground text-base">
                  Tous nos prestataires sont validés et notés par la communauté
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* How it Works - Clients */}
      <section className="py-20 bg-background">
        <div className="container mx-auto px-4">
          <div className="text-center mb-16">
            <h2 className="mb-4 text-foreground">Comment <span className="text-accent">ça fonctionne</span>?</h2>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 max-w-7xl mx-auto">
            {/* For Clients */}
            <div className="bg-card backdrop-blur-sm rounded-3xl p-10 shadow-2xl border-2 border-primary/30 hover:border-primary hover:shadow-primary/30 transition-all">
              <div className="flex items-center gap-3 mb-10">
                <div className="size-12 rounded-xl bg-primary/20 border-2 border-primary flex items-center justify-center shadow-lg">
                  <AlertCircle className="size-6 text-primary" />
                </div>
                <h3 className="text-primary">Pour les clients</h3>
              </div>

              <div className="space-y-8">
                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-primary text-primary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-primary/50 transition-all border-2 border-primary">
                    1
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Publiez votre demande</h4>
                    <p className="text-sm text-muted-foreground">
                      Décrivez votre besoin urgent avec les détails nécessaires et la date souhaitée
                    </p>
                  </div>
                </div>

                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-primary text-primary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-primary/50 transition-all border-2 border-primary">
                    2
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Recevez des offres</h4>
                    <p className="text-sm text-muted-foreground">
                      Les professionnels disponibles vous proposent leurs prix et disponibilités
                    </p>
                  </div>
                </div>

                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-primary text-primary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-primary/50 transition-all border-2 border-primary">
                    3
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Choisissez et payez</h4>
                    <p className="text-sm text-muted-foreground">
                      Sélectionnez la meilleure offre et payez en toute sécurité
                    </p>
                  </div>
                </div>

                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-primary text-primary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-primary/50 transition-all border-2 border-primary">
                    4
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Validez le service</h4>
                    <p className="text-sm text-muted-foreground">
                      Une fois le travail terminé, validez et notez le prestataire
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* For Providers */}
            <div className="bg-card backdrop-blur-sm rounded-3xl p-10 shadow-2xl border-2 border-secondary/30 hover:border-secondary hover:shadow-secondary/30 transition-all">
              <div className="flex items-center gap-3 mb-10">
                <div className="size-12 rounded-xl bg-secondary/20 border-2 border-secondary flex items-center justify-center shadow-lg">
                  <Users className="size-6 text-secondary" />
                </div>
                <h3 className="text-secondary">Pour les prestataires</h3>
              </div>

              <div className="space-y-8">
                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-secondary text-secondary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-secondary/50 transition-all border-2 border-secondary">
                    1
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Consultez les demandes</h4>
                    <p className="text-sm text-muted-foreground">
                      Parcourez les besoins urgents dans votre domaine d'expertise
                    </p>
                  </div>
                </div>

                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-secondary text-secondary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-secondary/50 transition-all border-2 border-secondary">
                    2
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Soumettez votre offre</h4>
                    <p className="text-sm text-muted-foreground">
                      Proposez votre prix et confirmez votre disponibilité immédiate
                    </p>
                  </div>
                </div>

                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-secondary text-secondary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-secondary/50 transition-all border-2 border-secondary">
                    3
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Effectuez le travail</h4>
                    <p className="text-sm text-muted-foreground">
                      Réalisez la prestation selon les termes convenus avec le client
                    </p>
                  </div>
                </div>

                <div className="flex gap-5 group hover:translate-x-2 transition-all">
                  <div className="size-12 rounded-xl bg-secondary text-secondary-foreground flex items-center justify-center shrink-0 font-bold text-lg shadow-lg group-hover:shadow-2xl group-hover:shadow-secondary/50 transition-all border-2 border-secondary">
                    4
                  </div>
                  <div>
                    <h4 className="font-semibold mb-2 text-foreground text-lg">Recevez votre paiement</h4>
                    <p className="text-sm text-muted-foreground">
                      Une fois validé, votre paiement est transféré automatiquement
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Categories Preview */}
      <section className="bg-background py-20 relative overflow-hidden border-t border-secondary/20">
        <div className="absolute bottom-0 left-0 size-96 bg-primary/10 rounded-full blur-3xl"></div>
        <div className="absolute top-0 right-0 size-96 bg-secondary/10 rounded-full blur-3xl"></div>
        <div className="container mx-auto px-4 relative z-10">
          <div className="text-center mb-16">
            <h2 className="mb-4 text-foreground">Nos <span className="text-accent">catégories</span></h2>
            <p className="text-muted-foreground max-w-2xl mx-auto text-lg">
              Des professionnels dans tous les domaines pour répondre à vos urgences
            </p>
          </div>

          <div className="flex flex-wrap gap-4 justify-center max-w-5xl mx-auto">
            {[
              "Tech & Informatique",
              "Musique & Événements",
              "Réparations",
              "Transport",
              "Cours & Formation",
              "Design & Création",
              "Traduction",
              "Juridique",
              "Santé & Bien-être"
            ].map((category, index) => (
              <Badge
                key={category}
                variant="outline"
                className={`px-6 py-3 text-sm border-2 ${
                  index % 3 === 0
                    ? "border-primary text-primary hover:bg-primary hover:text-primary-foreground"
                    : index % 3 === 1
                    ? "border-secondary text-secondary hover:bg-secondary hover:text-secondary-foreground"
                    : "border-accent text-accent hover:bg-accent hover:text-accent-foreground"
                } shadow-lg hover:shadow-xl hover:scale-105 transition-all cursor-pointer font-medium`}
              >
                {category}
              </Badge>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-20 bg-background relative overflow-hidden">
        <div className="absolute inset-0">
          <div className="absolute top-0 left-1/4 size-96 bg-primary/20 rounded-full blur-3xl"></div>
          <div className="absolute bottom-0 right-1/4 size-96 bg-secondary/20 rounded-full blur-3xl"></div>
        </div>
        <div className="container mx-auto px-4 relative z-10">
          <Card className="max-w-5xl mx-auto bg-card border-2 border-primary/30 shadow-2xl overflow-hidden relative">
            <CardContent className="pt-20 pb-20 text-center relative z-10">
              <div className="size-20 rounded-full bg-primary/20 border-2 border-primary flex items-center justify-center mx-auto mb-6 shadow-xl shadow-primary/50">
                <AlertCircle className="size-10 text-primary" />
              </div>
              <h2 className="mb-6 text-foreground">Prêt à commencer?</h2>
              <p className="text-muted-foreground mb-12 max-w-2xl mx-auto text-lg">
                Rejoignez des milliers d'utilisateurs qui font confiance à SOS-BESOIN
                pour leurs besoins urgents
              </p>
              <div className="flex flex-col sm:flex-row gap-6 justify-center">
                <Button size="lg" className="bg-primary text-primary-foreground hover:bg-primary/90 shadow-2xl shadow-primary/50 hover:shadow-primary/70 transition-all text-lg px-10 py-6 h-auto font-bold">
                  <AlertCircle className="size-5 mr-2" />
                  Publier un besoin
                  <ArrowRight className="size-5 ml-2" />
                </Button>
                <Button size="lg" variant="outline" className="border-2 border-secondary text-secondary hover:bg-secondary hover:text-secondary-foreground shadow-xl shadow-secondary/30 hover:shadow-secondary/50 transition-all text-lg px-10 py-6 h-auto">
                  Devenir prestataire
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-secondary/20 py-12 bg-card">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <div className="size-10 rounded-full bg-primary flex items-center justify-center shadow-lg shadow-primary/50">
                  <AlertCircle className="size-6 text-primary-foreground" />
                </div>
                <span className="font-bold text-xl text-foreground">SOS<span className="text-primary">-BESOIN</span></span>
              </div>
              <p className="text-sm text-muted-foreground">
                La plateforme de mise en relation pour vos besoins urgents
              </p>
            </div>

            <div>
              <h4 className="font-semibold mb-4 text-foreground">Plateforme</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-primary transition-colors">Comment ça marche</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Catégories</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Tarifs</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4 text-foreground">Support</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-secondary transition-colors">Centre d'aide</a></li>
                <li><a href="#" className="hover:text-secondary transition-colors">Contact</a></li>
                <li><a href="#" className="hover:text-secondary transition-colors">FAQ</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4 text-foreground">Légal</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-accent transition-colors">Conditions d'utilisation</a></li>
                <li><a href="#" className="hover:text-accent transition-colors">Politique de confidentialité</a></li>
                <li><a href="#" className="hover:text-accent transition-colors">Mentions légales</a></li>
              </ul>
            </div>
          </div>

          <div className="border-t border-secondary/20 mt-8 pt-8 text-center text-sm text-muted-foreground">
            <p>&copy; 2026 SOS-BESOIN. Tous droits réservés.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}