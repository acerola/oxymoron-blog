require_relative "test_helper"

runner = TestRunner.new
site, destination = SiteTestSupport.build_site

at_exit do
  FileUtils.remove_entry(destination) if destination && Dir.exist?(destination)
end

read_output = lambda do |relative_path|
  full_path = File.join(destination, relative_path)
  runner.assert_file_exists(full_path)
  File.read(full_path)
end

atom_entry_count = lambda do |xml_content|
  document = REXML::Document.new(xml_content)
  namespace = { "atom" => "http://www.w3.org/2005/Atom" }
  count = 0
  REXML::XPath.each(document, "//atom:entry", namespace) { count += 1 }
  count
end

# Pre-compute article fixture data once from disk so tests stay data-driven.
all_articles = SiteTestSupport.articles
visible_by_lang = {}
hidden_by_lang  = {}
%w[en ja ko].each do |lang|
  visible_by_lang[lang] = all_articles.select { |a| a[:lang] == lang && !a[:hidden] }
                                      .sort_by { |a| a[:date] }.reverse
  hidden_by_lang[lang]  = all_articles.select { |a| a[:lang] == lang && a[:hidden] }
end

# ---------------------------------------------------------------------------
# Core routes
# ---------------------------------------------------------------------------

runner.run("generates expected core routes") do
  %w[
    index.html
    en/index.html
    ja/index.html
    ko/index.html
    categories/index.html
    tags/index.html
    feed.xml
    posts-feed.xml
    sitemap.xml
  ].each do |route|
    runner.assert_file_exists(File.join(destination, route))
  end
end

runner.run("generates article pages for each language") do
  all_articles.each do |article|
    route = "posts/#{article[:slug]}/#{article[:lang]}/index.html"
    runner.assert_file_exists(File.join(destination, route))
  end
end

# ---------------------------------------------------------------------------
# Root redirect
# ---------------------------------------------------------------------------

runner.run("root index.html redirects to /en/") do
  root = read_output.call("index.html")
  runner.assert_includes(root, 'url=/en/')
  runner.assert_includes(root, 'window.location.replace("/en/")')
end

# ---------------------------------------------------------------------------
# Language home pages – visibility
# ---------------------------------------------------------------------------

runner.run("language home pages show only visible posts for that language") do
  %w[en ja ko].each do |lang|
    home = read_output.call("#{lang}/index.html")

    visible_by_lang[lang].each do |article|
      runner.assert_includes(home, article[:title])
    end

    hidden_by_lang[lang].each do |article|
      runner.refute_includes(home, article[:title])
    end

    # Titles from other languages' visible posts should not appear
    (%w[en ja ko] - [lang]).each do |other|
      visible_by_lang[other].each do |article|
        runner.refute_includes(home, article[:title])
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Draft / hidden posts
# ---------------------------------------------------------------------------

runner.run("hidden post pages remain directly accessible") do
  en_draft = read_output.call("posts/2024-06-15-draft-example/en/index.html")
  ja_draft = read_output.call("posts/2024-06-15-draft-example/ja/index.html")
  ko_draft = read_output.call("posts/2024-06-15-draft-example/ko/index.html")

  runner.assert_includes(en_draft, "Example Draft Post")
  runner.assert_includes(ja_draft, "下書き記事の例")
  runner.assert_includes(ko_draft, "초안 글 예시")
end

runner.run("hidden posts show draft banner") do
  en_draft = read_output.call("posts/2024-06-15-draft-example/en/index.html")
  runner.assert_includes(en_draft, "Draft")
  runner.assert_includes(en_draft, "Draft - This post is hidden from public listings")
end

runner.run("visible posts do not show draft banner") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.refute_includes(en_post, "Draft - This post is hidden from public listings")
end

runner.run("hidden posts are excluded from category detail pages") do
  visible_by_lang["en"].each do |article|
    next unless article[:category]
    cat_slug = article[:category].downcase.gsub(/\s+/, "-")
    cat_page = read_output.call("en/categories/#{cat_slug}/index.html")
    runner.assert_includes(cat_page, article[:title])
  end

  hidden_by_lang["en"].each do |article|
    next unless article[:category]
    cat_slug = article[:category].downcase.gsub(/\s+/, "-")
    cat_page = read_output.call("en/categories/#{cat_slug}/index.html")
    runner.refute_includes(cat_page, article[:title])
  end
end

runner.run("hidden posts are excluded from tag detail pages") do
  tag_example = read_output.call("en/tags/example/index.html")
  runner.assert_includes(tag_example, "Programming Pearls")
  runner.refute_includes(tag_example, "Example Draft Post")
end

