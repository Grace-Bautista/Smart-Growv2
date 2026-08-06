import 'package:flutter/material.dart';
import 'package:smart_grow_code/custom_header_button.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  static const guides = <GuideArticle>[
    GuideArticle(
      title: 'Oyster Mushroom Florida Strain',
      subtitle: 'Climate, fruiting targets, and daily management',
      sections: [
        GuideSection(
          heading: 'Why growers choose it',
          paragraphs: [
            'Florida oyster is a warm-weather oyster mushroom that performs well in tropical and lowland conditions. It is a practical strain when daytime temperatures are often too high for cooler oyster varieties.',
            'It grows quickly, colonizes aggressively, and can still produce attractive clusters when fresh air, humidity, and cleanliness are managed well.',
          ],
        ),
        GuideSection(
          heading: 'Best growing targets',
          bullets: [
            'Spawn run temperature: about 24 C to 30 C.',
            'Fruiting temperature: about 22 C to 30 C, with many growers aiming near 25 C to 28 C.',
            'Relative humidity during fruiting: usually 85% to 95%.',
            'CO2 should stay low during fruiting to avoid long stems and small caps.',
            'Fresh air is critical. Oyster mushrooms react very quickly to stale air.',
            'Indirect light is enough for fruiting. They do not need intense direct sun.',
          ],
        ),
        GuideSection(
          heading: 'What healthy fruiting looks like',
          bullets: [
            'Short to medium stems and well-opened caps.',
            'Even clusters forming from the fruiting holes.',
            'Good cap color without yellowing or dry cracking.',
            'No sour smell, slime, or black contamination on the bag mouth.',
          ],
        ),
        GuideSection(
          heading: 'Common problems',
          bullets: [
            'Long stems and tiny caps: usually too much CO2 or poor ventilation.',
            'Dry, cracked caps: humidity too low or airflow too harsh.',
            'Very thin fruit bodies: weak substrate nutrition or poor moisture balance.',
            'Slow bag colonization: weak spawn, poor sterilization, or substrate too wet.',
            'Green mold: contamination from dirty inoculation, weak sterilization, or damaged bags.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Smart-Grow Project Overview',
      subtitle: 'How your system solves ADHIKA humidity problems',
      sections: [
        GuideSection(
          heading: 'Project context',
          paragraphs: [
            'Your defense paper identifies inconsistent humidity management, weak water pressure, manual spraying, and labor-heavy monitoring as the main problems in the grow house.',
            'SMART-GROW addresses those gaps with automated humidification support, ventilation control, water refill support, mobile monitoring, alerts, and digital logging.',
          ],
        ),
        GuideSection(
          heading: 'Core modules in this project',
          bullets: [
            'SCD40 for temperature, humidity, and CO2 tracking.',
            'Water level sensing for refill decisions.',
            'Pump control for tank refill support.',
            'Fan control for stale-air removal and CO2 reduction.',
            'Mobile dashboard for status, override, and viewing sensor trends.',
          ],
        ),
        GuideSection(
          heading: 'What this means for growers',
          bullets: [
            'Less dependence on constant manual checking.',
            'More stable fruiting conditions.',
            'Faster response during hot afternoons and dry periods.',
            'A clearer maintenance trail through digital monitoring and logs.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Substrate And Fruiting Bag Guide',
      subtitle: 'Bag preparation from mixing to incubation',
      sections: [
        GuideSection(
          heading: 'Typical substrate approach',
          paragraphs: [
            'Oyster mushrooms are commonly grown on agricultural waste such as rice straw, sawdust, corn cobs, or mixed cellulose-rich materials. The exact recipe depends on what is cheap, clean, and available in your area.',
            'Whatever formula you choose, the substrate should be moist but not dripping. If you squeeze a handful firmly, only a few drops should come out.',
          ],
        ),
        GuideSection(
          heading: 'Bag preparation workflow',
          bullets: [
            'Sort and clean raw materials. Remove moldy, rotten, or muddy parts.',
            'Chop or break bulky material to improve packing and colonization.',
            'Add water gradually until field capacity is reached.',
            'Load the substrate into polypropylene bags and fit the neck ring or cotton plug system.',
            'Sterilize or pasteurize consistently. The cleaner the substrate, the safer the grow.',
            'Cool fully before inoculation. Hot substrate can kill spawn.',
          ],
        ),
        GuideSection(
          heading: 'Good inoculation practice',
          bullets: [
            'Use clean hands, clean tools, and a clean table.',
            'Avoid talking, coughing, or exposing opened bags for too long.',
            'Mix spawn evenly or layer it properly, depending on your method.',
            'Seal immediately after inoculation.',
          ],
        ),
        GuideSection(
          heading: 'Incubation tips',
          bullets: [
            'Keep bags away from direct sunlight.',
            'Do not let condensation pool heavily inside bags.',
            'Separate contaminated bags early so they do not spread spores.',
            'Allow full white colonization before opening for fruiting.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Fruiting House Management',
      subtitle: 'Humidity, airflow, hygiene, and harvest timing',
      sections: [
        GuideSection(
          heading: 'Daily fruiting room checklist',
          bullets: [
            'Check temperature and humidity at the start of the day.',
            'Confirm the fan is exchanging stale air without drying the room too much.',
            'Inspect water supply before running the humidifier.',
            'Remove dead pins, old stems, and contaminated bags.',
            'Watch for insects, sour smells, or standing water.',
          ],
        ),
        GuideSection(
          heading: 'Humidity and airflow balance',
          paragraphs: [
            'High humidity alone is not enough. Oyster mushrooms also need fresh air. A closed room with only misting often produces long stems, curled caps, and weak clusters.',
            'Good management means humidifying in short cycles while also replacing stale air. The goal is moist air, not wet surfaces everywhere.',
          ],
        ),
        GuideSection(
          heading: 'Harvest timing',
          bullets: [
            'Harvest clusters before the caps flatten too much and before heavy spore drop starts.',
            'Cut cleanly at the base to avoid leaving rotting tissue on the bag.',
            'Handle gently because oyster caps bruise easily.',
            'Sort by size and quality immediately after harvest.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Humidity Control Playbook',
      subtitle: 'How to keep oyster fruiting conditions stable',
      sections: [
        GuideSection(
          heading: 'Target conditions',
          bullets: [
            'Maintain fruiting humidity around 80% to 95%, especially during pinning and cap expansion.',
            'Prevent direct dry airflow from hitting exposed mushroom clusters.',
            'Avoid drenching surfaces so heavily that contamination and slime increase.',
          ],
        ),
        GuideSection(
          heading: 'Signs of poor humidity control',
          bullets: [
            'Pinheads abort or dry out early.',
            'Caps crack, curl, or remain too small.',
            'Bag mouths dry faster than the rest of the room.',
            'Humidity swings heavily between morning and afternoon.',
          ],
        ),
        GuideSection(
          heading: 'Practical actions',
          bullets: [
            'Use the humidity screen to confirm live room readings before adjusting operation.',
            'Check if the refill pump has enough water source support.',
            'Inspect misting distribution and humidifier cleanliness regularly.',
            'Balance humidity with fresh-air exchange instead of trying to solve everything with more water alone.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Fan And CO2 Management',
      subtitle: 'Ventilation rules for healthy oyster clusters',
      sections: [
        GuideSection(
          heading: 'Why CO2 matters',
          paragraphs: [
            'Your paper highlights the importance of ventilation control together with humidity. Oyster mushrooms react fast to stale air, especially during fruiting.',
          ],
        ),
        GuideSection(
          heading: 'Symptoms of too much CO2',
          bullets: [
            'Long stems and undersized caps.',
            'Clusters stretching toward openings.',
            'Weak, thin fruit bodies with poor shelf appeal.',
          ],
        ),
        GuideSection(
          heading: 'Using the fan screen well',
          bullets: [
            'Use AUTO mode when you want the system to respond to rising CO2 and heat.',
            'Use MANUAL mode when you need a timed ventilation cycle during peak heat.',
            'If caps begin drying, reduce harsh airflow and compensate with better humidity distribution.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Water Refill Pump Guide',
      subtitle: 'How the refill side supports the humidifier system',
      sections: [
        GuideSection(
          heading: 'Why refill automation matters',
          paragraphs: [
            'The project paper points to uneven watering and unreliable manual intervention as a major weakness. A refill pump reduces the chance that the humidifier runs dry during hot periods.',
          ],
        ),
        GuideSection(
          heading: 'Operator reminders',
          bullets: [
            'Keep the water source clean to avoid feeding debris into the humidifier system.',
            'Inspect hoses and suction filters for clogging.',
            'Watch the humidifier screen for low-water status and pump activity.',
            'If the pump keeps running, inspect the tank path rather than assuming the sensor is wrong immediately.',
          ],
        ),
        GuideSection(
          heading: 'Maintenance checks',
          bullets: [
            'Look for leaks around fittings and tank entries.',
            'Clean intake filters before sediment flow becomes heavy.',
            'Verify that the water level sensor is still mounted securely and not shorting against wet surfaces.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Dashboard, Alerts, And Manual Override',
      subtitle: 'How to use the app during normal operations',
      sections: [
        GuideSection(
          heading: 'Best workflow',
          bullets: [
            'Check dashboard sensor chips first for temperature, humidity, CO2, and water condition.',
            'Open the humidifier screen when water support or moisture levels look weak.',
            'Open the fan screen when heat or CO2 begins to climb.',
            'Use notifications as prompts, but verify with the live screens before making a change.',
          ],
        ),
        GuideSection(
          heading: 'Manual override cases',
          bullets: [
            'Unexpected hot afternoon and poor airflow.',
            'Humidity drop after door opening or weather shift.',
            'Temporary sensor recovery period after maintenance.',
            'Testing a relay or pump path after hardware changes.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Maintenance And Reliability',
      subtitle: 'What to inspect so the system stays dependable',
      sections: [
        GuideSection(
          heading: 'Weekly checks',
          bullets: [
            'Inspect relay wiring and terminal tightness.',
            'Confirm OLED readability and I2C wiring stability.',
            'Clean humidifier parts and refill lines.',
            'Review sensor values for unrealistic jumps or flat lines.',
          ],
        ),
        GuideSection(
          heading: 'Failure patterns to watch',
          bullets: [
            'No change in humidity even while the system appears active.',
            'Pump runs but tank level does not recover.',
            'Fan relay clicks but airflow does not increase.',
            'Sensor values disappear from the dashboard while the ESP32 is still reachable.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Contamination And Hygiene Manual',
      subtitle: 'How to prevent losses before they spread',
      sections: [
        GuideSection(
          heading: 'Main contamination sources',
          bullets: [
            'Dirty raw materials.',
            'Weak pasteurization or sterilization.',
            'Cooling bags in dirty areas.',
            'Poor inoculation hygiene.',
            'Damaged bags and reused contaminated tools.',
          ],
        ),
        GuideSection(
          heading: 'Warning signs',
          bullets: [
            'Green, black, orange, or pink growth in or on the substrate.',
            'Sour, foul, or alcoholic smell.',
            'Wet slime around the bag neck or fruiting holes.',
            'Colonization that stalls and never turns fully white.',
          ],
        ),
        GuideSection(
          heading: 'Response plan',
          bullets: [
            'Remove contaminated bags immediately.',
            'Do not open suspect bags inside the clean inoculation area.',
            'Disinfect shelves, tools, and hands after handling infected material.',
            'Track which batch failed so you can identify whether the issue started in substrate, inoculation, or fruiting.',
          ],
        ),
      ],
    ),
    GuideArticle(
      title: 'Cost And Small-Farm Practicality',
      subtitle: 'Keeping the system useful for ADHIKA-scale deployment',
      sections: [
        GuideSection(
          heading: 'Why this matters',
          paragraphs: [
            'Your paper emphasizes practicality for small-scale farms. A smart system only helps if the parts are maintainable and the workflow is simple enough to keep using.',
          ],
        ),
        GuideSection(
          heading: 'Stay practical',
          bullets: [
            'Prefer simple sensor checks and clear operator actions over overly complex automation.',
            'Document wiring changes every time you move a sensor or relay channel.',
            'Train users to read the dashboard and understand what each alert really means.',
            'Track labor savings, fewer missed watering events, and better fruit quality when evaluating the project.',
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeaderButton(title: 'GUIDES'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: guides.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth > 900 ? 1.8 : 2.8,
                    ),
                    itemBuilder: (context, index) {
                      final guide = guides[index];
                      return GuideCard(article: guide);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideCard extends StatefulWidget {
  const GuideCard({super.key, required this.article});

  final GuideArticle article;

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: isHovered ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHovered ? const Color(0xFFB68C63) : Colors.grey.shade400,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered ? Colors.black26 : Colors.black12,
              blurRadius: isHovered ? 10 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GuideArticlePage(article: widget.article),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.menu_book, size: 40, color: Color(0xFFB68C63)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.article.subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideArticlePage extends StatelessWidget {
  const GuideArticlePage({super.key, required this.article});

  final GuideArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
        backgroundColor: const Color(0xFFB68C63),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            article.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.brown.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...article.sections.map(
            (section) => _GuideSectionCard(section: section),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.heading,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...section.paragraphs.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(paragraph, style: const TextStyle(height: 1.5)),
              ),
            ),
            ...section.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFFB68C63),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(bullet, style: const TextStyle(height: 1.45)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideArticle {
  const GuideArticle({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<GuideSection> sections;
}

class GuideSection {
  const GuideSection({
    required this.heading,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
}
