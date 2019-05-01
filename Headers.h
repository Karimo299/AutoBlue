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
SBWiFiManager *wifiManager = [NSClassFromString(@"SBWiFiManager") sharedInstance];
BluetoothManager *BTManager = [NSClassFromString(@"BluetoothManager") sharedInstance];

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
