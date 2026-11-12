# Adaptive staged delivery

Stage boundaries are derived from the feature, not a template number.

Use one stage when the change is local, coherent, and independently verifiable. Split larger work when architectural foundations, integration, specialist capability, runtime constraints, or production validation have distinct dependencies or proof requirements.

A stage should have:
- One coherent outcome.
- Explicit dependencies.
- A small set of observable completion conditions.
- A verification method appropriate to the claim.
- A clear closeout boundary.

Avoid artificial stages, speculative future stages, and stage counts chosen to look thorough. Add or revise stages when repository inspection reveals real dependencies. Keep completed and remaining work distinct. Earlier scaffolding must not be represented as completion of a later user-visible capability.
