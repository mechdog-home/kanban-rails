# ============================================================================
# Importmap Configuration
# ============================================================================
#
# LEARNING NOTES:
#
# Importmap is Rails' way of managing JavaScript dependencies WITHOUT
# a bundler like Webpack or esbuild. It maps package names to URLs.
#
# HOW IT WORKS:
# - `pin "name"` maps a JS module name to a file or CDN URL
# - `pin_all_from` maps a directory of files to module names
# - In the browser, `import X from "name"` resolves via the import map
# - No node_modules, no npm install, no build step!
#
# COMPARISON TO NODE.JS:
# - Node: npm install sortablejs → require('sortablejs')
# - Rails: pin "sortablejs" → import Sortable from "sortablejs"
# - Same result, but Rails uses the browser's native import maps
#
# TO ADD A PACKAGE:
# - Run: ./bin/importmap pin <package-name>
# - Or manually add a pin line with a CDN URL
# - Check https://generator.jspm.io/ for ESM-compatible CDN URLs
#
# ============================================================================

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Sortable.js — drag-and-drop library for our Kanban board
# We use the ESM (ES Module) version so it works with importmap
# The "modular/sortable.esm.js" path gives us a proper ES module export
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/modular/sortable.esm.js"
