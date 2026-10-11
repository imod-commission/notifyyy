#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

#define kDomain  CFSTR("com.imodcommission.notifyyy")
#define kChanged CFSTR("com.imodcommission.notifyyy/preferences.changed")

static BOOL    gEnabled = NO;
static CGFloat gOffsetY = 0;

static void loadPrefs(void) {
    CFPreferencesAppSynchronize(kDomain);

    gEnabled = CFPreferencesGetAppBooleanValue(CFSTR("enabled"), kDomain, NULL);

    gOffsetY = 0;
    CFPropertyListRef v = CFPreferencesCopyAppValue(CFSTR("customY"), kDomain);
    if (v) {
        if (CFGetTypeID(v) == CFNumberGetTypeID()) {
            gOffsetY = [(__bridge NSNumber *)v doubleValue];
        } else if (CFGetTypeID(v) == CFStringGetTypeID()) {
            gOffsetY = [(__bridge NSString *)v doubleValue];
        }
        CFRelease(v);
    }
}

static void prefsChanged(CFNotificationCenterRef c, void *o,
                         CFStringRef n, const void *obj, CFDictionaryRef u) {
    loadPrefs();
}

// 横屏判断兜底：windowScene → 前台 active scene → 主屏宽高
static BOOL vi_isLandscape(id window) {
    if ([window respondsToSelector:@selector(windowScene)]) {
        UIWindowScene *scene = [window windowScene];
        if (scene) {
            return UIInterfaceOrientationIsLandscape(scene.interfaceOrientation);
        }
    }

    if (@available(iOS 13.0, *)) {
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]] &&
                s.activationState == UISceneActivationStateForegroundActive) {
                UIWindowScene *ws = (UIWindowScene *)s;
                return UIInterfaceOrientationIsLandscape(ws.interfaceOrientation);
            }
        }
    }

    CGSize size;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    size = [UIScreen mainScreen].bounds.size;
#pragma clang diagnostic pop
    return size.width > size.height;
}

%hook SBBannerWindow

- (void)setFrame:(CGRect)frame {
    // 关开关 / 偏移为 0 → 完全不干预
    if (!gEnabled || gOffsetY == 0) {
        %orig;
        return;
    }

    // 关键：横屏时系统给的 frame 宽 > 高，直接放行
    if (frame.size.width > frame.size.height) {
        %orig;
        return;
    }

    // 方向 API 兜底
    if (vi_isLandscape(self)) {
        %orig;
        return;
    }

    // 竖屏：只改 Y，宽高沿用系统传入值
    CGRect f = frame;
    f.origin.y += gOffsetY;
    %orig(f);
}

%end

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)prefsChanged,
        kChanged,
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}