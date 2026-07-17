from main import summarize_market

REFUSAL_PHRASES = [
    "i don't have access",
    "i can't verify",
    "real-time data",
]

SAMPLE_INPUTS = [
    "Apple stock rose 3% today after strong iPhone sales.",
    "Tesla shares dropped 5% following disappointing delivery numbers.",
    "Amazon announced a new AI chip, sending shares up 2%.",
]


def test_summary_is_not_empty():
    for text in SAMPLE_INPUTS:
        result = summarize_market(text)
        assert len(result.strip()) > 0


def test_summary_does_not_refuse():
    for text in SAMPLE_INPUTS:
        result = summarize_market(text).lower()
        for phrase in REFUSAL_PHRASES:
            assert phrase not in result, f"Refusal phrase '{phrase}' found in: {result}"
