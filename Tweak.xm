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
static BOOL useTimer;
static float timer;
static BOOL canDisable = YES;

static void loadPrefs() {
    static NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.autoblue"];
		enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : NO;
		enabled = [prefs objectForKey:@"useTimer"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : NO;    
		timer = [prefs objectForKey:@"timer"] ? [[prefs objectForKey:@"timer"]floatValue] * 60 : 5 * 60;
	  timer = 10.0;
}

%hook BluetoothManager
- (void)_connectedStatusChanged {
	%orig;
	if (enabled && ![self connected] && [self powered]) {
		if (useTimer) {
			if (canDisable) {
			[self performSelector:@selector(disable) withObject:nil afterDelay:timer];
			}
		} else {
			[self disable];
		}
	}
}

	-(void)setPowered:(BOOL)arg1 {
		%orig;
		NSLog(@"%d, arg1 %d", [self powered], arg1);
		if (enabled && ![self connected] && arg1) {
				NSLog(@"setPowered");
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer * NSEC_PER_SEC));
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					if (![self connected]) {
					%orig(NO);
					}
			});
		}
	}

	%new
	- (void)disable {
			if (![self connected] && [self powered]) {
					canDisable = YES;
					NSLog(@"disable");
					[self setEnabled:NO];
					[self setPowered:NO];
					NSLog(@"%d", [self powered]);
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