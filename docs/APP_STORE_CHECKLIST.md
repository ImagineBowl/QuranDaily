# QuranDaily — App Store submission checklist

Use before **Submit for Review**. Bundle ID: `com.Imaginebowl.QuranDaily`.

---

## 1. Apple Developer & App Store Connect

- [ ] Sign in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] **Agreements, Tax, and Banking** complete (Paid Apps agreement for IAP)
- [ ] Create app: iOS, name **QuranDaily**, bundle ID `com.Imaginebowl.QuranDaily`
- [ ] Primary category: **Books** or **Reference**

---

## 2. Legal & privacy

- [ ] **Privacy Policy** URL (HTTPS) — on-device data, APIs, IAP, contact email
- [ ] URL entered in App Store Connect + link in app Settings (recommended)
- [ ] **Support** URL or email in Connect and app
- [ ] **App Privacy** labels completed honestly (no account; local bookmarks/position; network for Quran/audio)
- [ ] **Export compliance** (HTTPS only → typically exempt)

---

## 3. In-App Purchases (tip jar)

- [ ] Consumables created and **Ready to Submit**:

| Product ID |
|------------|
| `com.Imaginebowl.QuranDaily.tip.small` |
| `com.Imaginebowl.QuranDaily.tip.medium` |
| `com.Imaginebowl.QuranDaily.tip.large` |

- [ ] Display names, descriptions, pricing, review screenshot
- [ ] **Sandbox** purchase tested on device
- [ ] Copy clear: optional, no features locked

---

## 4. Build (Xcode)

- [ ] Version / build number set for release
- [ ] Distribution signing
- [ ] Archive → Validate → Upload
- [ ] Build processed in TestFlight; attached to version
- [ ] `UIBackgroundModes = audio` (already in project)

**Recommended before submit**

- [ ] Dynamic version in Settings (from bundle)
- [ ] Privacy + Support links in Settings
- [ ] Lock screen Now Playing (optional v1.0)

---

## 5. TestFlight

- [ ] Install on physical iPhone
- [ ] First launch Quran download
- [ ] Read, bookmark, Continue Reading (after real read)
- [ ] Listen, Recent (Listen-only), audio stream/download
- [ ] Background audio
- [ ] Settings, cache clear, Sandbox tip

---

## 6. Listing metadata

- [ ] Description, subtitle, keywords
- [ ] Screenshots (required iPhone sizes)
- [ ] 1024×1024 app icon
- [ ] Age rating (likely 4+)
- [ ] Copyright; credit AlQuran Cloud / reciter in description

---

## 7. App Review notes

- [ ] Notes: first-launch download, how to play audio, Sandbox for tips
- [ ] Contact phone/email for reviewer
- [ ] No login required

---

## 8. Content

- [ ] AlQuran Cloud / islamic.network terms acceptable for your use
- [ ] Attribution in app or store listing

---

## 9. Submit

- [ ] IAPs linked to version; metadata complete
- [ ] **Submit for Review**

---

## 10. After approval

- [ ] Release
- [ ] Plan 1.0.1 (lock screen, in-app legal links, polish)

---

## Already in good shape

- Paid Developer membership
- Core app: Read, Listen, Bookmarks, Settings, offline text, optional tips
- StoreKit 2 + `Transaction.updates`
- Background audio capability

## Highest-risk gaps

1. Privacy Policy URL  
2. Support contact  
3. IAP fully configured + Sandbox tested  
4. Screenshots + listing  
5. Real-device TestFlight pass  
