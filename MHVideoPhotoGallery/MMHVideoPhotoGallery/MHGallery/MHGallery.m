
#import "MHGallery.h"
#import "MHOverviewController.h"
#import <objc/runtime.h>

NSString * const MHYoutubeBaseURL          = @"http://www.youtube.com/watch?v=%@";
NSString * const MHYoutubeChannel          = @"https://gdata.youtube.com/feeds/api/users/%@/uploads?&max-results=50&alt=json";
NSString * const MHYoutubePlayBaseURL      = @"https://www.youtube.com/get_video_info?video_id=%@&el=embedded&ps=default&eurl=&gl=US&hl=%@";
NSString * const MHYoutubeInfoBaseURL      = @"http://gdata.youtube.com/feeds/api/videos/%@?v=2&alt=jsonc";
NSString * const MHVimeoThumbBaseURL       = @"http://vimeo.com/api/v2/video/%@.json";
NSString * const MHVimeoVideoBaseURL       = @"http://player.vimeo.com/v2/video/%@/config";
NSString * const MHVimeoBaseURL            = @"http://vimeo.com/%@";
NSString * const MHGalleryViewModeShare    = @"MHGalleryViewModeShare";


NSDictionary *MHDictionaryForQueryString(NSString *string){
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	NSArray *allFieldsArray = [string componentsSeparatedByString:@"&"];
	for (NSString *fieldString in allFieldsArray){
		NSArray *pairArray = [fieldString componentsSeparatedByString:@"="];
		if (pairArray.count == 2){
			NSString *key = pairArray[0];
			NSString *value = [pairArray[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			dictionary[key] = value;
		}
	}
	return dictionary;
}

NSBundle *MHGalleryBundle(void) {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kMHGalleryBundleName];
        bundle = [NSBundle bundleWithPath:path];
    });
    return bundle;
}

static NSString* (^ CustomLocalizationBlock)(NSString *localization) = nil;
static UIImage* (^ CustomImageBlock)(NSString *imageToChangeName) = nil;

void MHGalleryCustomImageBlock(UIImage *(^customImageBlock)(NSString *imageToChangeName)){
    CustomImageBlock = customImageBlock;
}
void MHGalleryCustomLocalizationBlock(NSString *(^customLocalizationBlock)(NSString *stringToLocalize)){
    CustomLocalizationBlock = customLocalizationBlock;
}

NSString *MHGalleryLocalizedString(NSString *localizeString) {
    if (CustomLocalizationBlock) {
        NSString *string = CustomLocalizationBlock(localizeString);
        if (string) {
            return string;
        }
    }
    return  NSLocalizedStringFromTableInBundle(localizeString, @"MHGallery", MHGalleryBundle(), @"");
}


UIImage *MHGalleryImage(NSString *imageName){
    if (CustomImageBlock) {
        UIImage *changedImage = CustomImageBlock(imageName);
        if (changedImage) {
            return changedImage;
        }
    }
    return [UIImage imageNamed:imageName];
}



