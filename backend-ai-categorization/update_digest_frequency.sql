-- Update digest frequency from 24/12 hours to 1 hour (hourly)
-- Run this after deploying the config change

-- Update all existing digest settings to hourly frequency
UPDATE digest_settings
SET frequency_hours = 1,
    updated_at = NOW()
WHERE frequency_hours IN (12, 24);

-- Verify the changes
SELECT user_id, frequency_hours, updated_at
FROM digest_settings
ORDER BY updated_at DESC;
