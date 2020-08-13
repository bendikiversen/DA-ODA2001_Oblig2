#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <sqlite3.h>

//Global variabel
int a = 0;

struct brukerkonto {
  char brukernavn[100];
  char fornavn   [250]; // alle navn bortsett fra etternavn
  char etternavn [100]; // det siste navnet
};

typedef struct brukerkonto konto_t;

int les_data   (konto_t *brukertabell);
void skriv_data (konto_t *brukertabell);

int main(int argc, char *argv[]) {
  
  //Hent miljøvariablen OBLIG
  char *env = getenv("OBLIG");

  //Sjekk kommandolinje-argument
  if(argc==2){
    if(argv[1][0] == 'b' || argv[1][0] == 'B')
      a = 2;
    else if(argv[1][0] == 'f' || argv[1][0] == 'F')
      a = 1;
  }

  //Sjekk miljøvariabel
  else if(env != NULL){
    if(env[0] == 'b' || env[0] == 'B')
      a = 2;
    else if(env[0] == 'f' || env[0] == 'F')
      a = 1;
  }

  konto_t brukertabell[200];
  les_data   (brukertabell);
  skriv_data (brukertabell);

  return 0;
}


int les_data   (konto_t *brukertabell)
{
  sqlite3 *db;
  sqlite3_stmt *data;
  const char *hale;

  int linje = 0;

  if(sqlite3_open("passwd.db", &db))
  {
    sqlite3_close(db);
    printf("Klarte ikke å åpne databasen: %s\n", sqlite3_errmsg(db));
    return 1;
  }

  //Klargjør og send spørring til DBMS
  if(sqlite3_prepare_v2(db, "SELECT brukernavn, navn FROM Bruker WHERE uid>=1000", 256, &data, &hale) != SQLITE_OK)
  {
    sqlite3_close(db);
    printf("Kunne ikke hente data: %s\n", sqlite3_errmsg(db));
    return(1);
  }


  while(sqlite3_step(data) == SQLITE_ROW)
  {
    char* fullnavn = NULL;                //Fullt navn
    fullnavn = sqlite3_column_text(data,1);
    
    if(fullnavn[0] != '\0')
    {
      fullnavn = strtok(fullnavn,",");     //Ta kun med "full name"
  
      int lengde = strlen(fullnavn);        //Hent lengden til fullnavn
      char fornavn[lengde];                 //Opprett en char-array med lengden til fullnavn
      strcpy(fornavn,fullnavn);             //Kopier fullnavn til fornavn
      char etternavn[100] = "";             //Opprett en char-array etternavn med lengden 100 og "tomt" innhold
      char* peker = strrchr(fornavn, ' ');  //Bruk strrchr til å gå til siste mellomrom i fornavn (til etternavnet...)
  
      if(peker != NULL)                     //strrchr returnerer NULL dersom den ikke fant noen mellomrom
      {
        int indeks = peker-fornavn+1;       //Indeksen til første tegn etter mellomrom
        int i;
  
        for(i=indeks; i<lengde; i++)
          etternavn[i-indeks] = fornavn[i];
        fornavn[indeks-1] = '\0';             //Setter null før etternavnet
      }
      else { strcpy(etternavn,fornavn); }     //Brukeren har ikke flere navn, fornavn = etternavn
  
      //Kopier fornavn og etternavn til brukertabell
      strcpy(brukertabell[linje].brukernavn, sqlite3_column_text(data, 0));
      strcpy(brukertabell[linje].fornavn, fornavn);
      strcpy(brukertabell[linje].etternavn, etternavn);
      linje++;
    }
    else
    {
      strcpy(brukertabell[linje].brukernavn, sqlite3_column_text(data, 0));
      strcpy(brukertabell[linje].fornavn, "");
      strcpy(brukertabell[linje].etternavn, "");
      linje++;
    }
  }
  brukertabell[linje+1].brukernavn[0] = '\0';
  return 0;
}

void skriv_data (konto_t *brukertabell) {
  int i = 0;
  while(brukertabell[i].brukernavn[0] != '\0')
  {
    switch(a) {
      case 0:
        printf("%s,%s,%s\n", brukertabell[i].etternavn, brukertabell[i].fornavn, brukertabell[i].brukernavn);
        break;
      case 1:
        printf("%s,%s,%s\n", brukertabell[i].fornavn, brukertabell[i].etternavn, brukertabell[i].brukernavn);
        break;
      case 2:
        printf("%s,%s,%s\n", brukertabell[i].brukernavn, brukertabell[i].etternavn, brukertabell[i].fornavn);
        break;
    }
     i++;
  }
}
