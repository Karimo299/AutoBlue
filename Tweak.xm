#import <PersistentConnection/PCSimpleTimer.h>

@interface CCUILabeledRoundButton : UIView
@property (nonatomic,copy) NSString * title;
@property (nonatomic,copy) NSString * subtitle;
-(void)disableBT;
-(void)disableWifi;
@end

@interface PSCellularDataSettingsDetail : NSObject
+(void)setEnabled:(BOOL)arg1;
@end

@interface PSAirplaneModeSettingsDetail : NSObject
+(BOOL)isEnabled;
@end

@interface PSWiFiSettingsDetail : NSObject
+(void)setEnabled:(BOOL)arg1;
@end

@interface BluetoothManager : NSObject
-(void)disableBT;
+(id)sharedInstance;
-(bool)powered;
-(void)setPowered:(BOOL)arg1;
-(BOOL)connected;
@end

@interface SBWiFiManager : NSObject
+(id)sharedInstance;
-(id)currentNetworkName;
-(void)disableWifi;
@end

@interface SBApplication : NSObject
-(NSString *)bundleIdentifier;
@end

@interface FBProcessState : NSObject
-(int)visibility;
@end

static NSUserDefaults *prefs;
SBWiFiManager *wifiManager = [%c(SBWiFiManager) sharedInstance];
BluetoothManager *BTManager = [%c(BluetoothManager) sharedInstance];

static bool enabled;
static bool BTEnabled;
static bool wifiEnabled;
static bool hotspot;
static bool charge;
static bool turnCell;
static bool shouldEnable;
static float wifiTimerTime;
static float BTTimerTime;
PCSimpleTimer *wifiPoweredTimer;
PCSimpleTimer *BTPoweredTimer;
CCUILabeledRoundButton *labeledBtns;

static void loadPrefs() {
  prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.autoblue"];
  enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : NO;
  BTEnabled = [prefs objectForKey:@"BTEnabled"] ? [[prefs objectForKey:@"BTEnabled"] boolValue] : NO;
  wifiEnabled = [prefs objectForKey:@"wifiEnabled"] ? [[prefs objectForKey:@"wifiEnabled"] boolValue] : NO;
  charge = [prefs objectForKey:@"charge"] ? [[prefs objectForKey:@"charge"] boolValue] : NO;
  turnCell = [prefs objectForKey:@"turnCell"] ? [[prefs objectForKey:@"turnCell"] boolValue] : NO;
  BTTimerTime = [prefs objectForKey:@"BTTimerTime"] ? [[prefs objectForKey:@"BTTimerTime"]floatValue] * 60 : 5 * 60;
  wifiTimerTime = [prefs objectForKey:@"wifiTimerTime"] ? [[prefs objectForKey:@"wifiTimerTime"]floatValue] * 60 : 5 * 60;
}

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
  return %orig(shouldEnable);
}
%end


%hook SBApplication
-(void)_updateProcess:(id)arg1 withState:(FBProcessState *)state {
	if ([state visibility] == 2 && enabled) {
    NSLog(@"%d",[[prefs valueForKey:[NSString stringWithFormat:@"selectApps-%@", [self bundleIdentifier]]] boolValue] );
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
loadPrefs();
  if (version >= 11) {
    %init(ios11);
  } else if (version < 11 && version >= 10) {
    %init(ios10);
  }
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.autoblue/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}
