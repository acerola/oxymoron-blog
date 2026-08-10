# AGENTS.md — Oxymoron's Blog

Jekyll 4.4+ multilingual blog (en/ja/ko). See README for overview and setup.

## Conventions

### Liquid patterns (every template starts with these)

```liquid
{% assign current_lang = page.lang | default: site.default_lang %}
{% assign t = site.data.translations[current_lang] %}
{% assign lang_prefix = "/" | append: current_lang %}
```

Link to a language-scoped page: `{{ lang_prefix | append: '/bookshelf/' | relative_url }}`

Find translations of the current page: `{% assign translations = site.articles | where: "ref", page.ref %}` (use `site.books` for books).

### Colors

- Primary accent: `#fc4d50` (coral red)
- Dark mode: Tailwind `slate` palette with `dark:` prefix
- Theme toggle persisted to `localStorage`, synced to Giscus

### CSS

- Tailwind is **locally built** — edit `assets/css/tailwind.src.css`, then `npm run build:css` and **commit the output** (`assets/css/tailwind.css`). CI/deploy do NOT run the CSS build.
- Custom styles go in `assets/css/main.css` (no build step, served directly).
- NO runtime CDN scripts — tests assert no `cdn.tailwindcss.com` or `unpkg.com/alpinejs`.

## Content model

### Articles (`_articles/YYYY-MM-DD-slug/{lang}.md`)

```yaml
---
layout: post
title: "Title"
date: 2024-06-01
description: "SEO summary"
category: General       # auto-discovered by i18n_pages.rb
tags: [tag1, tag2]      # auto-discovered by i18n_pages.rb
lang: en
ref: unique-slug        # identical across all language versions
# hidden: true          # draft — hidden from listings, accessible via direct URL
---
```

### Books (`_books/book-slug/{lang}.md`)

```yaml
---
title: "Book Title"
author: "Author Name"
status: finished         # reading | finished | wishlist
rating: 4.5              # 0.0–5.0
spine_color: "#0e7490"   # fallback when no cover image
ref: book-slug
lang: en
---
```

### Categories and tags are auto-generated

`_plugins/i18n_pages.rb` auto-discovers categories and tags from article front matter and generates per-language archive pages at build time. No manual file creation needed — just use them in front matter.

### Per-language structural pages

`i18n_pages.rb` also generates: `/{lang}/` (home), `/{lang}/categories/`, `/{lang}/tags/`, `/{lang}/bookshelf/`, plus top-level `/categories/`, `/tags/`, `/bookshelf/`.

Manual per-language pages (not auto-generated): `{lang}/about.md` — create these by hand.

## Gotchas

- **Never edit `_site/`** — auto-generated, wiped on each build.
- **`ref` must be identical** across all language versions of the same article/book.
- **Date format**: `YYYY-MM-DD` in filenames and front matter.
- **Categories are case-sensitive** — match exactly.
- **Reading time** auto-calculated at 200 words/minute.
- **Hidden posts** (`hidden: true`) are still built and accessible via direct URL — just excluded from listings.
- **`_config.yml` sets `exclude` explicitly** — adding a new file/dir to the repo? Add it there too or it'll ship in the built site.

## CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **CI** (`.github/workflows/ci.yml`) | Push, PR | `jekyll doctor` → `jekyll build` → test suite |
| **Deploy** (`.github/workflows/deploy.yml`) | Push to `release` | Build with Pages baseurl → deploy to GitHub Pages |

CI runs on every push and PR. Deploy only triggers on the `release` branch (not `main`).
