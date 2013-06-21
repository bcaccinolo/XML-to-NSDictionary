//
//  XMLReader.h
//
//

#import <Foundation/Foundation.h>


@interface XMLReader : NSObject <NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
    __autoreleasing NSError **errorPointer;
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(__autoreleasing NSError **)error;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(__autoreleasing NSError **)error;

@end
