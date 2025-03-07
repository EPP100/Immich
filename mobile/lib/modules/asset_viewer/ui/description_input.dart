import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/modules/asset_viewer/providers/asset_description.provider.dart';
import 'package:immich_mobile/shared/models/asset.dart';
import 'package:immich_mobile/shared/ui/immich_toast.dart';
import 'package:logging/logging.dart';
import 'package:immich_mobile/shared/models/store.dart' as store;

class DescriptionInput extends HookConsumerWidget {
  DescriptionInput({
    super.key,
    required this.asset,
  });

  final Asset asset;
  final Logger _log = Logger('DescriptionInput');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final isFocus = useState(false);
    final isTextEmpty = useState(controller.text.isEmpty);
    final descriptionProvider = ref.watch(assetDescriptionProvider(asset).notifier);
    final description = ref.watch(assetDescriptionProvider(asset));
    final owner = store.Store.get(store.StoreKey.currentUser);
    final hasError = useState(false);

    controller.text = description;

    submitDescription(String description) async {
      hasError.value = false;
      try {
        await descriptionProvider.setDescription(
          description,
        );
      } catch (error, stack) {
        hasError.value = true;
        _log.severe("Error updating description $error", error, stack);
        ImmichToast.show(
          context: context,
          msg: "description_input_submit_error".tr(),
          toastType: ToastType.error,
        );
      }
    }

    Widget? suffixIcon;
    if (hasError.value) {
      suffixIcon = const Icon(Icons.warning_outlined);
    } else if (!isTextEmpty.value && isFocus.value) {
      suffixIcon = IconButton(
        onPressed: () {
          controller.clear();
          isTextEmpty.value = true;
        },
        icon: Icon(
          Icons.cancel_rounded,
          color: Colors.grey[500],
        ),
        splashRadius: 10,
      );
    }

    return TextField(
      enabled: owner.isarId == asset.ownerId,
      focusNode: focusNode,
      onTap: () => isFocus.value = true,
      onChanged: (value) {
        isTextEmpty.value = false;
      },
      onTapOutside: (a) async {
        isFocus.value = false;
        focusNode.unfocus();

        if (description != controller.text) {
          await submitDescription(controller.text);
        }
      },
      autofocus: false,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      controller: controller,
      style: const TextStyle(
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'description_input_hint_text'.tr(),
        border: InputBorder.none,
        hintStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
          color: textColor.withOpacity(0.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
