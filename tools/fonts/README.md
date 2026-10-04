# Fonts

Subsets used by `../make-header.py`, embedded into `assets/header.svg`
(GitHub shows SVGs as images, which can't load web fonts):

| File | Font | Characters | License |
|---|---|---|---|
| `name.woff2` | Space Grotesk Bold, by Florian Karsten | "Yash Sawarkar" | SIL Open Font License 1.1 |
| `roles.woff2` | JetBrains Mono Regular, by JetBrains | the role lines (incl. "DevOps on AWS & GCP") | SIL Open Font License 1.1 |

Fetched from Google Fonts with `text=` set to only the characters used. If
you change the name or the roles, fetch new subsets the same way, then run:

    tools/make-header.py tools/fonts/name.woff2 tools/fonts/roles.woff2 > assets/header.svg
