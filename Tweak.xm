@class BluetoothManager;

@interface BluetoothManager
- (void)setEnabled:(BOOL)arg1;
- (void)setPowered:(BOOL)arg1;
- (bool)connected;
@end

static BluetoothManager *btMan;
static BOOL enabled;
static BOOL useTimer;
static int timer;

static void loadPrefs() {
	CFStringRef APPID = CFSTR("com.karimo299.autoblue");
	NSArray *keyList = [(NSArray *)CFPreferencesCopyKeyList((CFStringRef)APPID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease];
	NSDictionary *prefs = (NSDictionary *)CFPreferencesCopyMultiple((CFArrayRef)keyList, (CFStringRef)APPID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	enabled = [[prefs valueForKey:@"isEnabled"] boolValue];
	useTimer = [[prefs valueForKey:@"useTimer"] boolValue];
	timer = [[prefs valueForKey:@"timer"]intValue] * 60;
}

%hook BluetoothManager
- (id)init {
	btMan = %orig;
	return btMan;
}

- (void)_connectedStatusChanged {
	%orig;
	loadPrefs();
	if (enabled) {
		if (useTimer) {
		[NSTimer scheduledTimerWithTimeInterval:timer
    	target:self
			selector:@selector(disable)
			userInfo:nil
			repeats:NO];
		} else {
			if (![btMan connected]) {
				[btMan setEnabled:0];
				[btMan setPowered:0];
			}
		}
	}
}

%new
- (void)disable {
	if (![btMan connected]) {
	[btMan setEnabled:0];
	[btMan setPowered:0];
	}
}

- (void) setPowered:(BOOL)arg1 {
	%orig;
	[NSTimer scheduledTimerWithTimeInterval:10
    	target:self
			selector:@selector(disable)
			userInfo:nil
			repeats:NO];
}
%end
