<p align="center">
<a href="https://github.com/liamcottle/appmarks-ios"><img src="Appmarks.png" width="150"></a>
</p>

<h2 align="center">Appmarks</h2>

Welcome | Create Appmark | Main Content | Group
:-:|:-:|:-:|:-:
![](Screenshots/1_main_empty.png) | ![](Screenshots/2_create_appmark.png) | ![](Screenshots/3_main_content.png) | ![](Screenshots/4_group.png)

# About

Appmarks is an [iOS app](https://apps.apple.com/us/app/appmarks/id1554446833?platform=iphone) developed with SwiftUI that lets you bookmark apps from the AppStore.

I've been wanting to learn to develop iOS apps with SwiftUI, but hadn't been able to come up with any ideas for a starter project. After coming across this <s>[tweet reply](https://twitter.com/j_holtslander/status/1355273816847437831)</s> [archived tweet](http://web.archive.org/web/20210129215733/https://twitter.com/j_holtslander/status/1355273816847437831) I decided this is what I would build.

> I wish the app store had a way to bookmark apps.

I'm completely new to Swift and SwiftUI, (coming from a Java/PHP/ObjC background), so if I'm doing something wrong, feel free to let me know!

# Features

Currently implemented features:

- [x] Bookmark apps from AppStore URLs on your Clipboard.
- [x] Bookmarked apps list show the app name, icon, developer and price.
- [x] Tap to view the app on the AppStore.
- [x] Swipe to remove bookmarked apps.
- [x] Share apps directly from the AppStore into Appmarks.
- [x] Create groups to organise bookmarked apps with a custom title.

# How it works

When an AppStore link is provided, the App ID is parsed from the URL and a request is made to the [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/LookupExamples.html) to retrieve its metadata.

# License

MIT