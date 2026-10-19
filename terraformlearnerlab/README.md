# Terraform AWS Academy Learner Labissa

## Mitä eroja täysillä oikeuksilla tehtyihin ympäristöihin ?

| Learner Lab -rajoite | Ratkaisu tässä versiossa |
|---|---|
| IAM-rooleja / instance profiileja ei voi luoda | Liittää valmiin `LabInstanceProfile`-profiilin (valinnainen) |
| VPC:n/aliverkkojen/yhdyskäytävien luonti on usein rajoitettu | Käyttää oletus-VPC:tä; AWS valitsee aliverkon saatavilla olevasta AZ:sta instanssityypin mukaan |
| Vain `us-east-1` / `us-west-2` käytettävissä | Oletusalue `us-east-1` |
| Vain pieniä instanssityyppejä | Oletuksena `t3.small` |
| Tunnukset vanhenevat sessioiden mukana | Käyttää labran väliaikaisia avaimia |
| Session Manager ei välttämättä toimi | SSH portissa 22 labran `vockey`-avaimella |

## Vaiheet

1. Käynnistä labra ja avaa **AWS Details → Show**.
2. Kopioi kohdasta **AWS CLI** nämä kolme arvoa:
   - `AWS_ACCESS_KEY_ID` (alkaa usein `ASIA...`)
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
3. Aseta arvot samaan terminaaliin, jossa ajat `terraform`-komennot:

   WSL/bash:
   ```bash
   export AWS_ACCESS_KEY_ID="ASIA..."
   export AWS_SECRET_ACCESS_KEY="..."
   export AWS_SESSION_TOKEN="..."
   export AWS_REGION="us-east-1"
   ```

   Vaihtoehtoisesti voit lisätä arvot tiedostoon `~/.aws/credentials`
   profiilin `[default]` alle:
   ```ini
   [default]
   aws_access_key_id=ASIA...
   aws_secret_access_key=...
   aws_session_token=...
   ```

4. Tarkista tunnukset:
   ```bash
   aws sts get-caller-identity
   ```

5. Ota ympäristö käyttöön:

    terraform init
    terraform apply

6.  Avaa web_url-output muutaman minuutin kuluttua (ensimmäisellä käynnistyksellä
    Docker asennetaan ja imaget rakennetaan).

Muuttujia ei vaadita. Repositorion URL osoittaa oletuksena tähän repositoryyn,
joten sen pitää olla julkinen ja haaran pitää olla olemassa (main oletuksena).


Vianmääritys
    Credential-virheet / ExpiredToken: labrasessio päättyi tai avaimet vaihtuivat.
    Kopioi uudet arvot ja vie ne uudelleen ympäristömuuttujiin. Vältä vanhentuneita
    merkintöjä tiedostossa ~/.aws/credentials.

    Instance profile tai key pair puuttuu: käytä
    -var instance_profile_name="" tai -var key_name="".

    Tarkista käynnistyksen eteneminen SSH:n kautta:
    sudo tail -f /var/log/user-data.log ja
    cd /opt/docker-projekti && sudo docker compose ps.

    Rajoita pääsyä: -var allowed_cidr="<oma-ip>/32".


Siivous


Aja "terraform destroy" komento ennen labran päättämistä. Jos labra nollautuu, state-tiedosto
voi viitata resursseihin, joita ei enää ole. Poista paikalliset
terraform.tfstate*-tiedostot ja aloita uudelleen.
