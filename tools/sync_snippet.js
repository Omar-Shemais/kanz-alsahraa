const fs = require('fs');
let snippet = fs.readFileSync('wordpress/snippets/kanz-app-control-snippet.php', 'utf8');
let adminJs = fs.readFileSync('wordpress/kanz-app-control/admin.js', 'utf8');

const startMarker = "function kanz_snippet_admin_js() {\n    return <<<'KANZ_CONTROL_EDITOR_JS'\n";
const endMarker = "\nKANZ_CONTROL_EDITOR_JS;\n}";

const wrappedJs = "(() => {\n  const start = () => {\n" + adminJs + "\n  };\n  if (document.readyState === 'loading') {\n    document.addEventListener('DOMContentLoaded', start, { once: true });\n  } else { start(); }\n})();";

const startIndex = snippet.indexOf(startMarker);
const endIndex = snippet.indexOf(endMarker);

if (startIndex === -1 || endIndex === -1) {
  console.error('Markers not found!');
  process.exit(1);
}

snippet = snippet.substring(0, startIndex + startMarker.length) + wrappedJs + snippet.substring(endIndex);

snippet = snippet.replace(
  "'parent' => (int) $term->parent,\n                );",
  "'parent' => (int) $term->parent,\n                    'count' => (int) $term->count,\n                );"
);

fs.writeFileSync('wordpress/snippets/kanz-app-control-snippet.php', snippet, 'utf8');
console.log('Successfully updated kanz-app-control-snippet.php');
