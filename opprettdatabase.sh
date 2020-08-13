#!/bin/sh
export R=/
export D=5

echo INFO: Henter informasjon om filsystem fra rot $R med dybde på $D...
bash filinfo.sh > filinfo.txt

echo INFO: Oppretter og importerer data til databasen.
sqlite3 passwd.db <<EOF
-- Brukertabell
DROP TABLE IF EXISTS Bruker;
CREATE TABLE Bruker (
  brukernavn varchar(20) NOT NULL,
  passord VARCHAR(50),
  uid SMALLINT NOT NULL,
  gid SMALLINT,
  navn VARCHAR(250),
  hjemmekatalog VARCHAR(100),
  kommandotolker VARCHAR(100),
  PRIMARY KEY(brukernavn),
  UNIQUE(uid)
);

-- Midlertidig tabell for dataimport
DROP TABLE IF EXISTS Staging;
CREATE TABLE Staging (
  tilgang         SMALLINT,
  disknummer      SMALLINT,
  filtype         VARCHAR (20),
  gid             SMALLINT,
  gruppenavn      VARCHAR (20),
  lenker          INT,
  inodenummer     INT,
  monteringspunkt VARCHAR (100),
  filnavn         VARCHAR (100),
  blokkstr        INT,
  filstr          INT,
  uid             SMALLINT,
  brukernavn      VARCHAR (20)
);

.mode csv
.separator ':'
.import /etc/passwd Bruker
.separator ';'
.import ./filinfo.txt Staging

-- Tabell for gruppe
DROP TABLE IF EXISTS Gruppe;
CREATE TABLE Gruppe (
  gruppenavn      VARCHAR (20),
  gid             SMALLINT,
  PRIMARY KEY(gruppenavn)
);

-- Tabell for filsystem
DROP TABLE IF EXISTS Filsystem;
CREATE TABLE Filsystem (
  filnavn          VARCHAR (20),
  inodenummer      SMALLINT,
  disknummer       SMALLINT,
  PRIMARY KEY(filnavn), 
  FOREIGN KEY(inodenummer) REFERENCES Inode(inodenummer), 
  FOREIGN KEY(disknummer) REFERENCES Inode(disknummer)
);

-- Tabell for Inode
DROP TABLE IF EXISTS Inode;
CREATE TABLE Inode (
  inodenummer      INT,
  disknummer       SMALLINT,
  filtype          VARCHAR(20),
  filstr           INT,
  lenker           INT,
  tilgang          SMALLINT,
  brukernavn       VARCHAR(20),
  gruppenavn       VARCHAR(20),
  PRIMARY KEY(inodenummer, disknummer), 
  FOREIGN KEY(brukernavn) REFERENCES Bruker(brukernavn), 
  FOREIGN KEY(gruppenavn) REFERENCES Gruppe(gruppenavn)
);

-- Tabell for maskinvare
DROP TABLE IF EXISTS Maskinvare;
CREATE TABLE Maskinvare (
		disknummer        SMALLINT, 
		monteringspunkt   VARCHAR(100), 
		blokkstr          INT,
		PRIMARY KEY(monteringspunkt, disknummer)
);

-- Tester import via staging...
INSERT OR IGNORE INTO Gruppe SELECT DISTINCT gruppenavn, gid FROM Staging;
INSERT OR IGNORE INTO Filsystem SELECT DISTINCT filnavn, inodenummer, disknummer FROM Staging;
INSERT OR IGNORE INTO Inode SELECT DISTINCT inodenummer, disknummer, filtype, filstr, lenker, tilgang, brukernavn, gruppenavn	FROM Staging;
INSERT OR IGNORE INTO Maskinvare SELECT DISTINCT disknummer, monteringspunkt, blokkstr FROM Staging;

-- All data i riktige tabeller, sletter midlertidig tabell
DROP TABLE Staging;

-- View for � hente ut plassforbruk per bruker
DROP VIEW IF EXISTS BrukerPlass;
CREATE VIEW BrukerPlass AS
    SELECT brukernavn,
           (CASE Instr(navn, ",") WHEN 0 THEN navn ELSE Substr(navn, 0, Instr(navn, ",") ) END) AS fullnavn,
           sum(filstr) AS forbruk
      FROM Bruker
           NATURAL JOIN
           Inode
     GROUP BY brukernavn;

EOF


echo INFO: Fullført. Sletter midlertidig fil.
rm ./filinfo.txt
