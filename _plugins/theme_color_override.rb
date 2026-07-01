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

      #markdown-content pre {
        margin: 1rem 0 1.25rem;
        padding: 1rem 1.125rem;
        overflow-x: auto;
        border: 1px solid var(--global-theme-color);
        border-radius: 6px;
        background: #eff6ff;
        color: #111827;
        line-height: 1.65;
        tab-size: 2;
      }

      #markdown-content pre code,
      #markdown-content pre code span {
        padding: 0;
        border: 0;
        background: transparent !important;
        color: inherit;
        font-size: 0.88rem;
        line-height: inherit;
        white-space: pre;
      }

      #markdown-content div.highlighter-rouge,
      #markdown-content div.highlight {
        border-radius: 6px;
        background: #eff6ff;
      }

      #markdown-content p code,
      #markdown-content li code,
      #markdown-content td code {
        padding: 0.12rem 0.32rem;
        border: 1px solid rgba(37, 99, 235, 0.16);
        border-radius: 4px;
        background: rgba(37, 99, 235, 0.08);
        color: #1d4ed8;
        font-size: 0.9em;
      }

      html[data-theme="dark"] #markdown-content pre {
        border-color: var(--global-theme-color);
        background: #0f1d33;
        color: #e5e7eb;
      }

      html[data-theme="dark"] #markdown-content div.highlighter-rouge,
      html[data-theme="dark"] #markdown-content div.highlight {
        background: #0f1d33;
      }

      html[data-theme="dark"] #markdown-content p code,
      html[data-theme="dark"] #markdown-content li code,
      html[data-theme="dark"] #markdown-content td code {
        border-color: rgba(96, 165, 250, 0.28);
        background: rgba(96, 165, 250, 0.12);
        color: #60a5fa;
      }

      #markdown-content .code-display-wrapper .copy {
        z-index: 3;
        border: 1px solid var(--global-theme-color);
        background: #ffffff;
        color: var(--global-theme-color);
        cursor: pointer;
        line-height: 1;
        padding: 0.35rem 0.45rem;
      }

      #markdown-content .code-display-wrapper .copy:focus-visible {
        opacity: 1;
        outline: 2px solid rgba(37, 99, 235, 0.32);
        outline-offset: 2px;
      }

      html[data-theme="dark"] #markdown-content .code-display-wrapper .copy {
        background: #111827;
      }

      @media (hover: none) {
        #markdown-content .code-display-wrapper .copy {
          opacity: 1;
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

  SCRIPT = <<~HTML.freeze
    <script id="site-code-copy-fallback">
      (function () {
        function legacyWriteText(text) {
          return new Promise(function (resolve, reject) {
            var textarea = document.createElement("textarea");
            textarea.value = text;
            textarea.setAttribute("readonly", "");
            textarea.style.position = "fixed";
            textarea.style.left = "-9999px";
            textarea.style.top = "-9999px";
            textarea.style.opacity = "0";
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();

            try {
              var copied = document.execCommand("copy");
              document.body.removeChild(textarea);
              copied ? resolve() : reject(new Error("copy command failed"));
            } catch (error) {
              document.body.removeChild(textarea);
              reject(error);
            }
          });
        }

        function writeText(text) {
          if (window.navigator.clipboard && typeof window.navigator.clipboard.writeText === "function" && window.isSecureContext) {
            return window.navigator.clipboard.writeText(text).catch(function () {
              return legacyWriteText(text);
            });
          }

          return legacyWriteText(text);
        }

        function codeTextFrom(pre) {
          var nestedPre = pre.querySelector("pre:not(.lineno)");
          var code = nestedPre || pre.querySelector("code") || pre;
          return code.innerText.trim();
        }

        function setCopyState(button, ok) {
          button.innerHTML = ok ? "<i class=\"fa-solid fa-clipboard-check\"></i>" : "<i class=\"fa-solid fa-triangle-exclamation\"></i>";
          button.setAttribute("aria-label", ok ? "Copied code to clipboard" : "Copy failed");

          window.setTimeout(function () {
            button.innerHTML = "<i class=\"fa-solid fa-clipboard\"></i>";
            button.setAttribute("aria-label", "Copy code to clipboard");
          }, 3000);
        }

        document.addEventListener(
          "click",
          function (event) {
            var button = event.target.closest && event.target.closest(".code-display-wrapper .copy");
            if (!button) return;

            var wrapper = button.closest(".code-display-wrapper");
            var pre = wrapper && wrapper.querySelector("pre");
            if (!pre) return;

            event.preventDefault();
            event.stopImmediatePropagation();

            writeText(codeTextFrom(pre)).then(
              function () {
                setCopyState(button, true);
              },
              function () {
                setCopyState(button, false);
              }
            );
          },
          true
        );
      })();
    </script>
  HTML

  def self.inject(output)
    return output unless output.include?("</head>")
    return output if output.include?('id="site-theme-color-overrides"')

    output.sub("</head>", "#{STYLE}#{SCRIPT}</head>")
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
