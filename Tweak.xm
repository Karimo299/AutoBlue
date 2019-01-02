#import <PersistentConnection/PCSimpleTimer.h>
#import "SparkAppList.h"
@class BluetoothManager;

@interface BluetoothManager : NSObject
- (void)setEnabled:(BOOL)arg1;
- (void)setPowered:(BOOL)arg1;
- (void)disable;
- (void)enable;
- (BOOL)connected;
- (BOOL)powered;
- (BOOL)blacklistEnabled;
@end

@interface SBApplication : NSObject
-(NSString *)bundleIdentifier;
@end

@interface FBProcessState : NSObject
-(int)visibility;
@end

static BOOL enabled;
static BOOL rn;
static BOOL charge;
static BOOL canEnable;
static float timerTime;
static BluetoothManager *btMan;
PCSimpleTimer *poweredTimer;
PCSimpleTimer *respringTimer; 
PCSimpleTimer *connectTimer;
PCSimpleTimer *blacklistTimer;

 
static void loadPrefs() {
    static NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.autoblue"];
		enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : NO;
		rn = [prefs objectForKey:@"rn"] ? [[prefs objectForKey:@"rn"] boolValue] : NO;  
		charge = [prefs objectForKey:@"charge"] ? [[prefs objectForKey:@"charge"] boolValue] : NO;  
		timerTime = [prefs objectForKey:@"timerTime"] ? [[prefs objectForKey:@"timerTime"]floatValue] * 60 : 5 * 60;
}
%hook SBApplication
-(void)_updateProcess:(id)arg1 withState:(FBProcessState *)state {
	if ([state visibility] != 1) {
		if ([SparkAppList doesIdentifier:@"com.karimo299.autoblue" andKey:@"selectedApps" containBundleIdentifier:[self bundleIdentifier]]) {
			[btMan enable];
		}
	}
	%orig;
}

%end

%hook BluetoothManager
- (id)init {
		[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
		[[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceBatteryStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging) {
				if (charge) {
					[self enable];	
				}
			}
		}];
	btMan = %orig;
	return btMan;
}

// // Disables Bluetooth if it was enabled before a respring
-(void)postNotification:(id)arg1 {
	if (enabled) {
		if (![self connected] && [self powered]) {
			static dispatch_once_t once;
			dispatch_once(&once, ^ {
				respringTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:timerTime serviceIdentifier:@"com.karimo299.autoblue" target:self selector:@selector(disable) userInfo:nil];
				[respringTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];	
			});
		}
	}
	%orig;
}

// The disabled state that was intorduce in ios 11
-(void)setBlacklistEnabled:(BOOL)arg1 {
	%orig;
	[poweredTimer invalidate];
	[respringTimer invalidate];
	[connectTimer invalidate];
	[blacklistTimer invalidate];
	if (enabled && ![self connected] && !arg1) {
		[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
		[connectTimer invalidate];
		[poweredTimer invalidate];
		blacklistTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:timerTime serviceIdentifier:@"com.karimo299.autoblue" target:self selector:@selector(disable) userInfo:nil];
		[blacklistTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
	}
}

//Disables after disconecting
- (void)_connectedStatusChanged {
	%orig;
	if (enabled && ![self connected] && [self powered]) {
		if (!rn) {
			if (![connectTimer isValid]){
			[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
			connectTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:timerTime serviceIdentifier:@"com.karimo299.autoblue" target:self selector:@selector(disable) userInfo:nil];
			[connectTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
			}
		} else {
			[self disable];
		}
	} else if ([self connected]) {
		[poweredTimer invalidate];
		[respringTimer invalidate];
		[connectTimer invalidate];
		[blacklistTimer invalidate];
	}
}

//Disables Bluetooth if it is Enabled but never connected
-(void)setPowered:(BOOL)arg1 {
	%orig(canEnable);
	[poweredTimer invalidate];
	[respringTimer invalidate];
	[connectTimer invalidate];
	[blacklistTimer invalidate];
	if (enabled && ![self connected] && canEnable) {
		poweredTimer = [[%c(PCSimpleTimer) alloc] initWithTimeInterval:timerTime serviceIdentifier:@"com.karimo299.autoblue" target:self selector:@selector(disable) userInfo:nil];
		[poweredTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
	}
}

-(BOOL)enabled {
    canEnable = !%orig;
    return %orig;
}

%new
- (void)enable {
	if (![self powered]) {
		canEnable = YES;
		[self setPowered:canEnable];
		[self setEnabled:canEnable];
	}
}

%new
- (void)disable {
	if (![self connected] && [self powered] && ![self blacklistEnabled]) {
		canEnable = NO;
		[self setPowered:canEnable];
		[self setEnabled:canEnable];
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