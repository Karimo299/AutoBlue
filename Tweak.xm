#include "Headers.h"
%group ios11
%hook BluetoothManager
-(id)init {
  if (enabled) {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
      if (charge) {
        if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {
          shouldEnable = YES;
          [BTManager setPowered:YES];
          [BTPoweredTimer invalidate];
        } else {
          if (BTEnabled) {
            if (BTTimerTime != 0 && ![BTPoweredTimer isValid]) {
              BTPoweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:BTTimerTime serviceIdentifier:@"com.karimo299.autoblue" target:labeledBtns selector:@selector(disableBT) userInfo:nil];
              [BTPoweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
            } else if (BTTimerTime == 0){
              [labeledBtns disableBT];
            }
          }
        }
      }
    }];
  }
  return %orig;
}

- (void)_connectedStatusChanged {
	%orig;
	if (enabled && ![self connected]) {
		if (BTTimerTime == 0) {
      [BTPoweredTimer invalidate];
      [labeledBtns disableBT];
    }
	}
}

- (BOOL) enabled {
  shouldEnable = !%orig;
  return %orig;
}

- (BOOL)setPowered:(BOOL)arg1 {
  if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/RealCC.dylib"]) {
    return %orig(shouldEnable);
  } else {
    return %orig;
  }
}
%end


%hook SBApplication
-(void)_updateProcess:(id)arg1 withState:(FBProcessState *)state {
	if ([state visibility] == 2 && enabled) {
		if ([[prefs valueForKey:[NSString stringWithFormat:@"selectApps-%@", [self bundleIdentifier]]] boolValue]) {
      shouldEnable = YES;
      [BTManager setPowered:YES];
    }
	}
	%orig;
}
%end

%hook CCUILabeledRoundButton
-(void)layoutSubviews{
  labeledBtns = self;
  %orig;
  if (enabled) {
    //Hotspot Button
    if ([self.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_HOTSPOT_NAME" value:@"CONTROL_CENTER_STATUS_HOTSPOT_NAME" table:@"Localizable"]]){
      if ([self.subtitle isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_GENERIC_OFF" value:@"CONTROL_CENTER_STATUS_GENERIC_OFF" table:@"Localizable"]]) {
        hotspot = 0;
      } else {
        hotspot = 1;
      }
    }

    //Wifi Button
  	if ([self.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_WIFI_NAME" value:@"CONTROL_CENTER_STATUS_WIFI_NAME" table:@"Localizable"]]){
      if ([self.subtitle isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_WIFI_BUSY" value:@"CONTROL_CENTER_STATUS_WIFI_BUSY" table:@"Localizable"]]){
        if (wifiEnabled && ![wifiPoweredTimer isValid]) {
          wifiPoweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:wifiTimerTime serviceIdentifier:@"com.karimo299.autoblue" target:self selector:@selector(disableWifi) userInfo:nil];
          [wifiPoweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
          }
        } else if([self.subtitle isEqualToString:[wifiManager currentNetworkName]]) {
          [wifiPoweredTimer invalidate];
          if (turnCell && !hotspot && ![%c(PSAirplaneModeSettingsDetail) isEnabled]) {
            [%c(PSCellularDataSettingsDetail) setEnabled:NO];
          }
        } else if ([self.subtitle isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_GENERIC_OFF" value:@"CONTROL_CENTER_STATUS_GENERIC_OFF" table:@"Localizable"]] && ![wifiManager currentNetworkName]) {
          [wifiPoweredTimer invalidate];
          if (turnCell && !hotspot && ![%c(PSAirplaneModeSettingsDetail) isEnabled]) {
            [%c(PSCellularDataSettingsDetail) setEnabled:YES];
          }
        }
      }

    //Bluetooth Button
    if ([self.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_BLUETOOTH_NAME" value:@"CONTROL_CENTER_STATUS_BLUETOOTH_NAME" table:@"Localizable"]]){
      if ([self.subtitle isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_GENERIC_ON" value:@"CONTROL_CENTER_STATUS_GENERIC_ON" table:@"Localizable"]]){
        if (BTEnabled) {
          if (BTTimerTime != 0 && ![BTPoweredTimer isValid]) {
            BTPoweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:BTTimerTime serviceIdentifier:@"com.karimo299.autoblue" target:self selector:@selector(disableBT) userInfo:nil];
            [BTPoweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
          }
        }
      } else if ([self.subtitle isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_GENERIC_OFF" value:@"CONTROL_CENTER_STATUS_GENERIC_OFF" table:@"Localizable"]] || [BTManager connected]) {
        [BTPoweredTimer invalidate];
      }
    }

  //Cellular Button
    if (([self.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_CELLUAR_DATA_NAME" value:@"CONTROL_CENTER_STATUS_CELLUAR_DATA_NAME" table:@"Localizable"]] && turnCell && ![%c(PSAirplaneModeSettingsDetail) isEnabled]) || ([self.title isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_CELLULAR_DATA_NAME" value:@"CONTROL_CENTER_STATUS_CELLULAR_DATA_NAME" table:@"Localizable"]] && turnCell && ![%c(PSAirplaneModeSettingsDetail) isEnabled])){
      if ([self.subtitle isEqualToString:[[NSBundle bundleWithPath:@"/System/Library/ControlCenter/Bundles/ConnectivityModule.bundle"] localizedStringForKey:@"CONTROL_CENTER_STATUS_GENERIC_ON" value:@"CONTROL_CENTER_STATUS_GENERIC_ON" table:@"Localizable"]] && !hotspot){
        [self disableWifi];
      } else {
        [%c(PSWiFiSettingsDetail) setEnabled:YES];
      }
    }
  }
}

%new
- (void)disableWifi {
  if(![self.subtitle isEqualToString:[wifiManager currentNetworkName]] && !hotspot){
    [%c(PSWiFiSettingsDetail) setEnabled: NO];
  }
}

%new
- (void)disableBT {
  [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
  if(![BTManager connected] && !hotspot && [BTManager powered]) {
    if ((charge && [[UIDevice currentDevice] batteryState] != UIDeviceBatteryStateCharging) || !charge) {
      shouldEnable = NO;
      [BTManager setPowered:NO];
    }
  }
}
%end
%end

%ctor {
  float version = [[[UIDevice currentDevice] systemVersion] floatValue];
  if (version >= 11) {
    %init(ios11);
  }
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.autoblue/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}
