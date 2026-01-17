#!/bin/bash
# Test UTF-8 encoding with various Unicode characters
# This tests basic multilingual plane, emoji, and combining characters

# Basic Latin + accents
echo "Basic: café résumé"

# Cyrillic
echo "Cyrillic: Привет мир"

# Chinese
echo "Chinese: 你好世界"

# Japanese
echo "Japanese: こんにちは世界"

# Arabic (RTL)
echo "Arabic: مرحبا بالعالم"

# Emoji
echo "Emoji: 😀🎉🌟❤️🚀"

# Combining characters
echo "Combining: é (e + ́)"

# Math symbols
echo "Math: ∑∫∂∞≠≈"

# Box drawing
echo "Box: ┌─┐│└┘"

# Zero-width characters (should not be visible)
echo "ZeroWidth: A​B​C"

# Multi-byte sequences
echo "Multi: 𝕳𝖊𝖑𝖑𝖔"
