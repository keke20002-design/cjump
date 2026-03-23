import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../skins/skin_model.dart';
import '../skins/skin_catalog.dart';
import '../skins/skin_renderer.dart';
import '../economy/coin_manager.dart';
import '../economy/persistence_manager.dart';
import '../ads/ad_manager.dart';

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
  String _previewId = 'green_core'; // 미리보기 (잠긴 스킨도 가능)
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _skins = buildSkinCatalog();
    _selectedId = PersistenceManager.instance.selectedSkin;
    _previewId = _selectedId;
    if (!kIsWeb) {
      _bannerAd = AdManager.instance.createBanner(
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _bannerLoaded = true);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bannerAd?.dispose();
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
            content: Text('Not enough coins (${skin.unlockValue} coins needed)'),
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

  void _onPreview(CharacterSkin skin) {
    setState(() => _previewId = skin.id);
  }

  Future<void> _onSelect(CharacterSkin skin) async {
    if (!skin.isUnlocked) return;
    setState(() {
      _selectedId = skin.id;
      _previewId = skin.id;
    });
    await PersistenceManager.instance.setSelectedSkin(skin.id);
  }

  Future<void> _onWatchAd(CharacterSkin skin) async {
    AdManager.instance.showSkinRewarded(
      onRewarded: () async {
        final pm = PersistenceManager.instance;
        final unlocked = List<String>.from(pm.unlockedSkins)..add(skin.id);
        await pm.setUnlockedSkins(unlocked);
        if (mounted) setState(() => skin.isUnlocked = true);
      },
      onDone: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _skins.firstWhere((s) => s.id == _previewId,
        orElse: () => _skins.first);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Skin Shop',
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
            Tab(text: 'Basic'),
            Tab(text: 'Effect'),
            Tab(text: 'Theme'),
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
                  previewId: _previewId,
                  onPreview: _onPreview,
                  onSelect: _onSelect,
                  onPurchase: _onPurchase,
                  onWatchAd: _onWatchAd,
                ),
                _SkinGrid(
                  skins: _filtered(SkinCategory.effect),
                  selectedId: _selectedId,
                  previewId: _previewId,
                  onPreview: _onPreview,
                  onSelect: _onSelect,
                  onPurchase: _onPurchase,
                  onWatchAd: _onWatchAd,
                ),
                _SkinGrid(
                  skins: _filtered(SkinCategory.theme),
                  selectedId: _selectedId,
                  previewId: _previewId,
                  onPreview: _onPreview,
                  onSelect: _onSelect,
                  onPurchase: _onPurchase,
                  onWatchAd: _onWatchAd,
                ),
              ],
            ),
          ),
          if (_bannerLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

// ── 선택된 스킨 미리보기 (애니메이션) ─────────────────────────────────────────

class _SelectedPreview extends StatefulWidget {
  final CharacterSkin skin;
  const _SelectedPreview({required this.skin});

  @override
  State<_SelectedPreview> createState() => _SelectedPreviewState();
}

class _SelectedPreviewState extends State<_SelectedPreview>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late SkinRenderer _renderer;

  @override
  void initState() {
    super.initState();
    _renderer = SkinRenderer(widget.skin);
    _ticker = createTicker((d) {
      final dt = d.inMicroseconds / 1e6 * 0.35;
      _renderer.update(dt);
      setState(() {});
    })..start();
  }

  @override
  void didUpdateWidget(_SelectedPreview old) {
    super.didUpdateWidget(old);
    if (old.skin.id != widget.skin.id) {
      _renderer = SkinRenderer(widget.skin);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final accentColor = skin.glowColor ?? skin.coreColor;

    return Container(
      height: 110,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // 애니메이션 캐릭터
          SizedBox(
            width: 100,
            height: 110,
            child: CustomPaint(
              painter: _SkinPreviewPainter(renderer: _renderer),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
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
                      '✨ Trail: ${skin.trailEffect.name}',
                      style: const TextStyle(
                          color: Color(0xFFFFD600), fontSize: 10),
                    ),
                  ),
                if (!skin.isUnlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🔒 LOCKED',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _SkinPreviewPainter extends CustomPainter {
  final SkinRenderer renderer;

  _SkinPreviewPainter({required this.renderer});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // 위아래 둥둥 떠다니는 효과
    final cy = size.height / 2;
    renderer.draw(canvas, cx, cy, true);
  }

  @override
  bool shouldRepaint(_SkinPreviewPainter old) => true;
}

// ── 스킨 그리드 ──────────────────────────────────────────────────────────────

class _SkinGrid extends StatelessWidget {
  final List<CharacterSkin> skins;
  final String selectedId;
  final String previewId;
  final void Function(CharacterSkin) onPreview;
  final Future<void> Function(CharacterSkin) onSelect;
  final Future<void> Function(CharacterSkin) onPurchase;
  final Future<void> Function(CharacterSkin) onWatchAd;

  const _SkinGrid({
    required this.skins,
    required this.selectedId,
    required this.previewId,
    required this.onPreview,
    required this.onSelect,
    required this.onPurchase,
    required this.onWatchAd,
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
        isPreviewing: skins[i].id == previewId,
        onPreview: () => onPreview(skins[i]),
        onSelect: () => onSelect(skins[i]),
        onPurchase: () => onPurchase(skins[i]),
        onWatchAd: () => onWatchAd(skins[i]),
      ),
    );
  }
}

// ── 스킨 카드 ─────────────────────────────────────────────────────────────────

class _SkinCard extends StatelessWidget {
  final CharacterSkin skin;
  final bool isSelected;
  final bool isPreviewing;
  final VoidCallback onPreview;
  final VoidCallback onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onWatchAd;

  const _SkinCard({
    required this.skin,
    required this.isSelected,
    required this.isPreviewing,
    required this.onPreview,
    required this.onSelect,
    required this.onPurchase,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !skin.isUnlocked;
    final accentColor = skin.glowColor ?? skin.coreColor;

    return GestureDetector(
      onTap: isLocked ? onPreview : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isLocked ? 0.03 : 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : isPreviewing
                    ? accentColor.withValues(alpha: 0.6)
                    : isLocked
                        ? Colors.white10
                        : accentColor.withValues(alpha: 0.3),
            width: isSelected || isPreviewing ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 12)]
              : isPreviewing
                  ? [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 8)]
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
                  'Select',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            else if (isLocked && skin.unlockType == UnlockType.adUnlock)
              GestureDetector(
                onTap: onWatchAd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFCE93D8).withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline_rounded,
                          color: Color(0xFFCE93D8), size: 13),
                      SizedBox(width: 4),
                      Text(
                        'WATCH AD',
                        style: TextStyle(
                            color: Color(0xFFCE93D8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
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
