/** Suggests a workspace slug from its name: "Niko Dance School" → "niko-dance-school". */
export function slugify(name: string): string {
  return name
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/ß/g, 'ss')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40)
    .replace(/-+$/, '')
}

export const SLUG_PATTERN = '^[a-z0-9][a-z0-9\\-]{2,39}$'
