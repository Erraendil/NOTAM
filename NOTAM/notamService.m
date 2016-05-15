#import "notamService.h"
#import <libxml/xmlstring.h>
#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#endif
@implementation notamService
+ (void)initialize
{
    [[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"xsd" forKey:@"http://www.w3.org/2001/XMLSchema"];
    [[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"notamService" forKey:@"urn:notam/v1/"];
}
+ (notamBinding *)notamBinding
{
    return [[[notamBinding alloc] initWithAddress:@"https://apidev.rocketroute.com/notam/v1/"] autorelease];
}
@end
@implementation notamBinding
@synthesize address;
@synthesize defaultTimeout;
@synthesize logXMLInOut;
@synthesize cookies;
@synthesize authUsername;
@synthesize authPassword;
- (id)init
{
    if((self = [super init])) {
        address = nil;
        cookies = nil;
        defaultTimeout = 10;//seconds
        logXMLInOut = NO;
        synchronousOperationComplete = NO;
    }
    
    return self;
}
- (id)initWithAddress:(NSString *)anAddress
{
    if((self = [self init])) {
        self.address = [NSURL URLWithString:anAddress];
    }
    
    return self;
}
- (void)addCookie:(NSHTTPCookie *)toAdd
{
    if(toAdd != nil) {
        if(cookies == nil) cookies = [[NSMutableArray alloc] init];
        [cookies addObject:toAdd];
    }
}
- (notamBindingResponse *)performSynchronousOperation:(notamBindingOperation *)operation
{
    synchronousOperationComplete = NO;
    [operation start];
    
    // Now wait for response
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    
    while (!synchronousOperationComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    return operation.response;
}
- (void)performAsynchronousOperation:(notamBindingOperation *)operation
{
    [operation start];
}
- (void) operation:(notamBindingOperation *)operation completedWithResponse:(notamBindingResponse *)response
{
    synchronousOperationComplete = YES;
}
- (notamBindingResponse *)getNotamUsingRequest:(NSString *)aRequest
{
    return [self performSynchronousOperation:[[(notamBinding_getNotam*)[notamBinding_getNotam alloc] initWithBinding:self delegate:self
                                                                                                             request:aRequest
                                               ] autorelease]];
}
- (void)getNotamAsyncUsingRequest:(NSString *)aRequest  delegate:(id<notamBindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [[(notamBinding_getNotam*)[notamBinding_getNotam alloc] initWithBinding:self delegate:responseDelegate
                                                                                                        request:aRequest
                                          ] autorelease]];
}
- (void)sendHTTPCallUsingBody:(NSString *)outputBody soapAction:(NSString *)soapAction forOperation:(notamBindingOperation *)operation
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.address
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:self.defaultTimeout];
    NSData *bodyData = [outputBody dataUsingEncoding:NSUTF8StringEncoding];
    
    if(cookies != nil) {
        [request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
    }
    [request setValue:@"wsdl2objc" forHTTPHeaderField:@"User-Agent"];
    [request setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
    [request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%u", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:self.address.host forHTTPHeaderField:@"Host"];
    [request setHTTPMethod: @"POST"];
    // set version 1.1 - how?
    [request setHTTPBody: bodyData];
    
    if(self.logXMLInOut) {
        NSLog(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
        NSLog(@"OutputBody:\n%@", outputBody);
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:operation];
    
    operation.urlConnection = connection;
    [connection release];
}
- (void) dealloc
{
    [address release];
    [cookies release];
    [super dealloc];
}
@end
@implementation notamBindingOperation
@synthesize binding;
@synthesize response;
@synthesize delegate;
@synthesize responseData;
@synthesize urlConnection;
- (id)initWithBinding:(notamBinding *)aBinding delegate:(id<notamBindingResponseDelegate>)aDelegate
{
    if (self = [super init]) {
        self.binding = aBinding;
        response = nil;
        self.delegate = aDelegate;
        self.responseData = nil;
        self.urlConnection = nil;
    }
    
    return self;
}
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.binding.authUsername
                                                 password:self.binding.authPassword
                                              persistence:NSURLCredentialPersistenceForSession];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Authentication Error" forKey:NSLocalizedDescriptionKey];
        NSError *authError = [NSError errorWithDomain:@"Connection Authentication" code:0 userInfo:userInfo];
        [self connection:connection didFailWithError:authError];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    NSHTTPURLResponse *httpResponse;
    if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *) urlResponse;
    } else {
        httpResponse = nil;
    }
    
    if(binding.logXMLInOut) {
        NSLog(@"ResponseStatus: %u\n", [httpResponse statusCode]);
        NSLog(@"ResponseHeaders:\n%@", [httpResponse allHeaderFields]);
    }
    
    NSMutableArray *cookies = [[NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:binding.address] mutableCopy];
    
    binding.cookies = cookies;
    [cookies release];
    if ([urlResponse.MIMEType rangeOfString:@"text/xml"].length == 0) {
        NSError *error = nil;
        [connection cancel];
        if ([httpResponse statusCode] >= 400) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]] forKey:NSLocalizedDescriptionKey];
            
            error = [NSError errorWithDomain:@"notamBindingResponseHTTP" code:[httpResponse statusCode] userInfo:userInfo];
        } else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
                                      [NSString stringWithFormat: @"Unexpected response MIME type to SOAP call:%@", urlResponse.MIMEType]
                                                                 forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"notamBindingResponseHTTP" code:1 userInfo:userInfo];
        }
        
        [self connection:connection didFailWithError:error];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (responseData == nil) {
        responseData = [data mutableCopy];
    } else {
        [responseData appendData:data];
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (binding.logXMLInOut) {
        NSLog(@"ResponseError:\n%@", error);
    }
    response.error = error;
    [delegate operation:self completedWithResponse:response];
}
- (void)dealloc
{
    [binding release];
    [response release];
    delegate = nil;
    [responseData release];
    [urlConnection release];
    
    [super dealloc];
}
@end
@implementation notamBinding_getNotam
@synthesize request;
- (id)initWithBinding:(notamBinding *)aBinding delegate:(id<notamBindingResponseDelegate>)responseDelegate
              request:(NSString *)aRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.request = aRequest;
    }
    
    return self;
}
- (void)dealloc
{
    if(request != nil) [request release];
    
    [super dealloc];
}
- (void)main
{
    [response autorelease];
    response = [notamBindingResponse new];
    
    notamBinding_envelope *envelope = [notamBinding_envelope sharedInstance];
    
    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *bodyElements = nil;
    bodyElements = [NSMutableDictionary dictionary];
    if(request != nil) [bodyElements setObject:request forKey:@"request"];
    
    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements];
    
    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"urn:xmethods-notam#getNotam" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;
        
        if (binding.logXMLInOut) {
            NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease]);
        }
        
        doc = xmlParseMemory([responseData bytes], [responseData length]);
        
        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];
            
            response.error = [NSError errorWithDomain:@"notamBindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;
            
            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {
                    
                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];
                        
                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "response")) {
                                    NSString  *bodyObject = [NSString  deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                // Had to modify auto-generated class with "soap" prefix XML compare
                                else if (xmlStrEqual(bodyNode->ns->prefix, (const xmlChar *) "soap") &&
                                         xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }
                        
                        response.bodyParts = responseBodyParts;
                    }
                }
            }
            
            xmlFreeDoc(doc);
        }
        
        xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
