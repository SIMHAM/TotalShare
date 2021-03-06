//
//	CGPDFDocument.m
//	Reader v2.0.0
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011 Julius Oklamcak. All rights reserved.
//
//	This work is being made available under a Creative Commons Attribution license:
//		«http://creativecommons.org/licenses/by/3.0/»
//	You are free to use this work and any derivatives of this work in personal and/or
//	commercial products and projects as long as the above copyright is maintained and
//	the original author is attributed.
//

#import "CGPDFDocument.h"

//
//	CGPDFDocumentRef CGPDFDocumentCreateX(CFURLRef, NSString *) function
//

CGPDFDocumentRef CGPDFDocumentCreateX(CFURLRef theURL, NSString *password)
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	CGPDFDocumentRef thePDFDocRef = NULL;

	if (theURL != NULL) // Check for non-NULL CFURLRef
	{
		thePDFDocRef = CGPDFDocumentCreateWithURL(theURL);

		if (thePDFDocRef != NULL) // Check for non-NULL CGPDFDocumentRef
		{
			if (CGPDFDocumentIsEncrypted(thePDFDocRef) == TRUE) // Encrypted
			{
				// Try a blank password first, per Apple's Quartz PDF example

				if (CGPDFDocumentUnlockWithPassword(thePDFDocRef, "") == FALSE)
				{
					// Nope, now let's try the provided password to unlock the PDF

					if ((password != nil) && ([password length] > 0)) // Not blank?
					{
						char text[128]; // char array buffer for the string conversion

						[password getCString:text maxLength:126 encoding:NSUTF8StringEncoding];

						if (CGPDFDocumentUnlockWithPassword(thePDFDocRef, text) == FALSE) // Log failure
						{
							#ifdef DEBUG
								NSLog(@"CGPDFDocumentCreateX: Unable to unlock [%@] with [%@]", theURL, password);
							#endif
						}
					}
				}

				if (CGPDFDocumentIsUnlocked(thePDFDocRef) == FALSE) // Cleanup unlock failure
				{
					CGPDFDocumentRelease(thePDFDocRef), thePDFDocRef = NULL;
				}
			}
		}
	}
	else // Log an error diagnostic
	{
		#ifdef DEBUG
			NSLog(@"CGPDFDocumentCreateX: theURL == NULL");
		#endif
	}

	return thePDFDocRef;
}

//
//	CGSize CGPDFDocumentPageSize(CFURLRef, NSString *, NSInteger) function
//

CGSize CGPDFDocumentPageSize(CFURLRef theURL, NSString *password, NSInteger page)
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	CGSize pageSize = CGSizeZero; // Default size on error

	CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateX(theURL, password);

	if (thePDFDocRef != NULL) // Check for non-NULL CGPDFDocumentRef
	{
		if (page < 1) page = 1; // Check the lower page bounds

		NSInteger pages = CGPDFDocumentGetNumberOfPages(thePDFDocRef);

		if (page > pages) page = pages; // Check the upper page bounds

		CGPDFPageRef thePDFPageRef = CGPDFDocumentGetPage(thePDFDocRef, page);

		if (thePDFPageRef != NULL) // Check for non-NULL CGPDFPageRef
		{
			CGRect cropBoxRect = CGPDFPageGetBoxRect(thePDFPageRef, kCGPDFCropBox);
			CGRect mediaBoxRect = CGPDFPageGetBoxRect(thePDFPageRef, kCGPDFMediaBox);
			CGRect effectiveRect = CGRectIntersection(cropBoxRect, mediaBoxRect);

			NSInteger degrees = CGPDFPageGetRotationAngle(thePDFPageRef);

			if (degrees == 0) // Check for page rotation
			{
				pageSize = effectiveRect.size;
			}
			else // Rotate the effective rect so many degrees
			{
				CGFloat radians = (degrees * M_PI / 180.0);

				CGAffineTransform rotation = CGAffineTransformMakeRotation(radians);

				CGRect rotatedRect = CGRectApplyAffineTransform(effectiveRect, rotation);

				pageSize = rotatedRect.size;
			}
		}
		else // Log an error diagnostic
		{
			#ifdef DEBUG
				NSLog(@"CGPDFDocumentPageSize: thePDFPageRef == NULL");
			#endif
		}

		CGPDFDocumentRelease(thePDFDocRef); // Cleanup CGPDFDocumentRef
	}
	else // Log an error diagnostic
	{
		#ifdef DEBUG
			NSLog(@"CGPDFDocumentPageSize: thePDFDocRef == NULL");
		#endif
	}

	return pageSize;
}

//
//	BOOL CGPDFDocumentNeedsPassword(CFURLRef, NSString *) function
//

BOOL CGPDFDocumentNeedsPassword(CFURLRef theURL, NSString *password)
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	BOOL needPassword = NO; // Default flag

	if (theURL != NULL) // Check for non-NULL CFURLRef
	{
		CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateWithURL(theURL);

		if (thePDFDocRef != NULL) // Check for non-NULL CGPDFDocumentRef
		{
			if (CGPDFDocumentIsEncrypted(thePDFDocRef) == TRUE) // Encrypted
			{
				// Try a blank password first, per Apple's Quartz PDF example

				if (CGPDFDocumentUnlockWithPassword(thePDFDocRef, "") == FALSE)
				{
					// Nope, now let's try the provided password to unlock the PDF

					if ((password != nil) && ([password length] > 0)) // Not blank?
					{
						char text[128]; // char array buffer for the string conversion

						[password getCString:text maxLength:126 encoding:NSUTF8StringEncoding];

						if (CGPDFDocumentUnlockWithPassword(thePDFDocRef, text) == FALSE)
						{
							needPassword = YES;
						}
					}
					else
						needPassword = YES;
				}
			}

			CGPDFDocumentRelease(thePDFDocRef); // Cleanup CGPDFDocumentRef
		}
	}
	else // Log an error diagnostic
	{
		#ifdef DEBUG
			NSLog(@"CGPDFDocumentNeedsPassword: theURL == NULL");
		#endif
	}

	return needPassword;
}

// EOF
