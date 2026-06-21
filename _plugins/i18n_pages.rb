# frozen_string_literal: true

module I18nPages
  # A page generated at build time without a corresponding source file.
  class GeneratedPage < Jekyll::PageWithoutAFile
    def initialize(site, dir, name, data, content = "")
      super(site, site.source, dir, name)
      self.data.merge!(data)
      self.content = content
    end
  end

  # Generates per-language structural pages (home, categories index, tags index)
  # and per-language taxonomy detail pages (individual category/tag archives).
  #
  # Categories and tags are auto-discovered from article front matter — no manual
  # file creation needed.
  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      languages    = site.config["languages"] || []
      translations = site.data["translations"] || {}

      generate_structural_pages(site, languages, translations)
      generate_taxonomy_pages(site, languages)
    end

    private

    def generate_structural_pages(site, languages, translations)
      languages.each do |lang|
        t = translations[lang] || {}

        # Home: /{lang}/
        add_page(site, lang, "index.html",
          { "layout" => "default", "lang" => lang, "permalink" => "/#{lang}/" },
          "{% include home-content.html %}")

        # Categories index: /{lang}/categories/
        add_page(site, "#{lang}/categories", "index.html",
          { "layout" => "default", "lang" => lang,
            "title" => t.dig("categories", "title") || "Categories",
            "permalink" => "/#{lang}/categories/" },
          "{% include categories-content.html %}")

        # Tags index: /{lang}/tags/
        add_page(site, "#{lang}/tags", "index.html",
          { "layout" => "default", "lang" => lang,
            "title" => t.dig("tags", "title") || "Tags",
            "permalink" => "/#{lang}/tags/" },
          "{% include tags-content.html %}")

        # Bookshelf: /{lang}/bookshelf/
        add_page(site, "#{lang}/bookshelf", "index.html",
          { "layout" => "default", "lang" => lang,
            "title" => t.dig("bookshelf", "title") || "Bookshelf",
            "permalink" => "/#{lang}/bookshelf/" },
          "{% include bookshelf-content.html %}")

        # Atom feed: /{lang}/feed.xml
        add_page(site, lang, "feed.xml",
          { "layout" => nil, "lang" => lang,
            "permalink" => "/#{lang}/feed.xml" },
          "{% include feed-content.xml %}")
      end

      # Top-level /categories/ and /tags/ (no lang — defaults to site.default_lang)
      add_page(site, "categories", "index.html",
        { "layout" => "default", "title" => "Categories", "permalink" => "/categories/" },
        "{% include categories-content.html %}")

      add_page(site, "tags", "index.html",
        { "layout" => "default", "title" => "Tags", "permalink" => "/tags/" },
        "{% include tags-content.html %}")

      add_page(site, "bookshelf", "index.html",
        { "layout" => "default", "title" => "Bookshelf", "permalink" => "/bookshelf/" },
        "{% include bookshelf-content.html %}")
    end

    def generate_taxonomy_pages(site, languages)
      categories = []
      tags       = []

      site.collections["articles"]&.docs&.each do |doc|
        categories << doc.data["category"] if doc.data["category"]
        (doc.data["tags"] || []).each { |t| tags << t }
      end

      categories.uniq!
      tags.uniq!

      categories.each do |category|
        slug = slugify(category)
        languages.each do |lang|
          add_page(site, "#{lang}/categories/#{slug}", "index.html",
            { "layout" => "category", "category" => category, "lang" => lang,
              "permalink" => "/#{lang}/categories/#{slug}/" })
        end
      end

      tags.each do |tag|
        slug = slugify(tag)
        languages.each do |lang|
          add_page(site, "#{lang}/tags/#{slug}", "index.html",
            { "layout" => "tag", "tag" => tag, "lang" => lang,
              "permalink" => "/#{lang}/tags/#{slug}/" })
        end
      end
    end

    def add_page(site, dir, name, data, content = "")
      site.pages << GeneratedPage.new(site, dir, name, data, content)
    end

    def slugify(value)
      value.downcase.gsub(/\s+/, "-")
    end
  end
end
