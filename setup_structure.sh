#!/bin/bash

# Create root directories
mkdir -p FocusZone/{App,Resources,Models,ViewModels,Views/Screens,Views/Components,Services,Helpers/Extensions,Previews}

# App
touch FocusZone/App/FocusZoneApp.swift
touch FocusZone/App/ThemeManager.swift

# Resources
touch FocusZone/Resources/Localizable.strings

# Models
touch FocusZone/Models/Task.swift
touch FocusZone/Models/TaskType.swift
touch FocusZone/Models/RepeatRule.swift

# ViewModels
touch FocusZone/ViewModels/TaskViewModel.swift
touch FocusZone/ViewModels/TimelineViewModel.swift
touch FocusZone/ViewModels/AIAssistantViewModel.swift

# Views - Screens
touch FocusZone/Views/Screens/TimelineView.swift
touch FocusZone/Views/Screens/TaskFormView.swift
touch FocusZone/Views/Screens/AIAssistantView.swift
touch FocusZone/Views/Screens/SettingsView.swift

# Views - Components
touch FocusZone/Views/Components/AppButton.swift
touch FocusZone/Views/Components/AppToggle.swift
touch FocusZone/Views/Components/AppTextField.swift
touch FocusZone/Views/Components/AppPicker.swift
touch FocusZone/Views/Components/AppModal.swift
touch FocusZone/Views/Components/AlertBox.swift
touch FocusZone/Views/Components/TaskCard.swift
touch FocusZone/Views/Components/DateSelector.swift

# Services
touch FocusZone/Services/TaskRepository.swift
touch FocusZone/Services/NotificationService.swift
touch FocusZone/Services/AIService.swift

# Helpers
touch FocusZone/Helpers/Utils.swift
touch FocusZone/Helpers/Extensions/Color+Ext.swift
touch FocusZone/Helpers/Extensions/Date+Ext.swift
touch FocusZone/Helpers/Extensions/View+Ext.swift

# Previews
touch FocusZone/Previews/ComponentPreviews.swift
touch FocusZone/Previews/ScreenPreviews.swift

echo \"✅ Project structure created in ./FocusZone\"