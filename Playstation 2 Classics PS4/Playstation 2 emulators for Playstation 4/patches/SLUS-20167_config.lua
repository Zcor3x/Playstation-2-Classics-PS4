apiRequest(0.1)

-- Possible fix for black screen (skip video)

eeInsnReplace(0x72C1E0, 0x63706D2E, 0x63706E2E)
eeInsnReplace(0x7226F4, 0x6D2E7374, 0x6E2E7374)