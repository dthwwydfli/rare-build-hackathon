import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/help_resources_repository.dart';
import '../../domain/models/professional_resource.dart';

class GetHelpContent extends ConsumerWidget {
  const GetHelpContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(helpResourcesProvider);

    return resourcesAsync.when(
      data: (resources) {
        final grouped = <HelpResourceCategory, List<ProfessionalResource>>{};
        for (final resource in resources) {
          grouped.putIfAbsent(resource.category, () => []).add(resource);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const LowercaseText(
              'professional support when you need it',
              style: TextStyle(
                color: AppTheme.inkPlumSoft,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            for (final category in HelpResourceCategory.values) ...[
              if (grouped[category]?.isNotEmpty ?? false) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: LowercaseText(
                    category.sectionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...grouped[category]!.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HelpResourceCard(resource: resource),
                  ),
                ),
              ],
            ],
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorBanner(
        message: 'could not load help resources',
      ),
    );
  }
}

class _HelpResourceCard extends StatelessWidget {
  const _HelpResourceCard({required this.resource});

  final ProfessionalResource resource;

  Future<void> _call(BuildContext context) async {
    final phone = resource.phone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        showAppSnackBar(context, 'number copied');
      }
    }
  }

  Future<void> _openUrl(BuildContext context) async {
    final url = resource.url;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _email(BuildContext context) async {
    final email = resource.email;
    if (email == null) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openInternal(BuildContext context) {
    final route = resource.internalRoute;
    if (route != null) context.push(route);
  }

  IconData get _icon => switch (resource.category) {
        HelpResourceCategory.crisis => Icons.emergency_outlined,
        HelpResourceCategory.debt => Icons.account_balance_wallet_outlined,
        HelpResourceCategory.licensed => Icons.psychology_outlined,
        HelpResourceCategory.coach => Icons.support_agent_outlined,
        HelpResourceCategory.tool => Icons.shield_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.lavenderLight,
                child: Icon(_icon, color: AppTheme.lavenderDeep, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resource.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (resource.available24_7)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.sageDeep.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const LowercaseText(
                              '24/7',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.sageDeep,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (resource.subtitle != null) ...[
                      const SizedBox(height: 4),
                      LowercaseText(
                        resource.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.inkPlumSoft,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      resource.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.inkPlumSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (resource.phone != null)
                OutlinedButton.icon(
                  onPressed: () => _call(context),
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const LowercaseText('call'),
                ),
              if (resource.url != null)
                OutlinedButton.icon(
                  onPressed: () => _openUrl(context),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const LowercaseText('website'),
                ),
              if (resource.email != null)
                OutlinedButton.icon(
                  onPressed: () => _email(context),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const LowercaseText('email'),
                ),
              if (resource.internalRoute != null)
                FilledButton.icon(
                  onPressed: () => _openInternal(context),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const LowercaseText('open'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
