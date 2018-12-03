@class BluetoothManager;

@interface BluetoothManager : NSObject
- (void)setEnabled:(BOOL)arg1;
- (void)setPowered:(BOOL)arg1;
- (void)disable;
- (BOOL)connected;
- (BOOL)powered;
- (int)bluetoothState;
@end

static BOOL enabled;
static BOOL rn;
static float timer;
static BOOL canDisable;

static void loadPrefs() {
    static NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.autoblue"];
		enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : NO;
		rn = [prefs objectForKey:@"rn"] ? [[prefs objectForKey:@"rn"] boolValue] : NO;    
		timer = [prefs objectForKey:@"timer"] ? [[prefs objectForKey:@"timer"]floatValue] * 60 : 5 * 60;
}

%hook BluetoothManager
NSTimer *tc;
- (void)_connectedStatusChanged {
	%orig;
	if (enabled && ![self connected] && [self powered]) {
		if (!rn) {
			tc	= [NSTimer scheduledTimerWithTimeInterval:timer
				target:self
				selector:@selector(disable)
				userInfo:nil
				repeats:NO];
		} else {
			[self disable];
		}
	} else if ([self connected]) {
	[tc invalidate];
	}	
}

NSTimer *tp;
	-(void)setPowered:(BOOL)arg1 {
		%orig;
		if (enabled && ![self connected] && arg1) {
				%orig(YES);
			tp	= [NSTimer scheduledTimerWithTimeInterval:timer
				target:self
				selector:@selector(disable)
				userInfo:nil
				repeats:NO];
			if (canDisable) {
				%orig(NO);
			}
		} else if (!arg1) {
		[tp invalidate];
		}
	}

	%new
	- (void)disable {
		if ((![self connected] && [self powered])) {
			canDisable = YES;
			[self setEnabled:NO];
			[self setPowered:NO];
			canDisable = NO;
		}
	}
	%end

%ctor {
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.autoblue/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}