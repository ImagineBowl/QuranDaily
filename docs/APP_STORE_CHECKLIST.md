# QuranDaily — App Store submission checklist

Use before **Submit for Review**. Bundle ID: `com.Imaginebowl.QuranDaily`.

---

## 1. Apple Developer & App Store Connect

- [ ] Sign in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] **Agreements, Tax, and Banking** complete (Paid Apps agreement for IAP)
- [ ] Create app: iOS, name **QuranDaily**, bundle ID `com.Imaginebowl.QuranDaily`
- [ ] Primary category: **Books** or **Reference**
- [ ] Copy the **Apple ID** (numeric) from App Information → set `appStoreURL` in `docs/app-config.json`

---

## 2. Legal & privacy

- [ ] **Privacy Policy** URL (HTTPS) — on-device data, APIs, IAP, contact email
- [ ] URL entered in App Store Connect + link in app Settings (recommended)
- [ ] Privacy policy mentions **AlQuran Cloud**, **islamic.network**, and **islamic.app** (Indo-Pak text)
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

- [ ] Version / build number set for release (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`)
- [ ] Consider lowering `IPHONEOS_DEPLOYMENT_TARGET` from 26.4 for broader reach (e.g. iOS 17+)
- [ ] Distribution signing
- [ ] Archive → Validate → Upload
- [ ] Build processed in TestFlight; attached to version
- [ ] `UIBackgroundModes = audio` (already in project)

**Already in app**

- [x] Dynamic version in Settings (from bundle)
- [x] Privacy + Support links in Settings
- [x] Lock screen Now Playing
- [x] Soft “Update available” prompt (remote config on GitHub Pages)

---

## 5. TestFlight

- [ ] Install on physical iPhone
- [ ] First launch Quran download
- [ ] Read, bookmark, Continue Reading (after real read)
- [ ] Listen, Recent (Listen-only), audio stream/download
- [ ] Background audio
- [ ] Settings, cache clear, Sandbox tip
- [ ] Settings → **Check for Updates** (with `latestVersion` bumped in `app-config.json`)

---

## 6. Listing metadata

- [ ] Description, subtitle, keywords
- [ ] Screenshots (required iPhone sizes)
- [ ] 1024×1024 app icon
- [ ] Age rating (likely 4+)
- [ ] Copyright; credit AlQuran Cloud, islamic.app, Mishary Alafasy (audio) in description

---

## 7. App Review notes

- [ ] Notes: first-launch download, how to play audio, Sandbox for tips
- [ ] Contact phone/email for reviewer
- [ ] No login required

---

## 8. Content

- [ ] AlQuran Cloud / islamic.network / islamic.app terms acceptable for your use
- [ ] Attribution in app or store listing

---

## 9. Submit

- [ ] IAPs linked to version; metadata complete
- [ ] **Submit for Review**

---

## 10. After each App Store release

- [ ] Bump `latestVersion` in `docs/app-config.json` and push (deploys via GitHub Pages)
- [ ] Set `appStoreURL` to `https://apps.apple.com/app/idYOUR_APPLE_ID` (not search URL)
- [ ] Optional: customize `updateMessage` for that release
- [ ] If Quran **data** format changed, bump `requiredQuranDataVersion` when that feature exists

Example `docs/app-config.json`:

```json
{
  "latestVersion": "1.0.1",
  "minimumRequiredVersion": "1.0.0",
  "updateMessage": "Improved Indo-Pak text and bug fixes.",
  "appStoreURL": "https://apps.apple.com/app/idXXXXXXXXXX"
}
```

Hosted at: `https://imaginebowl.github.io/QuranDaily/app-config.json`

---

## Already in good shape

- Paid Developer membership
- Core app: Read, Listen, Bookmarks, Settings, offline text, optional tips
- StoreKit 2 + `Transaction.updates`
- Background audio + lock screen controls
- Indo-Pak script (default) with emoji-safe text sanitization
- Soft update prompt on launch + Settings check

## Highest-risk gaps before first submit

1. Privacy policy — add islamic.app if not deployed yet  
2. IAP fully configured + Sandbox tested  
3. Screenshots + listing metadata  
4. Real-device TestFlight pass  
5. Replace `appStoreURL` search link with real App Store ID URL after app is created
