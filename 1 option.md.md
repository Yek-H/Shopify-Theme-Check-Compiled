{% comment %}
Collection Grid with Type (V7 - Performance Refactor)

Performance-oriented changes:
- Keeps the original visual design and section schema.
- Caps eager images at 2 because Liquid cannot know the visitor viewport.
- Uses section.location + section.index for automatic LCP priority.
- Removes fetchpriority="low" from other visible/eager images.
- Keeps the first-product fallback optional and disabled by default.
- Aligns deferred rendering with the actual eager-image limit.
- Replaces repeated srcset arithmetic with a bounded, viewport-appropriate set.
- Uses a responsive contain-intrinsic-size placeholder tied to the actual grid width.
- Removes redundant section-level containment.
- Preserves accessibility, responsive behavior, and editor settings.
{% endcomment %}

{%- liquid
  assign selected_collections = section.settings.collections

  assign has_collections = false
  if selected_collections != blank and selected_collections.size > 0
    assign has_collections = true
  endif

  assign should_render = false
  if has_collections or request.design_mode
    assign should_render = true
  endif

  if should_render
    assign collections_to_show = section.settings.collections_to_show | default: 10 | plus: 0
    assign collections_per_row = section.settings.collections_per_row | default: 5 | plus: 0
    assign mobile_columns = section.settings.mobile_columns | default: 2 | plus: 0
    assign priority_mode = section.settings.image_priority | default: 'auto'
    assign section_index = section.index | default: 0 | plus: 0

    assign use_product_image_fallback = section.settings.use_product_image_fallback
    assign show_description = section.settings.show_description
    assign show_product_count = section.settings.show_product_count

    assign eager_limit = 2
    assign fetch_priority_first = 'auto'

    case priority_mode
      when 'high'
        assign fetch_priority_first = 'high'
      when 'lazy'
        assign eager_limit = 0
      else
        if section.location == 'template' and section_index == 1
          assign fetch_priority_first = 'high'
        elsif section_index > 3
          assign eager_limit = 0
        endif
    endcase

    assign container_padding = 40
    assign desktop_gap = 30
    assign desktop_subtract = collections_per_row | minus: 1 | times: desktop_gap | plus: container_padding
    assign tablet_gap = 20
    assign tablet_subtract = tablet_gap | times: 2 | plus: container_padding
    assign mobile_gap = 15
    assign mobile_subtract = mobile_columns | minus: 1 | times: mobile_gap | plus: container_padding

    assign intrinsic_info_height = 94
    if show_description
      assign intrinsic_info_height = intrinsic_info_height | plus: 70
    endif
    if show_product_count
      assign intrinsic_info_height = intrinsic_info_height | plus: 22
    endif

    capture sizes_attr
      echo '(min-width: 1400px) calc((1400px - ' | append: desktop_subtract | append: 'px) / ' | append: collections_per_row | append: '), '
      echo '(min-width: 1025px) calc((100vw - ' | append: desktop_subtract | append: 'px) / ' | append: collections_per_row | append: '), '
      echo '(min-width: 769px) calc((100vw - ' | append: tablet_subtract | append: 'px) / 3), '
      echo 'calc((100vw - ' | append: mobile_subtract | append: 'px) / ' | append: mobile_columns | append: ')'
    endcapture

    assign sizes_attr = sizes_attr | strip

    assign image_width = 1536
    assign widths_attr = '320,480,640,768,960,1200,1536'

    assign label_view_all = ''
    if section.settings.show_view_all
      assign label_view_all = 'sections.collection_list.view_all' | t

      if label_view_all contains 'Translation missing'
        assign label_view_all = 'View all'
      endif
    endif
  endif
-%}

