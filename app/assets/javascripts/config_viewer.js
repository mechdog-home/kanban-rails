// ============================================================================
// Config Viewer - Markdown Parser
// ============================================================================
//
// LEARNING NOTES:
//
// This is a simple markdown parser that converts markdown text to HTML.
// It runs in the browser (client-side) to render config files.
//
// COMPARISON TO RAILS:
// - Could use a Ruby gem like Redcarpet or CommonMarker server-side
// - But client-side is faster for simple files and reduces server load
// - Rails would use: raw Redcarpet::Markdown.new(renderer).render(text)
//
// ============================================================================

(function() {
  'use strict';
  
  /**
   * Parse markdown to HTML
   */
  function parseMarkdown(markdown) {
    if (!markdown) return '';
    
    let html = markdown
      // Escape HTML entities
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      
      // Headers
      .replace(/^###### (.+)$/gm, '<h6>$1</h6>')
      .replace(/^##### (.+)$/gm, '<h5>$1</h5>')
      .replace(/^#### (.+)$/gm, '<h4>$1</h4>')
      .replace(/^### (.+)$/gm, '<h3>$1</h3>')
      .replace(/^## (.+)$/gm, '<h2>$1</h2>')
      .replace(/^# (.+)$/gm, '<h1>$1</h1>')
      
      // Code blocks
      .replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
      
      // Inline code
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      
      // Bold and italic
      .replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      
      // Strikethrough
      .replace(/~~(.+?)~~/g, '<del>$1</del>')
      
      // Blockquotes
      .replace(/^&gt; (.+)$/gm, '<blockquote>$1</blockquote>')
      
      // Links
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank">$1</a>')
      
      // Horizontal rules
      .replace(/^---$/gm, '<hr>')
      .replace(/^\*\*\*$/gm, '<hr>');
    
    // Process lists
    html = processLists(html);
    
    // Wrap remaining lines in paragraphs
    html = wrapParagraphs(html);
    
    return html;
  }
  
  /**
   * Process unordered and ordered lists
   */
  function processLists(text) {
    const lines = text.split('\n');
    const result = [];
    let inList = false;
    let listType = null;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const unorderedMatch = line.match(/^(\s*)[-*] (.+)$/);
      const orderedMatch = line.match(/^(\s*)\d+\. (.+)$/);
      
      if (unorderedMatch) {
        if (!inList) {
          inList = true;
          listType = 'ul';
          result.push('<ul>');
        }
        result.push(`<li>${unorderedMatch[2]}</li>`);
      } else if (orderedMatch) {
        if (!inList) {
          inList = true;
          listType = 'ol';
          result.push('<ol>');
        }
        result.push(`<li>${orderedMatch[2]}</li>`);
      } else {
        if (inList) {
          inList = false;
          result.push(`</${listType}>`);
        }
        result.push(line);
      }
    }
    
    if (inList) {
      result.push(`</${listType}>`);
    }
    
    return result.join('\n');
  }
  
  /**
   * Wrap non-tag lines in paragraphs
   */
  function wrapParagraphs(text) {
    const lines = text.split('\n');
    const result = [];
    
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed && 
          !trimmed.match(/^<[\w/]/) && 
          !trimmed.startsWith('```') &&
          !trimmed.match(/^[-*] /) &&
          !trimmed.match(/^\d+\. /)) {
        result.push(`<p>${line}</p>`);
      } else {
        result.push(line);
      }
    }
    
    return result.join('\n');
  }
  
  // Export for use in views
  window.parseMarkdown = parseMarkdown;
})();
