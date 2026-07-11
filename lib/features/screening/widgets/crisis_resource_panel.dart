import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/help_resources_repository.dart';
import '../../../domain/models/professional_resource.dart';

Future<void> launchHelplinePhone(BuildContext context, String phone) async {
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

Future<void> launchHelplineUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class CrisisResourcePanel extends ConsumerWidget {
  const CrisisResourcePanel({
    super.key,
    this.resourceIds,
    this.compact = false,
  });

  /// When null, shows default crisis resources (samaritans, gamcare, nhs-111).
  final List<String>? resourceIds;
  final bool compact;

  static const defaultCrisisIds = ['samaritans', 'gamcare', 'nhs-111'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(helpResourcesProvider);

    return resourcesAsync.when(
      data: (all) {
        final ids = resourceIds ?? defaultCrisisIds;
        final resources = ids
            .map((id) => all.where((r) => r.id == id).firstOrNull)
            .whereType<ProfessionalResource>()
            .toList();

        if (resources.isEmpty) {
          return const ErrorBanner(message: 'could not load helpline numbers');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final resource in resources) ...[
              if (compact)
                _CompactResourceTile(resource: resource)
              else
                _CrisisResourceCard(resource: resource),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorBanner(message: 'could not load help resources'),
    );
  }
}

class _CrisisResourceCard extends StatelessWidget {
  const _CrisisResourceCard({required this.resource});

  final ProfessionalResource resource;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency_outlined, color: AppTheme.granola),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resource.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (resource.available24_7)
                const LowercaseText(
                  '24/7',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.sageDeep,
                  ),
                ),
            ],
          ),
          if (resource.subtitle != null) ...[
            const SizedBox(height: 4),
            LowercaseText(
              resource.subtitle!,
              style: const TextStyle(fontSize: 12, color: AppTheme.inkPlumSoft),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            resource.description,
            style: const TextStyle(fontSize: 13, color: AppTheme.inkPlumSoft),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (resource.phone != null)
                FilledButton.icon(
                  onPressed: () =>
                      launchHelplinePhone(context, resource.phone!),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: LowercaseText('call ${resource.phone}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.granola,
                  ),
                ),
              if (resource.url != null)
                OutlinedButton.icon(
                  onPressed: () => launchHelplineUrl(context, resource.url!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const LowercaseText('website'),
                ),
              if (resource.internalRoute != null)
                OutlinedButton.icon(
                  onPressed: () => context.push(resource.internalRoute!),
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

class _CompactResourceTile extends StatelessWidget {
  const _CompactResourceTile({required this.resource});

  final ProfessionalResource resource;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.phone_in_talk_outlined, color: AppTheme.granola),
        title: Text(resource.name),
        subtitle: resource.phone != null ? Text(resource.phone!) : null,
        trailing: resource.phone != null
            ? FilledButton(
                onPressed: () => launchHelplinePhone(context, resource.phone!),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.granola),
                child: const LowercaseText('call'),
              )
            : null,
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
