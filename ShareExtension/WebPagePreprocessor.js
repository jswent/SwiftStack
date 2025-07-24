//
//  WebPagePreprocessor.js
//  stack-share
//
//  JavaScript preprocessing file for extracting web page metadata
//

var ExtensionPreprocessingJS = {
    run: function(args) {
        // Extract basic page metadata
        var title = document.title || "";
        var url = document.URL || "";
        var description = "";
        
        // Try to extract description from meta tags
        var metaDescription = document.querySelector('meta[name="description"]');
        if (metaDescription) {
            description = metaDescription.getAttribute("content") || "";
        }
        
        // Fallback to Open Graph description
        if (!description) {
            var ogDescription = document.querySelector('meta[property="og:description"]');
            if (ogDescription) {
                description = ogDescription.getAttribute("content") || "";
            }
        }
        
        // Try to extract a representative image URL
//        var imageUrl = "";
//        var ogImage = document.querySelector('meta[property="og:image"]');
//        if (ogImage) {
//            imageUrl = ogImage.getAttribute("content") || "";
//        }
        
        // Return the extracted data
        args.completionFunction({
            title: title.trim(),
            url: url,
            description: description.trim(),
//            imageUrl: imageUrl
        });
    }
};
