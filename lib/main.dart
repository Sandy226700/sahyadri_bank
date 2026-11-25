import 'package:flutter/material.dart';
import 'api_service.dart';
import 'config.dart';

void main() {
  runApp(const SahyadriBankApp());
}

class SahyadriBankApp extends StatelessWidget {
  const SahyadriBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.bankName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F3D68)),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _isOpsMode = false;
  int _titleTapCount = 0;
  DateTime? _lastTapTime;

  String _serverEnv = AppConfig.appEnv;
  bool _isHealthy = false;

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    try {
      final health = await ApiService.fetchHealth();
      if (!mounted) return;
      setState(() {
        _serverEnv = health['environment'] ?? AppConfig.appEnv;
        _isHealthy = health['status'] == 'healthy';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isHealthy = false);
    }
  }

  void _handleTitleTap() {
    if (_isOpsMode) return;

    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    _lastTapTime = now;

    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      _showDeveloperLoginDialog();
    }
  }

  void _showDeveloperLoginDialog() {
    final userController = TextEditingController();
    final passController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF0F3D68)),
                  SizedBox(width: 8),
                  Text('Developer Ops Access'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter data engineering credentials to unlock environment telemetry and ingestion audit logs.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'Developer ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Passcode',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (userController.text.trim() == AppConfig.devUsername &&
                        passController.text == AppConfig.devPassword) {
                      Navigator.pop(ctx);
                      _checkServerHealth();
                      setState(() => _isOpsMode = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Developer Ops Mode Unlocked')),
                      );
                    } else {
                      setDialogState(() {
                        errorText = 'Invalid developer credentials';
                      });
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _lockOpsMode() {
    setState(() {
      _isOpsMode = false;
      _selectedIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched back to Customer Banking View')),
    );
  }

  Color _envColor(String env) {
    switch (env.toUpperCase()) {
      case 'PROD':
        return Colors.red.shade700;
      case 'TEST':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final opsScreens = [
      BankingLedgerTab(isOpsMode: _isOpsMode),
      const BranchSummaryTab(),
      const PipelineAuditTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance, color: Color(0xFF0F3D68)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppConfig.bankName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_isOpsMode)
            IconButton(
              tooltip: 'Developer Ops Login',
              icon: const Icon(Icons.lock_outline, size: 20, color: Colors.grey),
              onPressed: _showDeveloperLoginDialog,
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _envColor(_serverEnv),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isHealthy ? Icons.cloud_done : Icons.cloud_off,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _serverEnv,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Exit Ops Mode',
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _lockOpsMode,
            ),
          ],
        ],
      ),
      body: _isOpsMode
          ? opsScreens[_selectedIndex]
          : BankingLedgerTab(isOpsMode: false),
      bottomNavigationBar: _isOpsMode
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) {
                setState(() => _selectedIndex = idx);
                _checkServerHealth();
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
                NavigationDestination(icon: Icon(Icons.store), label: 'Branches'),
                NavigationDestination(icon: Icon(Icons.fact_check), label: 'Audit Ops'),
              ],
            )
          : null,
    );
  }
}

class BankingLedgerTab extends StatefulWidget {
  final bool isOpsMode;
  const BankingLedgerTab({super.key, required this.isOpsMode});

  @override
  State<BankingLedgerTab> createState() => _BankingLedgerTabState();
}

class _BankingLedgerTabState extends State<BankingLedgerTab> {
  String _selectedFormat = 'ALL';
  final List<String> _formats = ['ALL', 'PDF', 'CSV', 'JSON', 'XLSX', 'TXT'];

  Future<Map<String, dynamic>> _loadData() async {
    final activeFilter = widget.isOpsMode ? _selectedFormat : 'ALL';
    final accounts = await ApiService.fetchAccounts();
    final txns = await ApiService.fetchTransactions(sourceFormat: activeFilter);
    return {'accounts': accounts, 'txns': txns};
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.isOpsMode
                      ? 'API Error: ${snapshot.error}'
                      : 'Unable to load account details right now. Pull down to refresh.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final accounts = snapshot.data!['accounts'] as List<dynamic>;
          final txns = snapshot.data!['txns'] as List<dynamic>;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text(
                'Your Accounts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  itemBuilder: (context, i) {
                    final acc = accounts[i];
                    return Card(
                      elevation: 2,
                      color: const Color(0xFF0F3D68),
                      margin: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Savings A/C ••••${acc['account_id']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              '₹ ${acc['net_balance'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'In: ₹${acc['total_credits']}  |  Out: ₹${acc['total_debits']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.isOpsMode ? 'Unified Ledger (Source Filter)' : 'Recent Transactions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (widget.isOpsMode) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: _formats.map((fmt) {
                    return ChoiceChip(
                      label: Text(fmt),
                      selected: _selectedFormat == fmt,
                      onSelected: (_) => setState(() => _selectedFormat = fmt),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              ...txns.map((t) {
                final isCredit = t['transaction_type'].toString().toUpperCase() == 'CREDIT';
                final subtitleText = widget.isOpsMode
                    ? '${t['transaction_date']} • Branch #${t['branch_id']} • [${t['source_format']}]'
                    : '${t['transaction_date']} • Branch #${t['branch_id']}';

                return Card(
                  elevation: 0.5,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        isCredit ? Icons.south_west : Icons.north_east,
                        color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      widget.isOpsMode
                          ? '${t['transaction_id']} • A/C #${t['account_id']}'
                          : 'Ref: ${t['transaction_id']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(subtitleText),
                    trailing: Text(
                      '${isCredit ? '+' : '-'} ₹${t['amount']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class BranchSummaryTab extends StatefulWidget {
  const BranchSummaryTab({super.key});

  @override
  State<BranchSummaryTab> createState() => _BranchSummaryTabState();
}

class _BranchSummaryTabState extends State<BranchSummaryTab> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<dynamic>>(
        future: ApiService.fetchBranchSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final rows = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront, color: Color(0xFF0F3D68)),
                  title: Text(
                    'Branch #${r['branch_id']}  (${r['transaction_date']})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Txns: ${r['transaction_count']} | Cr: ₹${r['total_credit']} | Dr: ₹${r['total_debit']}',
                  ),
                  trailing: Text(
                    '₹${r['total_volume']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PipelineAuditTab extends StatefulWidget {
  const PipelineAuditTab({super.key});

  @override
  State<PipelineAuditTab> createState() => _PipelineAuditTabState();
}

class _PipelineAuditTabState extends State<PipelineAuditTab> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<dynamic>>(
        future: ApiService.fetchAuditLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final logs = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              final isSuccess = log['status'].toString().toUpperCase() == 'SUCCESS';
              return Card(
                child: ListTile(
                  leading: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    '${log['source_file']} → ${log['target_table']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Read: ${log['rows_read']} | Loaded: ${log['rows_loaded']}\n'
                    '${log['run_ts']} • ${log['message'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(
                      log['status'],
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
