"""News deduplication (section 55). The same wire story appears on many
sites; group near-duplicates into one cluster rather than showing N
near-identical cards."""

from __future__ import annotations

import re
import unicodedata
from urllib.parse import urlparse, urlunparse

_TRACKING_PARAMS = {"utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "fbclid", "ref"}


def canonicalize_url(url: str) -> str:
    parsed = urlparse(url)
    query_pairs = [
        pair for pair in parsed.query.split("&") if pair and pair.split("=")[0] not in _TRACKING_PARAMS
    ]
    return urlunparse(parsed._replace(query="&".join(query_pairs), fragment=""))


def normalize_headline(headline: str, language: str) -> str:
    text = unicodedata.normalize("NFKC", headline).strip().lower()
    if language == "ar":
        # Basic Arabic normalization: unify alef/hamza variants and strip
        # diacritics, per section 9's "normalize Arabic carefully".
        text = re.sub("[إأآا]", "ا", text)
        text = re.sub("ى", "ي", text)
        text = re.sub("ة", "ه", text)
        text = re.sub(r"[ً-ٟ]", "", text)  # tashkeel
    text = re.sub(r"[^\w\s]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def headline_similarity(a: str, b: str) -> float:
    """Jaccard similarity over normalized-headline word sets — a simple,
    dependency-free stand-in for a semantic-similarity model. Adequate for
    catching near-identical wire-story duplicates; not a general semantic
    dedup solution (see docs/DATA_SOURCES.md limitations)."""
    words_a, words_b = set(a.split()), set(b.split())
    if not words_a or not words_b:
        return 0.0
    intersection = len(words_a & words_b)
    union = len(words_a | words_b)
    return intersection / union


def is_probable_duplicate(
    url_a: str, headline_a: str, url_b: str, headline_b: str, language: str, threshold: float = 0.75
) -> bool:
    if canonicalize_url(url_a) == canonicalize_url(url_b):
        return True
    sim = headline_similarity(normalize_headline(headline_a, language), normalize_headline(headline_b, language))
    return sim >= threshold
