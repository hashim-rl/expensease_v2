// This file contains the names of all routes used in the ExpensEase app.
abstract class Routes {
  // Onboarding & Authentication Flow (7 screens)
  static const SPLASH = _Paths.SPLASH;
  static const AUTH_HUB = _Paths.AUTH_HUB;
  static const SIGNUP = _Paths.SIGNUP;
  static const LOGIN = _Paths.LOGIN;
  static const PASSWORD_RESET = _Paths.PASSWORD_RESET;
  static const GROUP_INVITE = _Paths.GROUP_INVITE; // Placeholder for deep linking
  static const GUEST_MODE = _Paths.GUEST_MODE;

  // Central Hub (1 screen)
  static const DASHBOARD = _Paths.DASHBOARD;

  // Core Functionality: Expenses (3 screens)
  static const ADD_EXPENSE = _Paths.ADD_EXPENSE;
  static const EXPENSE_DETAILS = _Paths.EXPENSE_DETAILS;
  static const RECURRING_EXPENSE = _Paths.RECURRING_EXPENSE;

  // Group Management (4 screens) <-- UPDATED COUNT
  static const GROUPS_LIST = _Paths.GROUPS_LIST;
  static const GROUP_DASHBOARD = _Paths.GROUP_DASHBOARD;
  static const MEMBERS_PERMISSIONS = _Paths.MEMBERS_PERMISSIONS;
  static const SETTLE_UP = _Paths.SETTLE_UP;
  static const SPLIT_SETUP = _Paths.SPLIT_SETUP; // <-- NEW ROUTE

  // Analytics and Reporting (3 screens)
  static const REPORTS_DASHBOARD = _Paths.REPORTS_DASHBOARD;
  static const MONTHLY_REPORT = _Paths.MONTHLY_REPORT;
  static const PDF_PREVIEW = _Paths.PDF_PREVIEW;

  // User Engagement and Configuration (3 screens)
  static const NOTIFICATIONS = _Paths.NOTIFICATIONS;
  static const SETTINGS = _Paths.SETTINGS;
  static const PROFILE = _Paths.PROFILE;
  static const EDIT_PROFILE = _Paths.EDIT_PROFILE; // New Route

  // Advanced Modules (1 screen) - MEAL route added
  static const MEAL = _Paths.MEAL; // New Route for Meal Feature
}

// This private class holds the actual path strings to prevent typos.
abstract class _Paths {
  // Onboarding
  static const SPLASH = '/splash';
  static const AUTH_HUB = '/auth-hub';
  static const SIGNUP = '/signup';
  static const LOGIN = '/login';
  static const PASSWORD_RESET = '/password-reset';
  static const GROUP_INVITE = '/group-invite';
  static const GUEST_MODE = '/guest-mode';

  // Hub
  static const DASHBOARD = '/dashboard';

  // Expenses
  static const ADD_EXPENSE = '/add-expense';
  static const EXPENSE_DETAILS = '/expense-details';
  static const RECURRING_EXPENSE = '/recurring-expense';

  // Groups
  static const GROUPS_LIST = '/groups-list';
  static const GROUP_DASHBOARD = '/group-dashboard';
  static const MEMBERS_PERMISSIONS = '/members-permissions';
  static const SETTLE_UP = '/settle-up';
  static const SPLIT_SETUP = '/split-setup'; // <-- NEW PATH

  // Reports
  static const REPORTS_DASHBOARD = '/reports-dashboard';
  static const MONTHLY_REPORT = '/monthly-report';
  static const PDF_PREVIEW = '/pdf-preview';

  // Settings
  static const NOTIFICATIONS = '/notifications';
  static const SETTINGS = '/settings';
  static const PROFILE = '/profile';
  static const EDIT_PROFILE = '/edit-profile';

  // Specialized Modes
  static const MEAL = '/meal'; // New Path for Meal Feature
}