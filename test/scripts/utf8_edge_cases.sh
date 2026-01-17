#!/bin/bash
# Test edge cases for UTF-8 decoding

# Invalid UTF-8 sequences (these should be handled gracefully)
echo "Testing invalid UTF-8 sequences..."

# Incomplete multi-byte sequence (will be handled by shell)
# Note: Bash will typically replace invalid sequences with replacement character

# Very long UTF-8 string (stress test)
echo "Long string test:"
python3 -c "print('A' * 1000 + '世界' + 'B' * 1000)"

# Mixed encodings within same output
echo "Mixed test: ASCII-café-世界-😀-مرحبا"

# UTF-8 in environment variable
export UTF8_VAR="Test 世界 🌍"
echo "From env: $UTF8_VAR"

# UTF-8 BOM (byte order mark) - shouldn't appear but test handling
printf '\xEF\xBB\xBFWith BOM\n'

# Surrogate pairs and high Unicode
echo "High Unicode: 🏴󠁧󠁢󠁳󠁣󠁴󠁿"

# Line break variations
echo "Line breaks:"
echo "Unix: Line1"
echo "Line2"
printf 'Windows: Line1\r\nLine2\r\n'

# Control characters that should be escaped or handled
echo "Control chars:"
for i in {0..31}; do
  if [ $i -ne 10 ] && [ $i -ne 13 ]; then
    printf "\\x$(printf '%02x' $i)"
  fi
done
echo ""

# Maximum width line test
python3 -c "print('=' * 200)"