static notamBinding_envelope *notamBindingSharedEnvelopeInstance = nil;
@implementation notamBinding_envelope
+ (notamBinding_envelope *)sharedInstance
{
    if(notamBindingSharedEnvelopeInstance == nil) {
        notamBindingSharedEnvelopeInstance = [notamBinding_envelope new];
    }
    
    return notamBindingSharedEnvelopeInstance;
}
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements
{
    xmlDocPtr doc;
    
    doc = xmlNewDoc((const xmlChar*)XML_DEFAULT_VERSION);
    if (doc == NULL) {
        NSLog(@"Error creating the xml document tree");
        return @"";
    }
    
    xmlNodePtr root = xmlNewDocNode(doc, NULL, (const xmlChar*)"Envelope", NULL);
    xmlDocSetRootElement(doc, root);
    
    xmlNsPtr soapEnvelopeNs = xmlNewNs(root, (const xmlChar*)"http://schemas.xmlsoap.org/soap/envelope/", (const xmlChar*)"soap");
    xmlSetNs(root, soapEnvelopeNs);
    
    xmlNsPtr xslNs = xmlNewNs(root, (const xmlChar*)"http://www.w3.org/1999/XSL/Transform", (const xmlChar*)"xsl");
    xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema-instance", (const xmlChar*)"xsi");
    
    xmlNewNsProp(root, xslNs, (const xmlChar*)"version", (const xmlChar*)"1.0");
    
    xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema", (const xmlChar*)"xsd");
    xmlNewNs(root, (const xmlChar*)"urn:notam/v1/", (const xmlChar*)"notamService");
    
    if((headerElements != nil) && ([headerElements count] > 0)) {
        xmlNodePtr headerNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Header", NULL);
        xmlAddChild(root, headerNode);
        
        for(NSString *key in [headerElements allKeys]) {
            id header = [headerElements objectForKey:key];
            xmlAddChild(headerNode, [header xmlNodeForDoc:doc elementName:key]);
        }
    }
    
    if((bodyElements != nil) && ([bodyElements count] > 0)) {
        xmlNodePtr bodyNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Body", NULL);
        xmlAddChild(root, bodyNode);
        
        for(NSString *key in [bodyElements allKeys]) {
            id body = [bodyElements objectForKey:key];
            xmlAddChild(bodyNode, [body xmlNodeForDoc:doc elementName:key]);
        }
    }
    
    xmlChar *buf;
    int size;
    xmlDocDumpFormatMemory(doc, &buf, &size, 1);
    
    NSString *serializedForm = [NSString stringWithCString:(const char*)buf encoding:NSUTF8StringEncoding];
    xmlFree(buf);
    
    xmlFreeDoc(doc);	
    return serializedForm;
}
@end
@implementation notamBindingResponse
@synthesize headers;
@synthesize bodyParts;
@synthesize error;
- (id)init
{
    if((self = [super init])) {
        headers = nil;
        bodyParts = nil;
        error = nil;
    }
    
    return self;
}
-(void)dealloc {
    self.headers = nil;
    self.bodyParts = nil;
    self.error = nil;	
    [super dealloc];
}
@end
