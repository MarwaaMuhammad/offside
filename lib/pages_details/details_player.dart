import 'package:flutter/material.dart';
import 'package:offside/models/player_model.dart';

class PlayerDetailsPage extends StatelessWidget {
  final Player player;

  const PlayerDetailsPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const Color darkBlue = Color(0xFF0D1956);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: darkBlue,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: const BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkBlue, Color(0xFF16246E)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Hero(
                          tag: 'player_img_${player.name}',
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: player.image != null && player.image!.isNotEmpty
                                ? AssetImage(player.image!)
                                : null,
                            child: player.image == null || player.image!.isEmpty
                                ? const Icon(Icons.person, size: 80, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          player.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          player.nationality,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Mini Info Cards =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoCard(context, "Position", player.position, Icons.sports_soccer, darkBlue),
                      _infoCard(context, "Age", "${player.age}", Icons.cake, darkBlue),
                      _infoCard(context, "Number", "#${player.number}", Icons.numbers, darkBlue),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    "Statistics",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ===== Stats Grid =====
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    children: [
                      _statBox(context, "Appearances", player.appearances, darkBlue),
                      _statBox(context, "Goals", player.goals, darkBlue),
                      _statBox(context, "Assists", player.assists, darkBlue),
                      _statBox(context, "Yellow Cards", player.yellowCards, Colors.amber),
                      _statBox(context, "Red Cards", player.redCards, Colors.red),
                      _statBox(context, "Minutes", player.minutesPlayed, darkBlue),
                      _statBox(context, "Shots", player.shots, darkBlue),
                      _statBox(context, "Passes", player.passes, darkBlue),
                      _statBox(context, "Played", player.played, darkBlue),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, String value, IconData icon, Color iconColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(BuildContext context, String title, int value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$value",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
