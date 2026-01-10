# Strava Authentication Testing Guide

## Overview
This guide will help you test the Strava authentication implementation in Misfit Metrics.

## Implementation Summary

### Files Modified
1. **SettingsView.swift** - Added Strava authentication section
2. **Misfit_MetricsApp.swift** - Ready for URL scheme handling
3. **StravaDebugView.swift** - NEW: Debug view for testing

### What Was Added

#### 1. Strava Section in Settings
- **Unauthenticated State**: Shows "Connect to Strava" button with cycling icon
- **Authenticated State**: Shows green checkmark, athlete name, and disconnect option
- **Footer**: Shows helpful text and token expiration date
- **Debug Link**: Access to StravaDebugView for troubleshooting

#### 2. Authentication Features
- Login via Strava app (if installed) or web browser
- Logout/disconnect functionality
- Automatic token refresh on successful login
- Athlete information display

## Prerequisites for Testing

### 1. Configure URL Scheme in Xcode
You need to add a URL scheme to your app so Strava can redirect back after authentication.

**Steps:**
1. Select your project in Xcode
2. Select your app target
3. Go to the "Info" tab
4. Expand "URL Types"
5. Add a new URL Type:
   - **Identifier**: `com.hunterleebrown.misfit-metrics` (or your bundle ID)
   - **URL Schemes**: `misfit-metrics`

### 2. Verify StravaConfig Values
Check `StravaConfig.swift` and ensure:
- `clientId` matches your Strava app
- `clientSecret` is correct
- `appname` matches your URL scheme
- `website` matches your redirect URI in Strava settings

### 3. Configure Strava Application
On the [Strava API Settings](https://www.strava.com/settings/api) page:
1. Set **Authorization Callback Domain** to: `www.hunterleebrown.com`
2. Or update `StravaConfig.website` to match your domain

## Testing Steps

### Test 1: Initial State (Not Authenticated)
1. Launch the app
2. Tap the gear icon to open Settings
3. Check the Strava section at the top
4. **Expected**: Should show "Connect to Strava" button with description text

### Test 2: Authentication Flow
1. Tap "Connect to Strava" button
2. **Two possible flows**:
   
   **A. If Strava App is Installed:**
   - Should switch to Strava app
   - Shows authorization screen
   - Tap "Authorize"
   - Should redirect back to Misfit Metrics
   
   **B. If Strava App is NOT Installed:**
   - Opens web browser (Safari)
   - Shows Strava login page
   - Log in to Strava
   - Tap "Authorize"
   - Should redirect back to app

3. **Expected After Success**:
   - Returns to Settings
   - Strava section updates automatically
   - Shows green checkmark
   - Displays "Connected to Strava"
   - Shows your athlete name (if available)
   - "Disconnect" button appears

### Test 3: Debug Information
1. Once authenticated, tap "Debug Info" in Strava section
2. **Expected to see**:
   - Authentication status (✅ Yes)
   - Expiration status
   - Token information (hidden for security)
   - Your athlete details (name, username, city, etc.)

### Test 4: Persistence
1. Authenticate with Strava
2. Close the app completely (swipe up from app switcher)
3. Relaunch the app
4. Open Settings
5. **Expected**: Should still show as authenticated

### Test 5: Logout
1. While authenticated, tap "Disconnect" button
2. **Expected**:
   - Red destructive button
   - Strava section updates
   - Shows "Connect to Strava" again
   - Token removed from keychain
   - UserDefaults cleared

### Test 6: Token Expiration
1. Check the expiration date in the footer
2. **Note**: Tokens typically last 6 hours
3. Use Debug View to see exact expiration time

## Troubleshooting

### Issue: Callback Doesn't Work
**Symptom**: After authorizing in Strava, doesn't return to app

**Solutions**:
1. Verify URL scheme is correctly configured in Xcode
2. Check that `StravaConfig` values match your Strava app settings
3. Ensure callback domain in Strava API settings matches

### Issue: "No window scene available" Error
**Symptom**: Crash when trying to authenticate

**Solution**: Already handled in `StravaAuthorizationViewModel` - should fallback to any available scene

### Issue: Authentication State Not Updating
**Symptom**: UI doesn't update after successful login

**Solutions**:
1. Check Console for Combine subscription issues
2. Verify `StravaAuthorizationViewModel.loginEvent.send(true)` is called
3. Use Debug View to verify token was saved

### Issue: Token Not Persisting
**Symptom**: Loses authentication after app restart

**Solutions**:
1. Check keychain access (ensure KeychainSwift is working)
2. Verify `Settings.shared.setAuthResponse()` is called
3. Use Debug View → "Check Token in Keychain" button

## Debug Console Output

When testing, watch for these console messages:
- `"Exp"` - Shows expiration date being checked
- `"-----> I think it's not expired."` - Token is still valid
- `"-----> I think it is expired."` - Token needs refresh
- HTTP errors if API calls fail

## What to Test Next

Once basic authentication works, you can:
1. Implement token refresh logic (when token expires)
2. Add Strava activity upload functionality
3. Fetch athlete activities from Strava API
4. Display Strava stats in the app

## Code Notes

### Important Classes
- `StravaAuthenticationSession`: Singleton managing auth state
- `StravaAuthorizationViewModel`: Handles OAuth flow
- `Settings`: Manages keychain and UserDefaults storage
- `StravaAuthResponse`: Token and athlete data model

### Key Published Properties
```swift
@Published var isAuthenticated: Bool
@Published var expired: Bool
var expireyDate: Date?
```

### Combine Event
```swift
StravaAuthorizationViewModel.loginEvent // Fires on successful login
```

## Security Notes
- Access token stored in Keychain (secure)
- Other auth data in UserDefaults
- Token never logged or displayed in UI
- Client secret should be moved to secure backend in production

## Next Steps for Production
1. Remove the "Debug Info" link from SettingsView
2. Implement token refresh when expired
3. Handle edge cases (network errors, denied permissions)
4. Add loading states during authentication
5. Consider moving client secret to backend