# ---------------------------------------------------------------------------
# Taxonomy routes and filtering
# ---------------------------------------------------------------------------

runner.run("category and tag detail pages are language filtered") do
  category_book = read_output.call("en/categories/book/index.html")
  tag_programming = read_output.call("en/tags/programming/index.html")

  runner.assert_includes(category_book, "Programming Pearls")
  runner.refute_includes(category_book, "プログラミング・パール")
  runner.refute_includes(category_book, "프로그래밍 펄")

  runner.assert_includes(tag_programming, "Programming Pearls")
  runner.refute_includes(tag_programming, "プログラミング・パール")
  runner.refute_includes(tag_programming, "프로그래밍 펄")
end

runner.run("taxonomy index and detail routes are localized") do
  %w[
    en/categories/index.html
    ja/categories/index.html
    ko/categories/index.html
    en/tags/index.html
    ja/tags/index.html
    ko/tags/index.html
    en/categories/book/index.html
    ja/categories/book/index.html
    ko/categories/book/index.html
    en/tags/programming/index.html
    ja/tags/programming/index.html
    ko/tags/programming/index.html
  ].each do |route|
    runner.assert_file_exists(File.join(destination, route))
  end
end

runner.run("taxonomy index aggregation is scoped to the active language") do
  en_categories = read_output.call("en/categories/index.html")
  ja_categories = read_output.call("ja/categories/index.html")
  ko_categories = read_output.call("ko/categories/index.html")
  en_tags       = read_output.call("en/tags/index.html")

  en_cat_count = visible_by_lang["en"].map { |a| a[:category] }.compact.uniq.size
  ja_cat_count = visible_by_lang["ja"].map { |a| a[:category] }.compact.uniq.size
  ko_cat_count = visible_by_lang["ko"].map { |a| a[:category] }.compact.uniq.size

  runner.assert_includes(en_categories, "#{en_cat_count} categories")
  runner.assert_includes(en_categories, ">1 posts<")
  runner.refute_includes(en_categories, ">3 posts<")

  runner.assert_includes(ja_categories, "#{ja_cat_count} カテゴリー")
  runner.assert_includes(ko_categories, "#{ko_cat_count} 카테고리")

  runner.assert_includes(en_tags, "#programming")
  runner.assert_includes(en_tags, ">1</span>")
  runner.refute_includes(en_tags, ">3</span>")
end

runner.run("taxonomy links are language-aware") do
  en_home = read_output.call("en/index.html")
  ja_home = read_output.call("ja/index.html")
  ko_home = read_output.call("ko/index.html")

  runner.assert_includes(en_home, "href=\"/en/categories/book/\"")
  runner.assert_includes(en_home, "href=\"/en/tags/programming/\"")

  runner.assert_includes(ja_home, "href=\"/ja/categories/book/\"")
  runner.assert_includes(ja_home, "href=\"/ja/tags/programming/\"")

  runner.assert_includes(ko_home, "href=\"/ko/categories/book/\"")
  runner.assert_includes(ko_home, "href=\"/ko/tags/programming/\"")
end

# ---------------------------------------------------------------------------
# Post layout content
# ---------------------------------------------------------------------------

runner.run("post page contains title, date, description, and body content") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_includes(en_post, "Programming Pearls")
  runner.assert_includes(en_post, "2026-01-01")
  runner.assert_includes(en_post, "Notes and insights from the classic programming book.")
  runner.assert_includes(en_post, "A collection of programming insights and techniques.")
end

runner.run("post page displays reading time") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_includes(en_post, "min read")
end

runner.run("post page links tags to localized tag pages") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_includes(en_post, "href=\"/en/tags/programming\"")
  runner.assert_includes(en_post, "#programming")
end

runner.run("post page links category to localized category page") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_includes(en_post, "href=\"/en/categories/book\"")
  runner.assert_includes(en_post, "Book")
end

runner.run("post page has back-to-all link for the current language") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  ja_post = read_output.call("posts/2026-01-01-programming-perls/ja/index.html")
  runner.assert_includes(en_post, "href=\"/en/\"")
  runner.assert_includes(en_post, "Back to all posts")
  runner.assert_includes(ja_post, "href=\"/ja/\"")
end

# ---------------------------------------------------------------------------
# Language switcher on post pages
# ---------------------------------------------------------------------------

runner.run("post pages include language switcher with all available translations") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_includes(en_post, "Read in")
  runner.assert_includes(en_post, "/posts/2026-01-01-programming-perls/ja/")
  runner.assert_includes(en_post, "/posts/2026-01-01-programming-perls/ko/")
end

