import 'package:flutter/material.dart';
import '../skins/skin_model.dart';
import '../skins/skin_catalog.dart';
import '../economy/coin_manager.dart';
import '../economy/persistence_manager.dart';

class SkinShopScreen extends StatefulWidget {
  final CoinManager coinManager;

  const SkinShopScreen({super.key, required this.coinManager});

  @override
  State<SkinShopScreen> createState() => _SkinShopScreenState();
}

class _SkinShopScreenState extends State<SkinShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<CharacterSkin> _skins = [];
  String _selectedId = 'green_core';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _skins = buildSkinCatalog();
    _selectedId = PersistenceManager.instance.selectedSkin;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<CharacterSkin> _filtered(SkinCategory cat) =>
      _skins.where((s) => s.category == cat).toList();

  Future<void> _onPurchase(CharacterSkin skin) async {
    final ok = await widget.coinManager.spend(skin.unlockValue);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('코인이 부족합니다 (${skin.unlockValue}코인 필요)'),
            backgroundColor: const Color(0xFF1A1A2E),
          ),
        );
      }
      return;
    }
    final pm = PersistenceManager.instance;
    final unlocked = List<String>.from(pm.unlockedSkins)..add(skin.id);
    await pm.setUnlockedSkins(unlocked);
    setState(() {
      skin.isUnlocked = true;
    });
  }

  Future<void> _onSelect(CharacterSkin skin) async {
    if (!skin.isUnlocked) return;
    setState(() => _selectedId = skin.id);
    await PersistenceManager.instance.setSelectedSkin(skin.id);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _skins.firstWhere((s) => s.id == _selectedId,
        orElse: () => _skins.first);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('스킨 상점',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(_selectedId),
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
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF4A90D9),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: '기본형'),
            Tab(text: '이펙트형'),
            Tab(text: '테마형'),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 선택된 스킨 미리보기
          _SelectedPreview(skin: selected),
          // 그리드
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _SkinGrid(
                  skins: _filtered(SkinCategory.basic),
                  selectedId: _selectedId,
                  onSelect: _onSelect,
                  onPurchase: _onPurchase,
                ),
                _SkinGrid(
                  skins: _filtered(SkinCategory.effect),
                  selectedId: _selectedId,
                  onSelect: _onSelect,
                  onPurchase: _onPurchase,
                ),
                _SkinGrid(
                  skins: _filtered(SkinCategory.theme),
                  selectedId: _selectedId,
                  onSelect: _onSelect,
                  onPurchase: _onPurchase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 선택된 스킨 미리보기 ──────────────────────────────────────────────────────

class _SelectedPreview extends StatelessWidget {
  final CharacterSkin skin;
  const _SelectedPreview({required this.skin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (skin.glowColor ?? skin.coreColor).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          // 미리보기 원
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: skin.coreColor,
              boxShadow: [
                BoxShadow(
                  color: (skin.glowColor ?? skin.coreColor)
                      .withValues(alpha: 0.5),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                skin.displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                skin.unlockDescription,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              if (skin.trailEffect != TrailType.none)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '✨ 트레일: ${skin.trailEffect.name}',
                    style: const TextStyle(
                        color: Color(0xFFFFD600), fontSize: 10),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 스킨 그리드 ──────────────────────────────────────────────────────────────

class _SkinGrid extends StatelessWidget {
  final List<CharacterSkin> skins;
  final String selectedId;
  final Future<void> Function(CharacterSkin) onSelect;
  final Future<void> Function(CharacterSkin) onPurchase;

  const _SkinGrid({
    required this.skins,
    required this.selectedId,
    required this.onSelect,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: skins.length,
      itemBuilder: (ctx, i) => _SkinCard(
        skin: skins[i],
        isSelected: skins[i].id == selectedId,
        onSelect: () => onSelect(skins[i]),
        onPurchase: () => onPurchase(skins[i]),
      ),
    );
  }
}

// ── 스킨 카드 ─────────────────────────────────────────────────────────────────

class _SkinCard extends StatelessWidget {
  final CharacterSkin skin;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPurchase;

  const _SkinCard({
    required this.skin,
    required this.isSelected,
    required this.onSelect,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !skin.isUnlocked;
    final accentColor = skin.glowColor ?? skin.coreColor;

    return GestureDetector(
      onTap: isLocked ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isLocked ? 0.03 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : isLocked
                    ? Colors.white10
                    : accentColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 스킨 미리보기
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? Colors.grey.withValues(alpha: 0.2)
                        : skin.coreColor,
                    boxShadow: isLocked
                        ? null
                        : [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                  ),
                  child: isLocked
                      ? const Icon(Icons.lock_rounded,
                          color: Colors.white30, size: 28)
                      : null,
                ),
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              skin.displayName,
              style: TextStyle(
                color: isLocked ? Colors.white30 : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (!isLocked && !isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '선택',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            else if (isLocked && skin.unlockType == UnlockType.coin)
              GestureDetector(
                onTap: onPurchase,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${skin.unlockValue}💰',
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else if (isLocked)
              Text(
                skin.unlockDescription,
                style: const TextStyle(color: Colors.white24, fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
