import { describe, expect, it } from 'vitest'
import { cardImage } from '../../app/utils/cardImage'

describe('cardImage', () => {
  const base = 'https://assets.tcgdex.net/en/swsh/swsh3/136'
  it('defaults to high quality webp', () => {
    expect(cardImage(base)).toBe(`${base}/high.webp`)
  })
  it('supports low quality', () => {
    expect(cardImage(base, 'low')).toBe(`${base}/low.webp`)
  })
})
