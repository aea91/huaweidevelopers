import 'package:flutter/material.dart';
import '../models/manager_definition.dart';
import '../services/firestore_service.dart';
import '../theme/app_chrome.dart';
import '../widgets/code_viewer.dart';

class ManagersScreen extends StatefulWidget {
  const ManagersScreen({super.key});

  @override
  State<ManagersScreen> createState() => _ManagersScreenState();
}

class _ManagersScreenState extends State<ManagersScreen> {
  final _firestoreService = FirestoreService();
  ManagerDefinition? selected;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppChrome.canvas,
      appBar: AppChrome.appBar(
        context: context,
        title: 'Managers',
        icon: Icons.manage_accounts_rounded,
      ),
      body: StreamBuilder<List<ManagerDefinition>>(
        stream: _firestoreService.getManagers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final managers = snapshot.data ?? [];
          if (managers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.manage_accounts,
                    size: 80,
                    color: Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No managers yet',
                    style: AppChrome.body(fontSize: 18, color: AppChrome.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add managers from the admin panel',
                    style: AppChrome.body(
                      fontSize: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            );
          }

          selected ??= managers.first;
          if (!managers.any((m) => m.id == selected!.id)) {
            selected = managers.first;
          }

          return isNarrow ? _buildNarrow(managers) : _buildWide(managers);
        },
      ),
    );
  }

  Widget _buildWide(List<ManagerDefinition> managers) {
    return Row(
      children: [
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Singleton managers',
                style: AppChrome.display(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a manager to preview its ArkTS implementation.',
                style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
              ),
              const SizedBox(height: 16),
              ...managers.map((m) => _managerTile(m)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected!.title,
                  style: AppChrome.body(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppChrome.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selected!.description,
                  style: AppChrome.body(fontSize: 14, color: AppChrome.muted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: CodeViewer(
                    code: selected!.code.trim(),
                    title: selected!.className,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(List<ManagerDefinition> managers) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...managers.map(
          (m) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.title,
                          style: AppChrome.body(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        m.fileName,
                        style: AppChrome.body(
                          fontSize: 12,
                          color: AppChrome.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.description,
                    style: AppChrome.body(fontSize: 13, color: AppChrome.muted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 380,
                    child: CodeViewer(code: m.code.trim(), title: m.className),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _managerTile(ManagerDefinition m) {
    final isSelected = selected?.id == m.id;
    return InkWell(
      onTap: () => setState(() => selected = m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppChrome.ink.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppChrome.ink.withOpacity(0.35)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.title,
                    style: AppChrome.body(
                      fontWeight: FontWeight.w700,
                      color: AppChrome.ink,
                    ),
                  ),
                ),
                Text(
                  m.fileName,
                  style: AppChrome.body(fontSize: 11, color: AppChrome.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              m.description,
              style: AppChrome.body(fontSize: 12, color: AppChrome.muted),
            ),
          ],
        ),
      ),
    );
  }
}
