# PLAYTEST 02 — Review Focus (v0.2.0 sanity pass)

Tämän reviewn tarkoitus on varmistaa, että Playtest 01:n palautteesta johdetut v0.2.0-muutokset oikeasti korjasivat olennaiset kitkakohdat ilman uusia regressioita.

## 1) Mitä reviewn pitää erityisesti varmistaa

### A. Beam tuntuu nyt välähdykseltä eikä pitkältä viivalta
- Refraction Beam näkyy lyhyenä, luettavana pulssina.
- Laukaus ei jää ruudulle liian pitkäksi aikaa eikä näytä jatkuvalta laserilta.
- Osuma-, bounce- ja endpoint-readability säilyvät vaikka pulssi on lyhyt.

### B. Prism Node ei katkaise bounce-logiikkaa
- Säde voi edelleen kimpoilla seinistä Prism Node -redirectin jälkeen.
- Redirect toimii eri kulmista, ei vain yhdessä "golden path" -asetelmassa.
- Ei synny tilanteita, joissa node syö säteen, tuottaa väärän segmentin tai lopettaa simulaation liian aikaisin.

### C. Testaamisen kitka on pienempi
- Immortality/dev-toggle toimii varmasti ja on helposti käytettävä.
- Se ei riko encounter-loopia, reward-valintaa tai restartia.
- Muut dev controls tukevat sanity-passia eivätkä sotke normaalia pelisilmukkaa.

### D. Valaistus/lit-zone-pass parantaa luettavuutta oikeasti
- Pelaaja, beam, prism node, enemyt ja arena erottuvat heti.
- Lit zones tukevat lukemista eivätkä peitä vaaroja, osumapisteitä tai HUD:ia.
- Muutos tuo enemmän "tässä tapahtuu jotain valolla" -fiilistä, vaikka gameplay-vaikutus on vielä kevyt.

### E. Core loop pysyy ehjänä muutosten jälkeen
- Encounter -> reward -> next encounter -> restart toimii ilman softlockeja.
- Reward-ohjaus on edelleen johdonmukainen näppäimistöllä ja hiirellä.
- v0.2.0 tuntuu kokonaisuutena vakaammalta, ei vain näyttävämmältä.

## 2) Mitkä havainnot ovat blocker / non-blocker ennen seuraavaa milestonea

## Blocker
- Beam näyttää edelleen pitkäkestoiselta eikä korjaa alkuperäistä palautetta.
- Prism redirect rikkoo wall bounce -jatkumon tai toimii epäluotettavasti useista kulmista.
- Immortality/debug toggle ei toimi luotettavasti tai aiheuttaa regressioita testisilmukkaan.
- Reward-paneli, encounter progression tai restart-loop voi jäädä jumiin.
- Valaistus heikentää gameplay-readabilityä (esim. beam endpointit, viholliset tai vaarat hukkuvat).
- Export-buildissä näkyy eri käytös kuin editor-runissa kriittisissä core loop -asioissa.

## Non-blocker
- Valaistus ei vielä luo suurta "wow"-efektiä, kunhan readability paranee.
- Light fantasy tuntuu vielä enemmän esitykseltä kuin systeemiltä.
- Beamin tai enemy pacingin hienosäätö kaipaa lisää tuningia, mutta core toimii.
- HUD/debug-tekstissä on vielä pientä siistimistarvetta.
- Prism preview/readability voisi olla selkeämpi, vaikka mekaaninen toiminta on jo oikein.

## 3) Artefaktit ja tiedostot, jotka pitää tarkistaa

## Ensisijaiset runtime-tiedostot
- `scenes/run_scene.tscn`
- `scripts/run_scene.gd`
- `scenes/main.tscn`
- `scripts/main.gd`
- `project.godot`

## Reviewn tukidokumentit
- `docs/playtests/2026-03-09-playtest-01.md`
- `docs/devlog.md`
- `docs/run-controls.md`
- `docs/milestones.md`
- `docs/mvp0-scope.md`

## Tarkistettavat build-artefaktit
- `build/windows/lantern_engine-windows-v0.2.0.zip`
- `build/linux/lantern_engine-linux-v0.2.0.tar.gz`
- tarvittaessa myös exporttien puretut binäärit/pck:t:
  - `build/windows/lantern_engine.exe`
  - `build/windows/lantern_engine.pck`
  - `build/linux/lantern_engine.x86_64`
  - `build/linux/lantern_engine.pck`

## Suositeltu tarkistusjärjestys
1. `docs/playtests/2026-03-09-playtest-01.md` -> mitä piti korjata
2. `docs/devlog.md` -> mitä v0.2.0:ssa väitetään tehdyksi
3. `scripts/run_scene.gd` -> toteutuuko korjauslogiikka oikeasti
4. `docs/run-controls.md` -> vastaavatko ohjeet nykyistä buildiä
5. Windows- ja Linux-buildit -> näkyykö sama käytös paketoiduissa artefakteissa
