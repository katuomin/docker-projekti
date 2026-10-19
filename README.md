# Projekti: Docker kurssin yhteenveto

Tämä repository sisältää Docker Compose muistiinpanosovelluksen,
joka koostuu seuraavista:

| Kontin nimi | Tarkoitus |
|---|---|
| web-kontti | nginx-verkkopalvelin, jossa staattiset tiedostot (html, css jne) |
| proxy-kontti | nginx-proxy, joka proxyttää verkkopalvelimen ja apikontin liikenteen |
| api-kontti | Node.js api, joka käsittelee muistiinpanoja verkkosivun ja tietokannan välillä |
| database-kontti | PostgreSQL-tietokanta, muistiinpanot tallennettu tänne |

Sovelluksen luonti:

Docker lukee compose.yaml-tiedostoa, jonka pohjalta se lähtee luomaan kontteja ja verkkoja. Kontit luodaan järjestyksessä paitsi healthcheck testejä odottavat kontit notes-api-kontti ja proxy-kontti. Tällä varmistetaan, että muista konteista riippuvaiset osat eivät lähde käynnistymään ennen kuin ne ovat valmiina. Kaikki liikenne käyttäjiltä ohjataan proxyn lävitse (nginx-alpine).

Ympäristö käyttää kahta verkkoa frontend-network ja backend-network. Taustalla toimivat kontti database on pelkästään sisäisessä backend-network verkossa. Pelkästään frontend-network verkossa on web ja proxy kontit ja verkkojen välistä kommunikointia hoitaa notes-api, joka on molemmissa verkoissa.

Kuinka luot ympäristön itsellesi:

Esivaatimukset:
    -Docker isäntäkoneella

Kopio repositorio https://github.com/katuomin/docker-projekti.git tyhjään kansioon.

Mene kansion sisälle esimerkiksi WSL:ää käyttäen ja rakenna ympäristö komennolla "docker compose up -d --build --force-recreate".

Ympäristö lähtee pyörimään localhost:80 portissa.

Ympäristön voi sammuttaa komennolla "docker compose down"

Healtchecks

Tarkistaa Notes-api ja database-konttien päätepisteiden(endpoints) toimivuuden ympäristöä luodessa. Tarkemmat ohjeet manuaalisten tarkistusten ajamiseen ACTIONS.md tiedostossa.

Volumes

Isäntäkoneella ollut tiedostopolku liitetään kontin sisälle Bind-mounttia käyttäen. Kontti ajonaikana tallentaa muistiinpanoja dockerin sisäisesti volyymille pgdata, jotta ymäristön ajonaikana tallennetut muistiinpanot säilyvät myös ympäristön uudelleen käynnistymisen jälkeen.

versio 2 ai muokkas tota ekaa :D

Isäntäkoneen tiedosto ./proxy/nginx.conf liitetään kontin sisälle bind mountilla (/etc/nginx/conf.d/default.conf), jolloin hostilla tehdyt muutokset näkyvät kontissa heti.
PostgreSQL taas tallentaa datan Dockerin hallitsemaan nimettyyn volyymiin pgdata (/var/lib/postgresql/data), joten muistiinpanot säilyvät konttien uudelleenkäynnistyksissä ja uudelleenluonnissa.
Huom: data poistuu vain, jos volyymi poistetaan erikseen (esim. docker compose down -v).

Esimerkki kuinka suorittaa tämä rakenne AWS-pilvessä, jonka ympäristö
on määritelty Terraformin avulla, katso [terraformlearnerlab/README.md](terraformlearnerlab/README.md).
