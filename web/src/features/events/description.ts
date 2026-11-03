import DOMPurify from 'dompurify'

// Event descriptions are stored as sanitised HTML (CLAUDE.md rule 10). The form edits plain text;
// imported events (API, website bridge) may carry richer HTML, which is sanitised again before rendering.

const ALLOWED = {
  ALLOWED_TAGS: ['p', 'br', 'strong', 'b', 'em', 'i', 'u', 'a', 'ul', 'ol', 'li', 'h3', 'h4', 'blockquote'],
  ALLOWED_ATTR: ['href', 'target', 'rel'],
}

export function sanitizeHtml(html: string): string {
  const clean = DOMPurify.sanitize(html, ALLOWED)
  // links open safely in a new tab
  return clean.replace(/<a /g, '<a target="_blank" rel="noopener noreferrer" ')
}

const escape = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

/** Plain text from the form → paragraphs of HTML. */
export function textToHtml(text: string): string {
  const paragraphs = text
    .trim()
    .split(/\n{2,}/)
    .map((p) => p.trim())
    .filter(Boolean)
  return sanitizeHtml(paragraphs.map((p) => `<p>${escape(p).replace(/\n/g, '<br>')}</p>`).join(''))
}

/** Stored HTML → plain text for editing. */
export function htmlToText(html: string): string {
  const withBreaks = html.replace(/<br\s*\/?>/gi, '\n').replace(/<\/(p|li|h3|h4|blockquote)>/gi, '\n\n')
  const doc = new DOMParser().parseFromString(withBreaks, 'text/html')
  return (doc.body.textContent ?? '').replace(/\n{3,}/g, '\n\n').trim()
}
