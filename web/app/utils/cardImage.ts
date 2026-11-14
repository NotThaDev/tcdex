export type CardImageQuality = 'low' | 'high'

/** Builds the TCGdex image URL from the card's base `image` field. */
export function cardImage(base: string, quality: CardImageQuality = 'high'): string {
  return `${base}/${quality}.webp`
}
