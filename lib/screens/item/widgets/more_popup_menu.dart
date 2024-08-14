import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class MorePopupMenu extends StatelessWidget {
  const MorePopupMenu({
    required this.item,
    required this.isBlocked,
    required this.onLoginTapped,
    super.key,
  });

  final Item item;
  final bool isBlocked;
  final VoidCallback onLoginTapped;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoteCubit>(
      create: (BuildContext context) => VoteCubit(
        item: item,
        authBloc: context.read<AuthBloc>(),
      ),
      child: BlocConsumer<VoteCubit, VoteState>(
        listenWhen: (VoteState previous, VoteState current) {
          return previous.status != current.status;
        },
        listener: (BuildContext context, VoteState voteState) {
          if (voteState.status == VoteStatus.submitted) {
            context.showSnackBar(content: 'Vote submitted.');
          } else if (voteState.status == VoteStatus.canceled) {
            context.showSnackBar(content: 'Vote canceled.');
          } else if (voteState.status == VoteStatus.failure) {
            context.showErrorSnackBar();
          } else if (voteState.status ==
              VoteStatus.failureKarmaBelowThreshold) {
            context.showSnackBar(
              content: "You can't downvote because you are karmaly broke.",
            );
          } else if (voteState.status == VoteStatus.failureNotLoggedIn) {
            context.showSnackBar(
              content: 'Not logged in, no voting! (;｀O´)o',
              action: onLoginTapped,
              label: 'Log in',
            );
          } else if (voteState.status == VoteStatus.failureBeHumble) {
            context.showSnackBar(
              content: 'No voting on your own post! (;｀O´)o',
            );
          }

          context.pop(MenuAction.upvote);
        },
        builder: (BuildContext context, VoteState voteState) {
          final bool upvoted = voteState.vote == Vote.up;
          final bool downvoted = voteState.vote == Vote.down;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BlocProvider<UserCubit>(
                create: (BuildContext context) =>
                    UserCubit()..init(userId: item.by),
                child: BlocBuilder<UserCubit, UserState>(
                  builder: (BuildContext context, UserState state) {
                    return Semantics(
                      excludeSemantics: state.status == Status.inProgress,
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            AnimatedCrossFade(
                              alignment: Alignment.center,
                              duration: AppDurations.ms300,
                              crossFadeState: state.status.isLoading
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              firstChild: const Icon(
                                Icons.account_circle_outlined,
                              ),
                              secondChild: const Icon(
                                Icons.account_circle,
                              ),
                            ),
                          ],
                        ),
                        title: Text(item.by),
                        subtitle: Text(
                          state.user.description,
                        ),
                        onTap: () {
                          context.pop();
                          final double fontSize = context
                              .read<PreferenceCubit>()
                              .state
                              .fontSize
                              .fontSize;
                          showDialog<void>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              semanticLabel:
                                  '''About ${state.user.id}. ${state.user.about}''',
                              title: Text(
                                'About ${state.user.id}',
                              ),
                              content: state.user.about.isEmpty
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          'empty',
                                          style: TextStyle(
                                            color: Palette.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  : SelectableLinkify(
                                      text: HtmlUtil.parseHtml(
                                        state.user.about,
                                      ),
                                      style: TextStyle(
                                        fontSize: fontSize,
                                      ),
                                      linkStyle: TextStyle(
                                        fontSize: fontSize,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      onOpen: (LinkableElement link) =>
                                          LinkUtil.launch(
                                        link.url,
                                        context,
                                      ),
                                      semanticsLabel: state.user.about,
                                    ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    locator
                                        .get<AppReviewService>()
                                        .requestReview();
                                    context.pop();
                                    onSearchUserTapped(context);
                                  },
                                  child: const Text(
                                    'Search',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    locator
                                        .get<AppReviewService>()
                                        .requestReview();
                                    context.pop();
                                  },
                                  child: const Text(
                                    'Okay',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                leading: Icon(
                  FeatherIcons.chevronUp,
                  color: upvoted ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  upvoted ? 'Upvoted' : 'Upvote',
                  style: upvoted
                      ? TextStyle(color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                subtitle: item is Story ? Text(item.score.toString()) : null,
                onTap: context.read<VoteCubit>().upvote,
              ),
              ListTile(
                leading: Icon(
                  FeatherIcons.chevronDown,
                  color:
                      downvoted ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  downvoted ? 'Downvoted' : 'Downvote',
                  style: downvoted
                      ? TextStyle(color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                onTap: context.read<VoteCubit>().downvote,
              ),
              BlocBuilder<FavCubit, FavState>(
                builder: (BuildContext context, FavState state) {
                  final bool isFav = state.favIds.contains(item.id);
                  return ListTile(
                    leading: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color:
                          isFav ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      isFav ? 'Unfavorite' : 'Favorite',
                    ),
                    onTap: () => context.pop(MenuAction.fav),
                  );
                },
              ),
              ListTile(
                leading: const Icon(FeatherIcons.share),
                title: const Text(
                  'Share',
                ),
                onTap: () => context.pop(MenuAction.share),
              ),
              ListTile(
                leading: const Icon(Icons.local_police),
                title: const Text(
                  'Flag',
                ),
                onTap: () => context.pop(MenuAction.flag),
              ),
              ListTile(
                leading: Icon(
                  isBlocked ? Icons.visibility : Icons.visibility_off,
                ),
                title: Text(
                  isBlocked ? 'Unblock' : 'Block',
                ),
                onTap: () => context.pop(MenuAction.block),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text(
                  'Cancel',
                ),
                onTap: () => context.pop(MenuAction.cancel),
              ),
            ],
          );
        },
      ),
    );
  }

  void onSearchUserTapped(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return BlocProvider<SearchCubit>(
          create: (_) => SearchCubit()
            ..addFilter(
              PostedByFilter(
                author: item.by,
              ),
            ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - Dimens.pt120,
            child: const Column(
              children: <Widget>[
                Expanded(
                  child: SearchScreen(
                    fromUserDialog: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
