SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
================================================================================
Function: dbo.fn_ExtractDigits
Description: Extracts all numeric digits (0-9) from an input string while 
             preserving their original order and including duplicates.
             
Author: john.hunter@triskelle.solutions
Created Date: 2025-08-01

Parameters:
    @InputString NVARCHAR(MAX) - The string to extract digits from.
                                 Can be NULL or empty.

Returns:
    NVARCHAR(MAX) - String containing only the digits from the input string.
                    Returns empty string ('') if input is NULL or contains no digits.

Examples:
    SELECT dbo.ExtractDigits('ABC123DEF456')           -- Returns: '123456'
    SELECT dbo.ExtractDigits('Phone: (555) 123-4567')  -- Returns: '5551234567'
    SELECT dbo.ExtractDigits('No digits here!')        -- Returns: ''
    SELECT dbo.ExtractDigits(NULL)                     -- Returns: ''

Notes:
    - This function only extracts ASCII digits 0-9
    - Unicode numeric characters from other languages are not extracted
    - Performance may degrade with extremely long strings (>1MB)
    - Consider using a set-based approach for very large strings

Revision History:
    2025-08-01 - john.hunter@triskelle.solutions - Initial creation
================================================================================
*/
CREATE FUNCTION [dbo].[fn_ExtractDigits]
(
    @InputString NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
    BEGIN
        -- Declare variables
        DECLARE @OutputString NVARCHAR(MAX) = N''; -- Stores the result string containing only digits
        DECLARE @Index INT = 1; -- Current position in the input string
        DECLARE @Length INT; -- Total length of the input string
        DECLARE @CurrentChar NCHAR(1); -- Current character being examined

        -- Handle NULL input by returning empty string
        IF @InputString IS NULL
            BEGIN
                RETURN '';
            END;

        -- Get the length of the input string
        SET @Length = LEN(@InputString);

        -- Handle empty string or strings with only spaces
        IF @Length = 0
           OR @Length IS NULL
            BEGIN
                RETURN '';
            END;

        -- Loop through each character in the input string
        WHILE @Index <= @Length
            BEGIN
                -- Extract the current character at position @Index
                SET @CurrentChar = SUBSTRING(@InputString, @Index, 1);

                -- Check if the current character is a digit (0-9)
                -- Using LIKE '[0-9]' pattern matching for digit detection
                IF @CurrentChar LIKE '[0-9]'
                    BEGIN
                        -- Append the digit to the output string
                        SET @OutputString = @OutputString + @CurrentChar;
                    END;

                -- Move to the next character
                SET @Index = @Index + 1;
            END;

        -- Return the string containing only digits
        -- Will return empty string if no digits were found
        RETURN @OutputString;
    END;
GO
