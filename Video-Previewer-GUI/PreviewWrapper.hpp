//
//  PreviewWrapper.hpp
//  Video-Previewer
//
//  Created by Mathew Denys on 13/01/21.
//

#ifndef PreviewWrapper_h
#define PreviewWrapper_h

#import <Foundation/Foundation.h>

@interface TestWrapper : NSObject

- (instancetype) init;
- (NSString*)    getString;

@end



@interface VideoPreviewWrapper : NSObject

- (instancetype) init:(NSString*)filePath;

@end


#endif /* PreviewWrapper_h */
