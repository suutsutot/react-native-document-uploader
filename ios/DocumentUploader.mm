#import <React/RCTBridgeModule.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface DocumentUploader : NSObject <RCTBridgeModule, UIDocumentPickerDelegate>

@property (nonatomic, copy) RCTPromiseResolveBlock resolver;
@property (nonatomic, copy) RCTPromiseRejectBlock rejecter;

@end

@implementation DocumentUploader

RCT_EXPORT_MODULE(DocumentUploader);

RCT_EXPORT_METHOD(pick:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (!rootVC) {
            reject(@"NO_ROOT", @"No root view controller", nil);
            return;
        }

        self.resolver = resolve;
        self.rejecter = reject;

        UIDocumentPickerViewController *picker;
        if (@available(iOS 14.0, *)) {
            picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeData]];
        } else {
            picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]
                                                                            inMode:UIDocumentPickerModeImport];
        }

        picker.delegate = self;
        picker.modalPresentationStyle = UIModalPresentationFormSheet;
        [rootVC presentViewController:picker animated:YES completion:nil];
    });
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;

    if (!url) {
        if (self.resolver) {
            self.resolver([NSNull null]);
            self.resolver = nil;
            self.rejecter = nil;
        }
        return;
    }

    BOOL accessGranted = [url startAccessingSecurityScopedResource];
    if (!accessGranted) {
        if (self.rejecter) {
            self.rejecter(@"ACCESS_DENIED", @"Could not access file", nil);
            self.resolver = nil;
            self.rejecter = nil;
        }
        return;
    }

    NSString *ext = url.pathExtension.lowercaseString;

    NSURL *outputURL = nil;

    if ([ext isEqualToString:@"heic"]) {
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:imageData];

        if (!image) {
            [url stopAccessingSecurityScopedResource];
            if (self.rejecter) {
                self.rejecter(@"HEIC_DECODE_ERROR", @"Could not decode HEIC image", nil);
                self.resolver = nil;
                self.rejecter = nil;
            }
            return;
        }

        NSData *jpegData = UIImageJPEGRepresentation(image, 1.0);
        if (!jpegData) {
            [url stopAccessingSecurityScopedResource];
            if (self.rejecter) {
                self.rejecter(@"JPEG_ENCODE_ERROR", @"Failed to encode JPEG", nil);
                self.resolver = nil;
                self.rejecter = nil;
            }
            return;
        }

        NSString *filename = [[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
        NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:filename];

        [jpegData writeToURL:tempURL atomically:YES];

        outputURL = tempURL;

        [url stopAccessingSecurityScopedResource];

    } else {
        NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        outputURL = [tempDir URLByAppendingPathComponent:url.lastPathComponent];

        if ([[NSFileManager defaultManager] fileExistsAtPath:outputURL.path]) {
            [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
        }

        [[NSFileManager defaultManager] copyItemAtURL:url toURL:outputURL error:nil];
        [url stopAccessingSecurityScopedResource];
    }

    NSError *attrError = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:outputURL.path error:&attrError];
    if (attrError) {
        if (self.rejecter) {
            self.rejecter(@"ATTR_ERROR", @"Could not read file attributes", attrError);
            self.resolver = nil;
            self.rejecter = nil;
        }
        return;
    }

    NSNumber *size = attributes[NSFileSize] ?: @0;

    NSDictionary *result = @{
        @"uri": outputURL.absoluteString,
        @"name": outputURL.lastPathComponent,
        @"type": outputURL.pathExtension,
        @"size": size
    };

    if (self.resolver) {
        self.resolver(result);
        self.resolver = nil;
        self.rejecter = nil;
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    if (self.resolver) {
        self.resolver([NSNull null]);
        self.resolver = nil;
        self.rejecter = nil;
    }
}

@end
