"""NOTE: could not be executed in this repo's development sandbox (no
working Python runtime) — see packages/election_rules_py/tests for details."""

from ingestion.dedup import canonicalize_url, is_probable_duplicate, normalize_headline


def test_canonicalize_strips_tracking_params():
    a = canonicalize_url("https://example.com/story?utm_source=twitter&id=5")
    b = canonicalize_url("https://example.com/story?id=5")
    assert a == b


def test_normalize_headline_unifies_arabic_alef_variants():
    assert normalize_headline("إعلان النتائج", "ar") == normalize_headline("اعلان النتائج", "ar")


def test_identical_url_is_duplicate_even_with_different_headline():
    assert is_probable_duplicate(
        "https://example.com/a?utm_source=x", "Headline One",
        "https://example.com/a", "Totally Different Headline",
        "en",
    )


def test_similar_headlines_flagged_duplicate():
    assert is_probable_duplicate(
        "https://site-a.com/story", "CEC announces candidate list deadline",
        "https://site-b.com/story", "CEC announces candidate list deadline today",
        "en",
    )


def test_dissimilar_headlines_not_duplicate():
    assert not is_probable_duplicate(
        "https://site-a.com/1", "CEC announces candidate list deadline",
        "https://site-b.com/2", "Fatah leadership meets in Ramallah",
        "en",
    )
