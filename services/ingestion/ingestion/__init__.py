"""News/document ingestion pipeline: fetch -> normalize -> dedupe ->
classify -> extract -> score -> human review queue -> database (section 9).

This service is a working SKELETON, not a fully built-out ingestion
system: source adapters, the NLP extraction step, and the review-queue
persistence are interfaces with one reference implementation each, wired
together in pipeline.py, so a real deployment can add adapters/providers
without redesigning the flow. See docs/DATA_SOURCES.md and
docs/SOURCE_LICENSING.md for what is required before enabling a new
source in production.
"""
