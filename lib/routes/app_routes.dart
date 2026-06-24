import 'package:go_router/go_router.dart';
import '../modules/account_nav/listing_members_screen.dart';
import '../models/listing_model.dart';

import '../core/services/auth_service.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/auth/forgot_password_screen.dart';
import '../modules/auth/update_password_screen.dart';
import '../modules/auth/role_selection_screen.dart';
import '../modules/auth/complete_profile_screen.dart';

import '../modules/home/home_screen.dart';
import '../modules/listings/listing_list_screen.dart';
import '../modules/listings/listing_detail_screen.dart';
import '../modules/listings/create_listing_screen.dart';
import '../modules/listings/edit_listing_screen.dart';
import '../modules/listings/housemate_post_screen.dart';

import '../modules/map/map_screen.dart';

import '../modules/payment/payment_screen.dart';
import '../modules/payment/payment_history_screen.dart';
import '../modules/payment/rent_reminder_screen.dart';

//import '../modules/reviews/review_screen.dart';
import '../modules/account_nav/account_screen.dart';
import '../modules/account_nav/manage_listing_screen.dart';
import '../modules/chat/chat_screen.dart';
import '../modules/chat/chat_inbox_screen.dart';
import '../shared/widgets/main_screen.dart';

import '../modules/listings/owner_list_profile_screen.dart';
import '../modules/account_nav/personal_info_screen.dart';
import '../modules/account_nav/security_screen.dart';
import '../modules/account_nav/notifications_screen.dart';

import '../modules/account_nav/blocked_users_screen.dart';

import '../modules/reports/earnings_report_screen.dart';

/// Data class passed as [extra] to the /chat route.
class ChatArgs {
  final String receiverId;
  final String receiverName;
  final String? listingId;
  final String? listingTitle;
  const ChatArgs({
    required this.receiverId,
    required this.receiverName,
    this.listingId,
    this.listingTitle,
  });
}

class AppRoutes {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authService,
      redirect: (context, state) {
        final isAuthenticated = authService.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';

        // Routes that unauthenticated users can access
        final isGuestAllowed = isAuthRoute || state.matchedLocation == '/home';

        if (authService.isPasswordRecoveryMode &&
            state.matchedLocation != '/update-password') {
          return '/update-password';
        }

        if (!isAuthenticated && !isGuestAllowed) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/update-password',
          builder: (context, state) => const UpdatePasswordScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) => const CompleteProfileScreen(),
        ),

        // Main Navigation Shell
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            // Branch 1: Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                  routes: [
                    GoRoute(
                      path: 'listings', // /home/listings — listing list
                      builder: (context, state) => ListingListScreen(
                        initialSearchQuery: state.extra as String?,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Branch 2: Search
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/listings',
                  builder: (context, state) => ListingListScreen(
                    initialSearchQuery: state.extra as String?,
                  ),
                ),
              ],
            ),
            // Branch 3: Payment
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/payment',
                  builder: (context, state) => const PaymentScreen(),
                ),
              ],
            ),
            // Branch 4: Account
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/account',
                  builder: (context, state) => const AccountScreen(),
                ),
              ],
            ),
          ],
        ),

        GoRoute(
          path: '/housemate-post',
          builder: (context, state) => const HousematePostScreen(),
        ),
        GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
        GoRoute(
          path: '/payment/history',
          builder: (context, state) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: '/payment/reminder',
          builder: (context, state) => const RentReminderScreen(),
        ),
        GoRoute(
          path: '/chat/inbox',
          builder: (context, state) => const ChatInboxScreen(),
        ),
        GoRoute(
          path: '/manage-listings',
          builder: (context, state) => const ManageListingScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            final args = state.extra as ChatArgs;
            return ChatScreen(
              receiverId: args.receiverId,
              receiverName: args.receiverName,
              listingId: args.listingId,
              listingTitle: args.listingTitle,
            );
          },
        ),
        GoRoute(
          path: '/home/owner-profile/:ownerId',
          builder: (context, state) =>
              OwnerProfileScreen(ownerId: state.pathParameters['ownerId']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/personal-info',
          builder: (context, state) => const PersonalInfoScreen(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecurityScreen(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const UpdatePasswordScreen(),
        ),
        GoRoute(
          path: '/manage-listing',
          builder: (context, state) => const ManageListingScreen(),
        ),
        GoRoute(
          path: '/manage-members',
          builder: (context, state) =>
              ListingMembersScreen(listing: state.extra as ListingModel),
        ),
        GoRoute(
          path: '/home/listings/detail',
          builder: (context, state) =>
              ListingDetailScreen(listing: state.extra as ListingModel?),
        ),
        GoRoute(
          path: '/home/listings/create',
          builder: (context, state) => const CreateListingScreen(),
        ),
        GoRoute(
          path: '/home/listings/edit',
          builder: (context, state) =>
              EditListingScreen(listing: state.extra as ListingModel),
        ),
        GoRoute(
          path: '/blocked-users',
          builder: (context, state) => const BlockedUsersScreen(),
        ),
        GoRoute(
          path: '/earnings-report',
          builder: (context, state) => const EarningsReportScreen(),
        ),
      ],
    );
  }
}