{%- if should_render -%}
  {% style %}
    #shopify-section-{{ section.id }} .product-grid-section {
      padding: 60px 0;
    }

    /* Own width wrapper to avoid modifying the global .page-width class. */
    #shopify-section-{{ section.id }} .product-grid__width {
      max-width: 1400px;
      margin: 0 auto;
      padding: 0 20px;
      box-sizing: border-box;
    }

    #shopify-section-{{ section.id }} .section-heading {
      text-align: center;
      font-size: 32px;
      font-weight: 600;
      margin: 0 0 40px;
      color: #333;
    }

    #shopify-section-{{ section.id }} .product-grid {
      display: grid;
      gap: {{ desktop_gap }}px;
      list-style: none;
      padding: 0;
      margin: 0;
    }

    @media (min-width: 1025px) {
      #shopify-section-{{ section.id }} .product-grid--desktop-2 {
        grid-template-columns: repeat(2, 1fr);
      }

      #shopify-section-{{ section.id }} .product-grid--desktop-3 {
        grid-template-columns: repeat(3, 1fr);
      }

      #shopify-section-{{ section.id }} .product-grid--desktop-4 {
        grid-template-columns: repeat(4, 1fr);
      }

      #shopify-section-{{ section.id }} .product-grid--desktop-5 {
        grid-template-columns: repeat(5, 1fr);
      }
    }

    @media (max-width: 1024px) and (min-width: 769px) {
      #shopify-section-{{ section.id }} .product-grid {
        grid-template-columns: repeat(3, 1fr);
        gap: 20px;
      }
    }

    #shopify-section-{{ section.id }} .product-card {
      background: #fff;
      border-radius: 8px;
      overflow: hidden;
      transition: transform 0.2s ease, box-shadow 0.2s ease;
      border: 1px solid #e5e5e5;
      display: flex;
      flex-direction: column;
      contain: paint layout;
    }

    #shopify-section-{{ section.id }} .product-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08);
    }

    /* Applied only to cards that are safe to defer. */
    #shopify-section-{{ section.id }} .product-card--deferred {
      content-visibility: auto;
      contain-intrinsic-size:
        auto calc((100vw - {{ mobile_subtract }}px) / {{ mobile_columns }})
        auto calc(((100vw - {{ mobile_subtract }}px) / {{ mobile_columns }}) * 1.25 + {{ intrinsic_info_height }}px);
    }

    @media (min-width: 769px) and (max-width: 1024px) {
      #shopify-section-{{ section.id }} .product-card--deferred {
        contain-intrinsic-size:
          auto calc((100vw - {{ tablet_subtract }}px) / 3)
          auto calc(((100vw - {{ tablet_subtract }}px) / 3) * 1.25 + {{ intrinsic_info_height }}px);
      }
    }

    @media (min-width: 1025px) and (max-width: 1399px) {
      #shopify-section-{{ section.id }} .product-card--deferred {
        contain-intrinsic-size:
          auto calc((100vw - {{ desktop_subtract }}px) / {{ collections_per_row }})
          auto calc(((100vw - {{ desktop_subtract }}px) / {{ collections_per_row }}) * 1.25 + {{ intrinsic_info_height }}px);
      }
    }

    @media (min-width: 1400px) {
      #shopify-section-{{ section.id }} .product-card--deferred {
        contain-intrinsic-size:
          auto calc((1400px - {{ desktop_subtract }}px) / {{ collections_per_row }})
          auto calc(((1400px - {{ desktop_subtract }}px) / {{ collections_per_row }}) * 1.25 + {{ intrinsic_info_height }}px);
      }
    }

    #shopify-section-{{ section.id }} .product-card__link {
      text-decoration: none;
      color: inherit;
      display: flex;
      flex-direction: column;
      height: 100%;
      border-radius: inherit;
    }

    #shopify-section-{{ section.id }} .product-card__link:focus-visible {
      outline: 2px solid currentColor;
      outline-offset: -2px;
    }

    @media (forced-colors: active) {
      #shopify-section-{{ section.id }} .product-card__link:focus-visible {
        outline: 2px solid;
      }
    }

    #shopify-section-{{ section.id }} .product-card__image-wrapper {
      position: relative;
      width: 100%;
      aspect-ratio: 4 / 5;
      background: #f5f5f5;
      overflow: hidden;
    }

    /* Fallback for browsers without aspect-ratio support. */
    @supports not (aspect-ratio: 4 / 5) {
      #shopify-section-{{ section.id }} .product-card__image-wrapper {
        height: 0;
        padding-top: 125%;
      }
    }

    #shopify-section-{{ section.id }} img.product-card__image {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      max-width: none;
      max-height: none;
      object-fit: cover;
      object-position: center center;
      transition: transform 0.5s ease;
    }

    #shopify-section-{{ section.id }} .product-card:hover img.product-card__image {
      transform: scale(1.04);
    }

    #shopify-section-{{ section.id }} .product-card__image-placeholder {
      position: absolute;
      inset: 0;
    }

    #shopify-section-{{ section.id }} .product-card__image-placeholder svg {
      width: 100%;
      height: 100%;
      display: block;
    }

    #shopify-section-{{ section.id }} .product-card__info {
      padding: 20px;
      text-align: center;
      flex-grow: 1;
      display: flex;
      flex-direction: column;
    }

    #shopify-section-{{ section.id }} .product-card__title {
      font-size: 16px;
      font-weight: 600;
      margin: 0 0 8px 0;
      color: #333;
      line-height: 1.4;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
      min-height: 2.8em;
    }

    #shopify-section-{{ section.id }} .product-card__type {
      font-size: 13px;
      margin: 0 0 12px 0;
      color: {{ section.settings.type_color | default: '#666666' }};
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    {% if section.settings.type_style == 'pill' %}
      #shopify-section-{{ section.id }} .product-card__type {
        display: inline-block;
        background: {{ section.settings.type_bg_color | default: '#f5f5f5' }};
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 12px;
        align-self: center;
      }
    {% elsif section.settings.type_style == 'underline' %}
      #shopify-section-{{ section.id }} .product-card__type {
        border-bottom: 2px solid {{ section.settings.type_color | default: '#666666' }};
        display: inline-block;
        padding-bottom: 2px;
        align-self: center;
      }
    {% endif %}

    #shopify-section-{{ section.id }} .product-card__count {
      font-size: 12px;
      color: #595959;
      margin: 0;
      margin-top: auto;
      padding-top: 8px;
    }

    #shopify-section-{{ section.id }} .product-grid__view-all {
      text-align: center;
      margin-top: 40px;
    }

    #shopify-section-{{ section.id }} .product-grid__onboarding {
      padding: 24px;
      border: 1px dashed #c9c9c9;
      border-radius: 8px;
      color: #555;
      text-align: center;
      font-size: 14px;
    }

    @media (max-width: 768px) {
      #shopify-section-{{ section.id }} .product-grid-section {
        padding: 40px 0;
      }

      #shopify-section-{{ section.id }} .section-heading {
        font-size: 24px;
        margin-bottom: 24px;
      }

      #shopify-section-{{ section.id }} .product-grid {
        gap: {{ mobile_gap }}px;
      }

      #shopify-section-{{ section.id }} .product-grid--mobile-1 {
        grid-template-columns: 1fr;
      }

      #shopify-section-{{ section.id }} .product-grid--mobile-2 {
        grid-template-columns: repeat(2, 1fr);
      }

      #shopify-section-{{ section.id }} .product-card__info {
        padding: 15px;
      }

      #shopify-section-{{ section.id }} .product-card__title {
        font-size: 14px;
        min-height: 2.8em;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      #shopify-section-{{ section.id }} .product-card,
      #shopify-section-{{ section.id }} img.product-card__image {
        transition: none;
      }

      #shopify-section-{{ section.id }} .product-card:hover {
        transform: none;
      }

      #shopify-section-{{ section.id }} .product-card:hover img.product-card__image {
        transform: none;
      }
    }
  {% endstyle %}

  <div class="product-grid-section" data-section-id="{{ section.id }}">
    <div class="product-grid__width">
      {%- if section.settings.heading != blank -%}
        <h2 class="section-heading">{{ section.settings.heading | escape }}</h2>
      {%- endif -%}

      {%- if has_collections == false -%}
        {%- if request.design_mode -%}
          <p class="product-grid__onboarding">
            Select collections in this section’s settings.
          </p>
        {%- endif -%}
      {%- else -%}
        <ul
          class="product-grid product-grid--desktop-{{ collections_per_row }} product-grid--mobile-{{ mobile_columns }}"
          role="list"
        >
          {%- for collection in selected_collections limit: collections_to_show -%}
            {%- liquid
              assign loading_strategy = 'lazy'
              assign fetch_priority = 'auto'

              if forloop.index <= eager_limit
                assign loading_strategy = 'eager'

                if forloop.index == 1
                  assign fetch_priority = fetch_priority_first
                endif
              endif

              assign deferred = true
              if eager_limit > 0 and forloop.index <= eager_limit
                assign deferred = false
              endif

              assign card_image = collection.featured_image

              if use_product_image_fallback and card_image == blank
                assign fallback_product = collection.products.first

                if fallback_product and fallback_product.featured_image
                  assign card_image = fallback_product.featured_image
                endif
              endif

              assign image_alt = card_image.alt | default: collection.title

              assign collection_description = ''
              if show_description
                assign collection_description = collection.description | strip_html | strip | truncate: 80
              endif

              assign product_count_label = ''
              if show_product_count
                assign product_count = collection.all_products_count | default: 0
                assign product_count_label = 'products.facets.product_count_simple' | t: count: product_count

                if product_count_label contains 'Translation missing'
                  if product_count == 1
                    assign product_count_label = '1 product'
                  else
                    assign product_count_label = product_count | append: ' products'
                  endif
                endif
              endif
            -%}

            <li class="product-card{% if deferred %} product-card--deferred{% endif %}">
              <a href="{{ collection.url }}" class="product-card__link">
                <div class="product-card__image-wrapper">
                  {%- if card_image -%}
                    {{
                      card_image
                      | image_url: width: image_width
                      | image_tag:
                        loading: loading_strategy,
                        fetchpriority: fetch_priority,
                        sizes: sizes_attr,
                        widths: widths_attr,
                        class: 'product-card__image',
                        decoding: 'async',
                        alt: image_alt
                    }}
                  {%- else -%}
                    <div class="product-card__image-placeholder" aria-hidden="true">
                      {{ 'product-1' | placeholder_svg_tag: 'placeholder-svg' }}
                    </div>
                  {%- endif -%}
                </div>

                <div class="product-card__info">
                  <h3 class="product-card__title">{{ collection.title | escape }}</h3>

                  {%- if show_description and collection_description != blank -%}
                    <p class="product-card__type">{{ collection_description | escape }}</p>
                  {%- endif -%}

                  {%- if show_product_count -%}
                    <p class="product-card__count">{{ product_count_label | escape }}</p>
                  {%- endif -%}
                </div>
              </a>
            </li>
          {%- endfor -%}
        </ul>

        {%- if section.settings.show_view_all -%}
          <div class="product-grid__view-all color-{{ section.settings.view_all_color_scheme }}">
            <a
              href="{{ routes.collections_url }}"
              class="{% if section.settings.view_all_style == 'link' %}link underlined-link{% elsif section.settings.view_all_style == 'solid' %}button{% else %}button button--secondary{% endif %}"
            >
              {{ label_view_all | escape }}
            </a>
          </div>
        {%- endif -%}
      {%- endif -%}
    </div>
  </div>
{%- endif -%}

