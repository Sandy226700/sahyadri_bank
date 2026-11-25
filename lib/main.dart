import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

void main() {
  runApp(const SahyadriBankApp());
}

class SahyadriBankApp extends StatelessWidget {
  const SahyadriBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahyadri Digital Bank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const BankHomeScreen(),
    );
  }
}

class BankHomeScreen extends StatefulWidget {
  const BankHomeScreen({super.key});

  @override
  State<BankHomeScreen> createState() => _BankHomeScreenState();
}

class _BankHomeScreenState extends State<BankHomeScreen> {
  bool _isDeveloperMode = false;
  int _devTabIndex = 0;
  int _titleTapCount = 0;
  DateTime? _lastTapTime;

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _accounts = [];
  List<dynamic> _transactions = [];
  List<dynamic> _branches = [];
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<List<dynamic>> _getEndpoint(String path) async {
    final uri = Uri.parse('${AppConfig.apiUrl}$path');
    final response = await http.get(uri).timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException(
            'Server wake-up timed out (60s). Pull down to retry.',
          ),
        );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} on $path: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('data')) {
      return decoded['data'] as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> _getEndpointSafe(String path) async {
    try {
      return await _getEndpoint(path);
    } catch (_) {
      return [];
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _getEndpoint('/accounts');
      final transactions = await _getEndpoint('/transactions');
      final branches = await _getEndpointSafe('/branches');
      final auditLogs = await _getEndpointSafe('/audit');

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _transactions = transactions;
        _branches = branches;
        _auditLogs = auditLogs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    _lastTapTime = now;

    if (_titleTapCount >= 3) {
      _titleTapCount = 0;
      if (_isDeveloperMode) {
        setState(() => _isDeveloperMode = false);
      } else {
        _showDeveloperLoginDialog();
      }
    }
  }

  void _showDeveloperLoginDialog() {
    final userController = TextEditingController();
    final passController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Developer / Ops Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 10),
                Text(
                  dialogError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final enteredUser = userController.text.trim();
                final enteredPass = passController.text.trim();
                if (enteredUser == AppConfig.devUser &&
                    enteredPass == AppConfig.devPass) {
                  Navigator.pop(ctx);
                  setState(() {
                    _isDeveloperMode = true;
                    _devTabIndex = 0;
                  });
                } else {
                  setDialogState(() {
                    dialogError = 'Invalid developer credentials';
                  });
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }

  Color _envBadgeColor() {
    switch (AppConfig.appEnv.toUpperCase()) {
      case 'PROD':
        return Colors.red.shade700;
      case 'TEST':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        title: GestureDetector(
          onTap: _handleTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              const Icon(Icons.account_balance, color: Color(0xFF0D47A1)),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Sahyadri Digital Bank',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF1A1C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_isDeveloperMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _envBadgeColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _errorMessage == null ? Icons.cloud_done : Icons.cloud_off,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppConfig.appEnv.toUpperCase(),
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
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Exit Ops Mode',
              onPressed: () => setState(() => _isDeveloperMode = false),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.lock_outline, color: Colors.grey),
              tooltip: 'Ops Login',
              onPressed: _showDeveloperLoginDialog,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        child: _isDeveloperMode ? _buildDeveloperView() : _buildCustomerView(),
      ),
      bottomNavigationBar: _isDeveloperMode
          ? NavigationBar(
              selectedIndex: _devTabIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _devTabIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'Accounts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Branches',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check),
                  label: 'Audit Ops',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildScrollableMessage(String message, {bool isError = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.wifi_off_rounded : Icons.inbox_outlined,
                  size: 48,
                  color: isError ? Colors.redAccent : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isError ? Colors.red.shade800 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _fetchAllData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Now'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildScrollableMessage(
        'Unable to load account details right now. Pull down to refresh.',
      );
    }
    if (_accounts.isEmpty && _transactions.isEmpty) {
      return _buildScrollableMessage(
        'No active accounts or transactions found. Pull down to refresh.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Your Accounts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._accounts.map((acc) {
          final name = acc['customer_name'] ?? acc['account_holder'] ?? 'Account';
          final accNo = acc['account_id'] ?? acc['account_number'] ?? '';
          final balance = acc['net_balance'] ?? acc['balance'] ?? 0;
          return Card(
            elevation: 0,
            color: const Color(0xFF0D47A1),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ $balance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A/C: $accNo',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._transactions.take(30).map((txn) {
          final type = (txn['txn_type'] ?? txn['type'] ?? '').toString().toUpperCase();
          final isCredit = type == 'CREDIT' || type == 'CR';
          final amount = txn['amount'] ?? 0;
          final desc = txn['description'] ?? txn['merchant'] ?? txn['account_id'] ?? 'Transaction';
          final date = txn['txn_date'] ?? txn['transaction_date'] ?? '';
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isCredit ? Colors.green.shade50 : Colors.red.shade50,
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
              title: Text(
                desc.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(date.toString(), style: const TextStyle(fontSize: 12)),
              trailing: Text(
                '${isCredit ? '+' : '-'} ₹$amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeveloperView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildScrollableMessage(
        'API Error (${AppConfig.apiUrl}):\n\n$_errorMessage',
        isError: true,
      );
    }

    if (_devTabIndex == 0) {
      if (_accounts.isEmpty) {
        return _buildScrollableMessage('No account rows returned from /accounts.');
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _accounts.length,
        itemBuilder: (_, i) {
          final item = _accounts[i];
          return Card(
            color: Colors.white,
            child: ListTile(
              title: Text('${item['account_id'] ?? 'Account'} • ${item['customer_name'] ?? ''}'),
              subtitle: Text(item.toString(), style: const TextStyle(fontSize: 12)),
            ),
          );
        },
      );
    }

    if (_devTabIndex == 1) {
      if (_branches.isEmpty) {
        return _buildScrollableMessage('No branch summary rows returned from /branches.');
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _branches.length,
        itemBuilder: (_, i) {
          final b = _branches[i];
          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.storefront, color: Color(0xFF0D47A1)),
              title: Text('${b['branch_code'] ?? b['branch_name'] ?? 'Branch'}'),
              subtitle: Text(b.toString(), style: const TextStyle(fontSize: 12)),
            ),
          );
        },
      );
    }

    if (_auditLogs.isEmpty) {
      return _buildScrollableMessage('No ingestion audit rows returned from /audit.');
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _auditLogs.length,
      itemBuilder: (_, i) {
        final log = _auditLogs[i];
        final status = (log['status'] ?? 'UNKNOWN').toString().toUpperCase();
        final isSuccess = status == 'SUCCESS';
        return Card(
          color: Colors.white,
          child: ListTile(
            leading: Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            title: Text(
              '${log['source_file'] ?? log['file_name'] ?? 'Batch'} ($status)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(log.toString(), style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}