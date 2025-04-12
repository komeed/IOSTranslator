# Guide:
- Either install Xcode and download repo and run project or install from app store.
- Upon running application, you can either scan the document with Apple's pdf scanner or take a photo.
- * Scanning Document will automatically generate pdf text and open a, as apple calls it, "ActivityViewController" (basically where you can save/share the file anywhere)
  * Taking photo will open an edit photo page, where you can choose to crop or open the translate page that has a toggle at the bottom to toggle translation by word or translation by line. Then, you can either save or delete the image.
#
# How I Made It:
- I used Apple's Vision Framework to perform OCR on the image and retrieve characters and corresponding bounding boxes.
- Before Apple's release of the Translation API, I used MySQL (sqlite3 in Xcode) to store chinese dictionary into a database, search characters and retrieve pronounciation and definitions corresponding to those characters.
- After its release I used Apple's new Translation API to make it faster, more code efficient, and not needing every language's dictionary stored into a database.
- For the UI I used SwiftUI (worst decision of my life by the way) and UIKit viewcontrollers.
- #
- More information on classes and bits of code is explained in comments in my code itself.
