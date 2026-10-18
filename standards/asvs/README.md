# OWASP ASVS — shipped requirement list

The requirement list subcriteria 8.7 is scored against, for the ASVS version the framework supports.
It is shipped rather than fetched so that an audit is reproducible and works offline: two audits of
the same commit read the same requirements.

| Field | Value |
|---|---|
| Standard | OWASP Application Security Verification Standard |
| Version | 5.0.0 |
| Source | the `v5.0.0_release` release of github.com/OWASP/ASVS |
| Licence | Creative Commons Attribution-ShareAlike 4.0 International. © the OWASP Foundation and the ASVS contributors |
| Changes | none — the file is the release asset, byte for byte |

Columns: `chapter_id, chapter_name, section_id, section_name, req_id, req_description, L`. Each
requirement is one line and the level is its last field, so the requirements of one chapter up to L2
are:

```bash
grep -E '^V6,' OWASP_Application_Security_Verification_Standard_5.0.0_en.csv | grep -E ',[12]$'
```

Adopting a new ASVS version is a framework release: its file is added beside this one, never in
place of it — a project that declared 5.0.0 keeps being scored against 5.0.0 until it moves.
