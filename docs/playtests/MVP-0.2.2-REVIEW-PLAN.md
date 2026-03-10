# MVP-0.2.2 Review Plan

Seuraavassa tarkastuksessa varmista erityisesti nämä:

1. **3/3 end-state ja restart**
   - Pelaajan voitto-/end-state 3/3 näyttää tarkoitukselliselta lopputilalta, ei crashilta tai soft lockilta.
   - Ruudulla on selkeä viesti siitä mitä tapahtui ja mitä pelaaja voi tehdä seuraavaksi.
   - Restart on näkyvä, ymmärrettävä ja toimii heti ilman epäselvää välivaihetta.
   - Testaa vähintään sekä näppäimistöllä että mahdollisella UI-painikkeella / ensisijaisella restart-polulla.

2. **Help / legend takaisin näkyviin**
   - Help/legendin voi avata uudelleen luotettavasti missä tahansa normaalissa pelitilassa.
   - Näppäin tai komento on ruudulla selkeästi kerrottu, eikä sitä tarvitse arvata.
   - Toistotesti: sulje ja avaa useita kertoja, varmista ettei tila jää jumiin tai katoa session aikana.

3. **Immortality-toggle on löydettävissä**
   - Immortality-toggle löytyy käytännössä ilman sisäpiiritietoa tai debugger-ajattelua.
   - Sijainti, nimeäminen ja näkyvyys ovat sellaiset, että testaaja osaa ottaa sen käyttöön nopeasti.
   - Varmista myös, että toggle antaa selkeän palautteen siitä onko se päällä vai pois päältä.

4. **Beam total range käyttää yhteistä budjettia bouncejen yli**
   - Beam ei saa “nollautua” bounceissa, vaan koko kuljettu matka vähentää samaa total range -budjettia.
   - Testaa usealla bounce-ketjulla ja eri kulmilla, jotta kokonaiskantama katkeaa odotetussa kohdassa.
   - Varmista, ettei yksittäinen bounce kasvata efektiivistä kantamaa yli määritellyn total range -arvon.

## Suositeltu tarkastusjärjestys
- Tarkista ensin näkyvimmät UX-korjaukset: end-state/restart, help/legend, immortality-toggle.
- Tarkista sen jälkeen beam range -käytös käytännön testiskenaarioilla.
- Kirjaa jokaisesta kohdasta lyhyesti: **OK / epäselvä / rikki**, sekä yksi konkreettinen havainto.