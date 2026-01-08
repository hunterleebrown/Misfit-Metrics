# Files to Delete - HealthKit Removal

Please delete these files from your Xcode project:

## Swift Files to Delete
1. `HealthKitHeartRateMonitor.swift`
2. `HealthKitHeartRateMonitorView.swift`
3. `HeartRateSourceSelectionView.swift`

## Documentation Files to Delete
4. `HEALTHKIT_SETUP.md`
5. `REMOVE_HEALTHKIT_FILES.md` (this file, after you're done)

## Project Settings to Revert

### Remove HealthKit Capability
1. In Xcode, select your project
2. Select your app target
3. Go to "Signing & Capabilities" tab
4. Find "HealthKit" in the capabilities list
5. Click the "X" or "-" button to remove it

### Remove Info.plist Entry (Optional)
You can remove this entry from Info.plist if you added it:
- Key: `NSHealthShareUsageDescription` or `Privacy - Health Share Usage Description`

However, leaving it won't hurt anything if you decide to add HealthKit back later.

## After Deletion

Your app will be back to:
- ✅ Bluetooth heart rate monitor only
- ✅ Real-time heart rate updates
- ✅ Clean, simple implementation
- ✅ No HealthKit dependencies

The Dashboard is already configured to only use the Bluetooth HeartRateMonitor.
