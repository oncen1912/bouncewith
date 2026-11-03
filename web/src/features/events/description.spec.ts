import { describe, expect, it } from 'vitest'
import { htmlToText, sanitizeHtml, textToHtml } from './description'

describe('event descriptions', () => {
  it('turns plain text into paragraphs, escaping HTML', () => {
    expect(textToHtml('Bring water.\n\nShoes <b>indoor</b>\nonly')).toBe(
      '<p>Bring water.</p><p>Shoes &lt;b&gt;indoor&lt;/b&gt;<br>only</p>',
    )
  })

  it('round-trips through the editor', () => {
    const text = 'Line one\nLine two\n\nSecond paragraph'
    expect(htmlToText(textToHtml(text))).toBe(text)
  })

  it('removes scripts, handlers and unknown tags', () => {
    const dirty =
      '<p onclick="x()">Hi<script>alert(1)</script><img src=x onerror=alert(1)></p><iframe></iframe>'
    expect(sanitizeHtml(dirty)).toBe('<p>Hi</p>')
  })

  it('keeps links but forces a safe target', () => {
    expect(sanitizeHtml('<a href="https://bouncewith.me">site</a>')).toBe(
      '<a target="_blank" rel="noopener noreferrer" href="https://bouncewith.me">site</a>',
    )
    expect(sanitizeHtml('<a href="javascript:alert(1)">x</a>')).not.toContain('javascript')
  })
})
