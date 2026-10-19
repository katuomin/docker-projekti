# Projekti: Docker kurssin yhteenveto

Tämä repository sisältää Docker Composella rakennettavan sivuston, jossa käydään läpi ja kerrotaan kurssin aikana käytettyjä Dockeriin liittyviä tekniikoita. Sivusto sisältää myös muistiinpanosovelluksen.
Sivusto koostuu seuraavista konteista:

| Kontin nimi | Tarkoitus |
|---|---|
| web-kontti | nginx-verkkopalvelin, jossa staattiset tiedostot (html, css jne) |
| proxy-kontti | nginx-proxy, joka proxyttää verkkopalvelimen ja apikontin liikenteen |
| api-kontti | Node.js api (notes-api), joka käsittelee muistiinpanoja verkkosivun ja tietokannan välillä |
| database-kontti | PostgreSQL-tietokanta, muistiinpanot tallennettu tänne |

## Ympäristön rakenne:


Docker lukee docker-compose.yaml-tiedoston ja käynnistää palvelut riippuvuuksien mukaan.
Proxy palvelu käynnistyy vasta, kun web palvelu on toimintakunnossa, ja notes-api palvelu käynnistyy vasta, kun database on toimintakunnossa (depends_on: condition: service_healthy).
Muut kontit ja niiden palvelut käynnistetään rinnakkain heti alussa. 
Ulkoinen HTTP-liikenne tulee proxy-kontin kautta portista 80 (nginx-alpine)

### Alla ohjeet ympäristön luomiseen:

Esivaatimukset:
- Docker isäntäkoneella
- Git



Kloonaa repo:

   git clone https://github.com/katuomin/docker-projekti.git

Mene kansion sisälle esimerkiksi WSL:ää käyttäen

    cd docker-projekti

Rakenna ympäristö komennolla

    docker compose up

Ympäristö lähtee pyörimään selaimella localhost:80 portissa.

Ympäristön voi kokeilun jälkeen tuhota komennolla

    docker compose down


## Verkot


Ympäristö käyttää kahta Docker-verkkoa:

- `frontend-network`: `web`, `proxy` ja `notes-api`
- `backend-network` (internal): `notes-api` ja `database`

Ympäristö käyttää kahta verkkoa: frontend-network ja backend-network. Taustalla toimiva database-kontti on pelkästään sisäisessä backend-network verkossa. Pelkästään frontend-network verkossa on web- ja proxy-kontit. Verkkojen välistä kommunikointia hoitaa api-kontti, joka on molemmissa verkoissa.





## Healthchecks

Tarkistaa Notes-api-, web- ja database-konttien päätepisteiden(endpoints) toimivuuden ympäristöä luodessa. Tarkemmat ohjeet manuaalisten tarkistusten ajamiseen ACTIONS.md tiedostossa.

## Volumes


Isäntäkoneen tiedosto ./proxy/nginx.conf liitetään kontin sisälle bind mountilla (/etc/nginx/conf.d/default.conf:ro), jolloin hostilla tehdyt muutokset näkyvät kontissa heti (":ro" tekee nginx-konfiguraation kontissa vain luku -tilaan, joten proxy ei voi muokata projektin tiedostoa).
PostgreSQL taas tallentaa datan Dockerin hallitsemaan nimettyyn volyymiin pgdata (/var/lib/postgresql/data), joten muistiinpanot säilyvät konttien uudelleenkäynnistyksissä ja uudelleenluonnissa.
Huom: data poistuu vain, jos volyymi poistetaan erikseen (esim. docker compose down -v).

Esimerkki kuinka suorittaa tämä rakenne AWS-pilvessä, jonka ympäristö
on määritelty Terraformin avulla, katso [terraformlearnerlab/README.md](terraformlearnerlab/README.md).
