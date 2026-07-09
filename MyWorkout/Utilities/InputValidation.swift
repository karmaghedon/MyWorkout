import Foundation

// MARK: - InputValidation

/// Centralized input validation for user-entered data. 
enum InputValidation {
    
    // MARK: - Weight Validation
    
    // Validates weight input is within acceptable range.
    /// - Parameter weight: Weight value to validate
    /// - Returns: Validated weight or nil if invalid
    static func validateWeight(_ weight: Double) -> Double? {
        guard weight >= 0 && weight <= 10000 else { return nil }
        return weight
    }
    
    /// Validates and clamps weight to acceptable range.
    /// - Parameter weight: Weight value to clamp
    /// - Returns: Weight clamped to valid range
    static func clampWeight(_ weight: Double) -> Double {
        max(0, min(weight, 10000))
    }
    
    // MARK: - Rep Validation
    
    /// Validates rep count is within acceptable range.
    /// - Parameter reps: Rep count to validate
    /// - Returns: Validated reps or nil if invalid
    static func validateReps(_ reps: Int) -> Int? {
        guard reps > 0 && reps <= 1000 else { return nil }
        return reps
    }
    
    /// Validates and clamps reps to acceptable range.
    /// - Parameter reps: Rep count to clamp
    /// - Returns: Reps clamped to valid range
    static func clampReps(_ reps: Int) -> Int {
        max(1, min(reps, 1000))
    }
    
    // MARK: - Name Validation
    /// Validates exercise or workout name is not empty or whitespace only.
    /// - Parameter name: Name to validate
    /// - Returns: Trimmed name or nil if invalid
    static func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 100 else { return nil }
        return trimmed
    }
    
    /// Check  if a name is valid (not empty or whitespaced only).
    ///  - Parameter naem: Name to check
    ///  - Returns: True if valid, flas otherwise
    static func isValidName(_ name: String) -> Bool {
        validateName(name) != nil
    }
    
    // MARK: - Duration Validation
    /// Validates rest timer duration is within acceptable range.
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Validated duration or nil if invalid
    static func validateRestDuration(_ seconds: Int) -> Int? {
        guard seconds >= 10 && seconds <= 600 else { return nil }
        return seconds
    }
    
    /// Validates and clamps rest duration to acceptable range.
    /// - Parameter seconds: Duration in seconds to clamp
    /// - Returns: Duration clamped to valid range (10–600 seconds)
    static func clampRestDuration(_ seconds: Int) -> Int {
        max(10, min(seconds, 600))
    }
    
    // MARK: - Equipment Validation
    /// Validates equipment quantity is within acceptable range.
    /// - Parameter quantity: Quantity to validate
    /// - Returns: Validated quantity or nil if invalid
    static func validateQuantity(_ quantity: Int) -> Int? {
        guard quantity >= 0 && quantity <= 100 else { return nil }
        return quantity
    }
    
    /// Validates and clamps quantity to acceptable range.
    /// - Parameter quantity: Quantity to clamp
    /// - Returns: Quantity clamped to valid range
    static func clampQuantity(_ quantity: Int) -> Int {
        max(0, min(quantity, 100))
    }
}
