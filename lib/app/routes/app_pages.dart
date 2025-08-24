import 'package:get/get.dart';
import 'package:expensease/app/modules/authentication/views/splash_view.dart';
import '../modules/authentication/bindings/auth_binding.dart';
import '../modules/authentication/views/auth_hub_view.dart';
import '../modules/authentication/views/guest_mode_view.dart';
import '../modules/authentication/views/login_view.dart';
import '../modules/authentication/views/password_reset_view.dart';
import '../modules/authentication/views/signup_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/expenses/bindings/expense_binding.dart';
import '../modules/expenses/bindings/expense_details_binding.dart';
import '../modules/expenses/bindings/recurring_expense_binding.dart';
import '../modules/expenses/views/add_expense_view.dart';
import '../modules/expenses/views/expense_details_view.dart';
import '../modules/expenses/views/recurring_expense_view.dart';
import '../modules/groups/bindings/group_binding.dart';
import '../modules/groups/bindings/group_dashboard_binding.dart';
import '../modules/groups/bindings/members_binding.dart';
import '../modules/groups/bindings/settle_up_binding.dart';
import '../modules/groups/views/group_dashboard_view.dart';
import '../modules/groups/views/groups_list_view.dart';
import '../modules/groups/views/members_permissions_view.dart';
import '../modules/groups/views/settle_up_view.dart';
import '../modules/reports/bindings/reports_binding.dart';
import '../modules/reports/views/monthly_report_view.dart';
import '../modules/reports/views/pdf_preview_view.dart';
import '../modules/reports/views/reports_dashboard_view.dart';
import '../modules/settings/bindings/notifications_binding.dart';
import '../modules/settings/bindings/profile_binding.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/notifications_view.dart';
import '../modules/settings/views/profile_view.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/specialized_modes/bindings/specialized_modes_binding.dart';
import '../modules/specialized_modes/views/couples_mode_setup_view.dart';
import '../modules/specialized_modes/views/family_mode_dashboard_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    // AUTH
    // ✅ FIX: The SPLASH route is now a simple page with no binding.
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.AUTH_HUB, page: () => const AuthHubView(), binding: AuthBinding()),
    GetPage(name: Routes.LOGIN, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(name: Routes.SIGNUP, page: () => const SignUpView(), binding: AuthBinding()),
    GetPage(name: Routes.PASSWORD_RESET, page: () => const PasswordResetView(), binding: AuthBinding()),
    GetPage(name: Routes.GUEST_MODE, page: () => const GuestModeView(), binding: AuthBinding()),

    // DASHBOARD
    GetPage(name: Routes.DASHBOARD, page: () => const DashboardView(), binding: DashboardBinding()),

    // GROUPS
    GetPage(name: Routes.GROUPS_LIST, page: () => const GroupsListView(), binding: GroupBinding()),
    GetPage(name: Routes.GROUP_DASHBOARD, page: () => GroupDashboardView(), binding: GroupDashboardBinding()),
    GetPage(name: Routes.MEMBERS_PERMISSIONS, page: () => const MembersPermissionsView(), binding: MembersBinding()),
    GetPage(name: Routes.SETTLE_UP, page: () => const SettleUpView(), binding: SettleUpBinding()),

    // EXPENSES
    GetPage(name: Routes.ADD_EXPENSE, page: () => const AddExpenseView(), binding: ExpenseBinding()),
    GetPage(name: Routes.EXPENSE_DETAILS, page: () => const ExpenseDetailsView(), binding: ExpenseDetailsBinding()),
    GetPage(name: Routes.RECURRING_EXPENSE, page: () => const RecurringExpenseView(), binding: RecurringExpenseBinding()),

    // REPORTS
    GetPage(name: Routes.REPORTS_DASHBOARD, page: () => const ReportsDashboardView(), binding: ReportsBinding()),
    GetPage(name: Routes.MONTHLY_REPORT, page: () => const MonthlyReportView(), binding: ReportsBinding()),
    GetPage(name: Routes.PDF_PREVIEW, page: () => const PdfPreviewView(), binding: ReportsBinding()),

    // SETTINGS
    GetPage(name: Routes.SETTINGS, page: () => const SettingsView(), binding: SettingsBinding()),
    GetPage(name: Routes.PROFILE, page: () => const ProfileView(), binding: ProfileBinding()),
    GetPage(name: Routes.NOTIFICATIONS, page: () => const NotificationsView(), binding: NotificationsBinding()),

    // SPECIALIZED MODES
    GetPage(name: Routes.COUPLES_MODE_SETUP, page: () => const CouplesModeSetupView(), binding: SpecializedModesBinding()),
    GetPage(name: Routes.FAMILY_MODE_DASHBOARD, page: () => const FamilyModeDashboardView(), binding: SpecializedModesBinding()),
  ];
}