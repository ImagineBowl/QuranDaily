//
//  QuranArabicTextSanitizer.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import Foundation

enum QuranArabicTextSanitizer {
    /// Strips characters that iOS may render as emoji when using standard Arabic fonts.
    /// Indo-Pak sources embed Private Use Area codes for specialized mushaf fonts; without
    /// those fonts the system often shows emoji fallbacks (e.g. tram, heart icons).
    static func sanitizedForDisplay(_ text: String) -> String {
        String(text.unicodeScalars.filter { shouldKeepScalar($0) })
    }

    private static func shouldKeepScalar(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value

        if value >= 0xE000 && value <= 0xF8FF {
            return false
        }

        if value >= 0xFE00 && value <= 0xFE0F {
            return false
        }

        if value >= 0xE0000 && value <= 0xE007F {
            return false
        }

        if scalar.properties.isEmoji {
            return false
        }

        return true
    }
}

extension String {
    var sanitizedForQuranDisplay: String {
        QuranArabicTextSanitizer.sanitizedForDisplay(self)
    }
}
