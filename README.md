# Kimi — personal job search assistant

Kimi reads new job postings every day, grades each one against your CV for **fit** and **realism**
(seniority, visa, requirements), sends you a morning briefing with the best matches, and answers
questions about them in a chat with cited sources.

> Named after my dog, who's also good at fetching things. Not related to Moonshot's Kimi models.

**Status:** in development. v1.0 is in progress; see the milestones for the roadmap.

## Planned architecture

- **Ingestion:** daily pull from public ATS APIs (Greenhouse, Lever, Ashby, SmartRecruiters) into S3
- **Retrieval:** section-aware chunking, Bedrock embeddings, hybrid search (pgvector + full-text) with reranking
- **Grading:** structured LLM scoring with evidence from the CV, evaluated against hand-labelled data
- **Delivery:** morning email digest, web app with chat, public demo with cost caps
- **Platform:** AWS (Lambda, Step Functions, Aurora PostgreSQL, Bedrock), Terraform, GitHub Actions

## Development

Requires [uv](https://docs.astral.sh/uv/).

```bash
make install   # dependencies + git hooks
make check     # lint, type check, tests (same as CI)
```

## License

MIT
