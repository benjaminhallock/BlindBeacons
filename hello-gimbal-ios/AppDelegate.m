
#import "AppDelegate.h"
#import <Gimbal/Gimbal.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [Gimbal setAPIKey:@"9030e75e-808e-435e-8267-a2dae2cfdfd5 " options:nil];

    [self localNotificationPermission];
    return YES;
}

# pragma mark - Local Notification Permission
- (void)localNotificationPermission {
    // this code will not work on iOS 7
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

@end
