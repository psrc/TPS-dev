SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
================================================================================
FUNCTION: dbo.fn_FormatCurrency (Clean Version)
================================================================================
PURPOSE: 
    Converts BIGINT monetary values into human-readable currency strings with 
    appropriate scale suffixes (B for billions, M for millions, K for thousands).

PARAMETERS:
    @amount BIGINT - The monetary amount to be formatted (can be positive or negative)

RETURNS:
    NVARCHAR(20) - Formatted currency string with appropriate suffix
    
EXAMPLES:
    1000         → '$1K'
    1500         → '$1.5K' 
    12430000000  → '$12.43B'
    1250000000   → '$1.25B'
    1250000      → '$1.25M'
    543200       → '$543.2K'
    15000        → '$15K'
    999          → '$999'

AUTHOR: john.hunter@triskelle.solutions
CREATED: 2025-07-03
MODIFIED: 2025-07-03 - Fixed trailing zeros issue using FORMAT function
================================================================================
*/
CREATE   FUNCTION [dbo].[fn_FormatCurrency]
(
    @amount BIGINT
)
RETURNS NVARCHAR(20)
AS
    BEGIN
        DECLARE @result NVARCHAR(20);

        /*
        Using FORMAT function with '0.##' pattern:
        - '0' = shows at least one digit before decimal
        - '.##' = shows up to 2 decimal places, but removes trailing zeros
        - This eliminates the trailing zeros issue completely
        */
        SELECT @result = CASE

                             -- Billions (1,000,000,000 and above)
                             WHEN ABS(@amount) >= 1000000000 THEN '$' + FORMAT(CAST(@amount AS DECIMAL(20, 2)) / 1000000000.0, '0.##') + 'B'

                             -- Millions (1,000,000 to 999,999,999)  
                             WHEN ABS(@amount) >= 1000000 THEN '$' + FORMAT(CAST(@amount AS DECIMAL(20, 2)) / 1000000.0, '0.##') + 'M'

                             -- Thousands (1,000 to 999,999)
                             WHEN ABS(@amount) >= 1000 THEN '$' + FORMAT(CAST(@amount AS DECIMAL(20, 2)) / 1000.0, '0.##') + 'K'

                             -- Less than 1,000 - display full amount without suffix
                             ELSE '$' + CAST(@amount AS NVARCHAR(10))
                         END;

        RETURN @result;
    END;
GO
