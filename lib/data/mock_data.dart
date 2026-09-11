import '../models/pick.dart';

const kPlans = <Plan>[
  Plan(
    id: 'free', name: 'Free', price: '\$0', period: 'MXN / mes',
    features: ['2 partidos gratis por día', '5 mensajes de chat IA por día', 'Análisis básico (1X2)'],
  ),
  Plan(
    id: 'premium', name: 'Premium', price: '\$149', period: 'MXN / mes',
    features: ['Picks y partidos ilimitados', 'Chat IA ilimitado', 'Todos los mercados (doble oportunidad, Poisson)'],
    recommended: true,
  ),
  Plan(
    id: 'pro', name: 'Pro', price: '\$299', period: 'MXN / mes',
    features: ['Todo lo de Premium', 'Picks VIP alta confianza', 'Alertas prioritarias'],
  ),
];

class NotifPref {
  final String key;
  final String label;
  final String sub;
  const NotifPref({required this.key, required this.label, required this.sub});
}

const kNotifDefs = <NotifPref>[
  NotifPref(key: 'picks', label: 'Picks nuevos del día', sub: 'Cuando publicamos los picks diarios'),
  NotifPref(key: 'resultados', label: 'Resultados de tus picks', sub: 'Aciertos y fallos de picks vistos'),
  NotifPref(key: 'alineacion', label: 'Alineación confirmada', sub: 'Cuando se publica la probable alineación del partido'),
  NotifPref(key: 'promos', label: 'Promociones y descuentos', sub: 'Ofertas de planes Premium/Pro'),
];

const kSportTabs = <String, String>{
  'all': 'Todos',
  'futbol': 'Fútbol',
  'nba': 'NBA',
  'tenis': 'Tenis',
  'nfl': 'NFL',
};


