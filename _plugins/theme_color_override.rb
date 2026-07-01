# frozen_string_literal: true

module ThemeColorOverride
  STYLE = <<~CSS.freeze
    <style id="site-theme-color-overrides">
      html {
        overflow-y: scroll;
        scrollbar-gutter: stable;
      }

      @media (min-width: 576px) {
        .publications ol.bibliography > li .abbr {
          flex: 0 0 25%;
          max-width: 25%;
        }

        .publications ol.bibliography > li .abbr + [id] {
          flex: 0 0 75%;
          max-width: 75%;
        }
      }

      :root {
        --global-theme-color: #2563eb;
        --global-hover-color: #1d4ed8;
        --global-footer-link-color: #2563eb;
      }

      html[data-theme="dark"] {
        --global-theme-color: #60a5fa;
        --global-hover-color: #93c5fd;
        --global-footer-link-color: #60a5fa;
      }
    </style>
  CSS

  def self.inject(output)
    return output unless output.include?("</head>")
    return output if output.include?('id="site-theme-color-overrides"')

    output.sub("</head>", "#{STYLE}</head>")
  end
end

Jekyll::Hooks.register :site, :post_render do |site|
  site.pages.each do |page|
    page.output = ThemeColorOverride.inject(page.output.to_s)
  end

  site.documents.each do |document|
    document.output = ThemeColorOverride.inject(document.output.to_s)
  end
end
