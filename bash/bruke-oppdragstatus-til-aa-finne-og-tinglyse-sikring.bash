#!/bin/bash

# Dette scenarioet trenger id for oppdrag i tillegg til bruker og passord
oppdragId="<oppdrags id>"
bruker="<brukernavn>"
passord="<passord>"

# Dersom du vil teste dette scriptet uten å tinglyse, sett denne til false
enableTinglysing=true

# Enkle funksjoner

# Henter dokumentId fra en urådighet i fra "getStatusOppdrag" payload
# Arg. 1 xmlPayload - payload fra getStatusOppdrag
# Arg. 2 indexInPayload -- Indeksen til uraadigheten i xmlPayload(arg. 1)
function getDokumentId() {
    xmlPayload="$1"
    indexInPayload="$2"
    echo "$(echo $xmlPayload | xmllint --xpath "//documentStatus[type='URAADIGHET'][$indexInPayload]/status/id/text()" --format -)"
}

# Henter referanse fra en urådighet i fra "getStatusOppdrag" payload
# Arg. 1 xmlPayload - payload fra getStatusOppdrag
# Arg. 2 indexInPayload -- Indeksen til uraadigheten i xmlPayload(arg. 1)
function getReference() {
    xmlPayload="$1"
    indexInPayload="$2"
    echo "$(echo $xmlPayload | xmllint --xpath "//documentStatus[type='URAADIGHET'][$indexInPayload]/status/reference/text()" --format -)"
}

# Henter description fra en urådighet i fra "getStatusOppdrag" payload
# Arg. 1 xmlPayload - payload fra getStatusOppdrag
# Arg. 2 indexInPayload -- Indeksen til uraadigheten i xmlPayload(arg. 1)
function getDescription() {
    xmlPayload="$1"
    indexInPayload="$2"
    echo "$(echo $xmlPayload | xmllint --xpath "//documentStatus[type='URAADIGHET'][$indexInPayload]/status/description/text()" --format -)"
}

# Henter dokument status fra en urådighet i fra "getStatusOppdrag" payload
# Arg. 1 xmlPayload - payload fra getStatusOppdrag
# Arg. 2 indexInPayload -- Indeksen til uraadigheten i xmlPayload(arg. 1)
function getDokumentStatus() {
    xmlPayload="$1"
    indexInPayload="$2"
    echo "$(echo $xmlPayload | xmllint --xpath "//documentStatus[type='URAADIGHET'][$indexInPayload]/status/statusCode/text()" --format -)"
}

# Henter dokumentid for en urådighet som har stastus signerg ifra "getStatusOppdrag" payload
# Arg. 1 xmlPayload - payload fra getStatusOppdrag
# Arg. 2 indexInPayload -- Indeksen til uraadigheten i xmlPayload(arg. 1)
function getDokumentIdForSignertUraadighet() {
    xmlPayload="$1"
    indexInPayload="$2"
    echo "$(echo $xmlPayload | xmllint --xpath "//documentStatus[type='URAADIGHET']/status[statusCode = 'SIGNERT']/id/text()" --format -)"
}

# Henter følgende streng for urådighet: id: 123456, reference: "uraadighet referanse", description: "Ur&#xE5;dighet - 1234/123/12// [G]"
# Arg. 1 xmlPayload - payload fra getStatusOppdrag
# Arg. 2 indexInPayload -- Indeksen til uraadigheten i xmlPayload(arg. 1)
function printIdReferenceDescriptionAndDocumentStatus() {
    xmlPayload="$1"
    indexInPayload="$2"
    echo "id: $(getDokumentId "$xmlPayload" $indexInPayload), reference: \"$(getReference "$xmlPayload" $indexInPayload)\", dokumentStatus: \"$(getDokumentStatus "$xmlPayload" $indexInPayload)\",description: \"$(getDescription "$xmlPayload" $indexInPayload)\""
}


