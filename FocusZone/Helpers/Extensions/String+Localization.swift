import Foundation

extension String {
    
    /// Returns a localized version of the string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version of the string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    /// Returns a localized version of the string with a single format argument
    func localized(with argument: CVarArg) -> String {
        return String(format: self.localized, argument)
    }
    
    /// Returns a localized version of the string with multiple format arguments
    func localized(with arguments: [CVarArg]) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

struct LocalizationKeys {
    
    static let welcome_message = "welcome_message"
    
    // MARK: - Common UI Elements
    static let close = "close"
    static let today = "today"
    static let enable = "enable"
    static let later = "later"
    static let active = "active"
    static let now = "now"
    static let live = "live"
    static let next = "next"
    static let tasks = "tasks"
    static let done = "done"
    
    // MARK: - Settings
    static let settings = "settings"
    static let appearance = "appearance"
    static let language = "language"
    static let notifications = "notifications"
    static let data = "data"
    static let about = "about"
    static let darkMode = "dark_mode"
    static let switchLightDarkThemes = "switch_light_dark_themes"
    static let taskReminders = "task_reminders"
    static let getNotifiedTasksStarting = "get_notified_tasks_starting"
    static let clearAllData = "clear_all_data"
    static let resetAllTasksSettings = "reset_all_tasks_settings"
    static let version = "version"
    static let contactSupport = "contact_support"
    static let getHelpSendFeedback = "get_help_send_feedback"
    static let builtWithSwiftUI = "built_with_swiftui"
    static let focusHelpsStayFocused = "focus_helps_stay_focused"
    static let stayFocusedAchieveMore = "stay_focused_achieve_more"
    
    // MARK: - Subscription
    static let subscription = "subscription"
    static let restorePurchases = "restore_purchases"
    static let restoreSubscriptionDevice = "restore_subscription_device"
    static let manageSubscription = "manage_subscription"
    static let changeCancelSubscription = "change_cancel_subscription"
    static let unlockAllFeatures = "unlock_all_features"
    
    // MARK: - Task Management
    static let createTask = "create_task"
    static let updateTask = "update_task"
    static let noTasksToday = "no_tasks_today"
    static let addFirstTask = "add_first_task"
    static let allDone = "all_done"
    static let greatWorkToday = "great_work_today"
    static let noTasks = "no_tasks"
    static let addSomeTasks = "add_some_tasks"
    static let focus = "focus"
    static let todayFocus = "today_focus"
    static let focusConcentration = "focus_concentration"
    
    // MARK: - Focus Modes
    static let focusMode = "focus_mode"
    static let suggestedFocusMode = "suggested_focus_mode"
    
    // MARK: - Notifications
    static let enableNotificationsTitle = "enable_notifications_title"
    static let enableNotificationsMessage = "enable_notifications_message"
    static let notificationsDisabled = "notifications_disabled"
    static let enableNotificationsDescription = "enable_notifications_description"
    
    // MARK: - Pro Features
    static let upgradeToPro = "upgrade_to_pro"
    static let pro = "pro"
    static let freeTrialActive = "free_trial_active"
    static let nextBilling = "next_billing"
    static let limitedFeatures = "limited_features"
    static let advancedAnalyticsContent = "advanced_analytics_content"
    
    // MARK: - Break Suggestions
    static let longTaskStretch = "long_task_stretch"
    static let quickSnackTime = "quick_snack_time"
    static let movementOpportunity = "movement_opportunity"
    static let properRestBreak = "proper_rest_break"
    static let stayHydrated = "stay_hydrated"
    static let workingStreak = "working_streak"
    static let intenseWorkRest = "intense_work_rest"
    static let mentalBreakTime = "mental_break_time"
    static let lunchBreak = "lunch_break"
    static let freshAirBreak = "fresh_air_break"
    static let eyeBreak = "eye_break"
    static let socialConnection = "social_connection"
    
    // MARK: - Task Status
    static let noActiveTask = "no_active_task"
    static let timeUp = "time_up"
    
    // MARK: - Widget
    static let configuration = "configuration"
    static let widgetDescription = "widget_description"
    static let favoriteEmoji = "favorite_emoji"
    static let world = "world"
    static let focusTracker = "focus_tracker"
    static let widgetDescriptionLong = "widget_description_long"
    static let timer = "timer"
    static let timerOn = "timer_on"
    static let timerOff = "timer_off"
    static let startTimer = "start_timer"
    static let timerNameConfiguration = "timer_name_configuration"
    static let timerName = "timer_name"
    static let startTimerAction = "start_timer_action"
    static let timerIsRunning = "timer_is_running"
    
    // MARK: - Task Types
    static let work = "work"
    static let exercise = "exercise"
    static let deepWorkSession = "deep_work_session"
    static let teamMeeting = "team_meeting"
    static let morningExercise = "morning_exercise"
    static let codeReview = "code_review"
    
    // MARK: - Time and Duration
    static let percentageComplete = "percentage_complete"
    static let timeRemaining = "time_remaining"
    static let timeUntilStart = "time_until_start"
    static let formattedTimeRange = "formatted_time_range"
    static let formattedStartTime = "formatted_start_time"
    
    // MARK: - Errors and Messages
    static let failedLoadProducts = "failed_load_products"
    static let productNotAvailable = "product_not_available"
    static let purchaseFailed = "purchase_failed"
    static let noActiveSubscription = "no_active_subscription"
    static let failedRestorePurchases = "failed_restore_purchases"
    
    // MARK: - Onboarding
    static let previous = "previous"
    static let skip = "skip"
    static let transformYourProductivity = "transform_your_productivity"
    static let discoverUltimateFocusCompanion = "discover_ultimate_focus_companion"
    static let powerfulFeatures = "powerful_features"
    static let readyToFocus = "ready_to_focus"
    static let startProductivityJourney = "start_productivity_jney"
    static let swipeToBeginJourney = "swipe_to_begin_journey"
}
