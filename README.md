# Projekti: Docker kurssin yhteenveto

Tämä repository sisältää Docker Compose muistiinpanosovelluksen,
joka koostuu seuraavista:

| Kontin nimi | Tarkoitus |
|---|---|
| web-kontti | nginx-verkkopalvelin, jossa staattiset tiedostot (html, css jne) |
| proxy-kontti | nginx-proxy, joka proxyttää verkkopalvelimen ja apikontin liikenteen |
| api-kontti | Node.js api, joka käsittelee muistiinpanoja verkkosivun ja tietokannan välillä |
| database-kontti | PostgreSQL-tietokanta, muistiinpanot tallennettu tänne |

Esimerkki kuinka suorittaa tämä rakenne AWS-pilvessä, jonka ympäristö
on määritelty Terraformin avulla, katso [terraformlearnerlab/README.md](terraformlearnerlab/README.md).
