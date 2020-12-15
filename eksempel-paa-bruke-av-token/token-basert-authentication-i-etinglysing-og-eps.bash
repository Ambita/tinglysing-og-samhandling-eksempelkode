#!/bin/bash

client_id="<client_id>"
client_secret="<client_secret>"
username="<username>"

# Skaffe to token. Setter BEARER_AND_ACCESS_TOKEN til "Bearer <token fra Ambita auth tjeneste>"
# Dette eksempelet at vi benytte truster flow. Må endres ihht. hvordan client er konfigurert
BEARER_AND_ACCESS_TOKEN="Bearer "$(curl --location --request POST 'https://beta-api.ambita.com/authentication/v2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-raw "client_id=$client_id&client_secret=$client_secret&grant_type=trusted&username=$username" |jq -r '.access_token')

# Eksempel med henting at status for et dokument fra etinglysing vha. bearer token
curl --location --request POST 'https://beta.etinglysing.no/ws/v7/dokument' \
--header 'Content-Type: text/xml' \
--header "Authorization: ${BEARER_AND_ACCESS_TOKEN}" \
--data-raw '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dok="http://dokument.ws7.etinglysing.no/">
   <soapenv:Header/>
   <soapenv:Body>
      <dok:getStatus>
         <documentId>15755120</documentId>
      </dok:getStatus>
   </soapenv:Body>
</soapenv:Envelope>'

# Eksempelet henter data for et settlement fra eps med samme token som vi brukte over.
# Henter oppgjør fra eps
curl --location --request GET 'https://beta-api.ambita.com/eps/v1/settlements/SET-1ae9060c-f6b7-4a72-a5e3-afed6b6f2e30' \
--header 'Content-Type: application/json' \
--header "Authorization: ${BEARER_AND_ACCESS_TOKEN}"