echo "Kaller getStatusOppdrag ..."
# Henter status fra oppdrag. Bruker oppdragId, user og passord for å hente xml payload fra webservice
xmlResultatFraGetStatusOppdrag=`curl --location --request POST 'https://beta.etinglysing.no/ws/v7/dokument' \
--header "Authorization: Basic $(echo -n $bruker:$passord | base64)" \
--header 'Content-Type: application/xml' \
--data-raw "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:dok=\"http://dokument.ws7.etinglysing.no/\">
   <soapenv:Header/>
   <soapenv:Body>
      <dok:getStatusOppdrag>
         <oppdragId>$oppdragId</oppdragId>
      </dok:getStatusOppdrag>
   </soapenv:Body>
</soapenv:Envelope>"`


# Dette scriptet skal bare virker dersom det kun finnes en uraadighet som er SIGNERT i et oppdrag.
antallSignertUraadigheterIOppdraget=$(echo $xmlResultatFraGetStatusOppdrag | xmllint --xpath "count(//documentStatus[type='URAADIGHET']/status[statusCode = 'SIGNERT'])" --format -)

# Sjekker at det bare finnes en signert sikring(urådighet) i oppdraget
# Dersom det ikke er tilfelle, listes alle urådigheter ut med status.
if ((antallSignertUraadigheterIOppdraget != 1)); then
  printf '%s\n' "Feil, det må være 1 URAADIGHET med status SIGNERT i oppdraget, fant $antallSignertUraadigheterIOppdraget" >&2
  if ((antallSignertUraadigheterIOppdraget > 1)); then
    echo "Fant flere enn 1 PART_SIGNERT uraadighet:"
    
    echo "Alle signert urådigheter i oppdraget med dokument status:"
    echo "---------------------------------------------------------"

    for (( index=1;index<=antallSignertUraadigheterIOppdraget;index++ ))
    do
      printIdReferenceDescriptionAndDocumentStatus "$xmlResultatFraGetStatusOppdrag" $index
    done
  else
    
    echo "Alle urådigheter i oppdraget med dokument status:"
    echo "-------------------------------------------------"
    antallUraadigheterIOppdraget=$(echo $xmlResultatFraGetStatusOppdrag | xmllint --xpath "count(//documentStatus[type='URAADIGHET'])" --format -)
    for (( uroIndex=1;uroIndex<=antallUraadigheterIOppdraget;uroIndex++ ))
    do
      printIdReferenceDescriptionAndDocumentStatus "$xmlResultatFraGetStatusOppdrag" $uroIndex
    done

  fi
  exit 1
fi


# Finner dokumentId fr 
dokumentIdForSignertUraadighet=$(getDokumentIdForSignertUraadighet "$xmlResultatFraGetStatusOppdrag" "1")
echo $dokumentIdForSignertUraadighet
  

if $enableTinglysing ; then
    ##Tinglyser ....
    echo "Tinglyser - dette tar litt tid"
    echo "------------------------------"
    
    resultatTinglysing=$(curl --location --request POST 'https://beta.etinglysing.no/ws/v7/dokument' \
    --header "Authorization: Basic $(echo -n $bruker:$passord | base64)" \
    --header 'Content-Type: application/xml' \
    --data-raw "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:dok=\"http://dokument.ws7.etinglysing.no/\">
       <soapenv:Header/>
       <soapenv:Body>
          <dok:tinglys>
            <documentId>$dokumentIdForSignertUraadighet</documentId>
          </dok:tinglys>
       </soapenv:Body>
    </soapenv:Envelope>")

    echo "Tinglysing payload:"
    echo "-------------------"
    echo $resultatTinglysing |
        xmllint --format -
fi

#Henter status fra oppdrag. Bruker oppdragId, user og passord for å hente xml payload fra webservice
statusForDokument=$(curl --location --request POST 'https://beta.etinglysing.no/ws/v7/dokument' \
--header "Authorization: Basic $(echo -n $bruker:$passord | base64)" \
--header 'Content-Type: application/xml' \
--data-raw "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:dok=\"http://dokument.ws7.etinglysing.no/\">
   <soapenv:Header/>
   <soapenv:Body>
      <dok:getStatus>
         <documentId>$dokumentIdForSignertUraadighet</documentId>
      </dok:getStatus>
   </soapenv:Body>
</soapenv:Envelope>")

echo "Get status payload:"
echo "-------------------"
echo $statusForDokument |
    xmllint --format -
