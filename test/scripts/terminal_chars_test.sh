#!/bin/bash
# Test special terminal control characters and ANSI escape sequences

# Bell character (may produce sound/visual bell)
echo "Bell: Here comes the bell... "
printf '\a'
echo ""

# Backspace
echo "Backspace test: ABC"
printf 'DEF\b\b\bXYZ\n'

# Tab characters
echo "Tabs:"
printf 'Col1\tCol2\tCol3\n'

# Carriage return
echo "Carriage return test:"
printf 'First line\rOverwrite\n'

# Form feed
echo "Form feed:"
printf 'Before\fAfter\n'

# Vertical tab
echo "Vertical tab:"
printf 'Line1\vLine2\n'

# ANSI color codes
echo "Colors:"
echo -e '\033[31mRed\033[0m \033[32mGreen\033[0m \033[33mYellow\033[0m \033[34mBlue\033[0m'

# Bold, italic, underline
echo "Formatting:"
echo -e '\033[1mBold\033[0m \033[3mItalic\033[0m \033[4mUnderline\033[0m'

# Cursor movement (may not be visible in all terminals)
echo "Cursor moves:"
printf 'Start\033[5CEnd\n'

# Line drawing with ANSI
echo "ANSI boxes:"
echo "┌────────┐"
echo "│  Box   │"
echo "└────────┘"

# Null bytes handling test (should handle gracefully)
echo "Null handling:"
printf 'Before\x00After\n'