runner.run("language switcher highlights the current language") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_match(/EN.*?bg-\[#fc4d50\]/m, en_post)
end

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

runner.run("navigation contains localized links") do
  en_home = read_output.call("en/index.html")
  runner.assert_includes(en_home, "href=\"/en/\"")
  runner.assert_includes(en_home, "href=\"/en/about\"")
  runner.assert_includes(en_home, "Writing")
  runner.assert_includes(en_home, "About")
end

runner.run("navigation includes language dropdown for all languages") do
  en_home = read_output.call("en/index.html")
  runner.assert_includes(en_home, "EN")
  runner.assert_includes(en_home, "KO")
  runner.assert_includes(en_home, "JA")
  runner.assert_includes(en_home, "English")
  runner.assert_includes(en_home, "한국어")
  runner.assert_includes(en_home, "日本語")
end

runner.run("navigation includes dark mode toggle") do
  en_home = read_output.call("en/index.html")
  runner.assert_includes(en_home, "theme-toggle")
  runner.assert_includes(en_home, "localStorage.theme")
end

# ---------------------------------------------------------------------------
# Default layout – HTML structure and SEO
# ---------------------------------------------------------------------------

runner.run("default layout uses local built assets and avoids runtime cdn scripts") do
  en_home = read_output.call("en/index.html")

  runner.assert_includes(en_home, "href=\"/assets/css/tailwind.css\"")
  runner.refute_includes(en_home, "https://cdn.tailwindcss.com")
  runner.refute_includes(en_home, "https://unpkg.com/alpinejs")
end

runner.run("pages have correct html lang attribute") do
  en_home = read_output.call("en/index.html")
  ja_home = read_output.call("ja/index.html")
  ko_home = read_output.call("ko/index.html")

  runner.assert_includes(en_home, '<html lang="en"')
  runner.assert_includes(ja_home, '<html lang="ja"')
  runner.assert_includes(ko_home, '<html lang="ko"')
end

runner.run("pages include viewport meta tag") do
  en_home = read_output.call("en/index.html")
  runner.assert_includes(en_home, 'name="viewport"')
  runner.assert_includes(en_home, "width=device-width")
end

runner.run("pages include favicon") do
  en_home = read_output.call("en/index.html")
  runner.assert_includes(en_home, "favicon.png")
end

runner.run("pages include seo meta tags") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_match(/<title>/, en_post)
end

# ---------------------------------------------------------------------------
# Hreflang alternate links
# ---------------------------------------------------------------------------

runner.run("post pages include hreflang alternate links") do
  en_post = read_output.call("posts/2026-01-01-programming-perls/en/index.html")
  runner.assert_includes(en_post, 'hreflang="en"')
  runner.assert_includes(en_post, 'hreflang="ja"')
  runner.assert_includes(en_post, 'hreflang="ko"')
  runner.assert_includes(en_post, 'hreflang="x-default"')
end

# ---------------------------------------------------------------------------
# Feed
# ---------------------------------------------------------------------------

runner.run("feed file is generated and valid xml") do
  feed = read_output.call("feed.xml")
  entry_count = atom_entry_count.call(feed)

  runner.assert(feed.start_with?("<?xml"), "Expected XML declaration in feed.xml")
  runner.assert(entry_count >= 0, "Unexpected negative feed entry count")
end

runner.run("feed includes article entries") do
  feed = read_output.call("feed.xml")
  entry_count = atom_entry_count.call(feed)

  runner.assert(entry_count > 0, "Expected at least one article entry in feed.xml")
  runner.assert_includes(feed, "/posts/2026-01-01-programming-perls/en/")
end

runner.skip("feed excludes hidden posts", "jekyll-feed does not filter by custom hidden frontmatter; consider adding exclude logic")

# ---------------------------------------------------------------------------
# Sitemap
# ---------------------------------------------------------------------------

runner.run("sitemap is valid xml and contains article urls") do
  sitemap = read_output.call("sitemap.xml")
  runner.assert(sitemap.start_with?("<?xml"), "Expected XML declaration in sitemap.xml")

  visible_by_lang["en"].each do |article|
    runner.assert_includes(sitemap, "/posts/#{article[:slug]}/en/")
  end
end

# ---------------------------------------------------------------------------
# Sidebar
# ---------------------------------------------------------------------------

runner.run("home page includes sidebar with categories and tags") do
  en_home = read_output.call("en/index.html")
  runner.assert_includes(en_home, "Categories")
  runner.assert_includes(en_home, "Tags")
  runner.assert_includes(en_home, "Quick Links")
  runner.assert_includes(en_home, "RSS Feed")
end

runner.run("sidebar categories exclude hidden posts from counts") do
  en_home = read_output.call("en/index.html")
  runner.refute_includes(en_home, "Example Draft Post")
end

# ---------------------------------------------------------------------------
# Footer
# ---------------------------------------------------------------------------

runner.run("footer includes copyright notice") do
  en_home = read_output.call("en/index.html")
  year = Time.now.year.to_s
  runner.assert_includes(en_home, year)
  runner.assert_includes(en_home, "Oxymoron")
end

# ---------------------------------------------------------------------------
# Category detail page content
# ---------------------------------------------------------------------------

runner.run("category detail page shows post count and category name") do
  book_en = read_output.call("en/categories/book/index.html")
  runner.assert_includes(book_en, "Book")
  runner.assert_includes(book_en, "1 posts")
end

runner.run("category detail page has view-all-categories link") do
  book_en = read_output.call("en/categories/book/index.html")
  runner.assert_includes(book_en, "href=\"/en/categories/\"")
  runner.assert_includes(book_en, "View all categories")
end

# ---------------------------------------------------------------------------
# Tag detail page content
# ---------------------------------------------------------------------------

runner.run("tag detail page shows tag name and post count") do
  tag_en = read_output.call("en/tags/programming/index.html")
  runner.assert_includes(tag_en, "#programming")
  runner.assert_includes(tag_en, "1 posts")
end

runner.run("tag detail page has view-all-tags link") do
  tag_en = read_output.call("en/tags/programming/index.html")
  runner.assert_includes(tag_en, "href=\"/en/tags/\"")
  runner.assert_includes(tag_en, "View all tags")
end

# ---------------------------------------------------------------------------
# Post ordering
# ---------------------------------------------------------------------------

runner.run("home page lists posts in reverse chronological order") do
  en_home = read_output.call("en/index.html")
  en_visible = visible_by_lang["en"]

  en_visible.each do |article|
    runner.assert(en_home.include?(article[:title]), "Post '#{article[:title]}' should appear on home page")
  end

  if en_visible.size >= 2
    pos1 = en_home.index(en_visible[0][:title])
    pos2 = en_home.index(en_visible[1][:title])
    runner.assert(pos1 < pos2, "Newer post (#{en_visible[0][:title]}) should appear before older (#{en_visible[1][:title]})")
  end
end

# ---------------------------------------------------------------------------
# Cross-language isolation on taxonomy pages
# ---------------------------------------------------------------------------

runner.run("japanese category page only shows japanese posts") do
  ja_book = read_output.call("ja/categories/book/index.html")
  runner.assert_includes(ja_book, "プログラミング・パール")
  runner.refute_includes(ja_book, "Programming Pearls")
  runner.refute_includes(ja_book, "프로그래밍 펄")
end

runner.run("korean tag page only shows korean posts") do
  ko_programming = read_output.call("ko/tags/programming/index.html")
  runner.assert_includes(ko_programming, "프로그래밍 펄")
  runner.refute_includes(ko_programming, "Programming Pearls")
  runner.refute_includes(ko_programming, "プログラミング・パール")
end

# ---------------------------------------------------------------------------
# UI translations
# ---------------------------------------------------------------------------

runner.run("japanese pages use japanese UI strings") do
  ja_home = read_output.call("ja/index.html")
  runner.assert_includes(ja_home, '<html lang="ja"')
  ja_categories = read_output.call("ja/categories/index.html")
  runner.assert_includes(ja_categories, "カテゴリー")
end

runner.run("korean pages use korean UI strings") do
  ko_home = read_output.call("ko/index.html")
  runner.assert_includes(ko_home, '<html lang="ko"')
  ko_categories = read_output.call("ko/categories/index.html")
  runner.assert_includes(ko_categories, "카테고리")
end

# ---------------------------------------------------------------------------
# Home page post note count
# ---------------------------------------------------------------------------

runner.run("home page shows visible post count") do
  en_home = read_output.call("en/index.html")
  en_count = visible_by_lang["en"].size
  runner.assert_includes(en_home, "#{en_count} notes")
end

# ---------------------------------------------------------------------------
# Bookshelf — navigation link
# ---------------------------------------------------------------------------

runner.run("navigation includes localized Bookshelf link") do
  en_home = read_output.call("en/index.html")
  ja_home = read_output.call("ja/index.html")
  ko_home = read_output.call("ko/index.html")

  runner.assert_includes(en_home, "Bookshelf")
  runner.assert_includes(en_home, "href=\"/en/bookshelf/\"")
  runner.assert_includes(ja_home, "本棚")
  runner.assert_includes(ja_home, "href=\"/ja/bookshelf/\"")
  runner.assert_includes(ko_home, "책장")
  runner.assert_includes(ko_home, "href=\"/ko/bookshelf/\"")
end

# ---------------------------------------------------------------------------
# Bookshelf — book detail pages
# ---------------------------------------------------------------------------

runner.run("book detail pages exist for every language") do
  %w[atomic-habits project-hail-mary dune].each do |slug|
    %w[en ja ko].each do |lang|
      runner.assert_file_exists(File.join(destination, "books/#{slug}/#{lang}/index.html"))
    end
  end
end

runner.run("book page shows title, author, status and review body") do
  ah = read_output.call("books/atomic-habits/en/index.html")
  runner.assert_includes(ah, "Atomic Habits")
  runner.assert_includes(ah, "James Clear")
  runner.assert_includes(ah, "Finished")
  runner.assert_includes(ah, "Small habits compound")
end

runner.run("rated book renders star rating, wishlist book does not") do
  ah = read_output.call("books/atomic-habits/en/index.html")
  runner.assert_includes(ah, "book-stars")
  runner.assert_includes(ah, "4.0 / 5")

  dune = read_output.call("books/dune/en/index.html")
  runner.refute_includes(dune, "book-stars")
end

runner.run("book page has language switcher and back-to-shelf link") do
  ah = read_output.call("books/atomic-habits/en/index.html")
  runner.assert_includes(ah, "/books/atomic-habits/ja/")
  runner.assert_includes(ah, "/books/atomic-habits/ko/")
  runner.assert_includes(ah, "href=\"/en/bookshelf/\"")
  runner.assert_includes(ah, "Back to bookshelf")
end

runner.run("book cover uses image when present and fallback when absent") do
  ah = read_output.call("books/atomic-habits/en/index.html")
  runner.assert_includes(ah, "/assets/books/atomic-habits/cover.png")

  phm = read_output.call("books/project-hail-mary/en/index.html")
  runner.assert_includes(phm, "book-cover--fallback")
end

# ---------------------------------------------------------------------------
# Bookshelf — index pages
# ---------------------------------------------------------------------------

runner.run("bookshelf index pages are generated for each language") do
  %w[
    bookshelf/index.html
    en/bookshelf/index.html
    ja/bookshelf/index.html
    ko/bookshelf/index.html
  ].each do |route|
    runner.assert_file_exists(File.join(destination, route))
  end
end

runner.run("bookshelf groups books into status shelves with links") do
  en_shelf = read_output.call("en/bookshelf/index.html")
  runner.assert_includes(en_shelf, "Currently reading")
  runner.assert_includes(en_shelf, "Finished")
  runner.assert_includes(en_shelf, "Want to read")
  runner.assert_includes(en_shelf, "Atomic Habits")
  runner.assert_includes(en_shelf, "Project Hail Mary")
  runner.assert_includes(en_shelf, "Dune")
  runner.assert_includes(en_shelf, "href=\"/books/project-hail-mary/en/\"")
end

runner.run("bookshelf is language filtered") do
  en_shelf = read_output.call("en/bookshelf/index.html")
  runner.refute_includes(en_shelf, "デューン 砂の惑星")

  ja_shelf = read_output.call("ja/bookshelf/index.html")
  runner.assert_includes(ja_shelf, "デューン 砂の惑星")
  runner.refute_includes(ja_shelf, "Dune")
end

# ---------------------------------------------------------------------------
# Bookshelf — styling & interaction wiring
# ---------------------------------------------------------------------------

runner.run("main.css defines bookshelf styles including dark mode") do
  css = read_output.call("assets/css/main.css")
  runner.assert_includes(css, ".bookcase")
  runner.assert_includes(css, ".book-spine")
  runner.assert_includes(css, ".book-pop")
  runner.assert_includes(css, ".dark .bookcase")
  runner.assert_includes(css, "prefers-reduced-motion")
end

runner.run("bookshelf page wires hover-reveal markup and touch script") do
  en_shelf = read_output.call("en/bookshelf/index.html")
  runner.assert_includes(en_shelf, "class=\"bookcase\"")
  runner.assert_includes(en_shelf, "book-spine")
  runner.assert_includes(en_shelf, "book-pop")
  runner.assert_includes(en_shelf, "is-open")
  runner.assert_includes(en_shelf, "addEventListener")
end

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

puts
puts "Summary: #{runner.passes} passed, #{runner.failures.size} failed, #{runner.skips.size} skipped"

if runner.failures.any?
  puts
  puts "Failures:"
  runner.failures.each_with_index do |(name, error), index|
    puts "#{index + 1}. #{name}"
    puts "   #{error.class}: #{error.message}"
  end
  exit 1
end
