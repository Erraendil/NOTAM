#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import <libxml/tree.h>
#import "USGlobals.h"
/* Cookies handling provided by http://en.wikibooks.org/wiki/Programming:WebObjects/Web_Services/Web_Service_Provider */
#import <libxml/parser.h>
#import "xsd.h"
#import "notamService.h"
@class notamBinding;
@interface notamService : NSObject {
	
}
+ (notamBinding *)notamBinding;
@end
@class notamBindingResponse;
@class notamBindingOperation;
@protocol notamBindingResponseDelegate <NSObject>
- (void) operation:(notamBindingOperation *)operation completedWithResponse:(notamBindingResponse *)response;
@end
@interface notamBinding : NSObject <notamBindingResponseDelegate> {
	NSURL *address;
	NSTimeInterval defaultTimeout;
	NSMutableArray *cookies;
	BOOL logXMLInOut;
	BOOL synchronousOperationComplete;
	NSString *authUsername;
	NSString *authPassword;
}
@property (copy) NSURL *address;
@property (assign) BOOL logXMLInOut;
@property (assign) NSTimeInterval defaultTimeout;
@property (nonatomic, retain) NSMutableArray *cookies;
@property (nonatomic, retain) NSString *authUsername;
@property (nonatomic, retain) NSString *authPassword;
- (id)initWithAddress:(NSString *)anAddress;
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(notamBindingOperation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (notamBindingResponse *)getNotamUsingRequest:(NSString *)aRequest ;
- (void)getNotamAsyncUsingRequest:(NSString *)aRequest  delegate:(id<notamBindingResponseDelegate>)responseDelegate;
@end
@interface notamBindingOperation : NSOperation {
	notamBinding *binding;
	notamBindingResponse *response;
	id<notamBindingResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (retain) notamBinding *binding;
@property (readonly) notamBindingResponse *response;
@property (nonatomic, assign) id<notamBindingResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(notamBinding *)aBinding delegate:(id<notamBindingResponseDelegate>)aDelegate;
@end
@interface notamBinding_getNotam : notamBindingOperation {
	NSString * request;
}
@property (retain) NSString * request;
- (id)initWithBinding:(notamBinding *)aBinding delegate:(id<notamBindingResponseDelegate>)aDelegate
	request:(NSString *)aRequest
;
@end
@interface notamBinding_envelope : NSObject {
}
+ (notamBinding_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements;
@end
@interface notamBindingResponse : NSObject {
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (retain) NSArray *headers;
@property (retain) NSArray *bodyParts;
@property (retain) NSError *error;
@end
