## Repon rakenne

| Polku | Mikä |
|---|---|
| `docker-compose.yaml` | Stack: web, proxy, notes-api, database |
| `web/`, `proxy/`, `notes-api/`, `db/` | Palvelumääritykset (Node/Express + nginx + Postgres) |
| `healthcheck/` | Pieni Python-CLI (paketti) HTTP-päätteiden tilan tarkistukseen |
| `tests/` | `healthcheck`-yksikkötestit (pytest), sisält. raja-arvotestit |
| `.github/workflows/ci.yml` | CI/CD-putki |

## Ajo-ohjeet paikallisesti

```bash
python3 -m pip install -e ".[dev]"   # asettaa healthcheck + ruff, pytest, build
ruff check healthcheck tests         # lint (sama kuin CI:n lint-job)
pytest -v                            # yksikkötestit (sama kuin CI:n test-job)
python3 -m build                     # pakkauksen sdist + wheel -> dist/
```

CLI:n kokeilu (parse-only -tila ei vaadi verkkoa):

```bash
healthcheck http://localhost:3000/health
healthcheck --check --retries 3 http://localhost:3000/health
```

## CI-putki

`.github/workflows/ci.yml` käynnistyy `push`- ja `pull_request`-triggereillä.

| Job | Tehtävä | Riippuu |
|---|---|---|
| `lint` | `ruff check` -tarkistus `healthcheck/` ja `tests/` | — |
| `test` | `pytest -v` (yksikkötestit, myöskin raja-arvotestit) | — |
| `package` | `python -m build`, ladataan `dist/*.whl` + `dist/*.tar.gz` artefaktina nimellä `healthcheck-<sha>` (säilytys 14 pv) | lint, test |
| `deploy` | Avaineton OIDC-deploy (AWS IAM roolin ottaminen) | lint, test, package |

`deploy` ajetaan vain `v*`-tagien päällä. Se käyttää GitHub-ympäristöä
(`production`) ja OIDC-tokenia ottamaan IAM-roolin — ei long-lived -avaimia
missään. Rolin ARN luetaan repon muuttujasta `DEPLOY_ROLE_ARN`.

## Turvallisuus

- **Least privilege:** workflow määrittelee `permissions: contents: read` ylimmän
  tasolla. Ainoa komento, joka tarvitsee enemmän, on `deploy`, joka lisää
  `id-token: write` vain itselleen.
- **Ei salaisuksia repossa:** putki ei käytä yhtään `secrets`-muuttujaa. Ainoa
  luottamusarvo on GitHubin `GITHUB_TOKEN`, rajoitettu yllä oleviin oikeuksiin.
- **Environments:** lint/test/package ajetaan `ci`-ympäristössä ja deploy
  `production`-ympäristössä, jotta suojailusääntöjä (esim. pakolliset
  approvaarit) voi kiinnittää vaiheittain.
- **Avaimetonta (OIDC) deploy-suunnitelma:** sen sijaan, että tallennettaisiin
  long-lived -AWS-avaimet, deploy-job esittää lyhytaikaisen OIDC-tokenin ja
  ottaa IAM-roolin (`aws-actions/configure-aws-credentials`,
  `audience: sts.amazonaws.com`). Rolin trust policy sallii
  `token.actions.githubusercontent.com` tälle repon, ja otetut todistuskirjat
  vanhentuvat alle tunnin kuluessa.

## Kustannus

- GitHub Actions on ilmainen julkisille repoille (epärajoitettu minuuttimäärä).
  Putki ajaa alle 2 minuutissa push kohden, joten myös yksityisellä repolla
  (2 000 ilmaista minuuttia/kk) se vie hyvin alle 1 % kvotasta.
- Artefaktit ovat muutamia kilotavua per build ja säilytetään 14 päivää.
