import XCTest
@testable import MyWorkout

@MainActor
final class UserSettingsStoreTests: XCTestCase {

    // MARK: - Fixtures

    /// A unique file path per test/call, so tests never see each
    /// other's data despite running against the real filesystem —
    /// same isolation goal the old `UserDefaults(suiteName:)` fixture
    /// served before `UserSettingsStore` moved off `UserDefaults`
    /// (whose `synchronize()` turned out not to reliably flush before
    /// process termination — see the type-level doc comment on
    /// `UserSettingsStore`).
    private func makeFileURL(testName: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "UserSettingsStoreTests."
                + testName
                + "."
                + UUID().uuidString
                + ".json"
            )
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

    func test_corruptedFieldInEnvelope_preservesOriginalDataAndReportsError() throws {
        let fileURL = makeFileURL(testName: #function)
        try corruptedEnvelopeData().write(to: fileURL)

        let store = UserSettingsStore(fileURL: fileURL)

        // Falls back to in-memory defaults for this session...
        XCTAssertEqual(store.settings.unitSystem, .pounds)
        // ...but must NOT have overwritten the real data on disk, and must
        // surface a loading error rather than failing silently.
        XCTAssertEqual(store.persistenceError?.operation, .loading)
        XCTAssertEqual(try Data(contentsOf: fileURL), corruptedEnvelopeData())
    }

    func test_corruptedFieldInEnvelope_refusesToSaveOverTheOriginalData() throws {
        let fileURL = makeFileURL(testName: #function)
        try corruptedEnvelopeData().write(to: fileURL)

        let store = UserSettingsStore(fileURL: fileURL)
        store.save()

        // save() must be a no-op while the on-disk data is unreadable —
        // never silently replace it with defaults.
        XCTAssertEqual(try Data(contentsOf: fileURL), corruptedEnvelopeData())
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
    func test_envelopeWithDifferentlyCasedKey_isStillTreatedAsEnvelopeShaped() throws {
        let fileURL = makeFileURL(testName: #function)
        let data = corruptedEnvelopeData(payloadKey: "Payload")
        try data.write(to: fileURL)

        let store = UserSettingsStore(fileURL: fileURL)

        XCTAssertEqual(store.persistenceError?.operation, .loading)
        XCTAssertEqual(try Data(contentsOf: fileURL), data)
    }

    // MARK: - Healthy round trip (sanity check)

    func test_validEnvelope_loadsSuccessfullyWithNoError() {
        let fileURL = makeFileURL(testName: #function)

        var settings = UserSettings.defaults
        settings.unitSystem = .kilograms
        settings.appearanceMode = .dark

        let firstStore = UserSettingsStore(fileURL: fileURL)
        firstStore.replace(with: settings)

        let reloaded = UserSettingsStore(fileURL: fileURL)

        XCTAssertNil(reloaded.persistenceError)
        XCTAssertEqual(reloaded.settings.unitSystem, .kilograms)
        XCTAssertEqual(reloaded.settings.appearanceMode, .dark)
    }

    // MARK: - Migration from the legacy UserDefaults-backed store

    /// Regression test: a real settings value saved by the old
    /// `UserDefaults`-backed store, from before this persistence
    /// change, must still be picked up on the first launch after the
    /// change rather than silently resetting to defaults.
    func test_legacyUserDefaultsData_isMigratedOnFirstLoad() throws {
        let suiteName = "UserSettingsStoreTests.\(#function).\(UUID().uuidString)"
        let legacyDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        legacyDefaults.removePersistentDomain(forName: suiteName)

        var settings = UserSettings.defaults
        settings.unitSystem = .kilograms
        settings.compoundRestSeconds = 240

        let envelope = PersistedEnvelope(schemaVersion: 1, payload: settings)
        legacyDefaults.set(try JSONEncoder().encode(envelope), forKey: "user_settings")

        let fileURL = makeFileURL(testName: #function)
        // No file exists yet at `fileURL` — this is the "first launch
        // since the persistence backend changed" case.
        let store = UserSettingsStore(fileURL: fileURL, legacyUserDefaults: legacyDefaults)

        XCTAssertNil(store.persistenceError)
        XCTAssertEqual(store.settings.unitSystem, .kilograms)
        XCTAssertEqual(store.settings.compoundRestSeconds, 240)

        // The migration must have also written the file, so a
        // subsequent launch doesn't depend on the legacy UserDefaults
        // key still being present.
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
