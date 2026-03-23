import 'package:flutter/material.dart';
import '../missions/daily_mission_manager.dart';
import '../economy/coin_manager.dart';

class MissionScreen extends StatefulWidget {
  final DailyMissionManager missionManager;
  final CoinManager coinManager;

  const MissionScreen({
    super.key,
    required this.missionManager,
    required this.coinManager,
  });

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text(
          'Daily Missions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ListenableBuilder(
              listenable: widget.coinManager,
              builder: (_, __) => Row(
                children: [
                  const Text('💰', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.coinManager.balance}',
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.missionManager,
        builder: (ctx, __) {
          final missions = widget.missionManager.missions;
          return Column(
            children: [
              // 총 달성 미션 수
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('📋 Total Completed: ',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text(
                      '${widget.missionManager.totalMissionsCompleted}',
                      style: const TextStyle(
                          color: Color(0xFFFF8A65),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 미션 목록
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: missions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _MissionCard(
                    mission: missions[i],
                    missionManager: widget.missionManager,
                    coinManager: widget.coinManager,
                    index: i,
                    onStateChanged: () => setState(() {}),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMission mission;
  final DailyMissionManager missionManager;
  final CoinManager coinManager;
  final int index;
  final VoidCallback onStateChanged;

  const _MissionCard({
    required this.mission,
    required this.missionManager,
    required this.coinManager,
    required this.index,
    required this.onStateChanged,
  });

  Color get _diffColor {
    switch (mission.difficulty) {
      case MissionDifficulty.easy: return const Color(0xFF69FF47);
      case MissionDifficulty.medium: return const Color(0xFFFFD600);
      case MissionDifficulty.hard: return const Color(0xFFFF5252);
    }
  }

  String get _diffLabel {
    switch (mission.difficulty) {
      case MissionDifficulty.easy: return 'EASY';
      case MissionDifficulty.medium: return 'MED';
      case MissionDifficulty.hard: return 'HARD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = mission.isCompleted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: completed ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? _diffColor.withValues(alpha: 0.6)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 난이도 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_diffLabel,
                    style: TextStyle(
                        color: _diffColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.description,
                  style: TextStyle(
                    color: completed ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 보상
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${mission.rewardCoins}💰',
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 진행도 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: mission.progressFraction,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? _diffColor : _diffColor.withValues(alpha: 0.5),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mission.currentProgress} / ${mission.targetValue}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              if (!completed)
                GestureDetector(
                  onTap: () async {
                    // 리롤: 15코인 소비
                    final ok = await coinManager.spend(15);
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough coins (15 needed)'),
                            backgroundColor: Color(0xFF1A1A2E),
                          ),
                        );
                      }
                      return;
                    }
                    await missionManager.rerollMission(index);
                    onStateChanged();
                  },
                  child: const Text(
                    '🔄 Reroll (15💰)',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              if (completed)
                const Text(
                  '✅ Completed!',
                  style: TextStyle(
                      color: Color(0xFF69FF47),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
