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

    NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *targetURL = [tempDir URLByAppendingPathComponent:url.lastPathComponent];

    if ([[NSFileManager defaultManager] fileExistsAtPath:targetURL.path]) {
        NSError *removeError = nil;
        [[NSFileManager defaultManager] removeItemAtURL:targetURL error:&removeError];
        if (removeError) {
            if (self.rejecter) {
                self.rejecter(@"REMOVE_ERROR", @"Failed to remove existing file in temp directory", removeError);
                self.resolver = nil;
                self.rejecter = nil;
            }
            return;
        }
    }

    NSError *copyError = nil;
    [[NSFileManager defaultManager] copyItemAtURL:url toURL:targetURL error:&copyError];
    [url stopAccessingSecurityScopedResource];

    if (copyError) {
        if (self.rejecter) {
            self.rejecter(@"COPY_ERROR", @"Could not copy file to temporary location", copyError);
            self.resolver = nil;
            self.rejecter = nil;
        }
        return;
    }

    NSError *attrError = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:targetURL.path error:&attrError];
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
        @"uri": targetURL.absoluteString,
        @"name": targetURL.lastPathComponent,
        @"type": targetURL.pathExtension,
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
