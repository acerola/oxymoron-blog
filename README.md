# Oxymoron's Blog

A multilingual personal blog built with [Jekyll](https://jekyllrb.com/). Notes on calm building — programming, technology, and software development.

**Live**: [oxymoron.blog](https://oxymoron.blog)

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Jekyll 4.4+ |
| Runtime | Ruby 3.2+ |
| CSS | Tailwind CSS 3.4 (local build) + `@tailwindcss/typography` |
| Fonts | Inter (Google Fonts) |
| Comments | Giscus (GitHub Discussions) |
| Deployment | GitHub Pages via GitHub Actions |

**Jekyll Plugins**: jekyll-paginate-v2, jekyll-seo-tag, jekyll-feed, jekyll-sitemap, custom i18n page generator (`_plugins/i18n_pages.rb`)

## Getting Started

### Prerequisites

- Ruby 3.2+
- Bundler (`gem install bundler`)
- Node.js 18+ (for Tailwind builds)

### Install & Run

```bash
bundle install
npm install
bundle exec jekyll serve
```

Open [http://localhost:4000](http://localhost:4000).

### Build CSS

```bash
npm run build:css       # one-time build
npm run watch:css       # rebuild on changes
```

### Production Build

```bash
bundle exec jekyll build
```

## Features

### Multilingual (i18n)

Three languages: **English** (default), **Japanese**, **Korean**.

- Each article and book lives in a folder with `en.md`, `ja.md`, `ko.md`
- The `ref` front matter field links translations together
- Language-scoped URLs: `/posts/{slug}/{lang}/`, `/books/{slug}/{lang}/`
- UI strings in `_data/translations/{lang}.yml`
- Language switcher in the nav and on post/book pages
- hreflang tags for SEO

### Bookshelf

A multilingual reading tracker with a 3D shelf UI.

- **Statuses**: Currently reading, Finished, Want to read — each its own shelf row
- **Ratings**: Star ratings (0.0–5.0) rendered inline
- **Covers**: Book covers from Open Library Covers API, with colored spine fallback
- **Popups**: Hover/focus popup portals that escape the horizontal scroll container
- **Touch**: Tap-to-peek on mobile, second tap navigates
- Fully translated across en/ja/ko

### Dark Mode

Toggle between light and dark themes. Preference is saved to localStorage and syncs with the Giscus comment theme.

### Draft / Hidden Posts

Set `hidden: true` in front matter to hide a post from all listings while keeping it accessible via direct URL.

### Taxonomy

Categories and tags are language-aware — each language root has its own category/tag index pages that only show posts in that language.

## Writing Posts

1. Create a folder: `_articles/YYYY-MM-DD-slug/`
2. Add language files (`en.md`, `ja.md`, `ko.md`)

### Front Matter

```yaml
---
layout: post
title: "Article Title"
date: 2026-02-08
description: "Short summary for cards and feeds"
category: General
tags: [tag1, tag2]
lang: en
ref: article-slug          # same value across all language versions
# hidden: true             # optional — hides from listings
---
```

## Adding a Book

1. Create a folder: `_books/book-slug/`
2. Add language files (`en.md`, `ja.md`, `ko.md`)

```yaml
---
title: "Book Title"
author: "Author Name"
status: finished           # reading | finished | wishlist
rating: 4.5                # 0.0–5.0
spine_color: "#0e7490"     # fallback when no cover image
ref: book-slug              # same value across all language versions
lang: en
---
Your review or notes here.
```

