import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/presentation/state_management/contacts/contact_bloc.dart';
import 'package:stardom/presentation/widgets/buttons/primary_button.dart';
import 'package:stardom/presentation/widgets/buttons/text_button.dart';
import 'package:stardom/presentation/widgets/input_field/custom_input.dart';

class ContactBottomSheet extends StatefulWidget {
  const ContactBottomSheet({super.key});

  @override
  ContactBottomSheetState createState() => ContactBottomSheetState();
}

class ContactBottomSheetState extends State<ContactBottomSheet> {
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  void loadContacts() {
    BlocProvider.of<ContactBloc>(context).add(LoadContacts());
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return SizedBox(
      height: size.height * 0.65,
      child: BlocBuilder<ContactBloc, ContactState>(
        builder: (context, state) {
          if (state is ContactLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ContactLoaded) {
            if (state.contacts.isEmpty) {
              return buildNoContacts();
            }

            final filteredContact = state.contacts
                .where((contact) => contact.displayName
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomInput(
                  labelText: context.strings().search_contact,
                  labelInline: true,
                  showInlineLabelWhenFocused: true,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value ?? "";
                    });
                  },
                  suffix: const Icon(
                    Iconsax.search_normal_1,
                    size: SSizes.iconMd,
                    color: SColors.onSurfaceLight,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredContact.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContact[index];

                      return Column(
                        children: contact.phones.map((phone) {
                          var title = (contact.displayName.trim().isNotEmpty
                                  ? contact.displayName.trim()
                                  : '-')
                              .capitalizeWords();
                          var number = phone.number.formatPhoneNumber();
                          var subtitle =
                              '${number.startsWith('7') || number.startsWith('9') ? '+251 ' : ''}$number (${phone.label.name})';
                          ColorPair colors =
                              generateAvatarColorPair(contact.displayName);

                          return ListTile(
                            dense: true,
                            onTap: () {
                              context.pop(number);
                            },
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.only(
                                left: 4, top: 6, bottom: 6, right: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(SSizes.borderRadiusMd),
                            ),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: colors.background,
                              child: Text(
                                "${title.split(" ").first[0]}${title.split(" ").last[0]}",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colors.foreground,
                                    ),
                              ),
                            ),
                            title: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: SColors.onSurfaceDark),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: SColors.onSurface),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is ContactError) {
            return buildNoContacts(
                message: state.message,
                withOpenSettings: state.shouldOpenSettings);
          }
          return buildNoContacts(withReload: true);
        },
      ),
    );
  }

  Widget buildNoContacts({
    bool withReload = false,
    bool withOpenSettings = false,
    String? message,
  }) {
    var size = MediaQuery.sizeOf(context);
    var minSize = min(size.width, size.height);

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: SColors.onSurfaceLightest,
          child: Icon(Iconsax.clipboard, color: SColors.onSurfaceLight),
        ),
        if (message != null)
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Text(
            context.strings().no_contacts,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (withReload)
          STextButton(
              text: context.strings().reload_contacts,
              enabled: true,
              onPressed: () {
                loadContacts();
              },
              analyticsButtonName: 'reload_contact'),
        if (withOpenSettings)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: minSize * 0.15),
            child: PrimaryButton(
                text: context.strings().open_settings,
                enabled: true,
                onPressed: () async {
                  await openAppSettings();
                  context.pop();
                },
                analyticsButtonName: 'open_app_settings'),
          ),
      ],
    ));
  }
}

class ColorPair {
  final Color background;
  final Color foreground;

  ColorPair({required this.background, required this.foreground});
}

ColorPair generateAvatarColorPair([String? seed]) {
  final random = seed != null
      ? Random(seed.codeUnits.fold(0, (a, b) => a! + b))
      : Random();

  final double hue = random.nextDouble() * 360;
  const double saturation = 0.4; // pastel feel
  const double lightness = 0.85; // light background

  final Color bgColor =
      HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  const Color fgColor = Colors.black87; // readable on light backgrounds

  return ColorPair(background: bgColor, foreground: fgColor);
}
