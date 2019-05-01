#include "../Headers.h"
%group ios10
%hook SBApplication
-(void)_updateProcess:(id)arg1 withState:(FBProcessState *)state {
	if ([state visibility] == 2 && enabled) {
		if ([[prefs valueForKey:[NSString stringWithFormat:@"selectApps-%@", [self bundleIdentifier]]] boolValue]) {
      [BTManager setPowered:YES];
    }
	}
	%orig;
}
%end

//Bluetooth Button
%hook CCUIBluetoothSetting
-(void)_setBluetoothEnabled:(BOOL)arg1 {
  %orig;
  [BTPoweredTimer invalidate];
  if (arg1) {
    if (BTEnabled) {
      if (BTTimerTime != 0 && ![BTPoweredTimer isValid]) {
        BTPoweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:BTTimerTime serviceIdentifier:@"com.karimo299.autoblue" target:BTManager selector:@selector(disableBT) userInfo:nil];
        [BTPoweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
      }
    }
  }
}
%end

//Wifi Button
%hook CCUIWiFiSetting
-(void)_setWifiEnabled:(BOOL)arg1 {
  %orig;
  [wifiPoweredTimer invalidate];
  if (arg1) {
    if (wifiPoweredTimer) {
        wifiPoweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:BTTimerTime serviceIdentifier:@"com.karimo299.autoblue" target:wifiManager selector:@selector(disableWifi) userInfo:nil];
        [wifiPoweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
      }
    }
  if (turnCell && ![%c(PSAirplaneModeSettingsDetail) isEnabled]) {
    [%c(PSCellularDataSettingsDetail) setEnabled:!arg1];
  }
}
%end

//Cellular Button
%hook PSCellularDataSettingsDetail
+(void)setEnabled:(BOOL)arg1 {
  %orig;
  if (turnCell && ![%c(PSAirplaneModeSettingsDetail) isEnabled]) {
    [%c(PSWiFiSettingsDetail) setEnabled:!arg1];
  }
}
%end


//Bluetooth Manager
%hook BluetoothManager
-(id)init {
  if (enabled) {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
      if (charge) {
        if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {
          [BTManager setPowered:YES];
          [BTPoweredTimer invalidate];
        } else {
          if (BTEnabled) {
            if (BTTimerTime != 0 && ![BTPoweredTimer isValid]) {
              BTPoweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:BTTimerTime serviceIdentifier:@"com.karimo299.autoblue" target:BTManager selector:@selector(disableBT) userInfo:nil];
              [BTPoweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
            } else {
              [BTManager disableBT];
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
      [BTManager disableBT];
    }
	}
}

%new
- (void)disableBT {
  if(![BTManager connected] && !hotspot){
    [BTManager setPowered:NO];
  }
}
%end

// Wifi Manager
%hook SBWiFiManager
%new
- (void)disableWifi {
  if(![wifiManager currentNetworkName] && !hotspot){
    [%c(PSWiFiSettingsDetail) setEnabled: NO];
  }
}
%end
%end


%ctor {
  float version = [[[UIDevice currentDevice] systemVersion] floatValue];
   if (version < 11 && version >= 10) {
    %init(ios10);
  }
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.autoblue/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}
