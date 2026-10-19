## Repon rakenne

| Polku | Kuvaus |
|---|---|
| `docker-compose.yaml` | Docker Compose -kokoonpano: web, proxy, notes-api ja database |
| `web/`, `proxy/`, `notes-api/`, `db/` | Palveluiden määritykset (Node.js/Express, nginx ja PostgreSQL) |
| `healthcheck/` | Pieni Python-komentorivityökalu HTTP-päätepisteiden tilan tarkistamiseen |
| `tests/` | `healthcheck`-paketin yksikkötestit (`pytest`), myös raja-arvotestit |
| `.github/workflows/ci.yml` | CI/CD-työnkulku |

## Paikallinen käyttö

```bash
python3 -m pip install -e ".[dev]"   # asentaa healthcheck-paketin ja kehitystyökalut
ruff check healthcheck tests         # koodin tarkistukset (sama komento kuin CI:n lint-tehtävässä)
pytest -v                            # yksikkötestit (sama komento kuin CI:n test-tehtävässä)
python3 -m build                     # rakentaa sdist- ja wheel-jakelut dist/-hakemistoon
```

Komentorivityökalun kokeilu (pelkkä jäsennystila ei vaadi verkkoyhteyttä):

```bash
healthcheck http://localhost:3000/health
healthcheck --check --retries 3 http://localhost:3000/health
```

## CI-putki

`.github/workflows/ci.yml` käynnistyy `push`- ja `pull_request`-tapahtumista.

| Tehtävä | Kuvaus | Riippuvuudet |
|---|---|---|
| `lint` | Tarkistaa `healthcheck/`- ja `tests/`-hakemistot komennolla `ruff check` | — |
| `test` | Suorittaa yksikkötestit komennolla `pytest -v`, myös raja-arvotestit | — |
| `package` | Rakentaa jakelupaketit komennolla `python -m build` ja tallentaa tiedostot `dist/*.whl` ja `dist/*.tar.gz` artefaktiksi nimellä `healthcheck-<sha>`. Artefakti säilytetään 14 päivää. | `lint`, `test` |
| `deploy` | Avaimeton käyttöönotto: OIDC-tunnistautuminen ja AWS:n IAM-roolin käyttö | `lint`, `test`, `package` |

`deploy` suoritetaan vain `v*`-tageihin liittyvissä ajoissa. Se käyttää GitHubin `production`-ympäristöä ja OIDC-tokenia IAM-roolin käyttöön. Pitkäaikaisia avaimia ei tallenneta. Roolin ARN luetaan tietovaraston `DEPLOY_ROLE_ARN`-muuttujasta.

## Dokumentoitu CI-virhe

1. **Virheen aiheuttanut commit:** `57dd037` ”hajooko” (muutettiin `healthcheck/core.py`-tiedostossa 500-tilakoodin luokitus arvosta `"down"` arvoon `"guh????"`).
2. **Epäonnistunut ajo:** [ajo #4](https://github.com/katuomin/docker-projekti/actions/runs/39035527857)
   - `Lint (ruff)` meni läpi, mutta `Test (pytest)` epäonnistui (exit code 1).
   - `Package`- ja `Deploy`-tehtävät ohitettiin (`needs: [lint, test]`), joten epäonnistuneesta ajosta ei syntynyt artefaktia.
   - Testin lokissa näkyi:
     ```
     >       assert classify_status(500) == "down"
     E       AssertionError: assert 'guh????' == 'down'
     ```
   - Lokista käyvät ilmi testin nimi, assert-lause sekä odotettu ja toteutunut arvo. Virheen sijainti löytyy ilman lisätarkistuksia.
3. **Korjaus:** `e6f485f` "sori korjasin". Putki meni jälleen läpi: [ajo #5](https://github.com/katuomin/docker-projekti/actions/runs/39035614272).

## Turvallisuus

## Tietoturva

- **Vähimmän oikeuden periaate:** työnkulku määrittää ylimmällä tasolla oikeudeksi `permissions: contents: read`. Vain `deploy` tarvitsee laajemmat oikeudet: sille annetaan lisäksi `id-token: write`.
- **Ei salaisuuksia tietovarastossa:** putki ei käytä `secrets`-muuttujia. GitHubin automaattisesti luoman `GITHUB_TOKEN`-tunnuksen oikeudet rajataan yllä mainitulla tavalla.
- **Ympäristöt:** `lint`-, `test`- ja `package`-tehtävät suoritetaan `ci`-ympäristössä ja `deploy`-tehtävä `production`-ympäristössä. Näin ympäristöjen suojauksia, kuten pakollisia hyväksyntöjä, voidaan ottaa käyttöön vaiheittain.
- **Avaimeton käyttöönotto OIDC:n avulla:** pitkäaikaisten AWS-avainten tallentamisen sijaan käyttöönotto pyytää lyhytikäisen OIDC-tokenin ja pyytää AWS:ltä väliaikaiset tunnistetiedot IAM-roolin käyttöä varten (`aws-actions/configure-aws-credentials`, `audience: sts.amazonaws.com`). Roolin luottamuskäytäntö sallii `token.actions.githubusercontent.com`-tunnisteen käytön tässä tietovarastossa. Väliaikaiset tunnistetiedot vanhenevat alle tunnissa.

## Kustannukset

- GitHub Actions on maksuton julkisissa tietovarastoissa, eikä niissä ole minuuttirajaa. Putki kestää alle kaksi minuuttia kutakin `push`-tapahtumaa kohti. Myös yksityisessä tietovarastossa se kuluttaa siis selvästi alle yhden prosentin 2 000 minuutin kuukausittaisesta maksuttomasta kiintiöstä.
- Rakennustuotannot ovat kooltaan muutamia kilotavuja, ja niitä säilytetään 14 päivää.
