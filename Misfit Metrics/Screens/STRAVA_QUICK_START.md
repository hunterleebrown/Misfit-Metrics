# 🚀 Strava Authentication Quick Start

## ⚡️ What You Need to Do RIGHT NOW

### 1. Configure URL Scheme (REQUIRED)
In Xcode:
1. Click your project in the navigator
2. Select your app target
3. Go to **Info** tab
4. Scroll to **URL Types** and expand it
5. Click **+** to add:
   - **Identifier**: `com.hunterleebrown.misfit-metrics`
   - **URL Schemes**: `misfit-metrics`

**Without this, authentication WILL NOT work!**

### 2. Verify Strava App Settings
Go to: https://www.strava.com/settings/api

Make sure:
- **Authorization Callback Domain** is set to: `www.hunterleebrown.com`
- **Client ID** matches `80133` (from StravaConfig.swift)

### 3. Build and Run! 🎉

## 🧪 Quick Test

1. **Launch app** → Tap gear icon (Settings)
2. **See Strava section** at top (should say "Connect to Strava")
3. **Tap "Connect to Strava"** → Opens Strava or Safari
4. **Authorize in Strava** → Should return to app
5. **Check Settings again** → Should show green checkmark + your name
6. **Tap "Debug Info"** → See all your token details

## ✅ Success Checklist

- [ ] URL scheme added to project
- [ ] Strava API settings configured
- [ ] App builds without errors
- [ ] Settings shows Strava section
- [ ] Can tap "Connect to Strava"
- [ ] Auth flow opens Strava/Safari
- [ ] Returns to app after authorization
- [ ] Settings shows connected state
- [ ] Your name appears
- [ ] Debug view shows token info
- [ ] App restart keeps you logged in
- [ ] Disconnect button works

## 🐛 Common Issues

**"Nothing happens when I tap Connect"**
→ Check Console for errors

**"Doesn't return to app after auth"**
→ Verify URL scheme is correct

**"Shows connected but no name"**
→ Check Debug View to see if athlete data exists

**"Not staying logged in"**
→ Check keychain permissions

## 📁 Files You Got

### New Files:
- ✅ `StravaDebugView.swift` - Debugging UI
- ✅ `StravaAuthenticationTests.swift` - Unit tests
- ✅ `STRAVA_AUTH_TESTING.md` - Full testing guide
- ✅ `STRAVA_IMPLEMENTATION_SUMMARY.md` - Complete overview
- ✅ `STRAVA_QUICK_START.md` - This file!

### Modified Files:
- ✅ `SettingsView.swift` - Added Strava section

### Existing Files (Already Working):
- ✅ All files in Strava folder

## 🎯 What Each File Does

**SettingsView.swift**
- Shows Strava login button or connected status
- Handles logout
- Links to debug view

**StravaDebugView.swift**
- Shows all token details
- Displays athlete info
- Tests keychain access

**StravaAuthorizationViewModel.swift**
- Manages OAuth flow
- Opens Strava app or web browser
- Handles callback

**StravaAuthenticationSession.swift**
- Stores auth state
- Checks token expiration
- Fetches tokens from Strava

**Settings.swift**
- Saves tokens to Keychain
- Saves data to UserDefaults
- Retrieves saved auth info

## 💡 Pro Tips

1. **Use Debug View**: When testing, always check Debug View to see what's stored
2. **Watch Console**: Look for "Exp" logs to see expiration checks
3. **Test Logout**: Make sure you can disconnect and reconnect
4. **Test Persistence**: Kill app and relaunch to verify login persists
5. **Remove Debug Link**: Before shipping, remove "Debug Info" link from SettingsView

## 🔐 Security Notes

- Access tokens stored in **Keychain** (secure ✅)
- Tokens never logged or displayed (secure ✅)
- Client secret in code (OK for now, move to backend later ⚠️)

## 🚀 What's Next?

Once authentication works:
1. **Implement token refresh** (when it expires)
2. **Upload activities to Strava** (using the access token)
3. **Fetch Strava activities** (show in your app)
4. **Display Strava stats** on Dashboard

## 📚 More Info

Need more details? Check:
- `STRAVA_AUTH_TESTING.md` - Complete testing guide
- `STRAVA_IMPLEMENTATION_SUMMARY.md` - Full overview
- `StravaAuthenticationTests.swift` - See how it works

## 🎉 You're Ready!

Just add the URL scheme and you're good to go. Happy coding! 🚴‍♂️
