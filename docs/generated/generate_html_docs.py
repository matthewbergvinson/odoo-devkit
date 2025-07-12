import os
import sys
import markdown
import json
from datetime import datetime

def convert_markdown_to_html(markdown_file, html_file, title="Documentation"):
    """Convert Markdown file to HTML with styling."""

    try:
        with open(markdown_file, 'r', encoding='utf-8') as f:
            md_content = f.read()

        # Convert markdown to HTML
        html_content = markdown.markdown(md_content, extensions=['tables', 'toc', 'codehilite'])

        # Create full HTML document
        html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - Royal Textiles Odoo</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8f9fa;
            padding: 20px;
        }}

        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}

        h1 {{
            color: #e83e8c;
            border-bottom: 3px solid #e83e8c;
            padding-bottom: 10px;
            margin-bottom: 30px;
        }}

        h2 {{
            color: #6f42c1;
            margin-top: 40px;
            margin-bottom: 20px;
            border-left: 4px solid #6f42c1;
            padding-left: 15px;
        }}

        h3 {{
            color: #495057;
            margin-top: 30px;
            margin-bottom: 15px;
        }}

        h4 {{
            color: #666;
            margin-top: 20px;
            margin-bottom: 10px;
        }}

        code {{
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            color: #e83e8c;
        }}

        pre {{
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 20px 0;
        }}

        pre code {{
            background: none;
            color: inherit;
            padding: 0;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }}

        th, td {{
            border: 1px solid #dee2e6;
            padding: 12px;
            text-align: left;
        }}

        th {{
            background: #f8f9fa;
            font-weight: 600;
            color: #495057;
        }}

        tr:nth-child(even) {{
            background: #f8f9fa;
        }}

        .toc {{
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }}

        .toc ul {{
            list-style-type: none;
            padding-left: 0;
        }}

        .toc li {{
            margin: 5px 0;
        }}

        .toc a {{
            color: #6f42c1;
            text-decoration: none;
        }}

        .toc a:hover {{
            text-decoration: underline;
        }}

        blockquote {{
            border-left: 4px solid #6f42c1;
            padding-left: 20px;
            margin: 20px 0;
            color: #666;
            font-style: italic;
        }}

        .header-info {{
            background: linear-gradient(135deg, #e83e8c 0%, #6f42c1 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }}

        .footer {{
            text-align: center;
            color: #666;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #dee2e6;
        }}

        .badge {{
            display: inline-block;
            padding: 4px 8px;
            background: #6f42c1;
            color: white;
            border-radius: 12px;
            font-size: 0.8em;
            margin: 2px;
        }}

        .api-method {{
            background: #28a745;
        }}

        .http-route {{
            background: #17a2b8;
        }}

        @media (max-width: 768px) {{
            body {{
                padding: 10px;
            }}

            .container {{
                padding: 20px;
            }}

            table {{
                font-size: 0.9em;
            }}
        }}
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/default.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>
    <script>hljs.highlightAll();</script>
</head>
<body>
    <div class="container">
        <div class="header-info">
            <h1>🏢 Royal Textiles Odoo Platform</h1>
            <p>📚 {title}</p>
            <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>

        {html_content}

        <div class="footer">
            <p><strong>Royal Textiles Odoo Platform Documentation</strong></p>
            <p>Generated by Task 6.7 - Documentation Generation System</p>
        </div>
    </div>
</body>
</html>"""

        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html_template)

        print(f"HTML documentation generated: {html_file}")
        return True

    except Exception as e:
        print(f"Error converting {markdown_file} to HTML: {e}")
        return False

def main():
    if len(sys.argv) < 4:
        print("Usage: python generate_html_docs.py <markdown_file> <html_file> <title>")
        sys.exit(1)

    markdown_file = sys.argv[1]
    html_file = sys.argv[2]
    title = sys.argv[3]

    success = convert_markdown_to_html(markdown_file, html_file, title)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
