// DesignSystem.swift
// Public API du package: importer DesignSystem donne accès à tout.
//
// Tokens:
//   ATFColors   → Color.atf*  (extension Color)
//   ATFTypography → Font.atf*  (extension Font)
//   ATFRadius   → ATFRadius.input / .card / .pill / .modal / .chip
//
// Icons:
//   ATFIcon     → SF Symbols enum (CaseIterable, Sendable)
//   ATFIconView → Image wrapper View
//
// Wordmark:
//   ATFWordmark → "Atfood." logotype
//
// Components:
//   ATFButton, ATFTextField, ATFChip, ATFBadge
//   ATFToast / ATFToastOverlay, ATFSkeleton
//   ATFAsyncImage
//
// Fonts: system only (SF Pro, New York), nothing to register.
//
// All types are public in their own source files; no re-exports needed.
