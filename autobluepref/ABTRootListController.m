#include "ABTRootListController.h"
#include <spawn.h>
#include <signal.h>
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>

@implementation ABTRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

		// Github source code button
	- (void) git {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://github.com/Karimo299/AutoBlue"]];
	}
		//Twitter button
	- (void) tweet {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://twitter.com/karimo299"]];
	}

		//Twitter button
	- (void) tweetPin {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://twitter.com/TPINPAL"]];
	}

	//Respring button
	- (void) respring {
		pid_t pid;
		int status;
		const char *argv[] = {"killall", "SpringBoard", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
		waitpid(pid, &status, WEXITED);
	}
@end