{% schema %}
{
  "name": "Collection Grid (Opt.)",
  "disabled_on": {
    "groups": ["header", "footer"]
  },
  "settings": [
    {
      "type": "text",
      "id": "heading",
      "label": "Heading",
      "default": "Featured Collections"
    },
    {
      "type": "collection_list",
      "id": "collections",
      "label": "Collections",
      "limit": 50
    },
    {
      "type": "range",
      "id": "collections_to_show",
      "min": 2,
      "max": 50,
      "step": 1,
      "label": "Collections to show",
      "default": 10
    },
    {
      "type": "range",
      "id": "collections_per_row",
      "min": 2,
      "max": 5,
      "step": 1,
      "label": "Collections per row (desktop)",
      "default": 5,
      "info": "Use 5 to match Mangas destacados card size."
    },
    {
      "type": "header",
      "content": "Image loading"
    },
    {
      "type": "select",
      "id": "image_priority",
      "label": "Image priority",
      "options": [
        {
          "value": "auto",
          "label": "Automatic (by section position)"
        },
        {
          "value": "high",
          "label": "High — this grid is the first thing on screen"
        },
        {
          "value": "lazy",
          "label": "Lazy — this grid is always below the fold"
        }
      ],
      "default": "auto",
      "info": "Set to High only if Lighthouse reports a collection image here as the LCP element. Only one section on a page should use High."
    },
    {
      "type": "checkbox",
      "id": "use_product_image_fallback",
      "label": "Use first product image when collection image is missing (slower)",
      "default": false
    },
    {
      "type": "header",
      "content": "Mobile Settings"
    },
    {
      "type": "select",
      "id": "mobile_columns",
      "label": "Mobile columns",
      "options": [
        {
          "value": "1",
          "label": "1 column"
        },
        {
          "value": "2",
          "label": "2 columns"
        }
      ],
      "default": "2"
    },
    {
      "type": "header",
      "content": "Collection Information"
    },
    {
      "type": "checkbox",
      "id": "show_description",
      "label": "Show collection description",
      "default": false
    },
    {
      "type": "checkbox",
      "id": "show_product_count",
      "label": "Show product count",
      "default": false
    },
    {
      "type": "header",
      "content": "Styling"
    },
    {
      "type": "color",
      "id": "type_color",
      "label": "Description color",
      "default": "#666666"
    },
    {
      "type": "select",
      "id": "type_style",
      "label": "Description style",
      "options": [
        {
          "value": "text",
          "label": "Plain"
        },
        {
          "value": "pill",
          "label": "Pill"
        },
        {
          "value": "underline",
          "label": "Underlined"
        }
      ],
      "default": "text"
    },
    {
      "type": "color",
      "id": "type_bg_color",
      "label": "Pill background",
      "default": "#f5f5f5"
    },
    {
      "type": "header",
      "content": "View All"
    },
    {
      "type": "checkbox",
      "id": "show_view_all",
      "label": "Enable 'View all'",
      "default": false
    },
    {
      "type": "select",
      "id": "view_all_style",
      "label": "Button style",
      "options": [
        {
          "value": "link",
          "label": "Link"
        },
        {
          "value": "outline",
          "label": "Outline"
        },
        {
          "value": "solid",
          "label": "Solid"
        }
      ],
      "default": "solid"
    },
    {
      "type": "color_scheme",
      "id": "view_all_color_scheme",
      "label": "Color scheme",
      "default": "scheme-1"
    }
  ],
  "presets": [
    {
      "name": "Collection Grid (Opt.)"
    }
  ]
}
{% endschema %}