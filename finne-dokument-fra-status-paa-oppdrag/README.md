# Finne og tinglyse dokument fra `getStatusOppdrag`
Bakgrunnen for dette eksempelet er behovet for å finne `documentId` til et dokument 
slik at det kan tinglyses vha. SOAP API-et. Dette er aktuelt for f.eks. meglere
som har referanse til oppdraget, men ikke til det aktuelle dokumentet.

Skriptet henter status op oppdraget vha. `getStatisOppdrag`, finner en 
signert urådighet (sikring) og tinglyser denne.

* Finnes ikke en signert urådighet listes alle urådigheter på oppdraget.
* Finnes 2 eller flere signerte urådigher listes disse.
* Finne 1 urådighet tinglyses denne.