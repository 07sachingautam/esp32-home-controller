import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bluetooth_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/master_control_card.dart';
import '../widgets/relay_card.dart';
import 'connection_screen.dart';

/// ============================================================================
/// HOME SCREEN
/// ============================================================================
/// The main dashboard: connection header, 4 relay cards in a responsive
/// grid, and the master control card. Listens to [BluetoothProvider] for
/// live status updates streamed from the ESP32.
/// ============================================================================
class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _relayTitles = [
    'Relay 1',
    'Relay 2',
    'Relay 3',
    'Relay 4',
  ];

  static const _relayIcons = [
    Icons.lightbulb_rounded,
    Icons.ac_unit_rounded,
    Icons.tv_rounded,
    Icons.power_rounded,
  ];

  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    // Listen for transient success/error messages and show them as SnackBars.
    final provider = context.read<BluetoothProvider>();
    _messageSub = provider.messages.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.text),
          backgroundColor: msg.isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      );
    });

    // Attempt a silent auto-reconnect to the last used device on launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.tryAutoReconnect();
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BluetoothProvider>();
    final status = provider.relayStatus;
    final isConnected = provider.isConnected;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (isConnected) {
              // Nothing to actively refresh — status streams automatically —
              // but this gives the user a satisfying gesture affordance.
              await Future.delayed(const Duration(milliseconds: 400));
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    ConnectionStatusBar(
                      state: provider.connectionState,
                      deviceName: provider.connectedDevice?.name,
                      onTapChangeDevice: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConnectionScreen(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            onPressed: widget.onToggleTheme,
                            icon: Icon(
                              widget.isDarkMode
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                            ),
                            tooltip: 'Toggle theme',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final isOn = status.relaysOn[index];
                      return RelayCard(
                        title: _relayTitles[index],
                        icon: _relayIcons[index],
                        isOn: isOn,
                        isEnabled: isConnected && !status.isMasterOff,
                        onChanged: (value) =>
                            provider.toggleRelay(index, value),
                      );
                    },
                    childCount: 4,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: MasterControlCard(
                    isMasterOff: status.isMasterOff,
                    isEnabled: isConnected,
                    onAllOff: provider.allOff,
                    onNormalMode: provider.normalMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
