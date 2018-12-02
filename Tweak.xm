@class BluetoothManager;

@interface BluetoothManager : NSObject
- (void)setEnabled:(BOOL)arg1;
- (void)setPowered:(BOOL)arg1;
- (BOOL)connected;
- (void)disable;
@end

static BluetoothManager *btMan;
static BOOL enabled;
static BOOL useTimer;
static float timer;
static BOOL waitingForTimer = NO;

static void loadPrefs() {
	CFStringRef APPID = CFSTR("com.karimo299.autoblue");
	NSArray *keyList = [(NSArray *)CFPreferencesCopyKeyList((CFStringRef)APPID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
	NSDictionary *prefs = (NSDictionary *)CFPreferencesCopyMultiple((CFArrayRef)keyList, (CFStringRef)APPID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	enabled = [[prefs valueForKey:@"isEnabled"] boolValue];
	useTimer = [[prefs valueForKey:@"useTimer"] boolValue];
	// timer = [[prefs valueForKey:@"timer"]floatValue] * 60;
	timer = 10.0;
}

%hook BluetoothManager
- (id)init {
	btMan = %orig;
	return btMan;
}

- (void)_connectedStatusChanged {
	%orig;
	loadPrefs();
	if (enabled && !waitingForTimer) {
		if (useTimer) {
			waitingForTimer = YES;
			[self performSelector:@selector(disable) withObject:nil afterDelay:timer];
		} else {
			[self disable];
		}
	}
}

%new
- (void)disable {
	waitingForTimer = NO;
	if (![btMan connected]) {
	[btMan setEnabled:0];
	[btMan setPowered:0];
	}
}

- (void)setPowered:(BOOL)arg1 {
	%orig;
	loadPrefs();
	if (enabled) {
		[self performSelector:@selector(disable) withObject:nil afterDelay:timer];
	}
}
%end
