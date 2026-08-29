import XCTest
@testable import MyWorkout

@MainActor
final class UserSettingsStoreTests: XCTestCase {

    // MARK: - Fixtures

    private let key = "user_settings"

    private func makeUserDefaults(testName: String) -> UserDefaults {
        let suiteName =
            "UserSettingsStoreTests."
            + testName
            + "."
            + UUID().uuidString

        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// A validly-shaped envelope containing real customizations, plus one
    /// unrecognized `appearanceMode` raw value ("Dark" — the real cases
    /// are lowercase "system"/"light"/"dark") to force the payload decode
    /// to throw. `payloadKey` lets a test swap in a different-cased key
    /// for the envelope wrapper itself.
    private func corruptedEnvelopeData(payloadKey: String = "payload") -> Data {
        let json = """
        {"schemaVersion":1,"\(payloadKey)":{"unitSystem":"kg","compoundRestSeconds":240,\
        "isolationRestSeconds":60,"bodyweightRestSeconds":90,"oneRepMaxFormula":"Brzycki",\
        "compoundIncrement":10,"isolationIncrement":5,"appearanceMode":"Dark"}}
        """
        return Data(json.utf8)
    }

    // MARK: - Corrupted field inside a valid envelope

    func test_corruptedFieldInEnvelope_preservesOriginalDataAndReportsError() {
        let defaults = makeUserDefaults(testName: #function)
        defaults.set(corruptedEnvelopeData(), forKey: key)

        let store = UserSettingsStore(userDefaults: defaults)

        // Falls back to in-memory defaults for this session...
        XCTAssertEqual(store.settings.unitSystem, .pounds)
        // ...but must NOT have overwritten the real data on disk, and must
        // surface a loading error rather than failing silently.
        XCTAssertEqual(store.persistenceError?.operation, .loading)
        XCTAssertEqual(defaults.data(forKey: key), corruptedEnvelopeData())
    }

    func test_corruptedFieldInEnvelope_refusesToSaveOverTheOriginalData() {
        let defaults = makeUserDefaults(testName: #function)
        defaults.set(corruptedEnvelopeData(), forKey: key)

        let store = UserSettingsStore(userDefaults: defaults)
        store.save()

        // save() must be a no-op while the on-disk data is unreadable —
        // never silently replace it with defaults.
        XCTAssertEqual(defaults.data(forKey: key), corruptedEnvelopeData())
        XCTAssertEqual(store.persistenceError?.operation, .saving)
    }

    /// Regression test for the case-sensitivity gap fixed alongside this
    /// test: an envelope whose wrapper key is cased differently
    /// ("Payload" instead of "payload") must still be recognized as
    /// envelope-shaped, so a corrupted field inside it throws and
    /// preserves the original data — instead of being misclassified as
    /// "not envelope-shaped" and handed to the tolerant legacy decoder,
    /// which would silently succeed with all-default settings and
    /// immediately persist that wipe over the user's real data.
    func test_envelopeWithDifferentlyCasedKey_isStillTreatedAsEnvelopeShaped() {
        let defaults = makeUserDefaults(testName: #function)
        let data = corruptedEnvelopeData(payloadKey: "Payload")
        defaults.set(data, forKey: key)

        let store = UserSettingsStore(userDefaults: defaults)

        XCTAssertEqual(store.persistenceError?.operation, .loading)
        XCTAssertEqual(defaults.data(forKey: key), data)
    }

    // MARK: - Healthy round trip (sanity check)

    func test_validEnvelope_loadsSuccessfullyWithNoError() {
        let defaults = makeUserDefaults(testName: #function)

        var settings = UserSettings.defaults
        settings.unitSystem = .kilograms
        settings.appearanceMode = .dark

        let firstStore = UserSettingsStore(userDefaults: defaults)
        firstStore.replace(with: settings)

        let reloaded = UserSettingsStore(userDefaults: defaults)

        XCTAssertNil(reloaded.persistenceError)
        XCTAssertEqual(reloaded.settings.unitSystem, .kilograms)
        XCTAssertEqual(reloaded.settings.appearanceMode, .dark)
    }
}
