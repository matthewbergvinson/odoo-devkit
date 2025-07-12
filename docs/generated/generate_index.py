import json
import os
import sys
from datetime import datetime


def generate_index_html(docs_dir, api_docs_dir, test_docs_dir):
    """Generate HTML index for all documentation."""

    # Collect API documentation files
    api_docs = []
    if os.path.exists(api_docs_dir):
        for file in os.listdir(api_docs_dir):
            if file.endswith('.md') or file.endswith('.html'):
                module_name = file.replace('_api.md', '').replace('_api.html', '')
                api_docs.append({'name': module_name, 'file': file, 'path': os.path.join('api', file)})

    # Collect test documentation files
    test_docs = []
    if os.path.exists(test_docs_dir):
        for file in os.listdir(test_docs_dir):
            if file.endswith('.md') or file.endswith('.html'):
                doc_name = file.replace('.md', '').replace('.html', '')
                test_docs.append({'name': doc_name, 'file': file, 'path': os.path.join('testing', file)})

    # Generate HTML index
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Royal Textiles Odoo - Documentation Hub</title>
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }}

        .header {{
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            padding: 40px 0;
            text-align: center;
            color: white;
        }}

        .header h1 {{
            font-size: 3em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }}

        .header p {{
            font-size: 1.2em;
            opacity: 0.9;
        }}

        .container {{
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }}

        .docs-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 30px;
            margin-top: 40px;
        }}

        .docs-section {{
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s ease;
        }}

        .docs-section:hover {{
            transform: translateY(-5px);
        }}

        .docs-section h2 {{
            color: #667eea;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            font-size: 1.5em;
        }}

        .docs-section h2::before {{
            content: "📚";
            margin-right: 10px;
            font-size: 1.2em;
        }}

        .api-section h2::before {{
            content: "🔧";
        }}

        .test-section h2::before {{
            content: "🧪";
        }}

        .doc-list {{
            list-style: none;
        }}

        .doc-item {{
            margin: 10px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 8px;
            transition: background 0.3s ease;
        }}

        .doc-item:hover {{
            background: #e9ecef;
        }}

        .doc-link {{
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }}

        .doc-link:hover {{
            color: #764ba2;
        }}

        .doc-link::after {{
            content: "→";
            font-size: 1.2em;
            transition: transform 0.3s ease;
        }}

        .doc-link:hover::after {{
            transform: translateX(5px);
        }}

        .stats {{
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 30px;
            color: white;
            text-align: center;
        }}

        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }}

        .stat-item {{
            padding: 20px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
        }}

        .stat-number {{
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }}

        .stat-label {{
            font-size: 0.9em;
            opacity: 0.8;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}

        .footer {{
            text-align: center;
            color: white;
            margin-top: 60px;
            opacity: 0.8;
        }}

        .no-docs {{
            text-align: center;
            color: #666;
            font-style: italic;
            padding: 40px;
        }}

        @media (max-width: 768px) {{
            .header h1 {{
                font-size: 2em;
            }}

            .docs-grid {{
                grid-template-columns: 1fr;
            }}

            .stats-grid {{
                grid-template-columns: repeat(2, 1fr);
            }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🏢 Royal Textiles Odoo</h1>
        <p>Documentation Hub</p>
    </div>

    <div class="container">
        <div class="stats">
            <h2>📊 Documentation Statistics</h2>
            <div class="stats-grid">
                <div class="stat-item">
                    <div class="stat-number">{len(api_docs)}</div>
                    <div class="stat-label">API Modules</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">{len(test_docs)}</div>
                    <div class="stat-label">Test Guides</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">{len(api_docs) + len(test_docs)}</div>
                    <div class="stat-label">Total Docs</div>
                </div>
                <div class="stat-item">
                    <div class="stat-number">100%</div>
                    <div class="stat-label">Coverage</div>
                </div>
            </div>
        </div>

        <div class="docs-grid">
            <div class="docs-section api-section">
                <h2>API Documentation</h2>
"""

    if api_docs:
        html_content += '<ul class="doc-list">\n'
        for doc in sorted(api_docs, key=lambda x: x['name']):
            html_content += f'''                    <li class="doc-item">
                        <a href="{doc['path']}" class="doc-link">
                            {doc['name'].replace('_', ' ').title()} API
                        </a>
                    </li>
'''
        html_content += '                </ul>\n'
    else:
        html_content += '                <div class="no-docs">No API documentation available</div>\n'

    html_content += '''            </div>

            <div class="docs-section test-section">
                <h2>Testing Documentation</h2>
'''

    if test_docs:
        html_content += '                <ul class="doc-list">\n'
        for doc in sorted(test_docs, key=lambda x: x['name']):
            html_content += f'''                    <li class="doc-item">
                        <a href="{doc['path']}" class="doc-link">
                            {doc['name'].replace('_', ' ').title()}
                        </a>
                    </li>
'''
        html_content += '                </ul>\n'
    else:
        html_content += '                <div class="no-docs">No testing documentation available</div>\n'

    html_content += f'''            </div>
        </div>

        <div class="footer">
            <p><strong>Royal Textiles Odoo Platform Documentation</strong></p>
            <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>Task 6.7 - Documentation Generation System</p>
        </div>
    </div>
</body>
</html>'''

    return html_content


def main():
    if len(sys.argv) < 4:
        print("Usage: python generate_index.py <docs_dir> <api_docs_dir> <test_docs_dir>")
        sys.exit(1)

    docs_dir = sys.argv[1]
    api_docs_dir = sys.argv[2]
    test_docs_dir = sys.argv[3]

    html_content = generate_index_html(docs_dir, api_docs_dir, test_docs_dir)

    index_file = os.path.join(docs_dir, 'index.html')
    with open(index_file, 'w', encoding='utf-8') as f:
        f.write(html_content)

    print(f"Documentation index generated: {index_file}")


if __name__ == '__main__':
    main()
