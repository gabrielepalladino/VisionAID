import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:main_app/pages/accessibility_provider.dart';

class GuidaScreen extends StatelessWidget {
  const GuidaScreen({super.key});

  static final List<_GuidaSezione> _sezioni = [
    _GuidaSezione(
      titolo: 'Navigazione dell\'app',
      icon: Icons.explore_outlined,
      voci: [
        _FAQ(
          domanda: 'Come è strutturata l\'app?',
          risposta:
              'L\'app è organizzata in sezioni accessibili dal menu principale. '
              'Troverai le voci principali nella schermata Home, da cui puoi '
              'raggiungere tutte le funzionalità disponibili con un singolo tocco.',
        ),
        _FAQ(
          domanda: 'Come torno alla schermata principale?',
          risposta:
              'Puoi tornare alla Home in qualsiasi momento premendo il pulsante '
              '"Indietro" del dispositivo oppure la freccia in alto a sinistra '
              'nella barra superiore dell\'app.',
        ),
        _FAQ(
          domanda: 'Come accedo alle Novità?',
          risposta:
              'Dalla schermata principale, tocca la voce "Novità". Qui troverai '
              'l\'elenco degli aggiornamenti recenti con la versione di riferimento '
              'e una descrizione delle modifiche introdotte.',
        ),
        _FAQ(
          domanda: 'Come accedo alle Informazioni sull\'app?',
          risposta:
              'Dal menu principale, seleziona "Informazioni". Troverai il numero '
              'di versione, il numero di build, le note legali e i link utili '
              'come la Privacy Policy e i Termini e condizioni.',
        ),
      ],
    ),

    _GuidaSezione(
      titolo: 'Accessibilità',
      icon: Icons.accessibility_new_outlined,
      voci: [
        _FAQ(
          domanda: 'Come attivo l\'alto contrasto?',
          risposta:
              'Vai nelle Impostazioni dell\'app e cerca la voce "Alto contrasto". '
              'Attivandola, l\'interfaccia passerà a colori ad alto contrasto '
              '(sfondo nero e testo bianco) per migliorare la leggibilità in '
              'condizioni di scarsa illuminazione o per utenti con difficoltà visive.',
        ),
        _FAQ(
          domanda: 'Come funziona la sintesi vocale?',
          risposta:
              'La sintesi vocale legge ad alta voce il nome degli elementi '
              'dell\'interfaccia quando vengono toccati. Puoi attivarla dalle '
              'Impostazioni alla voce "Sintesi vocale". Assicurati che il volume '
              'del dispositivo non sia azzerato.',
        ),
        _FAQ(
          domanda: 'Come cambio la dimensione del testo?',
          risposta:
              'Nelle Impostazioni trovi il cursore "Dimensione testo" che ti '
              'permette di aumentare o ridurre la dimensione dei caratteri in '
              'tutta l\'app. La modifica viene applicata immediatamente.',
        ),
        _FAQ(
          domanda: 'Come funziona il feedback aptico?',
          risposta:
              'Il feedback aptico produce una leggera vibrazione del dispositivo '
              'ogni volta che esegui un\'azione (tocco di un pulsante, invio di '
              'un modulo, ecc.). Puoi disattivarlo dalle Impostazioni se preferisci '
              'non averlo.',
        ),
        _FAQ(
          domanda: 'Le impostazioni di accessibilità vengono salvate?',
          risposta:
              'Sì. Tutte le preferenze di accessibilità (contrasto, sintesi vocale, '
              'dimensione testo, feedback aptico) vengono salvate automaticamente '
              'e ripristinate ad ogni avvio dell\'app.',
        ),
      ],
    ),

    _GuidaSezione(
      titolo: 'Supporto e ticket',
      icon: Icons.headset_mic_outlined,
      voci: [
        _FAQ(
          domanda: 'Come contatto il supporto?',
          risposta:
              'Dal menu principale seleziona "Supporto". Si aprirà un modulo '
              'attraverso cui potrai inviare una richiesta di assistenza '
              'direttamente al nostro team.',
        ),
        _FAQ(
          domanda: 'Cosa devo inserire nel modulo di supporto?',
          risposta:
              'Il modulo richiede: il tuo indirizzo email (obbligatorio), '
              'un numero di telefono facoltativo, la categoria del problema '
              '(es. problema tecnico, errore nell\'app, richiesta funzionalità), '
              'una descrizione dettagliata del problema e, se utile, uno screenshot.',
        ),
        _FAQ(
          domanda: 'Come allego uno screenshot?',
          risposta:
              'Nel modulo di supporto trovi il pulsante "Aggiungi screenshot". '
              'Toccalo per aprire la galleria del dispositivo e selezionare '
              'un\'immagine. Puoi rimuovere lo screenshot selezionato toccando '
              'la X in alto a destra sull\'anteprima.',
        ),
        _FAQ(
          domanda: 'Come faccio a sapere se il ticket è stato ricevuto?',
          risposta:
              'Dopo l\'invio, comparirà un messaggio di conferma con il numero '
              'del ticket assegnato. Riceverai aggiornamenti all\'indirizzo email '
              'che hai indicato nel modulo.',
        ),
        _FAQ(
          domanda: 'Quanto tempo ci vuole per ricevere una risposta?',
          risposta:
              'Il nostro team risponde solitamente entro 1-2 giorni lavorativi. '
              'Per problemi urgenti, indica nella descrizione la natura critica '
              'del problema così da ricevere priorità nella gestione.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final acc = Provider.of<AccessibilityProvider>(context);
    final hc  = acc.highContrast;

    return Scaffold(
      backgroundColor: hc ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: hc ? Colors.black : Colors.blue,
        foregroundColor: Colors.white,
        title: Text(
          'Guida',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            acc.triggerHapticFeedback();
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner intro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hc ? Colors.grey[900] : Colors.blue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hc ? Colors.white24 : Colors.blue.withOpacity(0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: hc ? Colors.white70 : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Qui trovi le risposte alle domande più comuni sull\'utilizzo '
                    'dell\'app.',
                    style: TextStyle(
                      color: hc ? Colors.white70 : Colors.blue[800],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sezioni
          ..._sezioni.map((s) => _SezioneWidget(sezione: s, hc: hc, acc: acc)),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'Non hai trovato quello che cercavi?\nContattaci dalla sezione Supporto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hc ? Colors.white38 : Colors.black38,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Sezione espandibile ───────────────────────────────────────────────────────
class _SezioneWidget extends StatefulWidget {
  final _GuidaSezione sezione;
  final bool hc;
  final dynamic acc;

  const _SezioneWidget({
    required this.sezione,
    required this.hc,
    required this.acc,
  });

  @override
  State<_SezioneWidget> createState() => _SezioneWidgetState();
}

class _SezioneWidgetState extends State<_SezioneWidget> {
  bool _expanded = false;
  int  _openFaq  = -1;

  void _toggleSection() {
    widget.acc?.triggerHapticFeedback();
    widget.acc?.speak(widget.sezione.titolo);
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) _openFaq = -1;
    });
  }

  void _toggleFaq(int i) {
    widget.acc?.triggerHapticFeedback();
    if (_openFaq == i) {
      widget.acc?.speak('Chiuso');
    } else {
      widget.acc?.speak(widget.sezione.voci[i].risposta);
    }
    setState(() => _openFaq = _openFaq == i ? -1 : i);
  }

  @override
  Widget build(BuildContext context) {
    final hc = widget.hc;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hc ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: hc ? Border.all(color: Colors.white24) : null,
        boxShadow: hc
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header sezione (tocca per espandere)
          GestureDetector(
            onTap: _toggleSection,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: hc
                          ? Colors.white.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(widget.sezione.icon, size: 18,
                        color: hc ? Colors.white : Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.sezione.titolo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hc ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '',
                    style: TextStyle(
                        color: hc ? Colors.white38 : Colors.black38),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: hc ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
            ),
          ),

          // Lista FAQ
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: hc ? Colors.white12 : Colors.grey[100]),
                ...widget.sezione.voci.asMap().entries.map((e) {
                  final i      = e.key;
                  final faq    = e.value;
                  final isOpen = _openFaq == i;
                  final isLast = i == widget.sezione.voci.length - 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Domanda
                      GestureDetector(
                        onTap: () => _toggleFaq(i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  isOpen
                                      ? Icons.remove_circle_outline
                                      : Icons.add_circle_outline,
                                  size: 18,
                                  color: isOpen
                                      ? (hc ? Colors.white : Colors.blue)
                                      : (hc ? Colors.white38 : Colors.black38),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  faq.domanda,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isOpen
                                        ? (hc ? Colors.white : Colors.blue)
                                        : (hc ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Risposta animata
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(46, 0, 16, 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hc
                                ? Colors.white.withOpacity(0.05)
                                : Colors.blue.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hc
                                  ? Colors.white12
                                  : Colors.blue.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            faq.risposta,
                            style: TextStyle(
                              color: hc ? Colors.white60 : Colors.black54,
                              height: 1.6,
                            ),
                          ),
                        ),
                        crossFadeState: isOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),

                      if (!isLast)
                        Divider(
                          height: 1, indent: 16, endIndent: 16,
                          color: hc ? Colors.white12 : Colors.grey[100],
                        ),
                    ],
                  );
                }),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ── Modelli dati ──────────────────────────────────────────────────────────────
class _GuidaSezione {
  final String titolo;
  final IconData icon;
  final List<_FAQ> voci;
  const _GuidaSezione({required this.titolo, required this.icon, required this.voci});
}

class _FAQ {
  final String domanda;
  final String risposta;
  const _FAQ({required this.domanda, required this.risposta});
}