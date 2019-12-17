#import "IrmaMobileBridgePlugin.h"

@interface IrmaMobileBridgePlugin ()
@end

@implementation IrmaMobileBridgePlugin {
  NSObject<FlutterPluginRegistrar>* registrar;
  FlutterMethodChannel* channel;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"irma.app/irma_mobile_bridge"
                                                              binaryMessenger:[registrar messenger]];
  IrmaMobileBridgePlugin* instance = [[IrmaMobileBridgePlugin alloc] initWithRegistrar:registrar channel:channel];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)r channel:(FlutterMethodChannel*)c {
  if (self = [super init]) {
    registrar = r;
    channel = c;
  }

  NSString* bundlePath = NSBundle.mainBundle.bundlePath;
  NSString* libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];

  // Mark librarypath as non-backup
  NSURL* URL = [NSURL fileURLWithPath: libraryPath];
  NSError* error = nil;
  BOOL success = [URL setResourceValue:[NSNumber numberWithBool: YES]
                                forKey:NSURLIsExcludedFromBackupKey error:&error];
  if (!success) {
    NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
  }

  [self debugLog:[NSString stringWithFormat:@"Starting irmago, lib=%@, bundle=%@", libraryPath, bundlePath]];
  IrmagobridgeStart(self, libraryPath, bundlePath);
  return self;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  [self debugLog:[NSString stringWithFormat:@"handling %@", call.method]];
  IrmagobridgeDispatchFromNative(call.method, (NSString*)call.arguments);
  result(nil);
}

- (void)debugLog:(NSString*)message {
#if DEBUG
  NSLog(@"[IrmaMobileBridgePlugin] %@", message);
#endif
}

- (void)dispatchFromGo:(NSString*)name payload:(NSString*)payload {
  [self debugLog:[NSString stringWithFormat:@"dispatching %@(%@)", name, payload]];
  [channel invokeMethod:name arguments:payload];
}

@end
