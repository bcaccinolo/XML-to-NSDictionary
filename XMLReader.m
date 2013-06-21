//
//  XMLReader.m
//

#import "XMLReader.h"

NSString *const kXMLReaderTextNodeKey = @"text";

@interface XMLReader (Internal)

- (id)initWithError:(NSError *__autoreleasing *)error;
- (NSDictionary *)objectWithData:(NSData *)data;

@end


@implementation XMLReader

#pragma mark -
#pragma mark Public methods

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    XMLReader *reader = [[XMLReader alloc] initWithError:error];
    NSDictionary *rootDictionary = [reader objectWithData:data];
    return rootDictionary;
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError *__autoreleasing *)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data error:error];
}

#pragma mark -
#pragma mark Parsing

- (id)initWithError:(NSError *__autoreleasing *)error
{
    if (self = [super init]) {
        errorPointer = error;
    }
    return self;
}

- (NSDictionary *)objectWithData:(NSData *)data
{
    /* Clear out any old data */
    dictionaryStack = nil;
    textInProgress = nil;
    
    dictionaryStack = [[NSMutableArray alloc] init];
    textInProgress = [[NSMutableString alloc] init];
    
    /* Initialize the stack with a fresh dictionary */
    [dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    /* Parse the XML */
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    BOOL success = [parser parse];
    
    /* Return the stack's root dictionary on success */
    if (success) {
        NSDictionary *resultDict = dictionaryStack[0];
        return resultDict;
    }
    
    return nil;
}

#pragma mark -
#pragma mark NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    #pragma unused(parser)
    #pragma unused(namespaceURI)
    #pragma unused(qName)
    
    /* Get the dictionary for the current level in the stack */
    NSMutableDictionary *parentDict = [dictionaryStack lastObject];

    /* Create the child dictionary for the new element, and initilaize it with the attributes */
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];
    
    /* If there's already an item for this key, it means we need to create an array */
    id existingValue = parentDict[elementName];
    if (existingValue) {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]]) {
            /* The array exists, so use it */
            array = (NSMutableArray *) existingValue;
        } else {
            /* Create an array if it doesn't exist */
            array = [NSMutableArray array];
            [array addObject:existingValue];

            /* Replace the child dictionary with an array of children dictionaries */
            parentDict[elementName] = array;
        }
        
        /* Add the new child dictionary to the array */
        [array addObject:childDict];
    } else {
        /* No existing value, so update the dictionary */
        parentDict[elementName] = childDict;
    }
    
    /* Update the stack */
    [dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    #pragma unused(parser)
    #pragma unused(elementName)
    #pragma unused(namespaceURI)
    #pragma unused(qName)

    /* Update the parent dict with text info */
    NSMutableDictionary *dictInProgress = [dictionaryStack lastObject];
    
    /* Set the text property */
    if ([textInProgress length] > 0) {
        dictInProgress[kXMLReaderTextNodeKey] = textInProgress;

        /* Reset the text */
        textInProgress = nil; //[textInProgress release];
        textInProgress = [[NSMutableString alloc] init];
    }
    
    /* Pop the current dict */
    [dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    #pragma unused(parser)

    /* Build the text value */
    [textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    #pragma unused(parser)

    /* Set the error pointer to the parser's error object */
    *errorPointer = parseError;
}

@end
