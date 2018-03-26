#import <CallKit/CallKit.h>
#import <Foundation/Foundation.h>

@protocol SINClient;
@protocol SINCall;

@interface SINCallKitProvider : NSObject <CXProviderDelegate>

- (instancetype)initWithClient:(id<SINClient>)client;

- (void)reportNewIncomingCall:(id<SINCall>)call;

- (BOOL)callExists:(NSString*)callId;

- (id<SINCall>)currentEstablishedCall;

@end
